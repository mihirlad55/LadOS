#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
CONF_DIR="$( readlink -f "$BASE_DIR/../../conf/dotfiles")"
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


source "$CONF_DIR/defaults.sh"

echo "Setting up git and doom emacs..."
if [[ "$DEFAULTS_FULL_NAME" != "" ]]; then
    name="$DEFAULTS_FULL_NAME"
else
    echo -n "What is your full name: "
    read name
fi

if [[ "$DEFAULTS_EMAIL" != "" ]]; then
    email="$DEFAULTS_EMAIL"
else
    echo -n "What is your email: "
    read email
fi

if [[ "$DEFAULTS_EDITOR" != "" ]]; then
    editor="$DEFAULTS_EDITOR"
else
    echo -n "What is your main editor: "
    read editor
fi

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
