FROM debian:latest
ARG CPU_CORES=8
WORKDIR /tmp/
RUN apt update
RUN apt dist-upgrade
RUN dpkg --add-architecture i386
RUN apt update
COPY apt_packages.txt .
RUN xargs apt install --yes < apt_packages.txt
WORKDIR /
RUN git clone https://github.com/rust-lang/rust
WORKDIR /rust/
RUN git checkout stable
RUN git submodule update --init --recursive
ENV CFLAGS="-march=pentium"
ENV CXXFLAGS="-march=pentium"
ENV RUST_BACKTRACE=full
RUN ./configure --set build.extended=true --set build.build=i686-unknown-linux-gnu \
    --set build.host=i586-unknown-linux-gnu --set build.target=i586-unknown-linux-gnu \
    --set llvm.cflags="-lz -fcf-protection=none" --set llvm.cxxflags="-lz -fcf-protection=none" \
    --set llvm.ldflags="-lz -fcf-protection=none" --set llvm.targets=X86 \
    --set llvm.download-ci-llvm=false
RUN ./x.py check
RUN PKG_CONFIG_ALLOW_CROSS=1 ./x.py dist -j $CPU_CORES 2>&1 | tee $(date --utc +%F_%H%M%S)-rust-i586-build-log.txt
# Then if you docker compose build you'll be able to docker exec -it into it and move around or
# docker cp files out of it.
COPY echo_sleep /
RUN chmod +x /echo_sleep
ENTRYPOINT ["/bin/bash", "/echo_sleep"]

