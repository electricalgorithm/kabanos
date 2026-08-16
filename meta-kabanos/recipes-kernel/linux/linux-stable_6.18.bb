inherit kernel

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9dd7b269db0b7fd2c4d46"

SRCREV = "1efe5d048a391de3ead2804b2e7f86376c356cc5"

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git;branch=linux-6.18.y;protocol=https \
           file://defconfig \
           file://container.cfg"

PV = "6.18+git"

S = "${WORKDIR}/git"

KERNEL_DEFCONFIG = "defconfig"
KERNEL_CONFIG_FRAGMENTS += " ${WORKDIR}/container.cfg"

COMPATIBLE_MACHINE = "beaglebone-yocto"