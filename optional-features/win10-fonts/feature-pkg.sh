#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="win10-fonts"
feature_desc="Install windows 10 fonts (using localrepo)"

provides=(ttf-ms-win10)
new_files=()
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=()
depends_pip3=()


function check_install() {
    if pacman -Q ttf-ms-win10 > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi

}

function install() {
    sudo pacman -S $provides --noconfirm --needed
}

function uninstall() {
    qecho "Uninstalling ttf-ms-win10..."
    sudo pacman -Rsu --noconfirm "${provides[@]}"
}


source "$LAD_OS_DIR/common/feature_common.sh"
