#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

sudo pacman -S refind --needed --noconfirm

sudo refind-install

sudo mkdir -p /boot/EFI/refind/themes
sudo rm -rf /boot/EFI/refind/themes/rEFInd-minimal
sudo git clone https://github.com/andersfischernielsen/rEFInd-minimal-black.git /boot/EFI/refind/themes/rEFInd-minimal

swap_path=$(cat /etc/fstab | grep -P -B 1 \
    -e "UUID=[a-zA-Z0-9\-]*[\t ]+none[\t ]+swap" | head -n1 | sed 's/# *//')
root_path=$(cat /etc/fstab | grep -P -B 1 \
    -e "UUID=[a-zA-Z0-9\-]*[\t ]+/[\t ]+" | head -n1 | sed 's/# *//')

partuuid=$(blkid -s PARTUUID -o value $root_path)

cp $BASE_DIR/refind-options.conf /tmp/refind-options.conf
cp $BASE_DIR/refind-manual.conf /tmp/refind-manual.conf

sed -i /tmp/refind-options.conf -e "s/root=PARTUUID=[a-z0-9\-]*/root=PARTUUID=$partuuid/"
sed -i /tmp/refind-options.conf -e "s;resume=;resume=$swap_path;"

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
include refind-manual.conf
include refind-options.conf
include themes/rEFInd-minimal/theme.conf
" | sudo tee -a /boot/EFI/refind/refind.conf

echo "Done"
