#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="steam"
feature_desc="Install steam with multilib repo"

provides=(steam)
new_files=("/etc/ld.so.conf.d/steam.conf")
modified_files=("/etc/pacman.conf")
temp_files=()

depends_aur=()
depends_pacman=()


function check_install() {
    if [[ "$(awk '/^\[multilib\]/,/^Include/' /etc/pacman.conf)" != "" ]] &&
        diff $BASE_DIR/steam.conf /etc/ld.so.conf.d/steam.conf; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Enabling multilib repo..."
    sudo sed -i 's/#*\[multilib\]/\[multilib\]/' /etc/pacman.conf
    sudo sed -i '/\[multilib\]/!b;n;cInclude = \/etc\/pacman.d\/mirrorlist' /etc/pacman.conf

    qecho "Updating database..."
    sudo pacman -Sy &> "$DEFAULT_OUT"

    qecho "Installing Steam..."

    sudo pacman -S steam --needed --noconfirm &> "$DEFAULT_OUT"

    qecho "Configuring library paths for steam..."
    sudo install -Dm 644 $BASE_DIR/steam.conf /etc/ld.so.conf.d/steam.conf
    sudo ldconfig

    qecho "DONE!"
}


source "$LAD_OS_DIR/common/feature_common.sh"
