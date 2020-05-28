#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_STEAM_CONF="$BASE_DIR/steam.conf"
readonly NEW_STEAM_CONF="/etc/ld.so.conf.d/steam.conf"
readonly MOD_PACMAN_CONF="/etc/pacman.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="steam"
readonly FEATURE_DESC="Install steam with multilib repo"
readonly PROVIDES=(steam)
readonly NEW_FILES=("$NEW_STEAM_CONF")
readonly MODIFIED_FILES=("$MOD_PACMAN_CONF")
readonly TEMP_FILES=() 
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()



function check_install() {
    if [[ "$(awk '/^\[multilib\]/,/^Include/' "$MOD_PACMAN_CONF")" != "" ]] &&
        diff "$BASE_STEAM_CONF" "$NEW_STEAM_CONF"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Enabling multilib repo..."
    sudo sed -i 's/#*\[multilib\]/\[multilib\]/' "$MOD_PACMAN_CONF"
    sudo sed -i '/\[multilib\]/!b;n;cInclude = \/etc\/pacman.d\/mirrorlist' \
        "$MOD_PACMAN_CONF"

    qecho "Updating database..."
    sudo pacman -Sy

    qecho "Installing Steam..."

    sudo pacman -S steam --needed --noconfirm

    qecho "Configuring library paths for steam..."
    sudo install -Dm 644 "$BASE_STEAM_CONF" "$NEW_STEAM_CONF"
    sudo ldconfig

    qecho "DONE!"
}

function uninstall() {
    qecho "Uninstalling steam..."
    sudo pacman -Rsu steam --noconfirm

    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
    sudo ldconfig

    qecho "Disabling multilib repo"
    sudo sed -i "$MOD_PACMAN_CONF" -e "s/^\[multilib\]$/#&/"
    sudo sed -i "$MOD_PACMAN_CONF" \
        -e '/^#\[multilib\]/!b;n;c#Include = \/etc\/pacman.d\/mirrorlist'

    sudo pacman -Sy
}


source "$LAD_OS_DIR/common/feature_footer.sh"
