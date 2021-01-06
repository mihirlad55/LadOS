#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_MAIN_RULES="$BASE_DIR/main.rules"
readonly NEW_IPTABLES_RULES="/etc/iptables/iptables.rules"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Firewall"
readonly FEATURE_DESC="Install IP Tables Rules"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_IPTABLES_RULES" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(iptables)
readonly DEPENDS_PIP3=()



function check_install() {
    if pacman -Q iptables > /dev/null &&
      diff "$BASE_MAIN_RULES" "$NEW_IPTABLES_RULES"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    local name new_wpa_supplicant_conf

    qecho "Copying "$BASE_MAIN_RULES" to $NEW_IPTABLES_RULES..."
    sudo install -Dm 644 "$BASE_MAIN_RULES" "$NEW_IPTABLES_RULES"
}

function post_install() {
    qecho "Enabling iptables.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" iptables.service
}

function uninstall() {
    qecho "Disabling iptables.service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" iptables.service

    qecho "Removing $NEW_IPTABLES_RULES..."
    sudo rm -f "$NEW_IPTABLES_RULES"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
