#!/bin/sh
# /usr/bin/mender_first_boot.sh

MARKER=/data/mender

# Wait until /data is mounted
while ! mountpoint -q /data; do
    sleep 0.2
done

# Run once
if [ ! -f "$MARKER" ]; then
    echo "First boot: populating /data..."
    cp -r /var/lib/mender /data/mender  # optional folder copy
    sync
fi
