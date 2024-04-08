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

# How to use this with retro computers?
When used with the following:
- [linic/docker-tcl-core-x86](https://github.com/linic/docker-tcl-core-x86)
- [linic/openssl-i586](https://github.com/linic/openssl-i586)
it's possible to build an image of Tiny Core Linux which somewhat replicates what would run on a
Pentium II laptop such as the IBM 560Z. This is the image:
- [linic/tcl-core-rust-i586](https://github.com/linic/tcl-core-rust-i586)

After that, it's much easier to deploy rust on a Pentium II laptop with a recent Linux kernel
provided by Tiny Core Linux. Building will still be very slow, but since we have a fully functional
docker image with the same compiler, it should be possible to build on a more powerful machine via
the docker container and then `docker cp` the binaries out of the container.

# May also be relevant...
- [Tiny Core Linux Forum - IBM ThinkPad 560Z Core Project Pentium II](http://forum.tinycorelinux.net/index.php/topic,26359.msg170383.html#msg170383)

# Docker Image
You can find one here 
[https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general](https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general)

# TODO
- Check if I still need the `tools` list in `config.toml` inserted from the `Dockerfile` in the next stable release after 1.77.1
