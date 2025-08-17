ARG ARCHITECTURE
ARG RUST_VERSION
ARG TCL_VERSION
FROM linichotmailca/tcl-core-x86:$TCL_VERSION-$ARCHITECTURE
ARG RUST_VERSION
ARG CPU_CORES=8
WORKDIR /home/tc/tools/
COPY --chown=tc:staff tools/tce-load-build-requirements.sh .
RUN ./tce-load-build-requirements.sh
WORKDIR /home/tc/
RUN git clone --depth 1 --branch $RUST_VERSION https://github.com/rust-lang/rust
WORKDIR /home/tc/rust/
RUN git submodule update --init --recursive
ENV CFLAGS="-march=pentium"
ENV CXXFLAGS="-march=pentium"
ENV RUST_BACKTRACE=full
# See the comment in config.additional_settings.toml for more details about why tools is set.
RUN ./configure --set change-id=142379 \
    --set build.extended=true --set build.build=i686-unknown-linux-gnu \
    --set build.host=i586-unknown-linux-gnu --set build.target=i586-unknown-linux-gnu \
    --set build.tools='cargo, clippy' \
    --set llvm.cflags='-lz -fcf-protection=none' --set llvm.cxxflags='-lz -fcf-protection=none' \
    --set llvm.ldflags='-lz -fcf-protection=none' --set llvm.targets=X86 \
    --set llvm.download-ci-llvm=false
# Check the configuration.
RUN cat bootstrap.toml
WORKDIR /home/tc/tools/
COPY --chown=tc:staff tools/get-certificate.sh .
RUN ./get-certificate.sh
COPY --chown=tc:staff certificates/crates-io-chain.crt /home/tc/certificates/
COPY --chown=tc:staff certificates/static-crates-io-chain.crt /home/tc/certificates/
COPY --chown=tc:staff certificates/github-com-chain.crt /home/tc/certificates/
COPY --chown=tc:staff tools/compare-certificate.sh .
RUN ./compare-certificate.sh
COPY --chown=tc:staff tools/trust-certificate.sh .
RUN /home/tc/tools/trust-certificate.sh
ENV CARGO_HTTP_CAINFO=/home/tc/certificates/cargo-certificates.crt
WORKDIR /home/tc/rust/
# I deactivated the RUN ./x.py check because of memory allocation of 131072 bytes failed error with rust 1.78
# RUN ./x.py check
# Build the rust tools and the full installer.
RUN PKG_CONFIG_ALLOW_CROSS=1 ./x.py dist -j $CPU_CORES 2>&1 | tee $(date --utc +%F_%H%M%S)-rust-i586-build-log.txt
# Then if you docker compose build you'll be able to docker exec -it into it and move around or
# docker cp files out of it.
COPY --chown=tc:staff tools/echo_sleep.sh /home/tc/tools/
ENTRYPOINT ["/bin/sh", "/home/tc/tools/echo_sleep.sh"]

