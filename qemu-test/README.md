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
with the *same* `defconfig` + `container.cfg`, plus the same additive
fragment the real recipe now applies for `MACHINE=qemuarm` --
`meta-kabanos/recipes-kernel/linux/files/qemuarm-virt.cfg` -- which turns on
`CONFIG_ARCH_VIRT` and the PL011 console QEMU's `-M virt` board needs. This
is no longer a hand-rolled equivalent: it is literally the same fragment
file `linux-stable_6.18.bb` lists in `KERNEL_CONFIG_FRAGMENTS:append:qemuarm`,
so a kernel built here has the same inputs as the one the `build-qemuarm` CI
job produces. Nothing about the real release's rootfs, `.wic` image, or
userspace is touched.

`/etc/inittab` in the built rootfs already has a `ttyrun`-guarded getty for
`ttyAMA0` (alongside `ttyS0`/`ttyO0`), so the login prompt shows up over
`-M virt`'s console without any rootfs changes either.

## Steps

```
scripts/00-download-release.sh [tag]     # fetch the .wic from a GitHub Release (default build-35)
scripts/01-fetch-kernel-src.sh           # clone the pinned kernel commit (via github.com/gregkh/linux,
                                          # since git.kernel.org is blocked by this environment's proxy policy)
scripts/02-build-qemu-kernel.sh          # build zImage with defconfig + container.cfg +
                                          # meta-kabanos/.../files/qemuarm-virt.cfg (the real recipe's own fragment)
scripts/03-build-mini-rootfs-tarball.sh  # busybox + its real .so deps, pulled from the mounted release
                                          # rootfs partition -- the "simple rootfs" for the offline podman test
                                          # (requires partition 2 of the .wic mounted at /mnt/kabanos-root)
scripts/04-boot-qemu.sh                  # boot: -M virt, the built zImage, the release .wic and mini-rootfs.tar
                                          # as two virtio-mmio disks, no -netdev at all
scripts/05-run-validation.exp            # expect script: boot -> login -> `which podman` -> dd the second
                                          # disk -> `podman import` -> `podman create` -> `podman start`
```

`logs/qemu-console.log` and `logs/expect-transcript.log` capture full
transcripts of each run.

`artifacts/` and `linux-src/` and `logs/` are gitignored (regeneratable /
environment-specific); only the scripts are tracked. The Kconfig fragment
itself lives in `meta-kabanos/recipes-kernel/linux/files/qemuarm-virt.cfg`,
not here -- it's a real recipe input, not a sandbox artifact.

## Two boot issues found and fixed while validating the 6.18 kernel

Rebuilding against the real recipe's `qemuarm-virt.cfg` (instead of a
sandbox-local duplicate with the same Kconfig lines) surfaced two bugs in
these scripts themselves -- not in the kernel or recipe -- both fixed here:

1. **`-drive if=virtio` attaches over PCI, and this kernel has no PCI host
   controller driver.** `defconfig` sets `CONFIG_PCI=y` but never
   `CONFIG_PCI_HOST_GENERIC` (the driver for QEMU virt's ECAM-based "gpex"
   PCIe host bridge), so PCI-attached disks are invisible to the guest --
   boot hangs forever at `Waiting for root device /dev/vda2...`. Fixed by
   attaching both disks as virtio-mmio instead (`-device virtio-blk-device`
   + `-drive if=none`), which needs no host controller since the virt
   board wires MMIO transports directly into the device tree, and
   `CONFIG_VIRTIO_MMIO=y` is already enabled -- no kernel/recipe change
   needed.
2. **virtio-mmio devices probe in the reverse of `-device` command-line
   order** (confirmed empirically, not assumed): the disk added *last*
   comes up as `/dev/vda`. `scripts/04-boot-qemu.sh` now adds the
   mini-rootfs disk before the WIC disk so the WIC lands on `/dev/vda`
   (matching `root=/dev/vda2` in `-append`) and the mini-rootfs lands on
   `/dev/vdb` (matching the `/dev/vdb` `scripts/05-run-validation.exp` dd's
   from).
3. **`scripts/05-run-validation.exp`'s shell-prompt regex never matched.**
   It looked for `[\r\n]#\s*$` (a bare `#` prompt starting a line), but this
   rootfs's actual `PS1` is `root@beaglebone-yocto:~# ` -- the `#` is
   preceded by `~`, not a newline. The shell was up and responsive the
   whole time; the script just never noticed. Fixed to `#\s*$`.

## Result

With all three fixed, a kernel built from the real recipe's own
`qemuarm-virt.cfg` fragment boots the unmodified build-35 release rootfs
end to end: login succeeds, `podman --version` reports 5.0.3, and
`podman import` + `podman create` build and register a container from the
offline mini-rootfs tarball with no network device attached at all
(`CREATE_RC=0`). `podman start` separately fails (`START_RC=125`) because
the kernel's netfilter config lacks the `ip_tables` module CNI's bridge
plugin needs for NAT -- a container-*networking* gap in the shared
`defconfig`/`container.cfg` (present for the real hardware target too, not
something this fragment introduced), not a boot failure.
