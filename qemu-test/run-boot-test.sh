#!/bin/bash
# Boots the kabanos qemuarm image from a Yocto deploy directory under QEMU and
# runs the podman test suite in boot-test.exp against it.
#
# Usage: run-boot-test.sh [deploy-dir] [console-log]
#   deploy-dir   defaults to build/tmp/deploy/images/qemuarm (where CI copies it)
#   console-log  defaults to qemu-test/logs/qemu-console.log
#
# Host requirements: qemu-system-arm, expect.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${HERE}/.." && pwd)"
DEPLOY_DIR="${1:-${REPO_ROOT}/build/tmp/deploy/images/qemuarm}"
LOG="${2:-${HERE}/logs/qemu-console.log}"

for tool in qemu-system-arm expect; do
  command -v "$tool" >/dev/null || { echo "error: $tool not found in PATH" >&2; exit 2; }
done

KERNEL="${DEPLOY_DIR}/zImage"
ROOTFS="${DEPLOY_DIR}/kabanos-image-qemuarm.rootfs.ext4"
for f in "$KERNEL" "$ROOTFS"; do
  [ -e "$f" ] || { echo "error: $f not found (is ${DEPLOY_DIR} a qemuarm deploy dir?)" >&2; exit 2; }
done

mkdir -p "$(dirname "$LOG")"
exec expect -f "${HERE}/boot-test.exp" "$KERNEL" "$ROOTFS" "$LOG"
