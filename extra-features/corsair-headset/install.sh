#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

echo "Copying file..."
sudo cp $BASE_PATH/30-corsair.conf /etc/X11/xorg.conf.d/

echo "Done"

