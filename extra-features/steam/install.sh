#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

echo "Enabling multilib repo..."
sudo sed -i 's/#*\[multilib\]/\[multilib\]/' /etc/pacman.conf
sudo sed -i '/\[multilib\]/!b;n;cInclude = \/etc\/pacman.d\/mirrorlist' /etc/pacman.conf

echo "Updating database..."
sudo pacman -Sy

echo "Installing Steam..."

sudo pacman -S steam --needed --noconfirm

echo "Configuring library paths for steam..."
sudo install -Dm 644 $BASE_DIR/steam.conf /etc/ld.so.conf.d/steam.conf
sudo ldconfig

echo "DONE!"
