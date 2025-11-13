# This bbclass is used to deploy a FIT-compatible kernel image.
#
# The deployed files are:
# - kernel-fit/linux.bin: the Linux kernel in a FIT-compatible format
# - kernel-fit/linux.bin.comp: the compression algorithm used (none, gzip, ...)
#
# Usage:
# - Have you kernel recipe inherit this bbclass
# - In your FIT image recipe, use ${DEPLOY_DIR_IMAGE}/kernel-fit/linux.bin{.comp}

inherit kernel-uboot

do_uboot_prepare_kimage() {
    cd ${B}
    uboot_prep_kimage > linux.bin.comp
}

addtask uboot_prepare_kimage before do_install after do_compile

kernel_do_deploy:append() {
    install -d $deployDir/kernel-fit
    install -m 0644 ${B}/linux.bin $deployDir/kernel-fit/linux-${KERNEL_IMAGE_NAME}.bin
    install -m 0644 ${B}/linux.bin.comp $deployDir/kernel-fit/linux-${KERNEL_IMAGE_NAME}.bin.comp

    ln -sf linux-${KERNEL_IMAGE_NAME}.bin $deployDir/kernel-fit/linux-${KERNEL_IMAGE_LINK_NAME}.bin
    ln -sf linux-${KERNEL_IMAGE_NAME}.bin.comp $deployDir/kernel-fit/linux-${KERNEL_IMAGE_LINK_NAME}.bin.comp

    ln -sf linux-${KERNEL_IMAGE_NAME}.bin $deployDir/kernel-fit/linux.bin
    ln -sf linux-${KERNEL_IMAGE_NAME}.bin.comp $deployDir/kernel-fit/linux.bin.comp
}
