# Bbclass in charge of creating the FIT image in an image recipe
#
# Customizations are added to the final rootfs:
#   - Add the partition table to the initramfs image
#   - Package the kernel, device trees, initramfs

inherit fitimage

INITRAMFS_IMAGE = "incent-image-initramfs"
INITRAMFS_FILE = "${INITRAMFS_IMAGE}-${MACHINE}.${INITRAMFS_FSTYPES}"
EXTENDED_INITRAMFS_FILE = "${IMAGE_LINK_NAME}-${INITRAMFS_IMAGE}-${MACHINE}-extended.${INITRAMFS_FSTYPES}"

#   FITIMAGE_UBOOT_SCRIPT  Path to U-Boot script to be integrated (optional)
FITIMAGE_UBOOT_SCRIPT ?= ""

IMAGE_FITIMAGE_WORKDIR = "${WORKDIR}/fitimage"
#ROOTFS_POSTPROCESS_COMMAND += "create_fitimage"

do_create_fitimage() {
    mkdir -p "${IMAGE_FITIMAGE_WORKDIR}"
    # Assemble fitimage
    fitimage_assemble \
        ${IMAGE_FITIMAGE_WORKDIR}/fit-image.its \
        ${IMAGE_FITIMAGE_WORKDIR}/fitImage \
        ${DEPLOY_DIR_IMAGE}/kernel-fit/linux.bin \
        "${FITIMAGE_UBOOT_SCRIPT}" \
        "${DEPLOY_DIR_IMAGE}/${INITRAMFS_FILE}"

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

    ## Link the fitImage inside the deploy directory searched for boot files
    ln -snf ${IMGDEPLOYDIR}/${IMAGE_NAME}.fitimage.itb "${DEPLOY_DIR_IMAGE}/fitImage"
}

addtask deploy_fitimage after do_create_fitimage before do_image_complete
addtask do_create_fitimage after do_rootfs 

