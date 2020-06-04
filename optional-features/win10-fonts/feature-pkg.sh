#!/usr/bin/bash

source "$LAD_OS_DIR/common/feature_header.sh"

FEATURE_NAME="Windows 10 TTF Fonts (pkg)"
FEATURE_DESC="Install windows 10 fonts (using localrepo)"
PROVIDES=(ttf-ms-win10)
NEW_FILES=()
MODIFIED_FILES=()
TEMP_FILES=()
DEPENDS_AUR=()
DEPENDS_PACMAN=()
DEPENDS_PIP3=()



function check_install() {
    if pacman -Q ttf-ms-win10 > /dev/null; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed"
        return 1
    fi

}

function install() {
    qecho "Installing ttf-ms-win10..."
    sudo pacman -S "${PROVIDES[@]}" --noconfirm --needed
}

function uninstall() {
    qecho "Uninstalling ttf-ms-win10..."
    sudo pacman -Rsu --noconfirm "${PROVIDES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
