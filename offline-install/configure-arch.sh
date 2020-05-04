#!/bin/sh

# Disable system journal being stored in RAM
echo "Disable system journal..."
sed -i 's/Storage=volatile/#Storage=auto/' /etc/systemd/journald.conf

# Remove special udev rule
echo "Removing special udev rule..."
rm /etc/udev/rules.d/81-dhcpcd.rules

# Disable and remove services created by archiso
echo "Disabling and removing services created by archiso..."
systemctl disable pacman-init
systemctl disable choose-mirror
rm -r /etc/systemd/system/{choose-mirror.service,pacman-init.service,etc-pacman.d-gnupg.mount,getty@tty1.service.d}
rm /etc/systemd/scripts/choose-mirror

# Remove special scripts of live environment
echo "Removing special scripts of live environment..."
rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
rm /root/{.automated_script.sh,.zlogin}
rm /etc/mkinitcpio-archiso.conf
rm -r /etc/initcpio

# Import archlinux keys
echo "Importing archlinux keys..."
pacman-key --init
pacman-key --populate archlinux

echo "Setting up locale and timezone..."
ln -sf /usr/share/zoneinfo/Americas/New_York /etc/localtime
hwclock --systohc

echo "Generating locale..."
locale-gen

echo "Making hostname file..."
echo "iphone" > /etc/hostname

echo "Making hosts file..."
echo "
127.0.0.1   localhost
::1         localhost
" > /etc/hosts

echo "Enter password for root:"
passwd

useradd mihirlad55
passwd mihirlad55
echo "Enter password for mihirlad55:"

echo "DONE!"

