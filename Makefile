# Build rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz
ARCHITECTURE=x86
RUST_VERSION=1.93.0
TCL_VERSION=17.x

.PHONY: all build

all: build

build:
	tools/build.sh ${ARCHITECTURE} ${RUST_VERSION} ${TCL_VERSION}

