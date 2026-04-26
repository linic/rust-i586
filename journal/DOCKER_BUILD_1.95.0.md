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
- [x] Fix Dockerfile path bug (bug #1): cp chain certs into COMPILE_DIR before compare
- [x] Fix CARGO_HTTP_CAINFO path (bug #2): point to `$COMPILE_DIR/cargo-certificates.crt`
- [x] Fix stale COPY of deleted `static-crates-io-chain2.crt` (bug #3)
- [x] Fix 17.x-x86 base image regressions: /tmp perms, sudo SUID, /home/tc ownership
- [x] Fix expired github.com leaf cert (rotated Jan→Mar 2026)
- [x] Fix missing GlobalSign Root CA R3 in cargo bundle (index.crates.io switched from Amazon to GlobalSign in early 2026)
- [x] Fix crates.io cert (switched from Amazon RSA 2048 M04 to GlobalSign Atlas Q4 between Mar 5 and Apr 26)
- [x] Verify x.py dist proceeds past cargo SSL errors (confirmed in build r5)
- [ ] Confirm x.py dist completes fully end-to-end (build r5 in progress — compiling stage1)
- [ ] Update CHANGE_ID from build logs
- [x] Investigate remaining cert friction; write `journal/CERTIFICATES_FRICTION_REMOVAL_PLAN.md` — drafted, pending discussion
- [ ] Push Docker image (after Nic confirms)

## Log

### 2026-04-26 — Journal created, Makefile updated, CLAUDE.md added

### 2026-04-26 — Dockerfile fixes (path bugs, 17.x-x86 regressions)

Fixed 3 Dockerfile path bugs (bugs #1-3 from starting point). Then discovered the `17.x-x86` floating tag was updated and introduced 3 regressions: `/tmp` lost world-write, `sudo` lost SUID bit, `/home/tc` changed ownership to root. Fixed with a `USER root` RUN block at the start of the Dockerfile.

### 2026-04-26 — Cert investigation: github.com + index.crates.io

Build r2 got through tce-load, git clone, configure, and cert comparison — but failed at `./x.py dist` because cargo couldn't validate `index.crates.io`. Root cause identified:
- github.com leaf cert expired (Jan 6 → Apr 5 2026); updated chain file
- index.crates.io switched from Amazon Trust Services to GlobalSign (between Nov 2025 and Apr 2026)
- Neither index.crates.io nor static.crates.io sends GlobalSign Root CA - R3 in their TLS chain
- CARGO_HTTP_CAINFO replaces the system trust store entirely, so the root must be in the bundle
- Added `certificates/globalsign-root-ca-r3.crt` (self-signed, valid 2009-2029)
- Updated `get-certificate.sh` to append it if present; Dockerfile COPYs it before get-certificate.sh runs

Build r3 running — verifying x.py dist proceeds.

### 2026-04-26 — crates.io CA rotation; build r5 clears all SSL errors

Build r3 failed compare-certificate.sh: crates.io had also switched from Amazon RSA 2048 M04 to GlobalSign Atlas R3 DV TLS CA 2025 Q4 (sometime between Mar 5 and Apr 26, 2026). Fetched new chain, updated `certificates/crates-io-chain.crt` (now 2 certs instead of 3; GlobalSign root handled by globalsign-root-ca-r3.crt).

Build r4 ran compare-certificate.sh correctly but hit a sequencing bug: `cp globalsign-root-ca-r3.crt` ran before `mkdir -p $COMPILE_DIR`. Fixed by merging mkdir + cp + get-certificate.sh into one RUN step.

Build r5: all cert issues resolved.
- At ~31s: `Updating crates.io index` — index.crates.io SSL verified ✓
- At ~34s: `Downloaded cc v1.2.28` — crate download from static.crates.io ✓
- At ~100s: `Finished dev profile [unoptimized] target(s) in 1m 09s` — bootstrap compiled ✓
- At ~108s: `Building stage1 unstable-book-gen` — multi-hour Rust compilation underway

Build r5 is currently running. CHANGE_ID and final success pending.

## Clarifying questions for Nic

*None open.*

## Decisions made without input

- Treating the COPY path mismatch (bug #1) and CARGO_HTTP_CAINFO (bug #2) as errors to fix during the build run — agreed with Nic.
- CHANGE_ID update deferred to after a successful build (will read from logs).

## Things out of scope / left alone

- `build-locally.sh` path changes (separate concern; working on TCL machine).
- `static-crates-io-chain2.crt` dual-chain rotation logic (will note in experiments; not changing without discussion).
