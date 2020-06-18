#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly SYMLINK_TLP_SVC="/etc/systemd/system/multi-user.target.wants/tlp.service"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="System Services"
readonly FEATURE_DESC="Enable system services"
readonly PROVIDES=()
readonly NEW_FILES=("$SYMLINK_TLP_SVC")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=("tlp")



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

function install() {
    qecho "Enabling tlp.service..."
    sudo systemctl enable ${SYSTEMD_FLAGS} tlp.service
}


source "$LAD_OS_DIR/common/feature_footer.sh"
