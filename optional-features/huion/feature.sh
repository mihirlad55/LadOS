#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="Huion"
feature_desc="Install scripts, services, configuration to use Huion tablet more conveniently"


provides=()
new_files=("/etc/X11/xorg.conf.d/52-tablet.conf"
           "/etc/udev/rules.d/80-huion.rules"
           "/usr/local/bin/adjust-huion"
           "/usr/local/bin/setup-huion-post-X11.sh")
modified_files=()
temp_files=()

depends_aur=(digimend-kernel-drivers-dkms-git)
depends_pacman=(linux-headers at xf86-input-wacom)


function check_install() {
    for f in ${new_files[@]}; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function install() {
    sudo rmmod hid-kye
    sudo rmmod hid-uclogic
    sudo rmmod hid-huion

    sudo install -Dm 644 $BASE_DIR/52-tablet.conf /etc/X11/xorg.conf.d/52-tablet.conf
    sudo install -Dm 644 $BASE_DIR/80-huion.rules /etc/udev/rules.d/80-huion.rules
    sudo install -Dm 644 $BASE_DIR/adjust-huion /usr/local/bin/adjust-huion
    sudo install -Dm 644 $BASE_DIR/setup-huion-post-X11.sh /usr/local/bin/setup-huion-post-X11.sh
}

function post_install() {
    qecho "Enabling std..."
    sudo systemctl enable --now atd
}

source "$LAD_OS_DIR/common/feature_common.sh"
