FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap hydra openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*
