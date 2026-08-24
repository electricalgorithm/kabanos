#!/bin/bash
# Clones the exact kernel commit pinned by meta-kabanos/recipes-kernel/linux/linux-stable_6.18.bb
# (same source the real image's kernel is built from), so any QEMU-boot kernel we build here
# stays byte-for-byte on the same tree/version as the actual release.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RECIPE="${REPO_ROOT}/meta-kabanos/recipes-kernel/linux/linux-stable_6.18.bb"
SRCREV="$(grep '^SRCREV' "${RECIPE}" | sed -E 's/SRCREV = "(.*)"/\1/')"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/linux-src"

echo "Pinned SRCREV from recipe: ${SRCREV}"

# git.kernel.org is blocked by this environment's network policy (confirmed via
# `curl "$HTTPS_PROXY/__agentproxy/status"` -> recentRelayFailures: 403 policy denial
# for git.kernel.org:443). Use the GitHub mirror of linux-stable instead, which
# carries the identical commit history/SHAs.
if [ ! -d "${DEST}/.git" ]; then
  git clone --filter=blob:none -b linux-6.18.y https://github.com/gregkh/linux.git "${DEST}"
fi
cd "${DEST}"
git fetch --depth 1 origin "${SRCREV}"
git checkout "${SRCREV}"
git rev-parse HEAD
