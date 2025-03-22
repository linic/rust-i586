# Build rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz
RUST_VERSION=1.85.0

all: build

build:
	tools/build.sh ${RUST_VERSION}

