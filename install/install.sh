#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/install_common.sh"

WIFI_ENABLED=0


function check_efi_mode() {
    msg "Checking if system booted in EFI mode..."
    if ls /sys/firmware/efi/efivars &> /dev/null; then
        msg2 "Verified EFI boot"
    else
        msg2 "System not booted in EFI mode"
        exit 1
    fi
}

function setup_partitions() {
    msg "Partition setup..."
    plain "Make sure you create the system partitions, format them, and mount root on /mnt with all the filesystems mounted on root"
    if [[ "$CONF_NOCONFIRM" = "no" ]]; then
        if ! prompt "Are the filesystems mounted?"; then
            msg2 "Please partition the drive and exit the shell once finished..."
            bash
        fi
    fi
}

function connect_to_internet() {
    msg "Checking internet connection..."
    if ! ping -c 1 www.google.com &> /dev/null; then
        if [[ "$CONF_USE_WIFI" = "yes" ]] || prompt "Setup WiFi for setup?"; then
            setup_wifi
        fi
    fi
    msg2 "Waiting for connection to Internet..."
    until ping -c 1 www.google.com &> /dev/null; do sleep 1; done
}

function setup_wifi() {
    msg "Setting up WiFI..."

    local network_conf

    if [[ -f "$CONF_DIR/network.conf" ]]; then
        network_conf="$(cat "$CONF_DIR/network.conf")"
    fi

    conf_path="/tmp/wpa_supplicant.conf"

    echo "ctrl_interface=/run/wpa_supplicant" > $conf_path
    echo "update_config=1" >> $conf_path

    if [[ "$network_conf" != "" ]]; then
        echo "$network_conf" >> $conf_path        
    else
        msg2 "Opening wpa_supplicant.conf to add network info..."
        pause
        vi $conf_path
    fi

    local adapter
    if [[ "$CONF_WIFI_ADAPTER" != "" ]]; then
        local adapter="$CONF_WIFI_ADAPTER"
    else
        ip link
        adapter="$(ask "Enter name of WiFI adapter")"
    fi

    wpa_supplicant $VERBOSITY_FLAG -B -i"${adapter}" -c "$conf_path"
    dhcpcd $VERBOSITY_FLAG

    WIFI_ENABLED=1
}

function update_system_clock() {
    msg "Updating system clock..."
    timedatectl set-ntp true
}

function rank_mirrors() {
    msg "Ranking pacman mirrors..."
    local country

    if [[ "$CONF_COUNTRY_CODE" != "" ]]; then
        country="$CONF_COUNTRY_CODE"        
    else
        country="$(ask "Enter your country code (i.e. US)")"
    fi

    msg2 "Beginning mirror ranking..." "(This may take a minute)"
    curl -s "https://www.archlinux.org/mirrorlist/?country=${country}&protocol=https&use_mirror_status=on" | \
        sed -e 's/^#Server/Server/' -e '/^#/d' | \
        "$BASE_DIR"/rankmirrors -n 5 -m 1 - \
        > /etc/pacman.d/mirrorlist

    msg2 "Top 5 $country mirrors saved in /etc/pacman.d/mirrorlist"
}

function enable_localrepo() {
    msg "Checking for localrepo..."
    if [[ -f "$LAD_OS_DIR/localrepo/localrepo.db" ]]; then
        if ! grep -q /etc/pacman.conf -e "LadOS"; then
            msg2 "Found localrepo. Enabling..."
            sed -i /etc/pacman.conf -e '1 i\Include = /LadOS/install/localrepo.conf'
        else
            msg2 "Localrepo already enabled"
        fi
        pacman -Sy
    fi
}

function pacstrap_install() {
    msg "Starting pacstrap install..."

    if mount | grep -q /mnt; then
        pacstrap /mnt base linux linux-firmware
    else
        error "Parititions not mounted on /mnt. Please mount the filesystems."
        exit 1
    fi
}

function generate_fstab() {
    msg "Generating fstab..."
    genfstab -U /mnt > /mnt/etc/fstab
}

function start_root_install() {
    msg "Preparing for root install..."

    msg2 "Copying LadOS to new system..."
    cp -rft "/mnt" "$LAD_OS_DIR"
    chmod -R go=u /mnt/LadOS

    if [[ "$WIFI_ENABLED" -eq 1 ]]; then
        msg2 "Copying wpa_supplicant to new system..."
        mkdir -p /mnt/etc/wpa_supplicant
        install -Dm 644 /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
    fi

    msg2 "Arch-chrooting to system as root..."
    arch-chroot /mnt /LadOS/install/root-install.sh "$VERBOSITY_FLAG"
}

function start_user_install() {
    msg "Preparing for user install..."

    msg2 "Getting default username..."
    local username
    read -r username < /mnt/var/tmp/default_user
    rm -f /mnt/var/tmp/default_user

    msg2 "Arch-chrooting with $username..."
    arch-chroot -u $username /mnt /LadOS/install/user-install.sh $VERBOSITY_FLAG
}


check_efi_mode

setup_partitions

connect_to_internet

update_system_clock

rank_mirrors

enable_localrepo

pacstrap_install

generate_fstab

start_root_install

start_user_install
