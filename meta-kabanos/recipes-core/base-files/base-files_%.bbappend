# Podman/runc need a cgroup filesystem, and sysvinit doesn't mount one.
# Mount the unified (v2) hierarchy; podman 5 deprecates cgroup v1.
do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'false', 'true', d)}; then
        echo "cgroup2 /sys/fs/cgroup cgroup2 defaults 0 0" >> ${D}${sysconfdir}/fstab
    fi
}
