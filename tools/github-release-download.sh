#!/bin/sh
wget https://github.com/linic/rust-i586/releases/download/$1/rust-$1-2026-01-31_111117-rust-i586-build-log.txt
wget https://github.com/linic/rust-i586/releases/download/$1/rust-$1-i586-unknown-linux-gnu.tar.gz
wget https://github.com/linic/rust-i586/releases/download/$1/rust-$1-i586-unknown-linux-gnu.tar.gz.bootstrap.toml
wget https://github.com/linic/rust-i586/releases/download/$1/rust-$1-i586-unknown-linux-gnu.tar.gz.md5.txt
wget https://github.com/linic/rust-i586/releases/download/$1/rust-$1-i586-unknown-linux-gnu.tar.gz.sha512.txt
wget https://github.com/linic/rust-i586/releases/download/$1/rust-$1-i586-unknown-linux-gnu.tar.gz.sig
wget https://github.com/linic/rust-i586/releases/download/$1/linic.asc
md5sum -c rust-$1-i586-unknown-linux-gnu.tar.gz.md5.txt
md5sum -c rust-$1-i586-unknown-linux-gnu.tar.gz.sha512.txt
gpg --verify rust-$1-i586-unknown-linux-gnu.tar.gz.sig
