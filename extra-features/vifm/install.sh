#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

sudo pacman -S ffmpeg ffmpegthumbnailer vifm --needed
sudo pip3 install poppler epub-thumbnailer
yay -S fontpreview

git clone https://github.com/marianosimone/epub-thumbnailer $BASE_DIR/epub-thumbnailer
sudo python $BASE_DIR/epub-thumbnailer/install.py install

sudo install -Dm 755 $BASE_DIR/vifmrun /usr/local/bin/vifmrun
install -Dm 755 $BASE_DIR/vifmimg $HOME/.vifm/scripts

sudo sed -i 's/Exec=vifm/Exec=vifmrun/' /usr/share/applications/vifm.desktop
