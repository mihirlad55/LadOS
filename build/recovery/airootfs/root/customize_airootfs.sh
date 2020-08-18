#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

echo 'Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.'

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

# Set root password
echo "Enter password to set for recovery root: "
passwd

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
