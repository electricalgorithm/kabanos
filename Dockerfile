FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y \
    bash \
    bc \
    bison \
    build-essential \
    chrpath \
    cpio \
    cvs \
    diffstat \
    file \
    flex \
    g++ \
    gawk \
    gcc \
    git \
    git-lfs \
    libncurses5-dev \
    libssl-dev \
    locales \
    lz4 \
    make \
    nano \
    perl \
    pkg-config \
    python3 \
    python3-distutils \
    python3-pexpect \
    python3-pip \
    qemu-system-arm \
    rsync \
    socat \
    sudo \
    texinfo \
    unzip \
    wget \
    xz-utils \
    zstd \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

WORKDIR /home/build/yocto

RUN useradd -m -s /bin/bash build && echo "build ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER build
