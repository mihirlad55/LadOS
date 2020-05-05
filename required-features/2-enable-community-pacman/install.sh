#!/usr/bin/bash

echo "Enabling community repo..."
sudo sed -i /etc/pacman.conf -e "s/^#\[community\]$/\[community\]/"
sudo sed -i /etc/pacman.conf -e '/\[community\]/!b;n;cInclude = \/etc\/pacman.d\/mirrorlist'

if awk '/^\[community\]/,/^Include/' /etc/pacman.conf; then
    echo "Community repo enabled!"
fi
