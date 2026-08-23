#!/bin/bash
# Builds a zImage from the EXACT kernel source/commit/defconfig/fragment the real
# kabanos release uses (meta-kabanos/recipes-kernel/linux/linux-stable_6.18.bb),
# with one additive fragment (artifacts/virt-boot.cfg) enabling QEMU's "virt"
# board so it can actually boot under an emulator that has no AM335x support.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/.." && pwd)"
SRC="${ROOT}/linux-src"
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

cd "${SRC}"

# Same merge order Yocto's kernel-yocto class uses: base defconfig, then
# fragments, in the order the recipe lists them (container.cfg), plus ours.
cat "${REPO_ROOT}/meta-kabanos/recipes-kernel/linux/files/defconfig" \
    "${REPO_ROOT}/meta-kabanos/recipes-kernel/linux/files/container.cfg" \
    "${ROOT}/config/virt-boot.cfg" \
    > .config

make olddefconfig

echo "--- Verifying the fragment actually took effect ---"
grep -E "^CONFIG_ARCH_VIRT=y|^CONFIG_SERIAL_AMBA_PL011=y|^CONFIG_SOC_AM33XX=y|^CONFIG_VIRTIO_BLK=y|^CONFIG_VIRTIO_MMIO=y" .config

make -j"$(nproc)" zImage dtbs

echo "--- Build output ---"
ls -la arch/arm/boot/zImage
cp arch/arm/boot/zImage "${ROOT}/artifacts/qemu-zImage"
echo "Copied to ${ROOT}/artifacts/qemu-zImage"
