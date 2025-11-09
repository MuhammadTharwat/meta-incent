# Common code for different Stryker images

inherit core-image

IMAGE_INSTALL:append = " packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

