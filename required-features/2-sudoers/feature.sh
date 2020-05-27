#!/usr/bin/bash


BASE_DIR="$( readlink -f "$(dirname "$0")" )"
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="Custom Sudoers Configuration"
feature_desc="Custom sudoers configuration to allow %wheel to use sudo, make neovim default editor, make /bin/udevadm not require password, and make restarting the network card not require password."

new_files=("/etc/sudoers.d/10-sudoers-custom")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=("sudo")


function check_install() {
    qecho "Checking 10-sudoers-custom..."
    if sudo diff "$BASE_DIR/10-sudoers-custom" "/etc/sudoers.d/10-sudoers-custom"; then
        qecho "$feature_name installed successfully"
        return 0
    fi

    echo "$feature_name is not installed" >&2
    return 1
}

function install() {
    sudo install -Dm 644 "$BASE_DIR/10-sudoers-custom" \
        /etc/sudoers.d/10-sudoers-custom
}

function uninstall() {
    qecho "Removing ${new_files[*]}..."
    rm -f "${new_files[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
