#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

CUR_DIR="$PWD"

sudo pacman -S lightdm lightdm-gtk-greeter xorg-server xorg-server-common --needed --noconfirm

git clone https://github.com/mihirlad55/dwm /tmp/dwm
cd /tmp/dwm
sudo make clean install

cd "$CUR_DIR"
rm -rf /tmp/dwm

sudo systemctl enable lightdm

sudo systemctl set-default graphical.target

