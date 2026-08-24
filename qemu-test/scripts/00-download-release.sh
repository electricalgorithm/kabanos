#!/bin/bash
# Downloads the .wic image for a given kabanos GitHub Release tag (default: latest known-good).
# Usage: 00-download-release.sh [tag]
set -euo pipefail

TAG="${1:-build-35}"
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../artifacts" && pwd)"
URL="https://github.com/electricalgorithm/kabanos/releases/download/${TAG}/kabanos-image-beaglebone-yocto.rootfs.wic"

echo "Downloading ${URL}"
curl -fL --retry 4 --retry-delay 5 -o "${DEST_DIR}/kabanos-${TAG}.wic" "${URL}"
ls -la "${DEST_DIR}/kabanos-${TAG}.wic"
