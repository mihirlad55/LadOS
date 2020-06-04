#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly SUDOERS_DIR="/etc/sudoers.d"
readonly NEW_SUDOERS_CONF="$SUDOERS_DIR/10-sudoers-custom"
readonly BASE_SUDOERS_CONF="$BASE_DIR/10-sudoers-custom"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Custom Sudoers Configuration"
readonly FEATURE_DESC="Custom sudoers configuration to allow %wheel to use \
sudo, make neovim default editor, make /bin/udevadm not require password, and \
make restarting the network card not require password."
readonly NEW_FILES=("$NEW_SUDOERS_CONF")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=("sudo" "diffutils")


function check_install() {
    qecho "Checking 10-sudoers-custom..."
    if sudo diff "$BASE_SUDOERS_CONF" "$NEW_SUDOERS_CONF"; then
        qecho "$FEATURE_NAME installed successfully"
        return 0
    fi

    echo "$FEATURE_NAME is not installed" >&2
    return 1
}

function install() {
    sudo install -Dm 644 "$BASE_SUDOERS_CONF" "$NEW_SUDOERS_CONF"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
