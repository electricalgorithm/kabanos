# QEMU boot + podman test

Boots the Yocto-built `qemuarm` kabanos image under QEMU and checks that it
actually works as a container host: the kernel carries the expected config,
podman runs, and containers start -- with and without podman's default
bridge network. CI runs this in the `build-qemuarm` job on every build and
does not publish the qemuarm assets unless it passes.

## Why `qemuarm` and not the BeagleBone image?

Mainline QEMU has no BeagleBone / TI AM335x machine model, so the real
`beaglebone-yocto` image can't boot under it. `MACHINE=qemuarm` builds the
same kabanos image (same distro, packages and `linux-stable` 6.18 kernel
recipe, with the same `defconfig` + `container.cfg`) for QEMU's `virt`
board. The only kernel difference is
`meta-kabanos/recipes-kernel/linux/files/qemuarm-virt.cfg`, which the recipe
adds for `qemuarm` only, to enable the `virt` board and its PL011 console.

The test boots exactly what Yocto deployed -- the kernel, the rootfs and the
kernel modules in it -- so modules load and the result reflects the build,
not a hand-assembled kernel.

## Running it

After a `MACHINE=qemuarm bitbake kabanos-image` build (or with the
`kabanos-image-qemuarm` CI artifact unpacked into a directory):

```
qemu-test/run-boot-test.sh [deploy-dir] [console-log]
```

- `deploy-dir` defaults to `build/tmp/deploy/images/qemuarm`, and must hold
  `zImage` and `kabanos-image-qemuarm.rootfs.ext4`.
- `console-log` defaults to `qemu-test/logs/qemu-console.log` (gitignored).
- Requires `qemu-system-arm` and `expect` on the host.

The rootfs is attached with `snapshot=on`, so the image is never modified
and every run starts clean. No network device is attached: everything the
tests need, including the container image, comes from the image itself.

## What it checks

`boot-test.exp` boots the image, logs in as root on the serial console and
runs each entry of `TEST_CASES` over that shell:

- the kernel is 6.18.x, and `/proc/config.gz` shows both `qemuarm-virt.cfg`
  and `container.cfg` were applied, and modules for the running kernel are
  installed
- cgroup v2 is mounted and the iptables `nat` table is usable (what runc
  and podman's CNI bridge network need)
- `podman --version` reports 5.x, and `podman info` works
- a minimal rootfs is built from the guest's own busybox and the libraries
  the dynamic loader reports for it, then `podman import`ed offline
- `podman run` works with `--network=none`, the container is PID 1 in its
  own PID namespace, `podman run` works on the default bridge network, and
  a detached container can be listed and removed

The script prints a `[PASS]`/`[FAIL]` line per case and exits non-zero if
any required case fails.

## Adding a test

Append one entry to `TEST_CASES` in `boot-test.exp`:

```tcl
[dict create name "podman reports v5.x" cmd {podman --version} rc 0 contains {podman version 5\.} xfail 0] \
```

| key        | meaning |
|------------|---------|
| `name`     | label shown in the report |
| `cmd`      | shell command run in the guest, verbatim; keep it to one line |
| `rc`       | expected exit code (`""` skips the check) |
| `contains` | Tcl regexp the output must match (`""` skips). The output includes the echoed command line, so match text the command *computes* (e.g. `echo ok-$((6*7))` → `ok-42`), not a literal it contains |
| `xfail`    | `0` = must pass. `1` = known failure: reported as `XFAIL` while it fails, and as `XPASS` -- which fails the suite -- once it passes |
