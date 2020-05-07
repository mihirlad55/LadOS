#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

echo "Adding custom sudo file..."

sudo pacman -S sudo --needed --noconfirm
sudo install -Dm 644 $BASE_DIR/10-sudoers-custom /etc/sudoers.d/10-sudoers-custom
