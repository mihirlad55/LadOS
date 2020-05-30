#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_SVC="$BASE_DIR/physlock.service"
readonly NEW_SVC="/etc/systemd/system/physlock.service"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Physlock service"
readonly FEATURE_DESC="Install physlock and custom service file"
readonly PROVIDES=()
readonly NEW_FILES=("$NEW_SVC")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(physlock)



function check_install() {
    if diff "$BASE_SVC" "$NEW_SVC"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying from $BASE_SVC to $NEW_SVC..."
    sudo install -Dm 644 "$BASE_SVC" "$NEW_SVC"
}

function post_install() {
    qecho "Enabling physlock.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" physlock.service
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
