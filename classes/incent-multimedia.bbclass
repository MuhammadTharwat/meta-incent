# Common code for multimedia images

TOUCHSCREEN_TOOLS = " \
                     tslib-tests \
                     tslib-calibrate \
                     tslib \
                    "

Qt_TOOLS= " \
           qtbase \
           qtdeclarative \
           "

VIDEO_TOOLS = " \
            gstreamer1.0 \
            gstreamer1.0-plugins-base \
            gstreamer1.0-plugins-good \
            fbida \
           "

IMAGE_INSTALL:append = " ${TOUCHSCREEN_TOOLS} ${Qt_TOOLS} ${VIDEO_TOOLS}"

IMAGE_INSTALL:append = " mesa mesa-demos"
IMAGE_INSTALL:append = " xserver-xorg xterm xinit xauth kmscube xkbcomp"
IMAGE_INSTALL:append = " libgles2 libegl"
IMAGE_INSTALL:append = " libv4l v4l-utils"
IMAGE_INSTALL:append = " boost boost-thread"
IMAGE_INSTALL:append = " libsdl2 libcamera"