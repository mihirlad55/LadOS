#!/bin/bash

CUR_DIR="$PWD"

# Install necessary packages

if command -v yay > /dev/null; then
    echo "Yay already installed."
    exit 0
fi

echo "Installing necessary packages..."
sudo pacman -S --needed --noconfirm base-devel git wget yajl

# Clone package-query
echo "Cloning package-query..."
cd /tmp
git clone https://aur.archlinux.org/package-query.git

# Make package
echo "Making package package-query..."
cd package-query/
makepkg -si --noconfirm

# Clone yay
echo "Cloning yay..."
cd ..
git clone https://aur.archlinux.org/yay.git

# Make package
echo "Making yay..."
cd yay/
makepkg -si --noconfirm

# Clean up
echo "Removing files and cleaning up"
cd ..
sudo rm -dR yay/ package-query/

cd "$CUR_DIR"
