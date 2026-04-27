# Docker Notes for rust-i586

Observations and surprises for future Claude (and Nic) working on this repo.

---

## The ENTRYPOINT trap: `echo_sleep.sh`

The Dockerfile sets:

```dockerfile
ENTRYPOINT ["/bin/sh", "/home/tc/tools/echo_sleep.sh"]
```

`echo_sleep.sh` runs an infinite counting loop:

```sh
let i=0; while :; do sleep 1; let i++; echo $i; done
```

**What this means in practice:**

- `docker run IMAGE some-command` does NOT run `some-command`. In exec-form ENTRYPOINT, any CMD or extra arguments are passed as arguments to `echo_sleep.sh`, which ignores them. The container just counts: 1, 2, 3…
- `docker run --rm IMAGE ls /home/tc/rust/*.txt` returns `1\n2\n3…`, not a file listing.
- You cannot use `docker run IMAGE <cmd>` to inspect container contents or run one-off commands without `--entrypoint`:

```sh
docker run --rm --entrypoint ls IMAGE /home/tc/rust/*.txt
```

- `docker compose up --detach` starts a long-lived container (which is how Nic originally used it — to keep a container alive for `docker cp`). This can leave orphaned containers holding disk resources across sessions.

**The better workflow for artifact extraction** is `docker create` + `docker cp`:

```sh
docker create --name extract linichotmailca/rust-i586:$VERSION
docker cp extract:/home/tc/rust/build/dist/rust-$VERSION-i586-unknown-linux-gnu.tar.gz ./
docker rm extract
```

`docker cp` works on containers in any state (Created, Running, Stopped). No need to start them.

See `plan/ECHO_SLEEP_REMOVAL.md` for the planned removal of `echo_sleep.sh`.

---

## Mechanical HDD on sdb1 — expect long waits

Docker data lives on `/mnt/sdb1/docker` (mechanical SATA drive, not SSD).

- **`docker compose build`** writes tens of GB of layer data during the final export step. This is slow. The x.py dist layer alone is ~20 GB.
- **`docker create` from a large image** (20 GB) takes **~12 minutes** on this drive as overlayfs extracts the layer chain. Do not assume the command is hung — it is just slow.
- **Build times** are longer than they would be on SSD. The full rust-i586 build took ~14h 51m for 1.95.0.

**Monitoring disk activity:**

```sh
awk '/sdb1/{print "writes_completed:",$8,"sectors_written:",$10,"ios_in_progress:",$12}' /proc/diskstats
```

If `ios_in_progress` > 0, Docker is actively reading or writing. Wait.

---

## BuildKit log buffer: 2 MiB per RUN step

BuildKit buffers each `RUN` step's output in a **2 MiB per-step buffer**. When the buffer fills:

- Output is silently dropped.
- The log file grows to a certain line count and then stops growing.
- You will see `[output clipped, log limit 2MiB reached]` as the last line.
- The build is **still running** — just not logging.

The `x.py dist` step generates far more than 2 MiB of output (hours of compilation). Expect two to three buffer-fill cycles during a full build.

**Do not mistake log silence for build completion or failure.** Check the process and disk instead:

```sh
# Process still alive?
ls /proc/$PID 2>/dev/null && echo "running" || echo "done"

# Disk still writing?
awk '/sdb1/{print $10}' /proc/diskstats   # sectors written — compare across checks

# Image updated? (only changes when Docker commits the final layer)
docker images --format "{{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | grep rust-i586
```

---

## BuildKit "parent snapshot" error — not real corruption

At the end of a long build, BuildKit may print:

```
ERROR: failed to prepare extraction snapshot "...": parent snapshot sha256:f17c... does not exist: not found
```

**This fires after the image is already fully written, named, and unpacked.** It is a post-export validation artifact, not data corruption.

Consequences:
- The image exists and is usable (`docker images`, `docker inspect`, `docker create`, `docker cp` all work).
- `docker compose build` exits non-zero (because the step failed), so `build.sh` prints "Build failed!" and stops.
- Any Docker image tags applied **after** the error-triggering tag are **not set**. In the 1.95.0 build, `1.95.0` was tagged before the error; `latest` was not.

**Workaround:** manually set the missing tags after confirming the image is intact:

```sh
docker tag linichotmailca/rust-i586:$VERSION linichotmailca/rust-i586:latest
```

---

## Checking if a build process is still alive

Do not use `kill -0 $PID` — it fails with "Operation not permitted" for root-owned processes when running as a non-root user. Use:

```sh
ls /proc/$PID 2>/dev/null && echo "running" || echo "done"
```

---

## The dist directory inside the container

After a successful build, `/home/tc/rust/build/dist/` inside the container contains ~11 packages (`.tar.gz` + `.tar.xz` pairs):

| Package | Notes |
|---------|-------|
| `rust-$V-i586-unknown-linux-gnu.tar.gz` | Combined toolchain — **this is the release artifact** |
| `cargo-$V-i586-unknown-linux-gnu.tar.gz` | cargo only |
| `rustc-$V-i586-unknown-linux-gnu.tar.gz` | rustc only |
| `rustc-dev-$V-i586-unknown-linux-gnu.tar.gz` | rustc dev tools |
| `rust-dev-$V-i586-unknown-linux-gnu.tar.gz` | dev package |
| `rust-std-$V-i586-unknown-linux-gnu.tar.gz` | std lib only |
| `rust-docs-$V-i586-unknown-linux-gnu.tar.gz` | HTML docs |
| `rust-docs-json-$V-i586-unknown-linux-gnu.tar.gz` | JSON docs |
| `rust-src-$V.tar.gz` | Source package |
| `rustc-$V-src.tar.gz` | Source with vendored deps |
| `rustc-$V-src-gpl.tar.gz` | GPL source variant |

`build.sh` only copies the combined tarball. The rest are available inside the container if needed.
