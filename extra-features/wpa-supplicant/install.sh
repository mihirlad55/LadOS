#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
INSTALL_CONF_DIR="$( readlink -f "$BASE_DIR/../../conf/install")"

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

sudo pacman -S wpa_supplicant dhcpcd --needed --noconfirm

ip link
echo "Note that the name of this card may change when you boot into the system"
echo -n "Enter name of network card: "
read card

echo "ctrl_interface=/run/wpa_supplicant" | 
    sudo tee /etc/wpa_supplicant/wpa_supplicant-${card}.conf \
    > /dev/null
echo "update_config=1" |
    sudo tee -a /etc/wpa_supplicant/wpa_supplicant-${card}.conf \
    > /dev/null

if [[ -f "$INSTALL_CONF_DIR/network.conf" ]]; then
    network="$(cat "$INSTALL_CONF_DIR/network.conf")"

    echo "$network" |
        sudo tee -a /etc/wpa_supplicant/wpa_supplicant-${card}.conf \
        > /dev/null
fi

echo "Opening wpa_supplicant file..."
if command -v sudoedit &> /dev/null; then
    sudoedit /etc/wpa_supplicant/wpa_supplicant-${card}.conf
else
    vim /etc/wpa_supplicant/wpa_supplicant-${card}.conf
fi

sudo systemctl enable --now wpa_supplicant@${card}.service
sudo systemctl enable --now dhcpcd.service
