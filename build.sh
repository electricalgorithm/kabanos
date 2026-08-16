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

# Setup bitbake path
export PATH="$(pwd)/bitbake/bin:$PATH"

echo "=== Setup Complete ==="
echo "Build configs are in build/conf/"
echo "To build the image, run: bitbake kabanos-image"
