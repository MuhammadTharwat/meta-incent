FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = "\
    file://all_update \
    file://fit_update \
    file://rootfs_update \
    "


do_install:append() {
        install -m 755 -d ${D}${datadir}/mender/modules/v3
        install -m 755 ${WORKDIR}/all_update ${D}${datadir}/mender/modules/v3/
        install -m 755 ${WORKDIR}/fit_update ${D}${datadir}/mender/modules/v3/
        install -m 755 ${WORKDIR}/rootfs_update ${D}${datadir}/mender/modules/v3/
}

FILES:${PN} += "\
    ${datadir}/mender/modules/v3/all_update \
    ${datadir}/mender/modules/v3/fit_update \
    ${datadir}/mender/modules/v3/rootfs_update \
"

