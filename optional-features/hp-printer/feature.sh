#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="hp-printer"
feature_desc="Install HP printer"

provides=()
new_files=()
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(cups hplip)

# TODO: Add configuration

function check_install() {
    sudo lpoptions
    read -p "Is your printer displayed here? [Y\n] " resp

    if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function prepare() {
    qecho "Enabling and starting cupsd..."
    sudo systemctl enable --now org.cups.cupsd
}

function install() {
    read -p "Enter printer name: " name

    lpinfo -m

    read -p "Enter driver path: " driver

    read -p "Enter ip address: " ip_address

    sudo lpadmin -p $name -E -v "ipp://$ip_address/ipp/print" -m $driver

    sudo lpoptions -d $name
}


source "$LAD_OS_DIR/common/feature_common.sh"
