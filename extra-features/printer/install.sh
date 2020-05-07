#!/usr/bin/bash

sudo pacman -S cups --needed

sudo systemctl enable org.cups.cupsd
sudo systemctl start org.cups.cupsd

echo -n "Enter printer name: "
read name

lpinfo -m

echo -n "Enter driver path: "
read driver

echo -n "Enter ip address: "
read ip_address

sudo lpadmin -p $name -E -v "ipp://$ip_address/ipp/print" -m $driver

sudo lpoptions -d $name

