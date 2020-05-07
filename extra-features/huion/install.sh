#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

sudo rmmod hid-kye
sudo rmmod hid-uclogic
sudo rmmod hid-huion

sudo pacman -S linux-headers at xf86-input-wacom --needed --noconfirm
yay -S digimend-kernel-drivers-dkms-git --noconfirm

sudo systemctl enable atd
sudo systemctl start atd

sudo install -Dm 644 $BASE_DIR/52-tablet.conf /etc/X11/xorg.conf.d/52-tablet.conf
sudo install -Dm 644 $BASE_DIR/80-huion.rules /etc/udev/rules.d/80-huion.rules
sudo install -Dm 644 $BASE_DIR/adjust-huion /usr/local/bin/adjust-huion
sudo install -Dm 644 $BASE_DIR/setup-huion-post-X11.sh /usr/local/bin/setup-huion-post-X11.sh

