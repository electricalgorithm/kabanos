#!/bin/bash
# Builds a tiny standalone rootfs tarball (busybox + its actual shared-lib
# dependencies, pulled straight out of the real built image) for the "create a
# container from a simple rootfs" test on-device. This is what `podman import`
# will consume on the guest -- entirely offline, no registry involved.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="/mnt/kabanos-root"   # real image rootfs, mounted read-only
WORK="${ROOT}/artifacts/mini-rootfs"
OUT="${ROOT}/artifacts/mini-rootfs.tar"

rm -rf "${WORK}"
mkdir -p "${WORK}"/{bin,lib,etc,proc,sys,tmp,dev}

cp -a "${SRC_ROOT}/bin/busybox.nosuid" "${WORK}/bin/busybox"
for lib in ld-linux-armhf.so.3 libc.so.6 libm.so.6; do
  cp -a "${SRC_ROOT}/lib/${lib}" "${WORK}/lib/${lib}"
done

ln -s busybox "${WORK}/bin/sh"

cat > "${WORK}/etc/os-release" <<'EOF'
NAME="kabanos-mini-rootfs"
PRETTY_NAME="Kabanos QEMU validation mini rootfs (busybox, offline)"
EOF

echo "kabanos-mini" > "${WORK}/etc/hostname"

tar --numeric-owner --owner=0 --group=0 -C "${WORK}" -cf "${OUT}" .
ls -la "${OUT}"
tar -tvf "${OUT}"
