#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly DESKTOP_FILES_DIR="$BASE_DIR/power-desktop-files/"
readonly INSTALL_DIR="/usr/share/applications"
readonly BASE_HIBERNATE_DESKTOP="$DESKTOP_FILES_DIR/hibernate.desktop"
readonly BASE_LOCK_DESKTOP="$DESKTOP_FILES_DIR/lock.desktop"
readonly BASE_LOGOUT_DESKTOP="$DESKTOP_FILES_DIR/logout.desktop"
readonly BASE_REBOOT_DESKTOP="$DESKTOP_FILES_DIR/reboot.desktop"
readonly BASE_POWEROFF_DESKTOP="$DESKTOP_FILES_DIR/poweroff.desktop"
readonly NEW_HIBERNATE_DESKTOP="$INSTALL_DIR/hibernate.desktop"
readonly NEW_LOCK_DESKTOP="$INSTALL_DIR/lock.desktop"
readonly NEW_LOGOUT_DESKTOP="$INSTALL_DIR/logout.desktop"
readonly NEW_REBOOT_DESKTOP="$INSTALL_DIR/reboot.desktop"
readonly NEW_POWEROFF_DESKTOP="$INSTALL_DIR/poweroff.desktop"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="power-desktop-files"
readonly FEATURE_DESC="Install lock, hibernate, logout, reboot, and poweroff desktop files"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$BASE_HIBERNATE_DESKTOP" \
    "$BASE_LOCK_DESKTOP" \
    "$BASE_LOGOUT_DESKTOP" \
    "$BASE_REBOOT_DESKTOP" \
    "$BASE_POWEROFF_DESKTOP" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(xdg-utils)



function check_install() {
    if diff "$BASE_HIBERNATE_DESKTOP" "$NEW_HIBERNATE_DESKTOP" &&
        diff "$BASE_LOCK_DESKTOP" "$NEW_LOCK_DESKTOP" &&
        diff "$BASE_LOGOUT_DESKTOP" "$NEW_LOGOUT_DESKTOP" &&
        diff "$BASE_REBOOT_DESKTOP" "$NEW_REBOOT_DESKTOP" &&
        diff "$BASE_POWEROFF_DESKTOP" "$NEW_POWEROFF_DESKTOP"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying files..."
    sudo install -Dm 644 "$BASE_HIBERNATE_DESKTOP" "$NEW_HIBERNATE_DESKTOP"
    sudo install -Dm 644 "$BASE_LOCK_DESKTOP" "$NEW_LOCK_DESKTOP"
    sudo install -Dm 644 "$BASE_LOGOUT_DESKTOP" "$NEW_LOGOUT_DESKTOP"
    sudo install -Dm 644 "$BASE_REBOOT_DESKTOP" "$NEW_REBOOT_DESKTOP"
    sudo install -Dm 644 "$BASE_POWEROFF_DESKTOP" "$NEW_POWEROFF_DESKTOP"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
