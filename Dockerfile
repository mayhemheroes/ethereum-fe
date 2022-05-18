FROM --platform=linux/amd64 ubuntu:20.04
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl cmake libboost-all-dev clang

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ADD . /mayhem-fe
WORKDIR /mayhem-fe

RUN  ~/.cargo/bin/cargo build --verbose --features solc-backend; exit 0
RUN echo 3479fd502d44de22 > /root/.cargo/git/checkouts/solc-rust-3479fd502d44de22/52d4146/solidity/commit_hash.txt
RUN  ~/.cargo/bin/cargo build --verbose --features solc-backend

FROM --platform=linux/amd64 ubuntu:20.04

COPY --from=builder /mayhem-fe/target/debug/fe /

