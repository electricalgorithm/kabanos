# QEMU boot validation

Boots a real kabanos GitHub Release image under QEMU and checks that the
userspace actually works: a shell comes up, `podman` is present, and a
container can be created from a local rootfs with no network access.

## Why not `-M beaglebone`?

There is no BeagleBone / TI AM335x machine model in mainline QEMU
(`qemu-system-arm -M help` has no `beaglebone`/`am33xx` entry), so the real
release kernel -- built only for the physical AM335x SoC
(`CONFIG_SOC_AM33XX=y`, no `CONFIG_ARCH_VIRT`, no `CONFIG_ARCH_MULTI_V7`
board support beyond it, real hardware UART on `ttyS0`) -- cannot boot on
any board QEMU emulates. That's the "BSP issue" to skip.

Rather than swapping in a foreign kernel, `scripts/02-build-qemu-kernel.sh`
rebuilds **the exact same kernel source commit** the release uses (the
`SRCREV` pinned in `meta-kabanos/recipes-kernel/linux/linux-stable_6.18.bb`),
with the *same* `defconfig` + `container.cfg`, plus one small additive
fragment (`config/virt-boot.cfg`) that turns on `CONFIG_ARCH_VIRT` and the
PL011 console QEMU's `-M virt` board needs. Nothing about the real release's
rootfs, `.wic` image, or userspace is touched.

`/etc/inittab` in the built rootfs already has a `ttyrun`-guarded getty for
`ttyAMA0` (alongside `ttyS0`/`ttyO0`), so the login prompt shows up over
`-M virt`'s console without any rootfs changes either.

## Steps

```
scripts/00-download-release.sh [tag]     # fetch the .wic from a GitHub Release (default build-35)
scripts/01-fetch-kernel-src.sh           # clone the pinned kernel commit (via github.com/gregkh/linux,
                                          # since git.kernel.org is blocked by this environment's proxy policy)
scripts/02-build-qemu-kernel.sh          # build zImage with defconfig + container.cfg + config/virt-boot.cfg
scripts/03-build-mini-rootfs-tarball.sh  # busybox + its real .so deps, pulled from the mounted release
                                          # rootfs partition -- the "simple rootfs" for the offline podman test
                                          # (requires partition 2 of the .wic mounted at /mnt/kabanos-root)
scripts/04-boot-qemu.sh                  # boot: -M virt, the built zImage, the release .wic as root=/dev/vda2,
                                          # mini-rootfs.tar as a second virtio-blk disk (/dev/vdb), no -netdev at all
scripts/05-run-validation.exp            # expect script: boot -> login -> `which podman` -> dd the second
                                          # disk -> `podman import` -> `podman create` -> `podman start`
```

`logs/qemu-console.log` and `logs/expect-transcript.log` capture full
transcripts of each run.

`artifacts/`, `linux-src/`, and `logs/` are gitignored (regeneratable /
environment-specific); only the scripts and `config/virt-boot.cfg` are
tracked.
