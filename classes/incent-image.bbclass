# Common code for different Incent images

inherit core-image

IMAGE_NAME = "${IMAGE_BASENAME}-${MACHINE}"

IMAGE_INSTALL:append = " openssh openssh-sshd openssh-sftp openssh-sftp-server"
IMAGE_INSTALL:append = " kernel-modules"
IMAGE_INSTALL:append = " libstdc++"

IMAGE_INSTALL:append = " packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_CLASSES += "incent-image-fitimage" 
IMAGE_CLASSES += "image-mender"

IMAGE_FSTYPES += "ext4"

create_data_dir() {
   mkdir -p ${IMAGE_ROOTFS}/data
}

IMAGE_PREPROCESS_COMMAND += "create_data_dir;"
