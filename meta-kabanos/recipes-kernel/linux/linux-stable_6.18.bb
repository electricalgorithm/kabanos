inherit kernel

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

SRCREV = "1efe5d048a391de3ead2804b2e7f86376c356cc5"

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git;branch=linux-6.18.y;protocol=https \
           file://defconfig \
           file://container.cfg"

# qemuarm-only: enables QEMU's "virt" board support (see files/qemuarm-virt.cfg)
# so this exact kernel source/version also boots under QEMU -- no QEMU machine
# model emulates the real beaglebone-yocto hardware (AM335x) this kernel
# otherwise targets. Scoped via :qemuarm overrides so beaglebone-yocto's
# SRC_URI/KERNEL_CONFIG_FRAGMENTS/task signatures are completely unchanged.
SRC_URI:append:qemuarm = " file://qemuarm-virt.cfg"

PV = "6.18+git"

S = "${WORKDIR}/git"

KERNEL_DEFCONFIG = "defconfig"
KERNEL_CONFIG_FRAGMENTS += " ${WORKDIR}/container.cfg"
KERNEL_CONFIG_FRAGMENTS:append:qemuarm = " ${WORKDIR}/qemuarm-virt.cfg"

COMPATIBLE_MACHINE = "beaglebone-yocto|qemuarm"