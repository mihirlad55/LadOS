#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

REPO_PATH="$HOME/.cache/yay"

mkdir -p "$REPO_PATH"

git clone https://aur.archlinux.org/ttf-ms-win10.git $REPO_PATH/ttf-ms-win10

if [[ -d "$BASE_DIR/win10-fonts" ]] && [[ "$(ls $BASE_DIR/win10-fonts)" != "" ]]; then
    echo "Found win10-fonts"
    echo "Copying fonts to $REPO_PATH/ttf-ms-win10/"
    cp -rf $BASE_DIR/win10-fonts/* $REPO_PATH/ttf-ms-win10/
else
    echo "Enter url to windows 10 fonts zip file if available, otherwise leave blank"
    read url

    if [[ "$url" != "" ]]; then
        curl $url --output /tmp/win10-fonts.zip
        unzip -o /tmp/win10-fonts.zip -d $REPO_PATH/ttf-ms-win10
    else
        echo "No url provided"
        exit 1
    fi
fi

yay -S --mflags --skipinteg --needed --noconfirm ttf-ms-win10
