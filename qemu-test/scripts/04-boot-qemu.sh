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
  -drive file="${WIC}",format=raw,if=virtio \
  -drive file="${MINI_ROOTFS}",format=raw,if=virtio \
  -nographic -no-reboot \
  -serial mon:stdio 2>&1 | tee "${LOG}"
