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
# kernel config does not get it.
SRC_URI:append:qemuarm = " file://qemuarm-virt.cfg"

PV = "6.18+git"

S = "${WORKDIR}/git"

# Plain kernel.bbclass (unlike kernel-yocto) only copies ${WORKDIR}/defconfig
# to .config and runs olddefconfig -- it has no notion of config fragments.
# KERNEL_CONFIG_FRAGMENTS is this recipe's own variable, merged on top of
# defconfig in do_configure:append below.
KERNEL_CONFIG_FRAGMENTS = "${WORKDIR}/container.cfg"
KERNEL_CONFIG_FRAGMENTS:append:qemuarm = " ${WORKDIR}/qemuarm-virt.cfg"

do_configure:append() {
    ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${KERNEL_CONFIG_FRAGMENTS}
    ${KERNEL_CONFIG_COMMAND}

    # Fail the build if Kconfig silently dropped a requested option (unmet
    # dependency, renamed symbol, ...), instead of shipping a kernel that
    # lacks it.
    missing=""
    for frag in ${KERNEL_CONFIG_FRAGMENTS}; do
        for opt in $(grep -E '^CONFIG_[A-Za-z0-9_]+=' "$frag"); do
            grep -qxF "$opt" ${B}/.config || missing="$missing $opt"
        done
    done
    if [ -n "$missing" ]; then
        bbfatal "Kernel config fragment options not set in final .config:$missing"
    fi
}

COMPATIBLE_MACHINE = "beaglebone-yocto|qemuarm"