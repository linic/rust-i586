# Build and Release Runbook

Step-by-step commands for building and releasing `rust-i586`. Reader: Claude or Nic.

Before starting, read `notes/DOCKER.md` for Docker-specific surprises (ENTRYPOINT behaviour,
slow HDD, BuildKit log clipping, snapshot errors).

---

## 0. Pre-flight checks

```sh
# Confirm versions in Makefile and docker-compose.yml match the target release
grep "RUST_VERSION\|CHANGE_ID" Makefile docker-compose.yml

# Check committed certificate chains are present
ls certificates/

# Confirm you are on a feature branch, not main
git branch --show-current
```

---

## 1. Start the build

```sh
# From the repo root. Log goes to /tmp for monitoring.
RUST_VERSION=1.95.0
sudo docker compose --progress=plain -f docker-compose.yml build \
    2>&1 | tee /tmp/rust-i586-build-$RUST_VERSION-rN.log &
BUILD_PID=$!
echo "Build PID: $BUILD_PID"
```

Or use `make build` which wraps the above via `tools/build.sh` (but `build.sh` also does
artifact extraction and signing — run it manually step by step if the build is already done).

---

## 2. Monitor the build

The `x.py dist` step takes 10–15 hours. The BuildKit log buffer fills after ~2 MiB of output
per RUN step and silently stops logging. Use these checks rather than watching the log file.

```sh
# Process alive?
ls /proc/$BUILD_PID 2>/dev/null && echo "running" || echo "done"

# Log growth (will plateau when buffer fills — that's normal)
wc -l /tmp/rust-i586-build-$RUST_VERSION-rN.log
tail -5 /tmp/rust-i586-build-$RUST_VERSION-rN.log

# Disk activity on the Docker HDD (sdb1)
awk '/sdb1/{print "writes:",$8,"sectors:",$10,"ios_in_progress:",$12}' /proc/diskstats

# Image updated? (only changes when Docker commits the final layer)
docker images --format "{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}" | grep rust-i586
```

Build is done when: process exits AND image timestamp is newer than the start time.

---

## 3. Confirm success and check CHANGE_ID

```sh
# Check build exit via log tail
tail -20 /tmp/rust-i586-build-$RUST_VERSION-rN.log

# Verify image was created
docker inspect linichotmailca/rust-i586:$RUST_VERSION \
    --format "ID: {{.Id}}\nCreated: {{.Created}}\nSize: {{.Size}}"

# Confirm CHANGE_ID is current for this Rust version
# (last entry in CONFIG_CHANGE_HISTORY array = correct value; no update needed if it matches Makefile)
gh api "repos/rust-lang/rust/contents/src/bootstrap/src/utils/change_tracker.rs?ref=$RUST_VERSION" \
    --jq '.content' | base64 -d | grep "change_id:" | tail -3
```

If the last `change_id` in the file matches `CHANGE_ID` in the Makefile, no update is needed.
If it differs, update `CHANGE_ID=` in `Makefile` and the `- CHANGE_ID=` line in `docker-compose.yml`.

---

## 4. Handle the BuildKit snapshot error (if it appeared)

If the build log ends with `ERROR: failed to prepare extraction snapshot … parent snapshot … does not exist`,
the image is still intact. The `latest` tag may not have been set. Fix it manually:

```sh
docker tag linichotmailca/rust-i586:$RUST_VERSION linichotmailca/rust-i586:latest
```

---

## 5. Extract artifacts

`docker create` + `docker cp` works on any container state (Created/Running/Stopped).
On the mechanical HDD, `docker create` from a 20 GB image takes ~12 minutes — not hung, just slow.

```sh
RUST_VERSION=1.95.0
docker create --name rust-i586-extract linichotmailca/rust-i586:$RUST_VERSION

mkdir -p release/$RUST_VERSION

docker cp rust-i586-extract:/home/tc/rust/build/dist/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz \
    release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz

docker cp rust-i586-extract:/home/tc/rust/bootstrap.toml \
    release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.bootstrap.toml

docker rm rust-i586-extract
```

Verify the tarball looks sane:

```sh
ls -lh release/$RUST_VERSION/
tar -tzf release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz | head -10
```

---

## 6. Checksums and GPG signature

```sh
cd release/$RUST_VERSION

sha512sum rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz \
    > rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.sha512.txt

md5sum rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz \
    > rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.md5.txt

gpg --detach-sign rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz

cd -
```

GPG requires Nic's key passphrase.

---

## 7. Push Docker image

Confirm with Nic before pushing. Docker Hub credentials must be active (`docker login`).

```sh
docker push linichotmailca/rust-i586:$RUST_VERSION
docker push linichotmailca/rust-i586:latest
```

---

## 8. Commit and push release artifacts

```sh
git add release/$RUST_VERSION/
git status  # confirm only the expected files
git commit -m "release: rust-$RUST_VERSION-i586-unknown-linux-gnu artifacts"
git push origin <branch>
```

Then open a PR and follow the merge flow in `collaboration/COLLAB.md`.

---

## 9. Cleanup

```sh
# Remove any leftover extract containers
docker ps -a | grep extract
docker rm rust-i586-extract 2>/dev/null

# Remove large temp dirs if created during debugging
rm -rf /tmp/rust-dist-list /tmp/rust-i586-dist-check /tmp/rust-i586-rust-root-check
```

---

## Updating certificate chains (when compare-certificate.sh fails)

Leaf certs rotate every ~3 months for github.com, crates.io, static.crates.io.

```sh
# Fetch live chains
./tools/get-certificate.sh /tmp/cert-update

# Inspect
./tools/show-cert-info.sh /tmp/cert-update
./tools/cat-cert-info.sh /tmp/cert-update

# Commit updated chains (rename fetched *.crt → *-chain.crt)
cp /tmp/cert-update/crates-io.crt       certificates/crates-io-chain.crt
cp /tmp/cert-update/static-crates-io.crt certificates/static-crates-io-chain.crt
cp /tmp/cert-update/github-com.crt       certificates/github-com-chain.crt

git add certificates/
git commit -m "certs: update chain files for <date>"
```

See `plan/CERTIFICATES_FRICTION_REMOVAL_PLAN.md` for why `CARGO_HTTP_CAINFO` points to the system
bundle and what friction remains.
