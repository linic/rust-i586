#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# Required .tcz to be able to build the
# rust-nightly-i586-unknown-linux-gnu.tar.gz
##################################################################

tce-load -wi cmake.tcz compiletc.tcz gcc.tcz git.tcz zlib_base-dev.tcz openssl-dev.tcz openssl.tcz curl.tcz ninja.tcz python3.9.tcz

