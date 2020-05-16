#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="physlock"
feature_desc="Install physlock and custom service file"

provides=()
new_files=("/etc/systemd/system/physlock.service")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(physlock)


function check_install() {
    if diff $BASE_DIR/physlock.service /etc/systemd/system/physlock.service; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying physlock.service..."
    sudo install -Dm 644 $BASE_DIR/physlock.service /etc/systemd/system/physlock.service
}

function post_install() {
    qecho "Enabling physlock.service..."
    sudo systemctl enable -f ${SYSTEMD_FLAGS[*]} physlock.service
}

function uninstall() {
    qecho "Removing ${new_files[@]}..."
    rm -f "${new_files[@]}"
}


source "$LAD_OS_DIR/common/feature_common.sh"
