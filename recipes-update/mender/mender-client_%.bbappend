FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = "\
    file://update \
    "

do_install:append() {
        install -m 755 -d ${D}${datadir}/mender/modules/v3
        install -m 755 ${WORKDIR}/update ${D}${datadir}/mender/modules/v3/
}

FILES:${PN} += "\
    ${datadir}/mender/modules/v3/update \
"

