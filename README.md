# rust-i586
Docker image which builds the rust toolchain for i586 processors. I use it on my ThinkPad 560z with a PII (i686) which has only 64 MB of RAM.

# Usage
`make` does it all. Note that the build of 1.86.0 took 3 hours 8 minutes on my AMD FX-9590 with a SATA III Samsung SSD.

# May also be relevant...
- [Tiny Core Linux Forum - IBM ThinkPad 560Z Core Project Pentium II](http://forum.tinycorelinux.net/index.php/topic,26359.msg170383.html#msg170383)

# Docker Images
You can find them here:
[https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general](https://hub.docker.com/repository/docker/linichotmailca/rust-i586/general)
Note that they are big. Once pulled, the 1.86.0 one takes 42 GB on my computer.

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

# Historical
Before the [Makefile](./Makefile) and the [build.sh](./tools/build.sh) I would run these commands manually.
Also, before 1.86.0, I would use the debian latest image as the base image. Since 1.86.0, I'm using a tinycore
image [which you can learn more about here](https://github.com/linic/docker-tcl-core-x86).
## Usage
To build the latest rust from the stable branch:
`sudo docker compose --progress=plain -f docker-compose.yml build`
To start the container:
`sudo docker compose --progress=plain -f docker-compose.yml up`
or `sudo docker compose up`
To move around and look what was generated:
`sudo docker exec -it rust-i586-main-1 bash`
To copy the `tar.gz`in which the installer is:
`sudo docker cp rust-i586-main-1:/rust/build/dist/rust-nightly-i586-unknown-linux-gnu.tar.gz .`

