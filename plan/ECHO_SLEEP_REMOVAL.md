# Plan: Remove echo_sleep.sh

## Problem

`tools/echo_sleep.sh` is set as the Docker image ENTRYPOINT:

```dockerfile
ENTRYPOINT ["/bin/sh", "/home/tc/tools/echo_sleep.sh"]
```

The script runs an infinite counting loop:

```sh
let i=0; while :; do sleep 1; let i++; echo $i; done
```

This causes two problems:

1. **`docker run IMAGE <cmd>` does not run `<cmd>`.** In exec-form ENTRYPOINT, any command or
   arguments passed to `docker run` become arguments to `echo_sleep.sh`, which ignores them.
   The container just counts upward. This makes `docker run --rm` useless for one-off inspection.

2. **`docker compose up --detach` creates a long-lived container** that holds overlayfs resources
   and can interfere with subsequent `docker create` calls or consume disk on the slow HDD.

The script was originally useful to keep a container alive long enough to run `docker cp` against
it interactively. But `docker cp` works on containers in *any* state — Created, Running, or
Stopped. There is no need to keep a container running for this purpose.

## Proposed change

Remove `echo_sleep.sh` and the `ENTRYPOINT` line from the Dockerfile. Update `build.sh` to use
`docker create` instead of `docker compose up --detach`.

### Dockerfile

Remove:

```dockerfile
COPY --chown=tc:staff tools/echo_sleep.sh /home/tc/tools/
ENTRYPOINT ["/bin/sh", "/home/tc/tools/echo_sleep.sh"]
```

### tools/build.sh

Replace:

```sh
sudo docker compose --progress=plain -f docker-compose.yml up --detach
sudo docker cp rust-i586-main-1:/home/tc/rust/build/dist/rust-$RUST_VERSION-...
sudo docker cp rust-i586-main-1:/home/tc/rust/bootstrap.toml ...
```

With:

```sh
sudo docker create --name rust-i586-main-1 linichotmailca/rust-i586:$RUST_VERSION
sudo docker cp rust-i586-main-1:/home/tc/rust/build/dist/rust-$RUST_VERSION-...
sudo docker cp rust-i586-main-1:/home/tc/rust/bootstrap.toml ...
sudo docker rm rust-i586-main-1
```

### tools/echo_sleep.sh

Delete the file.

## What stays the same

All `docker cp` calls remain identical — `docker cp` works on a Created container just as well
as a Running one.

## Risks and mitigations

**Risk:** If `build.sh` is run while a container named `rust-i586-main-1` already exists (from a
previous interrupted run), `docker create` will fail with a "name already in use" error.
**Mitigation:** Add `docker rm rust-i586-main-1 2>/dev/null || true` before the `docker create`
line — the same pattern used by most CI scripts.

**Risk:** Anyone using the Docker image interactively via `docker run` (without `--entrypoint`)
will get a shell that exits immediately rather than a counting loop.
**Mitigation:** The image is primarily used for artifact extraction, not interactive work. The
runbook (`runbook/BUILD_AND_RELEASE.md`) documents `docker create` + `docker cp` as the correct
workflow.

## Status

- [ ] Implement (Dockerfile + build.sh + delete echo_sleep.sh)
- [ ] Verify `docker cp` still works after build completes
- [ ] Merge
