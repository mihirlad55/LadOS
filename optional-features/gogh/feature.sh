#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Gogh"
readonly FEATURE_DESC="Install gnome-terminal gogh theme"
readonly PROVIDES=()
readonly NEW_FILES=()
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(gnome-terminal)

readonly URL="https://git.io/vQgMr"



function check_install() {
    # TODO: not really using this feature right now. Need to fill this in later
    # and figure it out
    :;
}

function install() {
    source <(wget -qO- "$URL")
}


source "$LAD_OS_DIR/common/feature_footer.sh"
