#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="Yay AUR Helper"
feature_desc="Install yay AUR helper"

provides=("yay")
new_files=()
modified_files=()
temp_files=("/tmp/yay")

depends_aur=()
depends_pacman=(base-devel git wget yajl)


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
    # Clone yay
    qecho "Cloning yay..."
    git clone $VERBOSITY_FLAG https://aur.archlinux.org/yay.git /tmp/yay
}

function install() {
    # Make package
    qecho "Making yay..."
    # Some non-error output goes to stderr
    (cd /tmp/yay && makepkg -si --noconfirm --noprogressbar &> "$DEFAULT_OUT")
}

function cleanup() {
    qecho "Removing /tmp/yay and /tmp/package-query..."
    rm -dRf ${temp_files[@]}
}

source "$LAD_OS_DIR/common/feature_common.sh"
