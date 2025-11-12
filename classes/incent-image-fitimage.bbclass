# Bbclass in charge of creating the FIT image in an image recipe
#
# Customizations are added to the final rootfs:
#   - Add the partition table to the initramfs image
#   - Add swk2 to the initramfs image (if enabled)
#   - Package the kernel, device trees, initramfs
#   - Sign the FIT image with swk1 (if enabled)

inherit fitimage

INITRAMFS_IMAGE = "welma-image-initramfs"
INITRAMFS_FILE = "${INITRAMFS_IMAGE}-${MACHINE}.${INITRAMFS_FSTYPES}"
EXTENDED_INITRAMFS_FILE = "${IMAGE_LINK_NAME}-${INITRAMFS_IMAGE}-${MACHINE}-extended.${INITRAMFS_FSTYPES}"

#   FITIMAGE_UBOOT_SCRIPT  Path to U-Boot script to be integrated (optional)
#   FITIMAGE_SETUP         Path to setup.bin to be integrated (optional)
FITIMAGE_UBOOT_SCRIPT ?= ""
FITIMAGE_SETUP ?= ""

DEPENDS += "${@bb.utils.contains('WELMA_SECURE_BOOT', '1', ' welma-signing-tools-native', '', d)}"
DEPENDS += "${@ 'welma-signing-tools-native' if d.getVar('WELMA_KEY_SWK2_PUB') else ''}"

IMAGE_FITIMAGE_WORKDIR = "${WORKDIR}/fitimage"
ROOTFS_POSTPROCESS_COMMAND += "extend_welma_initramfs create_fitimage"

# This function creates the extended initramfs:
#   - Takes the deployed initramfs
#   - Appends SWK2
#   - Appends files from WELMA_CONF_WORKDIR
extend_welma_initramfs() {   
    extend_dir="${IMAGE_FITIMAGE_WORKDIR}/extend.d"
    rm -rf "$extend_dir"
    mkdir -p "$extend_dir"

    # Collect files from WELMA_CONF_WORKDIR: default bootflags, partitions
    cp -r ${WELMA_CONF_WORKDIR}/. "$extend_dir/."

    if [ -n "${WELMA_KEY_SWK2_PUB}" ]; then
        bbnote "Adding SWK2 to initramfs"
        install -D -m 644 ${WELMA_KEY_SWK2_PUB} "$extend_dir/etc/swk/swk2.crt"
    fi
    # Concatenate archives
    cp "${DEPLOY_DIR_IMAGE}/${INITRAMFS_FILE}" "${IMAGE_FITIMAGE_WORKDIR}/${EXTENDED_INITRAMFS_FILE}"
    # Append the Welma conf extension as a gzipped CPIO archive
    # (it must be gzipped so that the kernel will load it regardless of the alignment)
    (cd "$extend_dir" && find . | cpio -o -H newc | gzip -c) >> "${IMAGE_FITIMAGE_WORKDIR}/${EXTENDED_INITRAMFS_FILE}"
}

create_fitimage() {
    mkdir -p "${IMAGE_FITIMAGE_WORKDIR}"
    # Assemble fitimage
    fitimage_assemble \
        ${IMAGE_FITIMAGE_WORKDIR}/fit-image.its \
        ${IMAGE_FITIMAGE_WORKDIR}/fitImage \
        ${DEPLOY_DIR_IMAGE}/u-boot/linux.bin \
        "${FITIMAGE_UBOOT_SCRIPT}" \
        "${FITIMAGE_SETUP}" \
        "${IMAGE_FITIMAGE_WORKDIR}/${EXTENDED_INITRAMFS_FILE}"
    # Sign fitimage
    if [ "${WELMA_SECURE_BOOT}" = "1" ] ; then
        bbnote "Signing the FIT image with ${WELMA_KEY_SWK1_PRIV}"
        sign-fitimage "${WELMA_KEY_SWK1_PRIV}" "${IMAGE_FITIMAGE_WORKDIR}/fitImage"
    fi
    # Install fitimage
    install -D -m 644 ${IMAGE_FITIMAGE_WORKDIR}/fitImage ${IMAGE_ROOTFS}/boot/fitImage
}

do_rootfs[depends] += " \
    virtual/kernel:do_deploy \
    ${INITRAMFS_IMAGE}:do_image_complete \
"

do_deploy_fitimage() {
    bbnote "Installing fit-image.its source file..."
    install -m 0644 ${IMAGE_FITIMAGE_WORKDIR}/fit-image.its "${IMGDEPLOYDIR}/${IMAGE_NAME}.fitimage.its"
    ln -snf ${IMAGE_NAME}.fitimage.its "${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.fitimage.its"

    bbnote "Installing fitImage file..."
    install -m 0644 ${IMAGE_FITIMAGE_WORKDIR}/fitImage "${IMGDEPLOYDIR}/${IMAGE_NAME}.fitimage.itb"
    ln -snf ${IMAGE_NAME}.fitimage.itb "${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.fitimage.itb"
}

do_deploy_extended_initramfs() {
    bbnote "Installing extended initramfs"
    install -m 0644 "${IMAGE_FITIMAGE_WORKDIR}/${EXTENDED_INITRAMFS_FILE}" "${IMGDEPLOYDIR}/${EXTENDED_INITRAMFS_FILE}"
}

addtask deploy_fitimage after do_rootfs before do_image_complete
addtask deploy_extended_initramfs after do_rootfs before do_image_complete

