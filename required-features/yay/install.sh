#!/bin/bash

CUR_DIR="$PWD"

echo Receive GPG keys for some packages
gpg --recv-keys 0FC3042E345AD05D

# Receive key for spotify
gpg --recv-keys A87FF9DF48BF1C90

# Receive key for bluez-utils-compat
gpg --recv-keys 06CA9F5D1DCF2659

# i3-wn-patchfonts
gpg --recv-keys 4E7160ED4AC8EE1D

# Install necessary packages
echo "Installing necessary packages..."
sudo pacman -S --needed base-devel git wget yajl

# Clone package-query
echo "Cloning package-query..."
cd /tmp
git clone https://aur.archlinux.org/package-query.git

# Make package
echo "Making package package-query..."
cd package-query/
makepkg -si

# Clone yay
echo "Cloning yay..."
cd ..
git clone https://aur.archlinux.org/yay.git

# Make package
echo "Making yay..."
cd yay/
makepkg -si

# Clean up
echo "Removing files and cleaning up"
cd ..
sudo rm -dR yay/ package-query/

cd "$CUR_DIR"
