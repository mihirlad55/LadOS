#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_SERVICE="$BASE_DIR/auto-mirror-rank.service"
readonly BASE_UPDATE_SH="$BASE_DIR/update-pacman-mirrors"
readonly NEW_SERVICE="/etc/systemd/system/auto-mirror-rank.service"
readonly NEW_UPDATE_SH="/usr/local/bin/update-pacman-mirrors"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Auto Mirror Rank"
readonly FEATURE_DESC="Rank pacman mirrors on startup"
readonly CONFLICTS=()
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_SERVICE" \
    "$NEW_UPDATE_SH" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(pacman-contrib)
readonly DEPENDS_PIP3=()



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
    qecho "Copying $BASE_UPDATE_SH to $NEW_UPDATE_SH..."
    sudo install -Dm 755 "$BASE_UPDATE_SH" "$NEW_UPDATE_SH"

    qecho "Copying $BASE_SERVICE to $NEW_SERVICE..."
    sudo install -Dm 644 "$BASE_SERVICE" "$NEW_SERVICE"
}

function post_install() {
    qecho "Enabling auto-mirror-rank.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" auto-mirror-rank.service
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
