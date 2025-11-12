SUMMARY = "Standard boot initramfs"
DESCRIPTION = "Small image useable as standard boot initramfs"

LICENSE = "MIT"

inherit initramfs-minimal

# Reset IMAGE_ROOTFS_SIZE to bitbake's default value, as it may be altered
IMAGE_ROOTFS_SIZE = "8192"
