#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# When building rust-nightly-i586-unknown-linux-gnu.tar.gz,
# cargo contacts index.crates.io and TLS verification fails
# even if ca-certificates is installed. This script trust the
# certificates.
##################################################################

CERTIFICATES_PATH=/home/tc/certificates
export SSL_CERT_FILE=$CERTIFICATES_PATH/cargo-certificates.crt
export CARGO_HTTP_CAINFO=$CERTIFICATES_PATH/cargo-certificates.crt
cd $CERTIFICATES_PATH
awk 'BEGIN {c=0; n=""}
/BEGIN CERTIFICATE/{c++; n="cargo-certificate-" c ".crt"}
{print > n}' cargo-certificates.crt
pwd
ls
sudo cp -v $CERTIFICATES_PATH/cargo-certificate-* /usr/local/share/ca-certificates/
sudo update-ca-certificates

