DESCRIPTION = "Mainline libcamera library"
HOMEPAGE = "git.libcamera.org/libcamera/libcamera.git"
LICENSE = "LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRCREV = "refs/tags/v0.7.0"
PV = "0.1+git${SRCPV}"
SRC_URI = "git://git.libcamera.org/libcamera/libcamera.git;protocol=https;branch=master"

S = "${WORKDIR}/git"

DEPENDS = "ca-certificates-native glib-2.0 ninja-native python3-native python3-jinja2-native python3-pyyaml-native python3-ply-native tiff-native jsoncpp libjpeg-turbo libyaml"

inherit meson pkgconfig python3native

EXTRA_OEMESON = " \
--buildtype=release \
--wrap-mode=default \
-Dpipelines=rpi/vc4,rpi/pisp \
-Dipas=rpi/vc4,rpi/pisp \
-Dv4l2=true \
-Dgstreamer=disabled \
-Dtest=false \
-Dlc-compliance=disabled \
-Dcam=disabled \
-Dqcam=disabled \
-Ddocumentation=disabled \
-Dpycamera=disabled \
"


## This is for meson to build subprojects 
do_configure:prepend() {
    export SSL_CERT_FILE="${STAGING_ETCDIR_NATIVE}/ssl/certs/ca-certificates.crt"
    export SSL_CERT_DIR="${STAGING_ETCDIR_NATIVE}/ssl/certs"
}

## This is to skip the RPATH error (due to libisp subproject)
INSANE_SKIP:${PN} += "rpaths"

FILES:${PN} += " ${libdir}/libcamera/*"
FILES:${PN} += " ${datadir}/libcamera/*"
FILES:${PN} += " ${datadir}/libpisp/*"

COMPATIBLE_MACHINE = "raspberrypi"