# Build rust-$RUST_VERSION-i586-unknown-linux-gnu.tar.gz
ARCHITECTURE=x86
CHANGE_ID=148671
CPU_CORES=6
RUST_VERSION=1.95.0
TCL_VERSION=17.x

.PHONY: all build build-locally

all: build

build:
	tools/build.sh ${ARCHITECTURE} ${CHANGE_ID} ${CPU_CORES} ${RUST_VERSION} ${TCL_VERSION}

build-locally:
	tools/build-locally.sh ${RUST_VERSION} ${CHANGE_ID} ${CPU_CORES}
