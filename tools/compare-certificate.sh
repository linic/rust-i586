#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# When building rust-nightly-i586-unknown-linux-gnu.tar.gz,
# cargo contacts index.crates.io and TLS verification fails
# even if ca-certificates is installed.
# This script validates if the certificate downloaded by
# https://github.com/linic/rust-i586/tools/get-certificate.sh is
# the same as the certificate chain obtained manually from a web
# browser and copied at 
# https://github.com/linic/rust-i586/certificates/crates-io-chain.crt
##################################################################

CERTIFICATES_PATH=/home/tc/certificates
if diff -u -Z $CERTIFICATES_PATH/crates-io-chain.crt $CERTIFICATES_PATH/crates-io.crt; then
 echo "Certificates from crates.io match."
else
 echo "Certificates from crates.io do not match!"
 echo "!!!!!! Expected:"
 cat $CERTIFICATES_PATH/crates-io-chain.crt
 echo "!!!!!! Obtained:"
 cat $CERTIFICATES_PATH/crates-io.crt
 exit 1
fi

if diff -u -Z $CERTIFICATES_PATH/static-crates-io-chain.crt $CERTIFICATES_PATH/static-crates-io.crt; then
 echo "Certificates from static.crates.io match."
else
 echo "Certificates from static.crates.io do not match!"
 echo "!!!!!! Expected:"
 cat $CERTIFICATES_PATH/static-crates-io-chain.crt
 echo "!!!!!! Obtained:"
 cat $CERTIFICATES_PATH/static-crates-io.crt
 echo "Trying again with $CERTIFICATES_PATH/static-crates-io-chain2.crt"
fi

if diff -u -Z $CERTIFICATES_PATH/static-crates-io-chain2.crt $CERTIFICATES_PATH/static-crates-io.crt; then
 echo "Certificates from static.crates.io match."
else
 echo "Certificates from static.crates.io do not match!"
 echo "!!!!!! Expected:"
 cat $CERTIFICATES_PATH/static-crates-io-chain2.crt
 echo "!!!!!! Obtained:"
 cat $CERTIFICATES_PATH/static-crates-io.crt
 exit 2
fi

if diff -u -Z $CERTIFICATES_PATH/github-com-chain.crt $CERTIFICATES_PATH/github-com.crt; then
 echo "Certificates from github.com match."
else
 echo "Certificates from github.com do not match!"
 echo "!!!!!! Expected:"
 cat $CERTIFICATES_PATH/github-com-chain.crt
 echo "!!!!!! Obtained:"
 cat $CERTIFICATES_PATH/github-com.crt
 exit 3
fi

