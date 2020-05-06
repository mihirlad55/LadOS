#!/usr/bin/bash

BASE_DIR=$(dirname "$0")
REQUIRED_FEATURES_DIR="$BASE_DIR/../required-features"

function pause() {
    read -p "Press enter to continue..."
}

function set_timezone() {
    local CURR_DIR="$PWD"

    local zone=

    IFS=$'\n'
    cd /usr/share/zoneinfo
    while true; do
        local options=$(ls)
        local i=1
        for option in ${options[@]}; do
            echo "$i. $option"
            i=$(($i+1))
        done
        echo -n "Select closest match: "
        read num

        local num=$((num-1))

        selection=(${options[$num]})
        if [[ -d "$selection" ]]; then
            cd $selection
        elif [[ -e "$selection" ]]; then
            zone="${PWD}/${selection}"
            break
        fi
    done

    echo "You selected $zone. Now symlinking $zone to /etc/localtime..."
    
    ln -sf "$zone" /etc/localtime

    cd "$CURR_DIR"
}

function set_adjtime() {
    hwclock --systohc
}

function set_locale() {
    echo "Opening /etc/locale.gen... Uncomment the correct locale..."
    pause

    vi /etc/locale.gen

    locale-gen

    local lang=$(cat /etc/locale.gen | egrep '^[^#].*$' -m 1 | cut -d' ' -f1)

    echo "LANG=$lang" >> /etc/locale.conf

    echo "Locale is set"
}

function set_hostname() {
    local hostname

    echo -n "Enter a hostname for this computer: "
    read hostname

    echo $hostname >> /etc/hostname

    echo "$hostname has been set in /etc/hostname"
}

function setup_hosts() {
    echo "Setting up default hosts file..."

    echo "127.0.0.1\tlocalhost" >> /etc/hosts
    echo "::1\tlocalhost" > /etc/hosts

    echo "Opening hosts file for additional configuration..."
    pause
    vi /etc/hosts
}

function create_initramfs() {
    echo "Making initframfs..."
    mkinitcpio -P linux
    echo "Done making initramfs"
}

function set_root_passwd() {
    echo "Set root password"
    until passwd; do done
    echo "Root password set"
}

function create_user_account() {
    echo "Creating new default user account..."
    read username

    echo "Creating user $username"
    useradd -m $username

    echo "Set password for $username"

    until passwd $username; do done

    echo "Password set for $username"
}

function setup_sudo_and_su() {
    pacman -Syyu

    echo "Installing sudo..."
    $REQUIRED_FEATURES_DIR/1-sudoers/install.sh

    usermod -a -G wheel "$username"
    echo "Added $username to group wheel"

    echo "Changing user to $username..."
    su -l -c -P "/root/LadOS/install/su-install.sh" $username
}

set_timezone

set_adjtime

set_locale

set_hostname

setup_hosts

create_initframfs

set_root_passwd

create_user_account

setup_sudo_and_su
