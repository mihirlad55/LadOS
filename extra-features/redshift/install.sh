#!/usr/bin/bash

sudo pacman -S redshift geoclue2 --needed --noconfirm

geoclue_conf_path="/etc/geoclue/geoclue.conf"

# Allow redshift to use geoclue
echo "Adding the following to $geoclue_conf_path..."
echo "[redshift]" | sudo tee -a $geoclue_conf_path
echo "allowed=true" | sudo tee -a $geoclue_conf_path
echo "system=false" | sudo tee -a $geoclue_conf_path
echo "users=" | sudo tee -a $geoclue_conf_path
echo "url=https://location.services.mozilla.com/v1/geolocate?key=geoclue" |
    sudo tee -a $geoclue_conf_path

echo "Done installing redshift"
