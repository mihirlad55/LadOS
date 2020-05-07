#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

echo "Installing physlock..."
sudo pacman -S physlock --needed --noconfirm

echo "Copying physlock.service..."
sudo install -Dm 644 $BASE_DIR/physlock.service /etc/systemd/system/physlock.service

sudo systemctl enable --now physlock.service
