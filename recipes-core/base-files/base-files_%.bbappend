FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://mender_env.sh"

do_install:append() {
    install -d ${D}/etc/profile.d/
    install -m 0755 ${WORKDIR}/mender_env.sh ${D}/etc/profile.d/
}
