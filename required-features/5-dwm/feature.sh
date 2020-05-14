#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="DWM"
feature_desc="Install DWM (Dynamic Window Manager)"

provides=()
new_files=("/usr/local/bin/dwm" \
            "/usr/local/bin/startdwm" \
            "/usr/share/xsessions/dwm.desktop" \
            "/usr/local/share/man/man1/dwm.1")
modified_files=()
temp_files=("/tmp/dwm")

depends_aur=()
depends_pacman=(lightdm lightdm-gtk-greeter xorg-server xorg-server-common)


function check_install() {
    for f in ${new_files[@]}; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function prepare() {
    qecho "Cloning dwm..."
    git clone $VERBOSITY_FLAG https://github.com/mihirlad55/dwm /tmp/dwm
}

function install() {
    qecho "Making dwm..."
    (cd /tmp/dwm && sudo make clean install &> "$DEFAULT_OUT")
}

function post_install() {
    qecho "Enabling lightdm..."
    sudo systemctl enable ${SYSTEMD_FLAGS[*]} lightdm

    sudo systemctl set-default ${SYSTEMD_FLAGS[*]} graphical.target
}

function cleanup() {
    qecho "Removing /tmp/dwm..."
    rm -rf /tmp/dwm
}

source "$LAD_OS_DIR/common/feature_common.sh"


