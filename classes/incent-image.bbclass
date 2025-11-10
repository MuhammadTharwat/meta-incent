# Common code for different Incent images

inherit core-image

IMAGE_INSTALL:append = " openssh openssh-sshd openssh-sftp openssh-sftp-server"
IMAGE_INSTALL:append = " kernel-modules"
IMAGE_INSTALL:append = " libstdc++"

IMAGE_INSTALL:append = " packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

