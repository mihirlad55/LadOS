#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
DESKTOP_FILES_DIR="$BASE_DIR/power-desktop-files/"
INSTALL_DIR="/usr/share/applications"


feature_name="power-desktop-files"
feature_desc="Install lock, hibernate, logout, reboot, and poweroff desktop files"

provides=()
new_files=("$INSTALL_DIR/hibernate.desktop" \
    "$INSTALL_DIR/lock.desktop" \
    "$INSTALL_DIR/logout.desktop" \
    "$INSTALL_DIR/reboot.desktop" \
    "$INSTALL_DIR/poweroff.desktop")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(xdg-utils)


function check_install() {
    if diff "$DESKTOP_FILES_DIR/hibernate.desktop" "$INSTALL_DIR/hibernate.desktop" &&
        diff "$DESKTOP_FILES_DIR/lock.desktop" "$INSTALL_DIR/lock.desktop" &&
        diff "$DESKTOP_FILES_DIR/logout.desktop" "$INSTALL_DIR/logout.desktop" &&
        diff "$DESKTOP_FILES_DIR/reboot.desktop" "$INSTALL_DIR/reboot.desktop" &&
        diff "$DESKTOP_FILES_DIR/poweroff.desktop" "$INSTALL_DIR/poweroff.desktop"; then
        echo "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi
}

function install() {
    echo "Copying files..."
    sudo install -Dm 644 $DESKTOP_FILES_DIR/hibernate.desktop \
        $INSTALL_DIR/hibernate.desktop
    sudo install -Dm 644 $DESKTOP_FILES_DIR/lock.desktop \
        $INSTALL_DIR/lock.desktop
    sudo install -Dm 644 $DESKTOP_FILES_DIR/logout.desktop \
        $INSTALL_DIR/logout.desktop
    sudo install -Dm 644 $DESKTOP_FILES_DIR/reboot.desktop \
        $INSTALL_DIR/reboot.desktop
    sudo install -Dm 644 $DESKTOP_FILES_DIR/poweroff.desktop \
        $INSTALL_DIR/poweroff.desktop
}


source "$LAD_OS_DIR/common/feature_common.sh"
