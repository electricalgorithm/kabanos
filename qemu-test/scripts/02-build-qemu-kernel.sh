#!/bin/bash
# Builds a zImage from the EXACT kernel source/commit/defconfig/fragment the real
# kabanos qemuarm CI target uses (meta-kabanos/recipes-kernel/linux/linux-stable_6.18.bb),
# including the same qemuarm-virt.cfg fragment the recipe itself now applies via
# SRC_URI:append:qemuarm / KERNEL_CONFIG_FRAGMENTS:append:qemuarm, so this build
# is not a hand-rolled equivalent -- it's literally the recipe's own inputs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/.." && pwd)"
SRC="${ROOT}/linux-src"
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

cd "${SRC}"

# Same merge order Yocto's kernel-yocto class uses, and the same order the
# real recipe lists KERNEL_CONFIG_FRAGMENTS in for MACHINE=qemuarm: base
# defconfig, then container.cfg, then qemuarm-virt.cfg.
cat "${REPO_ROOT}/meta-kabanos/recipes-kernel/linux/files/defconfig" \
    "${REPO_ROOT}/meta-kabanos/recipes-kernel/linux/files/container.cfg" \
    "${REPO_ROOT}/meta-kabanos/recipes-kernel/linux/files/qemuarm-virt.cfg" \
    > .config

make olddefconfig

echo "--- Verifying the fragment actually took effect ---"
grep -E "^CONFIG_ARCH_VIRT=y|^CONFIG_SERIAL_AMBA_PL011=y|^CONFIG_SOC_AM33XX=y|^CONFIG_VIRTIO_BLK=y|^CONFIG_VIRTIO_MMIO=y" .config

make -j"$(nproc)" zImage dtbs

echo "--- Build output ---"
ls -la arch/arm/boot/zImage
cp arch/arm/boot/zImage "${ROOT}/artifacts/qemu-zImage"
echo "Copied to ${ROOT}/artifacts/qemu-zImage"
