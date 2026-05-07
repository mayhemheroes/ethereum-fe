FROM --platform=linux/amd64 rustlang/rust:nightly AS builder

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake libboost-all-dev clang && \
    rm -rf /var/lib/apt/lists/*

ADD . /mayhem-fe
WORKDIR /mayhem-fe

RUN cargo build --release

RUN mkdir -p /deps && \
    ldd /mayhem-fe/target/release/fe | tr -s '[:blank:]' '\n' | grep '^/' | xargs -I % sh -c 'cp % /deps;'

FROM debian:trixie-slim AS package

COPY --from=builder /deps /deps
COPY --from=builder /mayhem-fe/target/release/fe /mayhem-fe/target/release/fe
ENV LD_LIBRARY_PATH=/deps
