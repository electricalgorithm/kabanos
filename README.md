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

## Building

This project must be built on a Linux system. macOS hosts are not supported for native Yocto builds.

```bash
# Build and enter the container
docker compose up -d
docker compose exec yocto-builder bash

# Inside the container, run the build script
bash build.sh

# Build the image
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
