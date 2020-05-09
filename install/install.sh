#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

WIFI_ENABLED=0

source "$BASE_DIR/conf/defaults.sh"

function pause() {
    read -p "Press enter to continue..."
}

function prompt() {
    while true; do
        echo -n "$1 [Y/n] "
        read resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

function check_efi_mode() {
    if ls /sys/firmware/efi/efivars > /dev/null; then
        echo "Verified EFI boot"
    else
        echo "System not booted in EFI mode"
        exit 1
    fi
}

function setup_partitions() {
    echo -ne "Make sure you create the system partitions, format them, and \
        mount root on /mnt with all the filesystems mounted on root\n"
    if [[ "$DEFAULTS_NOCONFIRM" = "no" ]]; then
        if ! prompt "Are the filesystems mounted?"; then
            echo "Please partition the drive and exit the shell once finished..."
            bash
        fi
    fi
}

function connect_to_internet() {
    if ! ping -c 1 www.google.com &> /dev/null; then
        if [[ "$DEFAULTS_USE_WIFI" = "yes" ]] || prompt "Setup WiFi for setup?"; then
            setup_wifi
        fi
    fi
    echo "Waiting for connection to Internet..."
    until ping -c 1 www.google.com &> /dev/null; do sleep 1; done
}

function setup_wifi() {
    local network_conf=$(cat $BASE_DIR/conf/network.conf)

    conf_path="/tmp/wpa_supplicant.conf"

    echo "ctrl_interface=/run/wpa_supplicant" > $conf_path
    echo "update_config=1" >> $conf_path

    if [[ "$network_conf" != "" ]]; then
        echo "$network_conf" >> $conf_path        
    else
        echo "Opening wpa_supplicant.conf to add network info..."
        pause
        vi $conf_path
    fi

    local adapter
    if [[ "$DEFAULTS_WIFI_ADAPTER" != "" ]]; then
        local adapter="$DEFAULTS_WIFI_ADAPTER"
    else
        ip link
        echo -n "Enter name of WiFI adapter: "
        read adapter
    fi

    wpa_supplicant -B -i${adapter} -c $conf_path
    dhcpcd

    WIFI_ENABLED=1
}

function update_system_clock() {
    echo "Updating system clock..."
    timedatectl set-ntp true
}

function rank_mirrors() {
    local country

    if [[ "$DEFAULTS_COUNTRY_CODE" != "" ]]; then
        country="$DEFAULTS_COUNTRY_CODE"        
    else
        echo -n "Enter your country code (i.e. US): "
        read country
    fi

    echo "Ranking pacman mirrors..."
    curl -s "https://www.archlinux.org/mirrorlist/?country=${country}&protocol=https&use_mirror_status=on" | \
        sed -e 's/^#Server/Server/' -e '/^#/d' | \
        $BASE_DIR/rankmirrors -n 5 -m 1 - \
        > /etc/pacman.d/mirrorlist

    echo "Top 5 $country mirrors saved in /etc/pacman.d/mirrorlist"
}

function pacstrap_install() {
    echo "Now beginning pacstrap install..."

    if mount | grep /mnt; then
        pacstrap /mnt base linux linux-firmware
    else
        echo "Parititions not mounted on /mnt. Please mount the filesystems."
        exit 1
    fi

    echo "Finished pacstrap install"
}

function generate_fstab() {
    echo "Generating fstab..."
    genfstab -U /mnt > /mnt/etc/fstab
    echo "Fstab generated"
}

function start_chroot_install() {
    echo "Copying LadOS to new system"
    mkdir -p /mnt/LadOS
    cp -r $BASE_DIR/../* /mnt/LadOS
    chmod -R go=u /mnt/LadOS

    if [[ "$WIFI_ENABLED" -eq 1 ]]; then
	echo "Copying wpa_supplicant to new system..."
        mkdir -p /mnt/etc/wpa_supplicant
        install -Dm 644 /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
    fi
    echo "Arch-chrooting to system"
    arch-chroot /mnt "/LadOS/install/chroot-install.sh"
}



check_efi_mode

setup_partitions

connect_to_internet

update_system_clock

rank_mirrors

pacstrap_install

generate_fstab

start_chroot_install
