# Kabanos

A minimal Yocto-based Linux distribution designed to run containers with Podman. No executables run, no weird services.

## Features

- **Kernel**: Amazon Linux 6.18.y mainline (from amazonlinux/linux)
- **Package Management**: IPK (opkg)
- **Container Runtime**: Podman
- **Init System**: sysvinit
- **Target**: x86_64 (genericx86-64-amazon machine)

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
- `build/tmp/deploy/images/genericx86-64-amazon/`
- `kabanos-image-genericx86-64-amazon.wic` - Disk image for QEMU/hardware
- `kabanos-image-genericx86-64-amazon.tar.xz` - Root filesystem tarball

## Running with QEMU

```bash
# Boot the WIC image
runqemu kabanos-image nographic slirp

# Or manually
qemu-system-x86_64 \
    -M q35 \
    -cpu q64 \
    -m 2048 \
    -drive file=build/tmp/deploy/images/genericx86-64-amazon/kabanos-image-genericx86-64-amazon.wic,format=raw,if=virtio \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -nographic \
    -serial mon:stdio
```

