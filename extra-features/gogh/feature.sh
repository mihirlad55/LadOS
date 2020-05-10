#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="Gogh"
feature_desc="Install gnome-terminal gogh theme"

provides=()
new_files=()
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(gnome-terminal)


function check_install() {
    # TODO: not really using this feature right now. Need to fill this in later
    # and figure it out
}

function install() {
    source <(wget -qO- https://git.io/vQgMr)
}

source "$LAD_OS_DIR/common/feature_common.sh"
