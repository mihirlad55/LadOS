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
partuuid=$(blkid | grep $root_path | egrep -o 'PARTUUID="[a-z0-9\-]*"' | sed -e 's/"//g' | cut -d'=' -f2)

options="options root=PARTUUID=$partuuid rw add_efi_memmap resume=$swap_path"
sed -i $BASE_DIR/arch.conf -e "s;^options root=.*$;$options;"

echo "Opening configuration files for any changes. The root PARTUUID has already been set along with the swap paritition path for resume"
read -p "Press enter to continue..."

if [[ "$EDITOR" != "" ]]; then
    $EDITOR $BASE_DIR/arch.conf
else
    vim $BASE_DIR/arch.conf
fi

sudo install -Dm 755 $BASE_DIR/arch.conf /boot/loader/entries/arch.conf
