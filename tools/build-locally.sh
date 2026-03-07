#!/bin/sh

###################################################################
# Copyright (C) 2026  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

usage()
{
  echo "usage"
  REQUIRED_ARGUMENTS="RUST_VERSION (see makefile)"
  CALL_EXAMPLE="./build-locally.sh 1.94.0"
  echo "$REQUIRED_ARGUMENTS"
  echo "For example: $CALL_EXAMPLE"
  echo "Note: consider running this in tmux to easily fix issues."
  return 2
}

git_clone_rust()
{
  git clone --depth 1 --branch $RUST_VERSION https://github.com/rust-lang/rust
  cd "$RUST_GIT_DIR"
  git submodule update --init --recursive
}

build()
{
  cd "$RUST_GIT_DIR"
  export CFLAGS="-march=pentium"
  export CXXFLAGS="-march=pentium"
  export RUST_BACKTRACE=full
  # See the comment in config.additional_settings.toml for more details about why tools is set.
  ./configure --set change-id=148795 \
    --set build.extended=true --set build.build=i686-unknown-linux-gnu \
    --set build.host=i586-unknown-linux-gnu --set build.target=i586-unknown-linux-gnu \
    --set build.tools='cargo, clippy' \
    --set llvm.cflags='-lz -fcf-protection=none' --set llvm.cxxflags='-lz -fcf-protection=none' \
    --set llvm.ldflags='-lz -fcf-protection=none' --set llvm.targets=X86 \
    --set llvm.download-ci-llvm=false
  # Check the configuration.
  cat bootstrap.toml
  cd "$COMPILE_DIR"
 ./get-certificate.sh "$COMPILE_DIR"
 ./compare-certificate.sh "$COMPILE_DIR"
 ./trust-certificate.sh "$COMPILE_DIR"
  export CARGO_HTTP_CAINFO="$COMPILE_DIR/cargo-certificates.crt"
  
  cd "$RUST_GIT_DIR"
  # I deactivated the RUN ./x.py check because of memory allocation of 131072 bytes failed error with rust 1.78
  # RUN ./x.py check
  # Build the rust tools and the full installer.
  PKG_CONFIG_ALLOW_CROSS=1 SSL_CERT_FILE=/usr/local/etc/ssl/certs/ca-certificates.crt SSL_CERT_DIR=/usr/local/etc/ssl/certs ./x.py dist -j $CPU_CORES 2>&1 | tee $(date --utc +%F_%H%M%S)-rust-i586-build-log.txt

  # Creating the release dir and copying the files in it.
  RELEASE_DIR="$COMPILE_DIR/release"
  RUST_TAR_GZ="rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz"
  mkdir -pv "$RELEASE_DIR"
  cp "$RUST_GIT_DIR/build/dist/$RUST_TAR_GZ"  "$RELEASE_DIR/"
  cp "$RUST_GIT_DIR/bootstrap.toml" "$RELEASE_DIR/$RUST_TAR_GZ.bootstrap.toml"
  cd "$RELEASE_DIR"
  sha512sum "$RUST_TAR_GZ" > "$RUST_TAR_GZ.sha512.txt"
  md5sum "$RUST_TAR_GZ" > "$RUST_TAR_GZ.md5.txt"
}

main()
{
  if [ $# -lt 1 ]; then
    usage "$@"
    exit "$?"
  fi
  
  RUST_VERSION="$1"
  CPU_CORES=6
  COMPILE_DIR="/home/tc/rust-$RUST_VERSION"
  RUST_GIT_DIR="$COMPILE_DIR/rust"
  mkdir -pv "$COMPILE_DIR"

  # Only copy if we are not in the $COMPILE_DIR because we're likely in the git dir.
  if [ "$PWD" != "$COMPILE_DIR" ]; then
    cp -rv * "$COMPILE_DIR/"
    cp -rv ../certificates/* "$COMPILE_DIR/"
    sudo chown tc:staff *
  fi

  cd "$COMPILE_DIR"
  ./tce-load-build-requirements.sh
  git_clone_rust

  build
  exit "$?"
}

main "$@"
