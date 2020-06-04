#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_CONF="$BASE_DIR/30-backlight.conf"
readonly NEW_CONF="/etc/X11/xorg.conf.d/30-backlight.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Configure Backlight"
readonly FEATURE_DESC="Install custom backlight configuration for Xorg"
readonly PROVIDES=()
readonly NEW_FILES=("$NEW_CONF")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(xorg-server)



function check_install() {
    if diff "$BASE_CONF" "$NEW_CONF" > /dev/null; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Installing custom backlight configuration for X11..."
    sudo install -Dm 644 "$BASE_CONF" "$NEW_CONF"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
