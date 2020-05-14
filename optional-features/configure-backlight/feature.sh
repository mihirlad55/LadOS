#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="Configure Backlight"
feature_desc="Install custom backlight configuration for Xorg"

provides=()
new_files=("/etc/X11/xorg.conf.d/30-backlight.conf")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(xorg-server)


function check_install() {
    if diff $BASE_DIR/30-backlight.conf \
        /etc/X11/xorg.conf.d/30-backlight.conf > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Installing custom backlight configuration for X11..."
    sudo install -Dm 644 $BASE_DIR/30-backlight.conf /etc/X11/xorg.conf.d/30-backlight.conf
}

source "$LAD_OS_DIR/common/feature_common.sh"


