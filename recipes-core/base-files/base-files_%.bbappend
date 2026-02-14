FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://mender_env.sh"

do_install:append() {
    install -d ${D}/etc/profile.d/
    install -m 0644  ${WORKDIR}/mender_env.sh ${D}${sysconfdir}/profile.d/
}

FILES:${PN} += "${sysconfdir}/profile.d/mender_env.sh"