require recipes-kernel/linux/linux-yocto.inc

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9dd7b269db0b7fd2c4d46"

SRCREV = "${AUTOREV}"

SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git;branch=linux-6.18.y;protocol=https \
           file://container.cfg"

PV = "6.18+git"

S = "${WORKDIR}/git"

KERNEL_DEFCONFIG = "multi_v7_defconfig"
KERNEL_CONFIG_FRAGMENTS += " ${WORKDIR}/container.cfg"

COMPATIBLE_MACHINE = "beaglebone-yocto"
