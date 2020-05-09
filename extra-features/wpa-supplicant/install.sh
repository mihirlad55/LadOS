#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

sudo pacman -S wpa_supplicant dhcpcd --needed --noconfirm

ip link
echo -n "Enter name of network card: "
read card

echo "ctrl_interface=/run/wpa_supplicant" | sudo tee /etc/wpa_supplicant/wpa_supplicant-${card}.conf
echo "update_config=1" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant-${card}.conf

echo "Opening wpa_supplicant file..."
if command -v sudoedit &> /dev/null; then
    sudoedit /etc/wpa_supplicant/wpa_supplicant-${card}.conf
else
    vim /etc/wpa_supplicant/wpa_supplicant-${card}.conf
fi

sudo systemctl enable --now wpa_supplicant@${card}.service
sudo systemctl enable --now dhcpcd.service
