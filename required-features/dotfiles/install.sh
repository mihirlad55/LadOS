#!/usr/bin/bash

sudo pacman -S git zsh xorg-xrdb --needed

if [[ ! -d "$HOME/.ssh/" ]]; then
    ssh-keygen
    echo "Create a new SSH key to clone the dotfiles"
    chromium "https://github.com/settings/keys"
fi

git clone git@github.com:mihirlad55/dotfiles /tmp/dotfiles
cp -rf /tmp/dotfiles/* $HOME/
rm -rf /tmp/dotfiles

# Change shell to zsh
chsh -s /usr/bin/zsh

# Rebuild .Xresources DB
xrdb ~/.Xresources
