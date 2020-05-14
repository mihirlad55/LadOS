#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="powertop"
feature_desc="Install powertop and systemd service file"

provides=()
new_files=("/etc/systemd/system/powertop.service")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(powertop)


function check_install() {
    if diff $BASE_DIR/powertop.service /etc/systemd/system/powertop.service; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying powertop.service to /etc/systemd/system..."
    sudo install -Dm 644 $BASE_DIR/powertop.service /etc/systemd/system/powertop.service
}

function post_install() {
    qecho "Enabling powertop.service..."
    sudo systemctl enable ${SYSTEMD_FLAGS[*]} powertop.service
}


source "$LAD_OS_DIR/common/feature_common.sh"
