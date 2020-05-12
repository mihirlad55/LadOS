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
        echo "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi
}

function prepare() {
    echo "Enabling and starting cupsd..."
    sudo systemctl enable --now org.cups.cupsd
}

function install() {
    echo -n "Enter printer name: "
    read name

    lpinfo -m

    echo -n "Enter driver path: "
    read driver

    echo -n "Enter ip address: "
    read ip_address

    sudo lpadmin -p $name -E -v "ipp://$ip_address/ipp/print" -m $driver

    sudo lpoptions -d $name
}


source "$LAD_OS_DIR/common/feature_common.sh"
