FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://incent-init-boot.sh"

do_install() {
        install -m 0755 ${WORKDIR}/incent-init-boot.sh ${D}/init

        # Create device nodes expected by some kernels in initramfs
        # before even executing /init.
        install -d ${D}/dev
        mknod -m 622 ${D}/dev/console c 5 1
}

inherit allarch

FILES:${PN} += "/init /dev/console"
