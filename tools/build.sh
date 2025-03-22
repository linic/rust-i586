#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# Build the rust-nightly-i586-unknown-linux-gnu.tar.gz and copy
# it out of the docker container.
##################################################################

RUST_VERSION=$1

if [ ! $# -eq 1 ]; then
  echo "Pass the RUST_VERSION to the build.sh script. For example: ./build.sh 1.85.0"
  exit 1
fi

if [ ! -f docker-compose.yml ] || ! grep -q "$RUST_VERSION" docker-compose.yml; then
  echo "Did not find $RUST_VERSION in docker-compose.yml. Rewriting docker-compose.yml."
  echo "services:\n"\
    " main:\n"\
    "   build:\n"\
    "     context: .\n"\
    "     args:\n"\
    "       - RUST_VERSION=$RUST_VERSION\n"\
    "     tags:\n"\
    "       - linichotmailca/rust-i586:$RUST_VERSION\n"\
    "       - linichotmailca/rust-i586:latest\n"\
    "     dockerfile: Dockerfile\n" > docker-compose.yml
fi

sudo docker compose --progress=plain -f docker-compose.yml build
sudo docker compose --progress=plain -f docker-compose.yml up --detach
mkdir -p ./release/$RUST_VERSION/
sudo docker cp rust-i586-main-1:/rust/build/dist/rust-nightly-i586-unknown-linux-gnu.tar.gz  ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz
sudo docker cp rust-i586-main-1:/rust/config.toml  ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.config.toml
sha512sum ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz > ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.sha512sum.txt
gpg --detach-sign ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz

