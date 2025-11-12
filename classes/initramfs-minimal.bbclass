# Common code for generating minimal initramfs images

INITRAMFS_PACKAGES ?= "initramfs-boot"

MACHINE_INITRAMFS_RDEPENDS ??= ""

PACKAGE_INSTALL = "${INITRAMFS_PACKAGES} busybox ${MACHINE_INITRAMFS_RDEPENDS} ${ROOTFS_BOOTSTRAP_INSTALL}"

# Do not pollute the initramfs image with rootfs features.
# Select 'read-only-rootfs' so that VIRTUAL-RUNTIME_update-alternatives is
# removed in do_rootfs (files /usr/lib/opkg/alternatives).
IMAGE_FEATURES = "read-only-rootfs"

IMAGE_LINGUAS = ""

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"

# Reset image suffix
IMAGE_NAME_SUFFIX = ""

NO_RECOMMENDATIONS = "1"

inherit core-image
