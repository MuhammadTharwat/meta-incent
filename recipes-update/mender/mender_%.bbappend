FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
inherit systemd

SYSTEMD_SERVICE:${PN} = "mender_first_boot.service"
SYSTEMD_AUTO_ENABLE = "enable"

SRC_URI:append = "\
    file://update \
    file://mender_first_boot.service \
    file://mender_first_boot.sh \
    "

do_install:append() {
        install -m 755 -d ${D}${datadir}/mender/modules/v3
        install -m 755 ${WORKDIR}/update ${D}${datadir}/mender/modules/v3/

        install -d ${D}${bindir}
        install -d  ${D}/${systemd_unitdir}/system

        # Install script
        install -m 0755 ${WORKDIR}/mender_first_boot.sh ${D}${bindir}/mender_first_boot.sh

        # Install systemd service
        install -m 0644 ${WORKDIR}/mender_first_boot.service  ${D}/${systemd_unitdir}/system/mender_first_boot.service 

}


SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN}:append = " mender_first_boot.service "

FILES:${PN} += "\
    ${datadir}/mender/modules/v3/update \
    ${bindir}/mender_first_boot.sh \
    ${systemd_unitdir}/system/mender_first_boot.service \
"

