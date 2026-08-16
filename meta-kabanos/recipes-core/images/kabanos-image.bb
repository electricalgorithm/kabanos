require recipes-core/images/core-image-minimal.bb

DESCRIPTION = "A minimal podman container distro"

IMAGE_INSTALL = "\
    ${CORE_IMAGE_EXTRA_INSTALL} \
    packagegroup-core-boot \
    kernel-modules \
    podman \
    iptables \
    iproute2 \
    socat \
    conmon \
    runc-opencontainers \
    slirp4netns \
    fuse-overlayfs \
    "

IMAGE_FEATURES += "ssh-server-openssh"

EXTRA_IMAGE_FEATURES = "debug-tweaks"
