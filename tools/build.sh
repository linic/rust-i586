#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# Build the rust-nightly-i586-unknown-linux-gnu.tar.gz and copy
# it out of the docker container.
##################################################################

PARAMETER_ERROR_MESSAGE="ARCHITECTURE CHANGE_ID CPU_CORES RUST_VERSION TCL_VERSION are required. For example: ./build.sh x86 148671 8 1.94.0 17.x"
if [ ! $# -eq 5 ]; then
  echo $PARAMETER_ERROR_MESSAGE
  exit 1
fi
ARCHITECTURE=$1
if [ $ARCHITECTURE != "x86" ]; then
  echo "ARCHITECTURE can only be x86 for now."
  exit 2
fi
CHANGE_ID=$2
CPU_CORES=$3
RUST_VERSION=$4
TCL_VERSION=$5

if [ ! -f docker-compose.yml ] || ! grep -q "$RUST_VERSION" docker-compose.yml || ! grep -q "$TCL_VERSION" docker-compose.yml; then
  echo "Did not find $RUST_VERSION in docker-compose.yml. Rewriting docker-compose.yml."
  echo "services:\n"\
    " main:\n"\
    "   build:\n"\
    "     context: .\n"\
    "     args:\n"\
    "       - ARCHITECTURE=$ARCHITECTURE\n"\
    "       - CHANGE_ID=$CHANGE_ID\n"\
    "       - CPU_CORES=$CPU_CORES\n"\
    "       - RUST_VERSION=$RUST_VERSION\n"\
    "       - TCL_VERSION=$TCL_VERSION\n"\
    "     tags:\n"\
    "       - linichotmailca/rust-i586:$RUST_VERSION\n"\
    "       - linichotmailca/rust-i586:latest\n"\
    "     dockerfile: Dockerfile\n" > docker-compose.yml
fi

if sudo docker compose --progress=plain -f docker-compose.yml build; then
  echo "Build succeeded."
else
  echo "Build failed!"
  exit 3
fi
sudo docker compose --progress=plain -f docker-compose.yml up --detach
mkdir -p ./release/$RUST_VERSION/
# Since 1.88.0, the tar.gz has the version number in its name.
sudo docker cp rust-i586-main-1:/home/tc/rust/build/dist/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz  ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz
sudo docker cp rust-i586-main-1:/home/tc/rust/bootstrap.toml  ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.bootstrap.toml
sha512sum ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz > ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.sha512.txt
md5sum ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz > ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz.md5.txt
gpg --detach-sign ./release/$RUST_VERSION/rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz

