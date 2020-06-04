#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly TMP_YAY_DIR="/tmp/yay"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="YAY AUR Helper"
readonly FEATURE_DESC="Install YAY AUR helper"
readonly PROVIDES=("yay")
readonly NEW_FILES=()
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_YAY_DIR")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(base-devel git wget yajl)

readonly YAY_URL="https://aur.archlinux.org/yay.git"



function check_install() {
    if command -v yay > /dev/null; then
        qecho "Yay installed"
        return 0
    else
        echo "Yay not installed" >&2
        return 1
    fi
}

function prepare() {
    if [[ ! -d "$TMP_YAY_DIR" ]]; then
        qecho "Cloning yay..."
        git clone "${GIT_FLAGS[@]}" "$YAY_URL" /tmp/yay
    fi
}

function install() {
    # Make package
    qecho "Making yay..."
    (cd "$TMP_YAY_DIR" && makepkg -si --noconfirm --noprogressbar --nocolor)
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    rm -rf "${TEMP_FILES[@]}"
}

function uninstall() {
    sudo pacman -Rsu "${PROVIDES[@]}" --noconfirm
}


source "$LAD_OS_DIR/common/feature_footer.sh"
