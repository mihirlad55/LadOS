#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

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
    if [[ ! -d "/tmp/dwm" ]]; then
        qecho "Cloning dwm..."
        git clone --depth 1 $VERBOSITY_FLAG https://github.com/mihirlad55/dwm /tmp/dwm
    fi
}

function install() {
    qecho "Making dwm..."
    (cd /tmp/dwm && sudo make clean install)
}

function post_install() {
    qecho "Enabling lightdm..."
    sudo systemctl enable -f ${SYSTEMD_FLAGS[*]} lightdm

    sudo systemctl set-default ${SYSTEMD_FLAGS[*]} graphical.target
}

function cleanup() {
    qecho "Removing /tmp/dwm..."
    rm -rf /tmp/dwm
}

function uninstall() {
    qecho "Removing dwm..."
    sudo rm -f "${new_files[@]}"
}

source "$LAD_OS_DIR/common/feature_footer.sh"

