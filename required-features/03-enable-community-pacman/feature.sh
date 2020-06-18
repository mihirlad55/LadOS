#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly MOD_PACMAN_CONF="/etc/pacman.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Enable Pacman Community Repo"
readonly FEATURE_DESC="Edit /etc/pacman.conf to enable pacman community repo"
readonly NEW_FILES=()
readonly MODIFIED_FILES=("$MOD_PACMAN_CONF")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()



function check_install() {
    local match

    # Check if community repo is uncommented
    match="$(awk '/^\[community\]/,/^Include/' "$MOD_PACMAN_CONF")"
    if [[ "$match" != "" ]]; then
        qecho "Community repo enabled!"
        return 0
    fi

    echo "Community repo not enabled" >&2
    return 1
}


function install() {
    # Uncomment community repo
    qecho "Editing $MOD_PACMAN_CONF"
    sudo sed -i "$MOD_PACMAN_CONF" -e "s/^#\[community\]$/\[community\]/" \
        -e '/\[community\]/!b;n;cInclude = \/etc\/pacman.d\/mirrorlist'
}

function uninstall() {
    # Comment out community repo
    qecho "Editing $MOD_PACMAN_CONF"
    sudo sed -i "$MOD_PACMAN_CONF" -e "s/^\[community\]$/#&/" \
        -e '/^#\[community\]/!b;n;c#Include = \/etc\/pacman.d\/mirrorlist'
}


source "$LAD_OS_DIR/common/feature_footer.sh"
