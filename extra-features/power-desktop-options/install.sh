#!/bin/sh

BASE_DIR=$(dirname "$0")

sudo pacman -S xdg-utils

echo "Copying files..."
sudo install -Dm 644 $BASE_PATH/power-desktop-files/hibernate.desktop /usr/share/applications/hibernate.desktop
sudo install -Dm 644 $BASE_PATH/power-desktop-files/lock.desktop /usr/share/applications/lock.desktop
sudo install -Dm 644 $BASE_PATH/power-desktop-files/logout.desktop /usr/share/applications/logout.desktop
sudo install -Dm 644 $BASE_PATH/power-desktop-files/reboot.desktop /usr/share/applications/reboot.desktop
sudo install -Dm 644 $BASE_PATH/power-desktop-files/poweroff.desktop /usr/share/applications/poweroff.desktop
