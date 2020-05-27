#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="Enable Pacman Community Repo"
feature_desc="Edit /etc/pacman.conf to enable pacman community repo"

new_files=()
modified_files=("/etc/pacman.conf")

depends_aur=()
depends_pacman=()


function check_install() {
    if [[ "$(awk '/^\[community\]/,/^Include/' /etc/pacman.conf)" != "" ]]; then
        qecho "Community repo enabled!"
        return 0
    fi

    echo "Community repo not enabled" >&2
    return 1
}


function install() {
    qecho "Editing /etc/pacman.conf"
    sudo sed -i /etc/pacman.conf \
        -e "s/^#\[community\]$/\[community\]/"
    sudo sed -i /etc/pacman.conf \
        -e '/\[community\]/!b;n;cInclude = \/etc\/pacman.d\/mirrorlist'
}

function uninstall() {
    qecho "Editing /etc/pacman.conf"
    sudo sed -i /etc/pacman.conf -e "s/^\[community\]$/#&/"
    sudo sed -i /etc/pacman.conf \
        -e '/^#\[community\]/!b;n;c#Include = \/etc\/pacman.d\/mirrorlist'
}


source "$LAD_OS_DIR/common/feature_footer.sh"
