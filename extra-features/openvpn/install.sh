#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

sudo pacman -S openvpn --needed --noconfirm


echo "To start the vpn, run systemctl start openvpn-client@miami"

echo "Get the username and password from https://www.expressvpn.com/sign-in"
echo "Get the server configs from https://www.expressvpn.com/sign-in and copy them into client/"

echo -n "Username: "
read username

echo -n "Password: "
read password

# Copy config files
echo "Copying config files..."
sudo mkdir /etc/openvpn/client
sudo install -m 644 $BASE_DIR/client/*  /etc/openvpn/client/

sudo touch /etc/openvpn/client/login.conf
echo $username | sudo tee -a /etc/openvpn/client/login.conf
echo $password | sudo tee -a /etc/openvpn/client/login.conf
