# CLAUDE.md

See /home/code/mes-repertoires-git/collaboration/COLLAB.md for collaboration norms.

## What this repo is

`rust-i586` builds a full Rust toolchain targeting `i586-unknown-linux-gnu` — an i586 (Pentium) without AVX or other instructions that would crash on the ThinkPad 560Z. The build runs inside a Docker container based on Tiny Core Linux (TCL).

## Build modes

- **Docker build** (`make build` → `tools/build.sh`): builds a Docker image, runs the build, copies artifacts out.
- **Local build** (`make build-locally` → `tools/build-locally.sh`): runs on a TCL machine; copies `tools/` and `certificates/` into `$COMPILE_DIR` (`/home/tc/rust-$RUST_VERSION-i586/`) then builds.

## Certificate workflow

Cargo can't use TCL's system certificates, so the build manages its own cert bundle.

**Committed reference certs** (`certificates/*-chain.crt`): manually validated chains, committed to the repo. Updated when servers rotate their certs (every few months for crates.io/static.crates.io/github.com).

**Build-time flow:**
1. `get-certificate.sh $DIR` — fetches live certs from crates.io, static.crates.io (plain + download endpoint), github.com into `$DIR/*.crt` and concatenates them into `$DIR/cargo-certificates.crt`.
2. `compare-certificate.sh $DIR` — diffs live fetched certs against `$DIR/*-chain.crt` reference files.
3. `trust-certificate.sh $DIR` — sets `CARGO_HTTP_CAINFO`, splits bundle, installs to system CA store.

**Updating certs:** run `get-certificate.sh`, inspect with `show-cert-info.sh` / `cat-cert-info.sh`, rename `*.crt` → `*-chain.crt`. If the cert seen in a docker build differs from the host, copy it from docker logs and strip the `#11 111.1 ` prefix (vim macro: `qqd10lq100@q`).

`static.crates.io` uses two concurrent chain files (`static-crates-io-chain.crt` and `static-crates-io-chain2.crt`) because of a CA rotation in progress.

## Branching

Follow COLLAB.md defaults: never commit directly to `main`; use a named branch and PR.
