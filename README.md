# rust-i586
Docker image which builds the rust toolchain for i586 processors.

# Usage
To build the latest rust from the stable branch: 
`sudo docker compose --progress=plain -f docker-compose.yml build` 
To start the container: 
`sudo docker compose --progress=plain -f docker-compose.yml up`
or `sudo docker compose up`
To move around and look what was generated:
`sudo docker exec -it rust-i586-main-1 bash`
To copy the `tar.gz`in which the installer is:
`sudo docker cp rust-i586-main-1:/rust/build/dist/rust-nightly-i586-unknown-linux-gnu.tar.gz .`

## Note
The build takes about 2 hours on a 10 years old 8 cores CPU with a 2TB SSD.

## Note 2
[linic/docker-tcl-core-x86](https://github.com/linic/docker-tcl-core-x86) may also be relevant.

# Docker Image
You can find one here 
[https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general](https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general)

# TODO
Create another repo and corresponding image for `libssl.so.1.1` and `libcrypto.so.1.1` needed by 
[linichotmailca/tcl-core-x86](https://hub.docker.com/repository/docker/linichotmailca/tcl-core-x86/general) to run `cargo new` 
and then make a repo to generate `tcl-core-rust-i586` image which will have a rust dev environment to build rust programs for i586 CPUs.
