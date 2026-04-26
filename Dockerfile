ARG ARCHITECTURE
ARG CHANGE_ID
ARG RUST_VERSION
ARG TCL_VERSION
ARG CHANGE_ID
FROM linichotmailca/tcl-core-x86:$TCL_VERSION-$ARCHITECTURE
ARG CHANGE_ID
ARG RUST_VERSION
ARG CPU_CORES=8
# The base image sets USER tc, but the 17.x image has /tmp without world-write
# and sudo without its SUID bit, which breaks tce-load. Fix both as root before
# switching back to tc for the rest of the build.
USER root
RUN chmod 1777 /tmp && chown -R tc:staff /tmp/tce /tmp/tcloop && chmod u+s /usr/bin/sudo \
    && chown tc:staff /home/tc
USER tc
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
RUN ./configure --set change-id=$CHANGE_ID \
    --set build.extended=true --set build.build=i686-unknown-linux-gnu \
    --set build.host=i586-unknown-linux-gnu --set build.target=i586-unknown-linux-gnu \
    --set build.tools='cargo, clippy' \
    --set llvm.cflags='-lz -fcf-protection=none' --set llvm.cxxflags='-lz -fcf-protection=none' \
    --set llvm.ldflags='-lz -fcf-protection=none' --set llvm.targets=X86 \
    --set llvm.download-ci-llvm=false
# Check the configuration.
RUN cat bootstrap.toml
WORKDIR /home/tc/tools/
ENV COMPILE_DIR="/home/tc/rust-$RUST_VERSION"
COPY --chown=tc:staff certificates/globalsign-root-ca-r3.crt /home/tc/certificates/
COPY --chown=tc:staff tools/get-certificate.sh .
RUN cp /home/tc/certificates/globalsign-root-ca-r3.crt $COMPILE_DIR/ && ./get-certificate.sh $COMPILE_DIR
COPY --chown=tc:staff certificates/crates-io-chain.crt /home/tc/certificates/
COPY --chown=tc:staff certificates/static-crates-io-chain.crt /home/tc/certificates/
COPY --chown=tc:staff certificates/github-com-chain.crt /home/tc/certificates/
COPY --chown=tc:staff tools/compare-certificate.sh .
RUN cp /home/tc/certificates/*-chain.crt $COMPILE_DIR/ && ./compare-certificate.sh $COMPILE_DIR
COPY --chown=tc:staff tools/trust-certificate.sh .
RUN /home/tc/tools/trust-certificate.sh $COMPILE_DIR
ENV CARGO_HTTP_CAINFO=$COMPILE_DIR/cargo-certificates.crt
WORKDIR /home/tc/rust/
# I deactivated the RUN ./x.py check because of memory allocation of 131072 bytes failed error with rust 1.78
# RUN ./x.py check
# Build the rust tools and the full installer.
RUN PKG_CONFIG_ALLOW_CROSS=1 SSL_CERT_FILE=/usr/local/etc/ssl/certs/ca-certificates.crt SSL_CERT_DIR=/usr/local/etc/ssl/certs ./x.py dist -j $CPU_CORES 2>&1 | tee $(date --utc +%F_%H%M%S)-rust-i586-build-log.txt
# Then if you docker compose build you'll be able to docker exec -it into it and move around or
# docker cp files out of it.
COPY --chown=tc:staff tools/echo_sleep.sh /home/tc/tools/
ENTRYPOINT ["/bin/sh", "/home/tc/tools/echo_sleep.sh"]

