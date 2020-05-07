#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

sudo pacman -S xorg-server --needed --noconfirm

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

echo "Installing custom backlight configuration for X11..."
sudo install -Dm 644 $BASE_DIR/30-backlight.conf /etc/X11/xorg.conf.d/30-backlight.conf
