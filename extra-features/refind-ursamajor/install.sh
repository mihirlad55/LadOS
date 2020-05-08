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
partuuid=$(blkid -s PARTUUID -o value $root_path)

cp $BASE_DIR/refind-options.conf /tmp/refind-options.conf
cp $BASE_DIR/refind-manual.conf /tmp/refind-manual.conf

sed -i /tmp/refind-options.conf -e "s/root=PARTUUID=[a-z0-9\-]*/root=PARTUUID=$partuuid/"
sed -i /tmp/refind-options.conf -e "s;resume=/dev/[a-z0-9]*;resume=$swap_path;"

echo "Opening configuration files for any changes. The root PARTUUID has already been set along with the swap paritition path for resume"
read -p "Press enter to continue..."

if [[ "$EDITOR" != "" ]]; then
    $EDITOR /tmp/refind-options.conf
    $EDITOR /tmp/refind-manual.conf
else
    vim /tmp/refind-options.conf
    vim /tmp/refind-manual.conf
fi

echo "Copying configuration files to /boot/EFI/refind/..."
sudo install -Dm 755 /tmp/refind-options.conf /boot/EFI/refind/refind-options.conf
sudo install -Dm 755 /tmp/refind-manual.conf /boot/EFI/refind/refind-manual.conf
sudo install -Dm 755 /usr/share/refind/refind.conf-sample /boot/EFI/refind/refind.conf

rm /tmp/refind-options.conf
rm /tmp/refind-manual.conf

echo "
include themes/rEFInd-minimal/theme.conf
include refind-options.conf
include refind-manual.conf
" | sudo tee -a /boot/EFI/refind/refind.conf

echo "Done"
