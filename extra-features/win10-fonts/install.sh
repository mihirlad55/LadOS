#!/bin/sh

BASE_DIR=$(dirname "$0")

REPO_PATH="$HOME/.cache/yay"

mkdir -p "$REPO_PATH"

git clone https://aur.archlinux.org/ttf-ms-win10.git $REPO_PATH/ttf-ms-win10
cp -r $BASE_DIR/win-fonts/* $HOME/.cache/yay/ttf-ms-win10/

yay -S --mflags --skipinteg ttf-ms-win10 
