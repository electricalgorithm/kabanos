#!/bin/bash
# Boots the REAL built kabanos-image (build-35 release .wic, unmodified) under
# QEMU's "virt" board, using the QEMU-compatible kernel from step 02 (same
# source/commit/defconfig as the real release, only + virt-boot.cfg).
#
# No BSP/AM335x machine model exists in mainline QEMU (verified: `qemu-system-arm
# -M help` has no beaglebone/am33xx entry) -- that's the "BSP issue" we were
# told to skip. Everything else (rootfs, userspace, podman, init config) is the
# unmodified release artifact.
#
# A second virtio-blk device exposes artifacts/mini-rootfs.tar as a raw block
# device for the offline "create a container from a simple rootfs" test -- no
# network device is attached at all, so there is no path to the internet from
# the guest.
#
# Disks are attached as virtio-mmio (-device virtio-blk-device + -drive
# if=none), not the "-drive if=virtio" PCI shorthand: on -M virt that
# shorthand attaches over PCI, but this kernel build (same defconfig +
# container.cfg + qemuarm-virt.cfg as the real recipe) never sets
# CONFIG_PCI_HOST_GENERIC, so the guest has no driver for QEMU's PCIe host
# bridge and the PCI-attached disks are invisible to it (root=/dev/vda2 never
# appears; boot hangs at "Waiting for root device"). virtio-mmio needs no
# host controller -- the virt board wires it up directly in the device tree
# -- and CONFIG_VIRTIO_MMIO=y is already enabled, so this needs no kernel
# config change at all.
#
# virtio-mmio devices probe in the REVERSE of command-line order (confirmed
# empirically: the last -device added comes up as vda, not the first), so
# the mini-rootfs disk is added before the WIC disk below to make the WIC
# land on /dev/vda -- matching root=/dev/vda2 in -append -- and the
# mini-rootfs land on /dev/vdb, matching the /dev/vdb the expect script
# dd's from.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIC="${ROOT}/artifacts/kabanos-build-35.wic"
KERNEL="${ROOT}/artifacts/qemu-zImage"
MINI_ROOTFS="${ROOT}/artifacts/mini-rootfs.tar"
LOG="${ROOT}/logs/qemu-console.log"

exec qemu-system-arm \
  -M virt \
  -cpu cortex-a15 \
  -m 1024 \
  -smp 2 \
  -kernel "${KERNEL}" \
  -append "console=ttyAMA0,115200 root=/dev/vda2 rootwait rw" \
  -drive file="${MINI_ROOTFS}",format=raw,if=none,id=disk1 \
  -device virtio-blk-device,drive=disk1 \
  -drive file="${WIC}",format=raw,if=none,id=disk0 \
  -device virtio-blk-device,drive=disk0 \
  -nographic -no-reboot \
  -serial mon:stdio 2>&1 | tee "${LOG}"
