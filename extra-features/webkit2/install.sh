#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

sudo pacman -S lightdm-webkit2-greeter --needed --noconfirm
yay -S lightdm-webkit2-theme-material2 --needed --noconfirm

echo "Changing greeter session in /etc/lightdm/lightdm.conf"
sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf

echo "To change greeter avatar, copy png to /var/lib/AccountsService/<username>."
echo "Note: <username> is the png itself, not a folder"

echo "To add backgrounds, copy backgrounds to /usr/share/backgrounds"
echo "Make sure the avatar and background are readable by everyone"

echo "Copying lightdm-webkit2-greeter.conf to /etc/lightdm"
sudo install -Dm 644 $BASE_DIR/lightdm-webkit2-greeter.conf /etc/lightdm/lightdm-webkit2-greeter.conf
