#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

REPO_PATH="$HOME/.cache/yay"

mkdir -p "$REPO_PATH"

git clone https://aur.archlinux.org/ttf-ms-win10.git $REPO_PATH/ttf-ms-win10
echo "Enter url to windows 10 fonts zip file if available, otherwise leave blank"
read url

if [[ "$url" != "" ]]; then
    curl $url --output /tmp/win10-fonts.zip
    unzip -o /tmp/win10-fonts.zip -d $REPO_PATH/ttf-ms-win10
else
    echo "No url provided"
    echo "Copy windows 10 fonts into $REPO_PATH/ttf-ms-win10/"
    read -p "Press enter to continue..."
fi


yay -S --mflags --skipinteg --needed --noconfirm ttf-ms-win10
