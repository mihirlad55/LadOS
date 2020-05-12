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
        echo "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi
}

function install() {
    echo "Copying physlock.service..."
    sudo install -Dm 644 $BASE_DIR/physlock.service /etc/systemd/system/physlock.service
}

function post_install() {
    echo "Enabling physlock.service..."
    sudo systemctl enable --now physlock.service
    echo "Enabled physlock.service"
}

source "$LAD_OS_DIR/common/feature_common.sh"
