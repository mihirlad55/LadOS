#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

echo "Installing cronie..."
sudo pacman -S cronie --needed --noconfirm

echo "Installing root crontab..."
sudo crontab $BASE_DIR/root-cron

echo "Enabling cronie..."
sudo systemctl enable --now cronie

echo "Done"
