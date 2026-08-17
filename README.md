# Kabanos

A minimal Yocto-based Linux distribution designed to run containers with Podman. No executables run, no weird services.

## Features

- **Kernel**: Greg Kroah-Hartman's official stable Linux 6.18 LTS (from kernel.org)
- **Package Management**: IPK (opkg)
- **Container Runtime**: Podman
- **Init System**: sysvinit
- **Target**: ARM (BeagleBone Black, `beaglebone-yocto` machine)

## Image Packages

The `kabanos-image` includes:

- `packagegroup-core-boot` — core boot components
- `kernel-modules` — kernel modules for the target
- `podman` — container runtime
- `conmon` — container monitor
- `runc-opencontainers` — OCI runtime
- `slirp4netns` — user-mode networking for rootless containers
- `fuse-overlayfs` — overlay filesystem support
- `iptables` — packet filtering
- `iproute2` — networking utilities
- `socat` — socket relay
- `openssh` — SSH server (via `IMAGE_FEATURES`)

## Project Structure

```
kabanos/
├── openembedded-core/               # OpenEmbedded core (scarthgap)
├── meta-yocto/                      # Yocto reference BSP/machines
├── bitbake/                         # BitBake build tool
├── meta-openembedded/               # OpenEmbedded layers
├── meta-virtualization/             # Virtualization/container layer
├── meta-kabanos/                    # Custom Kabanos layer
│   ├── conf/
│   │   ├── layer.conf
│   │   ├── distro/kabanos.conf
│   │   └── machine/
│   ├── recipes-kernel/linux/
│   │   ├── linux-stable_6.18.bb    # Vanilla kernel.org 6.18 recipe
│   │   ├── defconfig               # BBB defconfig
│   │   └── files/container.cfg     # Podman kernel config fragment
│   └── recipes-core/images/
│       ├── kabanos-image.bb
│       └── kabanos.wks
├── build/
│   └── conf/
│       ├── bblayers.conf
│       └── local.conf
├── validate.sh                      # Fast local validation script
├── build.sh                         # Clone deps and init build env
├── Dockerfile                       # Docker build environment
├── docker-compose.yml
└── .github/workflows/build.yml      # CI: validate + build + qemu-test
```

## Validation

Before pushing, run the fast validation script to catch parse errors and config issues in ~5 minutes instead of waiting 1.5+ hours for a full CI build:

```bash
# Inside the container
bash validate.sh
```

This script:
1. Checks project structure and dependencies
2. Sources the Yocto build environment
3. Parses all recipes (`bitbake --parse-only`)
4. Verifies the kernel recipe is available
5. Generates the task queue without executing (`bitbake -n`)

**Local workflow:**
```bash
# 1. Make changes
# 2. Validate locally
docker compose exec yocto-builder bash validate.sh

# 3. If validation passes, push
git add -A && git commit -m "message"
git push origin main
```

**CI workflow:**
- `validate` job runs first (~5-10 min)
- If validation passes, `build` job runs (~hours)
- If validation fails, build is skipped

## Building

This project must be built on a Linux system. macOS hosts are not supported for native Yocto builds.

```bash
# Build and enter the container
docker compose up -d
docker compose exec yocto-builder bash

# Inside the container, run the build script
bash build.sh

# Validate before full build (recommended)
bash validate.sh

# Build the image (this takes hours on first run)
bitbake kabanos-image
```

Build artifacts will be in:
- `build/tmp/deploy/images/beaglebone-yocto/`
- `kabanos-image-beaglebone-yocto.wic` - Disk image for QEMU/hardware
- `kabanos-image-beaglebone-yocto.tar.*` - Root filesystem tarball

## Running with QEMU

```bash
# Boot the WIC image for BeagleBone Black
runqemu kabanos-image nographic slirp

# Or manually
qemu-system-arm \
    -M beaglebone \
    -m 2048 \
    -drive file=build/tmp/deploy/images/beaglebone-yocto/kabanos-image-beaglebone-yocto.wic,format=raw,if=virtio \
    -netdev user,id=net0 \
    -device virtio-net-device,netdev=net0 \
    -nographic \
    -serial mon:stdio
```
