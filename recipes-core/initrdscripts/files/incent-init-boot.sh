#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

mkdir /proc
mkdir /sys
mkdir -p /mnt/root
mount -t proc proc /proc
mount -t sysfs sysfs /sys

mount -t devtmpfs devtmpfs /dev

# Extract root device from /proc/cmdline
ROOT_DEV=$(cat /proc/cmdline | sed -e 's/^.*root=//' -e 's/ .*$//')

echo "Real root filesystem at: $ROOT_DEV"

# Ensure the root device exists, or wait
while [ ! -e "$ROOT_DEV" ]; do
    echo "Waiting for root device $ROOT_DEV..."
    sleep 1
done

# Mount the real root filesystem (assuming ext4, change if needed)
mount -o ro $ROOT_DEV /mnt/root

if [ $? -ne 0 ]; then
    echo "Failed to mount root filesystem. Dropping to shell."
    /bin/sh
fi

# Switch root
echo "Switching to real root filesystem..."
mount --move /proc /mnt/root/proc
mount --move /sys /mnt/root/sys

# Optional: mount other required FS, like /dev
if [ -d /mnt/root/dev ]; then
    mount --move /dev /mnt/root/dev
fi

exec switch_root /mnt/root /sbin/init