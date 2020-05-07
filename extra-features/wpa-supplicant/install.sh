#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

sudo pacman -S wpa_supplicant dhcpcd --needed

sudo install -Dm 644 wpa_supplicant-wlp2s0.conf /etc/wpa_supplicant/wpa_supplicant-wlp2s0.conf

sudo systemctl enable --now wpa_supplicant@wlp2s0.service
sudo systemctl enable --now dhcpcd.service
