#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# Copy rust-nightly-i586-unknown-linux-gnu.tar.gz
# out of the docker container.
##################################################################

PARAMETER_ERROR_MESSAGE="RUST_VERSION is required. For example: 1.88.0"
if [ ! $# -eq 1 ]; then
  echo $PARAMETER_ERROR_MESSAGE
  exit 1
fi
RUST_VERSION=$1

# Since 1.88.0, the tar.gz has the version number in its name.
sudo docker cp rust-i586-main-1:/home/tc/rust/build/dist/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz  ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz
sudo docker cp rust-i586-main-1:/home/tc/rust/bootstrap.toml  ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.bootstrap.toml
sha512sum ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz > ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.sha512.txt
md5sum ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz > ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.md5.txt
gpg --detach-sign ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz

