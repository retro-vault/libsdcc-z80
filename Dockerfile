# extras/docker/sdcc/Dockerfile
FROM debian:12-slim

ARG SDCC_VERSION=4.5.0
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /opt

# Base tools + Fuse (GTK). Swap to fuse-emulator-sdl if you prefer SDL.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget xz-utils bzip2 make git python3 \
    fuse-emulator-gtk fuse-emulator-utils pasmo which \
 && rm -rf /var/lib/apt/lists/*

# Download SDCC prebuilt tarball
RUN wget -O /tmp/sdcc.tar.bz2 \
  "https://downloads.sourceforge.net/project/sdcc/sdcc-linux-amd64/${SDCC_VERSION}/sdcc-${SDCC_VERSION}-amd64-unknown-linux2.5.tar.bz2"

# Extract SDCC and clean
RUN mkdir -p /opt/sdcc \
 && tar -xjf /tmp/sdcc.tar.bz2 -C /opt/sdcc --strip-components=1 \
 && rm /tmp/sdcc.tar.bz2

# Put SDCC on PATH
ENV PATH="/opt/sdcc/bin:${PATH}"

# Working directory for your repo
WORKDIR /work