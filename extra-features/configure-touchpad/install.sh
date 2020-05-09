#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

sudo pacman -S xorg-server --noconfirm --needed

shopt -s expand_aliases
echo "Installing custom touchpad configuration for X11..."
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

sudo install -Dm 644 $BASE_DIR/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf
