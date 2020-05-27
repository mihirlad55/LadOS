#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"

source "$LAD_OS_DIR/common/feature_header.sh"

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
    read -rp "Is your printer displayed here? [y/N] " resp

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
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" org.cups.cupsd
}

function install() {
    read -rp "Enter printer name: " name

    lpinfo -m

    read -rp "Enter driver path: " driver

    read -rp "Enter ip address: " ip_address

    sudo lpadmin -p "$name" -E -v "ipp://$ip_address/ipp/print" -m "$driver"

    sudo lpoptions -d "$name"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
