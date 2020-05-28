#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="hp-printer"
readonly FEATURE_DESC="Install HP printer"
readonly PROVIDES=()
readonly NEW_FILES=()
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(cups hplip)

# TODO: Add configuration



function check_install() {
    local resp

    sudo lpoptions
    read -rp "Is your printer displayed here? [y/N] " resp

    if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function prepare() {
    qecho "Enabling and starting cupsd..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" org.cups.cupsd
}

function install() {
    local name driver ip_address

    read -rp "Enter printer name: " name

    lpinfo -m

    read -rp "Enter driver path: " driver

    read -rp "Enter ip address: " ip_address

    sudo lpadmin -p "$name" -E -v "ipp://$ip_address/ipp/print" -m "$driver"

    sudo lpoptions -d "$name"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
