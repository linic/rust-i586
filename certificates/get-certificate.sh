#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# When building rust-nightly-i586-unknown-linux-gnu.tar.gz,
# cargo contacts index.crates.io and TLS verification fails
# even if ca-certificates is installed. This script gets the
# certificate certificate chain from the server.
# Manual comparison with certificates obtained and verified
# manually is advised.
##################################################################

CERTIFICATES_PATH=.
mkdir -p $CERTIFICATES_PATH
echo "Q" | openssl s_client -showcerts -timeout -servername crates.io crates.io:443 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERTIFICATES_PATH/crates-io.crt
# 2025-07-12 - This gives a certificate from amazon, because it hits https://cloudfront-static.crates.io/ now
echo "Q" | openssl s_client -showcerts -timeout -servername static.crates.io static.crates.io:443 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERTIFICATES_PATH/static-crates-io.crt
# 2025-07-12 - When downloading crates, the certificate is different.
echo "Q" | openssl s_client -showcerts -timeout https://static.crates.io/crates/aho-corasick/1.1.3/download 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERTIFICATES_PATH/static-crates-io-download.crt
echo "Q" | openssl s_client -showcerts -timeout -servername github.com github.com:443 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERTIFICATES_PATH/github-com.crt
#openssl s_client -showcerts index.crates.io:443 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERTIFICATES_PATH/index-crates-io.crt
cat $CERTIFICATES_PATH/crates-io.crt > $CERTIFICATES_PATH/cargo-certificates.crt
cat $CERTIFICATES_PATH/static-crates-io.crt >> $CERTIFICATES_PATH/cargo-certificates.crt
cat $CERTIFICATES_PATH/static-crates-io-download.crt >> $CERTIFICATES_PATH/cargo-certificates.crt
cat $CERTIFICATES_PATH/github-com.crt >> $CERTIFICATES_PATH/cargo-certificates.crt
#cat $CERTIFICATES_PATH/index-crates-io.crt >> $CERTIFICATES_PATH/cargo-certificates.crt

