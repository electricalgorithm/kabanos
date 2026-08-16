require recipes-kernel/linux/linux-yocto.inc

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9dd7b269db0b7fd2c4d46"

SRCREV = "7977e7e41ed53db4f7373472a3d624e6516402b2"

SRC_URI = "git://github.com/amazonlinux/linux.git;branch=amazon-6.18.y/mainline;protocol=https \
           file://container.cfg"

PV = "6.18+git"

S = "${WORKDIR}/git"

KERNEL_DEFCONFIG = "multi_v7_defconfig"
KERNEL_CONFIG_FRAGMENTS += " ${WORKDIR}/container.cfg"

COMPATIBLE_MACHINE = "qemuarm|qemuarm64|kabanos-bbb"
