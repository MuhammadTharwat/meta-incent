SUMMARY = "Incent Development image"
LICENSE = "MIT"
inherit incent-image
inherit incent-multimedia


IMAGE_INSTALL:append = " devmem2"
IMAGE_INSTALL:append = " evtest"
IMAGE_INSTALL:append = " stressapptest"