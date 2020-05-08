#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

sudo pacman -S intel-ucode amd-ucode --needed --noconfirm

sudo bootctl install

sudo mkdir -p /boot/loader/entries

echo -n "Enter the path to the root partition (i.e. /dev/sda1): "
read root_path

swap_path=$(blkid | grep "swap" | cut -d':' -f1)
partuuid=$(blkid -s PARTUUID -o value $root_path)

cp $BASE_DIR/arch.conf /tmp/arch.conf

options="options root=PARTUUID=$partuuid rw add_efi_memmap resume=$swap_path"
sed -i /tmp/arch.conf -e "s;^options root=.*$;$options;"

echo "Opening configuration files for any changes. The root PARTUUID has already been set along with the swap paritition path for resume"
read -p "Press enter to continue..."

if [[ "$EDITOR" != "" ]]; then
    $EDITOR /tmp/arch.conf
else
    vim /tmp/arch.conf
fi

sudo install -Dm 755 /tmp/arch.conf /boot/loader/entries/arch.conf

rm /tmp/arch.conf
