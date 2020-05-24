#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="Configure Corsair"
feature_desc="Install custom corsair configuration for Xorg"

provides=()
new_files=("/etc/X11/xorg.conf.d/30-corsair.conf")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(xorg-server)


function check_install() {
    if diff $BASE_DIR/30-corsair.conf \
        /etc/X11/xorg.conf.d/30-corsair.conf > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Installing custom corsair configuration for X11..."
    sudo install -Dm 644 $BASE_DIR/30-corsair.conf /etc/X11/xorg.conf.d/30-corsair.conf
}

function uninstall() {
    qecho "Removing ${new_files[@]}..."
    rm -f "${new_files[@]}"
}

source "$LAD_OS_DIR/common/feature_footer.sh"
