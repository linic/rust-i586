# rust-i586
Docker image which builds the rust toolchain for i586 processors.

# Usage
To build the latest rust from the stable branch:
`sudo docker compose --progress=plain -f docker-compose.yml build`
To start the container:
`sudo docker compose --progress=plain -f docker-compose.yml up`
To move around and look what was generated:
`sudo docker exec -it rust-i586-rust-i586-1 bash`
To copy the `tar.gz`in which the installer is:
`sudo docker cp rust-i586-rust-i586-1:/rust/build/dist/rust-nightly-i586-unknown-linux-gnu.tar.gz .`

## Note
The build takes about 2 hours on a 10 years old 8 cores CPU with a 2TB SSD.

## Note 2
[linic/docker-tcl-core-x86](https://github.com/linic/docker-tcl-core-x86) may also be relevant.

