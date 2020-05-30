#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly TMP_DWM_DIR="/tmp/dwm"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="DWM"
readonly FEATURE_DESC="Install DWM (Dynamic Window Manager)"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "/usr/local/bin/dwm" \
    "/usr/local/bin/startdwm" \
    "/usr/share/xsessions/dwm.desktop" \
    "/usr/local/share/man/man1/dwm.1" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_DWM_DIR")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=( \
    lightdm \
    lightdm-gtk-greeter \
    xorg-server \
    xorg-server-common \
)

readonly DWM_URL="https://github.com/mihirlad55/dwm"



function check_install() {
    local f

    for f in "${NEW_FILES[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    qecho "$FEATURE_NAME is installed"
    return 0
}

function prepare() {
    if [[ ! -d "$TMP_DWM_DIR" ]]; then
        qecho "Cloning dwm..."
        git clone "${GIT_FLAGS[@]}" "$DWM_URL" "$TMP_DWM_DIR"
    fi
}

function install() {
    qecho "Making dwm..."
    (cd "$TMP_DWM_DIR" && sudo make clean install)
}

function post_install() {
    qecho "Enabling lightdm..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" lightdm.service

    sudo systemctl set-default "${SYSTEMD_FLAGS[@]}" graphical.target
}

function cleanup() {
    qecho "Removing $TMP_DWM_DIR..."
    rm -rf "$TMP_DWM_DIR"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
