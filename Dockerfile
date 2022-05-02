# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder
SHELL ["/bin/bash", "-c"]
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl cmake libboost-all-dev clang
# RUN DEBIAN_FRONTEND=noninteractive apt-get install -y source
# RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget

# RUN wget https://github.com/ethereum/fe/releases/download/v0.15.0-alpha/fe_amd64
# RUN chmod +x fe_amd64
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# RUN source $HOME/.cargo/env
# ENV PATH=$PATH:$HOME/.cargo/bin

## Add source code to the build stage.
ADD . /mayhem-fe
WORKDIR /mayhem-fe

RUN  ~/.cargo/bin/cargo build --verbose --features solc-backend; exit 0
RUN echo 3479fd502d44de22 > /root/.cargo/git/checkouts/solc-rust-3479fd502d44de22/52d4146/solidity/commit_hash.txt
RUN  ~/.cargo/bin/cargo build --verbose --features solc-backend

FROM --platform=linux/amd64 ubuntu:20.04

COPY --from=builder /mayhem-fe/target/debug/fe /

