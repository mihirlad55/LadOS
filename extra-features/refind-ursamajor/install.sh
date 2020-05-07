#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

sudo pacman -S refind --needed --noconfirm

sudo refind-install

sudo mkdir -p /boot/EFI/refind/themes
sudo git clone https://github.com/kgoettler/ursamajor-rEFInd.git /boot/EFI/refind/themes/rEFInd-minimal

echo -n "Enter the path to the root partition (i.e. /dev/sda1): "
read root_path

swap_path=$(blkid | grep "swap" | cut -d':' -f1)
partuuid=$(blkid | grep $root_path | egrep -o 'PARTUUID="[a-z0-9\-]*"' | sed -e 's/"//g')

sed -i $BASE_DIR/refind-options.conf -e "s/root=PARTUUID=[a-z0-9\-]*/root=PARTUUID=$partuuid/"
sed -i $BASE_DIR/refind-options.conf -e "s;resume=/dev/[a-z0-9]*;resume=$swap_path;"

echo "Opening configuration files for any changes. The root PARTUUID has already been set along with the swap paritition path for resume"
read -p "Press enter to continue..."

if [[ "$EDITOR" != "" ]]; then
    $EDITOR $BASE_DIR/refind-options.conf
    $EDITOR $BASE_DIR/refind-manual.conf
else
    vim $BASE_DIR/refind-options.conf
    vim $BASE_DIR/refind-manual.conf
fi

echo "Copying configuration files to /boot/EFI/refind/..."
sudo install -Dm 755 $BASE_DIR/refind-options.conf /boot/EFI/refind/refind-options.conf
sudo install -Dm 755 $BASE_DIR/refind-manual.conf /boot/EFI/refind/refind-manual.conf
sudo install -Dm 755 /usr/share/refind/refind.conf-sample /boot/EFI/refind/refind.conf

echo "
include themes/rEFInd-minimal/theme.conf
include refind-options.conf
include refind-manual.conf
" | sudo tee -a /boot/EFI/refind/refind.conf

echo "Done"
