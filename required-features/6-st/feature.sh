#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="st"
feature_desc="Install st (Simple Terminal)"

provides=()
new_files=("/usr/local/bin/st" \
    "/usr/share/applications/st.desktop" \
    "/usr/local/share/man/man1/st.1")
modified_files=("/usr/share/terminfo")
temp_files=("/tmp/st")

depends_aur=()
depends_pacman=()


function check_install() {
    for f in ${new_files[@]}; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" &>2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function prepare() {
    qecho "Cloning st..."
    git clone https://github.com/mihirlad55/st /tmp/st
}

function install() {
    qecho "Making st..."
    (cd /tmp/st && sudo make clean install)
}

function cleanup() {
    qecho "Removing /tmp/st..."
    rm -rf /tmp/st
}

source "$LAD_OS_DIR/common/feature_common.sh"


