#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

echo "Copying file..."
sudo install -Dm 644 $BASE_PATH/30-corsair.conf /etc/X11/xorg.conf.d/30-corsair.conf

echo "Done"

