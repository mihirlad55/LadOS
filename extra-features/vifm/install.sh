#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

sudo pacman -S ffmpeg ffmpegthumbnailer vifm python python-pip --needed --noconfirm
sudo pip3 install poppler epub-thumbnailer
yay -S fontpreview --needed --noconfirm

git clone https://github.com/marianosimone/epub-thumbnailer /tmp/epub-thumbnailer
sudo python /tmp/epub-thumbnailer/install.py install
rm -rf /tmp/epub-thumbnailer

sudo install -Dm 755 $BASE_DIR/vifmrun /usr/local/bin/vifmrun
install -Dm 755 $BASE_DIR/vifmimg $HOME/.vifm/scripts

sudo sed -i 's/Exec=vifm/Exec=vifmrun/' /usr/share/applications/vifm.desktop
