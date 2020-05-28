#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_SVC="$BASE_DIR/powertop.service"
readonly NEW_SVC="/etc/systemd/system/powertop.service"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Powertop"
readonly FEATURE_DESC="Install powertop and systemd service file"
readonly PROVIDES=()
readonly NEW_FILES=("/etc/systemd/system/powertop.service")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(powertop)



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
    qecho "Copying $BASE_SVC to $NEW_SVC..."
    sudo install -Dm 644 "$BASE_SVC" "$NEW_SVC"
}

function post_install() {
    qecho "Enabling powertop.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" powertop.service
}

function uninstall() {
    qecho "Disabling powertop.service..."
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" powertop.service

    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
