#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="Yay AUR Helper"
feature_desc="Install yay AUR helper"

provides=("yay" "package-query")
new_files=()
modified_files=()
temp_files=("/tmp/yay" "/tmp/package-query")

depends_aur=()
depends_pacman=(base-devel git wget yajl)


function check_install() {
    if command -v yay > /dev/null; then
        echo "Yay installed."
        exit 0
    fi
}

function prepare() {
    # Clone package-query
    echo "Cloning package-query..."
    git clone https://aur.archlinux.org/package-query.git /tmp/package-query

    # Make package
    echo "Making package package-query..."
    (cd /tmp/package-query && makepkg -si --noconfirm)

    # Clone yay
    echo "Cloning yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
}

function install() {
    # Make package
    echo "Making yay..."
    (cd /tmp/yay && makepkg -si --noconfirm)
}

function cleanup() {
    echo "Removing /tmp/yay and /tmp/package-query..."
    rm -dRf ${temp_files[@]}
    echo "Done removing /tmp/yay and /tmp/package-query"
}

source "$LAD_OS_DIR/common/feature_common.sh"
