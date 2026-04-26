# rust-i586

Builds a full Rust toolchain targeting `i586-unknown-linux-gnu` — an i586 (Pentium) target without AVX or illegal instructions — for use on the ThinkPad 560Z (Pentium II) running Tiny Core Linux.

The build runs inside a Docker container based on Tiny Core Linux 17.x/x86. The key configure flags are:

```sh
CFLAGS="-march=pentium"
CXXFLAGS="-march=pentium"
./configure \
    --set change-id=<CHANGE_ID> \
    --set build.extended=true \
    --set build.build=i686-unknown-linux-gnu \
    --set build.host=i586-unknown-linux-gnu \
    --set build.target=i586-unknown-linux-gnu \
    --set build.tools='cargo, clippy' \
    --set llvm.cflags='-lz -fcf-protection=none' \
    --set llvm.cxxflags='-lz -fcf-protection=none' \
    --set llvm.ldflags='-lz -fcf-protection=none' \
    --set llvm.targets=X86 \
    --set llvm.download-ci-llvm=false
```

The `i586` target comes from [Building Rust for a Pentium 2](https://ww1.thecodecache.net/projects/p2-rust/). The target could theoretically make Rust work on original Pentiums, but there is an open bug ([#93059](https://github.com/rust-lang/rust/issues/93059)) about CET opcodes on i586 processors.

## Artifacts

Published on GitHub releases and on a partial mirror at [http://tcz.facedebouc.sbs/](http://tcz.facedebouc.sbs/).

### Downloading from GitHub releases

```sh
./tools/github-release-download.sh 1.93.0
```

### Docker Images

Available on Docker Hub:
[https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general](https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general)

Note: images are large. The 1.86.0 image takes ~42 GB pulled.

## Building

`make build` — builds using Docker (default).  
`make build-locally` — works inside a 32-bit Tiny Core Linux user space.

Approximate build times:
- `make build-locally` for 1.94.0: ~4h 48m on AMD Phenom II X6 + mechanical SATA
- `make build` for 1.86.0: ~3h 8m on AMD FX-9590 + SATA III SSD

The `CHANGE_ID` build arg maps to Rust's `change-id` in `bootstrap.toml`. The correct value for each release appears near the end of the build log (no error is thrown if it's wrong — the build just prints it). Update `Makefile` and `docker-compose.yml` after each successful build.

## Certificate management

Cargo uses `CARGO_HTTP_CAINFO` to validate TLS connections to crates.io, index.crates.io, static.crates.io, and github.com during the build. This variable **completely replaces** the system trust store for cargo; system certificates are ignored.

The build flow:

1. **`get-certificate.sh $DIR`** — fetches live TLS chains from each server into `$DIR/*.crt` and concatenates them into `$DIR/cargo-certificates.crt`.
2. **`compare-certificate.sh $DIR`** — compares live chains against the committed `certificates/*-chain.crt` reference files. Fails the build if they differ, prompting a human review.
3. **`trust-certificate.sh $DIR`** — splits the bundle into individual certs, installs them to `/usr/local/share/ca-certificates/`, runs `update-ca-certificates`, then sets `SSL_CERT_FILE` and `CARGO_HTTP_CAINFO`.
4. **Dockerfile ENV** sets `CARGO_HTTP_CAINFO=/usr/local/etc/ssl/certs/ca-certificates.crt` — after step 3, the system bundle already includes all standard Mozilla root CAs (including GlobalSign Root CA - R3) plus our custom server certs, so cargo trusts them all.

### Updating reference certificates

Servers rotate their leaf certificates roughly every 3 months. When `compare-certificate.sh` fails the build:

1. Run `get-certificate.sh` locally to fetch current chains.
2. Inspect with `tools/show-cert-info.sh` / `tools/cat-cert-info.sh`.
3. Rename the fetched `*.crt` files to `*-chain.crt` and copy to `certificates/`.
4. Commit and re-build.

`static.crates.io` may use two concurrent certificate families during a CA rotation (`static-crates-io-chain.crt` + `static-crates-io-chain2.crt`).

### Why not use TCL system certs directly?

`ca-certificates.tcz` is installed during the build and contains ~146 standard root CAs. `update-ca-certificates` populates `/usr/local/etc/ssl/certs/ca-certificates.crt`. The `SSL_CERT_FILE` variable works for x.py (Python), but cargo ignores it — only `CARGO_HTTP_CAINFO` applies to cargo. Pointing `CARGO_HTTP_CAINFO` to the system bundle (after `update-ca-certificates` has merged our custom certs into it) is the solution adopted since 2026-04-26. See `journal/CERTIFICATES_FRICTION_REMOVAL_PLAN.md` for the full analysis.

## Related projects

- [linic/docker-tcl-core-x86](https://github.com/linic/docker-tcl-core-x86) — base TCL Docker image
- [linic/openssl-i586](https://github.com/linic/openssl-i586) — OpenSSL build for i586
- [linic/tcl-core-rust-i586](https://github.com/linic/tcl-core-rust-i586) — repackages the output of this repo into `.tcz` extensions loadable by Tiny Core Linux

## Context

- [Tiny Core Linux Forum — ThinkPad 560Z Core Project](http://forum.tinycorelinux.net/index.php/topic,26359.msg170383.html#msg170383)

With the toolchain installed on TCL, it's possible to build Rust programs on the 560Z natively. Building is slow, but since the Docker image contains the exact same compiler, cross-compilation via `docker exec` + `docker cp` is the practical workflow.
