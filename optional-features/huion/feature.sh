#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly INSTALL_BIN_DIR="/usr/local/bin"
readonly NEW_TABLET_CONF="/etc/X11/xorg.conf.d/52-tablet.conf"
readonly NEW_HUION_RULES="/etc/udev/rules.d/80-huion.rules"
readonly NEW_ADJUST_SH="$INSTALL_BIN_DIR/adjust-huion"
readonly NEW_SETUP_SH="$INSTALL_BIN_DIR/setup-huion-post-X11.sh"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Huion"
readonly FEATURE_DESC="Install scripts, services, configuration to use Huion \
tablet more conveniently"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_TABLET_CONF" \
    "$NEW_HUION_RULES" \
    "$NEW_ADJUST_SH" \
    "$NEW_SETUP_SH" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=(digimend-kernel-drivers-dkms-git)
readonly DEPENDS_PACMAN=(linux-headers at xf86-input-wacom)



function check_install() {
    local f

    for f in "${NEW_FILES[@]}"; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    qecho "$FEATURE_NAME is installed"
    return 0
}

function install() {
    sudo rmmod hid-kye
    sudo rmmod hid-uclogic
    sudo rmmod hid-huion

    sudo install -Dm 644 "$BASE_DIR/52-tablet.conf" "$NEW_TABLET_CONF"
    sudo install -Dm 644 "$BASE_DIR/80-huion.rules" "$NEW_HUION_RULES"
    sudo install -Dm 644 "$BASE_DIR/adjust-huion" "$NEW_ADJUST_SH"
    sudo install -Dm 644 "$BASE_DIR/setup-huion-post-X11.sh" "$NEW_SETUP_SH"
}

function post_install() {
    qecho "Enabling std..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" atd
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}

source "$LAD_OS_DIR/common/feature_footer.sh"
