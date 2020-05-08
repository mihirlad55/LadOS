#!/usr/bin/bash

CUR_DIR="$PWD"
sudo pacman -S git zsh xorg-xrdb --needed --noconfirm

git clone https://github.com/mihirlad55/dotfiles /tmp/dotfiles
cd /tmp/dotfiles
git submodule init
git submodule update --init

echo "Copying /tmp/dotfiles to $HOME/"
cp -rf /tmp/dotfiles/. $HOME/

echo "Removing /tmp/dotfiles"
rm -rf /tmp/dotfiles

cd "$CUR_DIR"

# Change shell to zsh
chsh -s /usr/bin/zsh

# Rebuild .Xresources DB
xrdb ~/.Xresources

echo "Setting up git and doom emacs..."

echo -n "What is your full name: "
read name

echo -n "What is your email: "
read email

echo -n "What is your main editor: "
read editor

git config --global user.name "$name"
git config --global user.email "$email"
git config --global core.editor "$editor"

echo "Name, email, and editor have been set globally for git."

sed -i $HOME/.doom.d/config.el -e \
    "s/user-full-name \"\"$/user-full-name \"$name\"/"
sed -i $HOME/.doom.d/config.el -e \
    "s/user-mail-address \"\"$/user-mail-address \"$email\"/"

echo "Name and email have been set for Doom Emacs"

echo "Installing neovim plugins..."
nvim -c "PlugInstall | qa"

echo "Done installing dotfiles"
