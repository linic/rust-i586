# Docker Build 1.95.0

Branch: improving_certificates_handling
Goal: Build and push rust-1.95.0-i586-unknown-linux-gnu via Docker; investigate and reduce certificate-update friction; fix any build errors found along the way.

## State at session start (2026-04-26)

Recent commits:
- `0b8aad3` changing the compile dir in build-locally.sh
- `49df4e8` added CHANGE_ID, CPU_CORES, cleaned the certificates folder
- `0db5bad` 1.94.0
- `1c0298d` 1.93.1 — last known good Docker build

Known bugs spotted while reading (before touching anything):

1. **Dockerfile COPY path mismatch**: `*-chain.crt` reference files are `COPY`'d to `/home/tc/certificates/` but `compare-certificate.sh` receives `$COMPILE_DIR` (`/home/tc/rust-$RUST_VERSION`) and looks for chain files there → compare would always fail in Docker. Works in local build only because `build-locally.sh` copies everything into `$COMPILE_DIR`.

2. **CARGO_HTTP_CAINFO in Dockerfile**: `ENV CARGO_HTTP_CAINFO=/home/tc/certificates/cargo-certificates.crt` but `get-certificate.sh` creates `cargo-certificates.crt` in `$COMPILE_DIR`, not `/home/tc/certificates/`. So that env var points at a non-existent file at build time.

3. **`static-crates-io-download.crt` not compared**: `get-certificate.sh` fetches it (different CA since 2025-07-12) but `compare-certificate.sh` has no corresponding `-chain.crt` check for it.

4. **`CHANGE_ID`**: still set to `148671` (1.94.0 value). Will update from build logs after a successful build (per Nic's guidance — no error thrown, the correct value appears at end of logs).

## Plan

- [x] Create journal
- [x] Add CLAUDE.md to repo
- [x] Update Makefile: RUST_VERSION → 1.95.0
- [ ] Fix Dockerfile path bug (bug #1 above): COPY chain certs to `$COMPILE_DIR` OR pass `/home/tc/certificates` as the cert path consistently
- [ ] Fix CARGO_HTTP_CAINFO path (bug #2)
- [ ] Run `make build`; fix errors one by one
- [ ] Update CHANGE_ID from build logs
- [ ] Investigate certificate issue (why can't cargo use TCL system certs?); document in `certificates/EXPERIMENTS.md`
- [ ] If fix non-trivial: write `journal/CERTIFICATES_FRICTION_REMOVAL_PLAN.md`; discuss with Nic
- [ ] Push Docker image (after Nic confirms)

## Log

### 2026-04-26 — Journal created, Makefile updated, CLAUDE.md added

## Clarifying questions for Nic

*None open.*

## Decisions made without input

- Treating the COPY path mismatch (bug #1) and CARGO_HTTP_CAINFO (bug #2) as errors to fix during the build run — agreed with Nic.
- CHANGE_ID update deferred to after a successful build (will read from logs).

## Things out of scope / left alone

- `build-locally.sh` path changes (separate concern; working on TCL machine).
- `static-crates-io-chain2.crt` dual-chain rotation logic (will note in experiments; not changing without discussion).
