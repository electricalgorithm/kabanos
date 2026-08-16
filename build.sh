#!/bin/bash
set -e

echo "=== Kabanos Yocto Build Environment Setup ==="

# Clone openembedded-core if not present
if [ ! -d "openembedded-core" ] || [ -z "$(ls -A openembedded-core 2>/dev/null)" ]; then
    echo "Cloning openembedded-core (scarthgap)..."
    rm -rf openembedded-core
    git clone -b scarthgap https://git.openembedded.org/openembedded-core openembedded-core
fi

# Clone meta-yocto if not present
if [ ! -d "meta-yocto" ] || [ -z "$(ls -A meta-yocto 2>/dev/null)" ]; then
    echo "Cloning meta-yocto (scarthgap)..."
    rm -rf meta-yocto
    git clone -b scarthgap https://git.yoctoproject.org/meta-yocto meta-yocto
fi

# Clone bitbake if not present
if [ ! -d "bitbake" ] || [ -z "$(ls -A bitbake 2>/dev/null)" ]; then
    echo "Cloning bitbake (2.8)..."
    rm -rf bitbake
    git clone -b 2.8 https://git.openembedded.org/bitbake bitbake
fi

# Clone meta-virtualization if not present
if [ ! -d "meta-virtualization" ] || [ -z "$(ls -A meta-virtualization 2>/dev/null)" ]; then
    echo "Cloning meta-virtualization (scarthgap)..."
    rm -rf meta-virtualization
    git clone -b scarthgap https://git.yoctoproject.org/git/meta-virtualization meta-virtualization || \
    git clone -b master https://git.yoctoproject.org/git/meta-virtualization meta-virtualization || \
    git clone https://git.yoctoproject.org/git/meta-virtualization meta-virtualization
fi

# Clone meta-openembedded if not present
if [ ! -d "meta-openembedded" ] || [ -z "$(ls -A meta-openembedded 2>/dev/null)" ]; then
    echo "Cloning meta-openembedded (scarthgap)..."
    rm -rf meta-openembedded
    git clone -b scarthgap https://github.com/openembedded/meta-openembedded.git meta-openembedded || \
    git clone -b master https://github.com/openembedded/meta-openembedded.git meta-openembedded || \
    git clone https://github.com/openembedded/meta-openembedded.git meta-openembedded
fi

# Setup build environment
echo "Initializing build environment..."
cd openembedded-core
source oe-init-build-env ../build
cd ..

# Configure bblayers.conf
echo "Configuring bblayers.conf..."
cat > build/conf/bblayers.conf << 'EOF'
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  ${TOPDIR}/../openembedded-core/meta \
  ${TOPDIR}/../meta-yocto/meta-poky \
  ${TOPDIR}/../meta-yocto/meta-yocto-bsp \
  ${TOPDIR}/../meta-openembedded/meta-oe \
  ${TOPDIR}/../meta-openembedded/meta-python \
  ${TOPDIR}/../meta-openembedded/meta-networking \
  ${TOPDIR}/../meta-openembedded/meta-filesystems \
  ${TOPDIR}/../meta-virtualization \
  ${TOPDIR}/../meta-kabanos \
  "
EOF

# Setup bitbake path
export PATH="$(pwd)/bitbake/bin:$PATH"

# Configure local.conf
if [ ! -f "build/conf/local.conf" ] || [ "$(grep -c 'DISTRO = "kabanos"' build/conf/local.conf 2>/dev/null)" -eq 0 ]; then
    echo "Configuring local.conf..."
    cat > build/conf/local.conf << 'EOF'
#
# Machine Selection
#
MACHINE ?= "kabanos-bbb"

#
# Where to place downloads
#
DL_DIR ?= "${TOPDIR}/../downloads"

#
# Where to place shared-state files
#
SSTATE_DIR ?= "${TOPDIR}/../sstate-cache"

#
# Where to place the build output
#
TMPDIR = "/tmp/yocto-tmp"

#
# Default policy config
#
DISTRO ?= "kabanos"

#
# Package Management configuration
#
PACKAGE_CLASSES ?= "package_ipk"

#
# Extra image configuration defaults
#
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"

#
# Additional image features
#
USER_CLASSES ?= "buildstats"

#
# Interactive shell configuration
#
PATCHRESOLVE = "noop"

#
# Disk Space Monitoring during the build
#
BB_DISKMON_DIRS ??= "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K \
    STOPTASKS,/tmp,100M,100K \
    HALT,${TMPDIR},100M,1K \
    HALT,${DL_DIR},100M,1K \
    HALT,${SSTATE_DIR},100M,1K \
    HALT,/tmp,10M,1K"

#
# SDK target architecture
#
SDKMACHINE ?= "x86_64"

#
# Qemu configuration
#
PACKAGECONFIG:append:pn-qemu-system-native = " sdl"

#
# CONF_VERSION
#
CONF_VERSION = "2"

IMAGE_INSTALL:append = " podman "
EOF
fi

# Verify layers
echo "Verifying layers..."
bitbake-layers show-layers

echo "=== Setup Complete ==="
echo "To build the image, run: bitbake kabanos-image"
