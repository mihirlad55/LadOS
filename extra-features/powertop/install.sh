#!/usr/bin/bash

BASE_DIR=$(dirname "$0")

sudo pacman -S powertop --needed

sudo install -Dm 644 $BASE_DIR/powertop.service /etc/systemd/system/powertop.service

sudo systemctl enable powertop
sudo systemctl start powertop
