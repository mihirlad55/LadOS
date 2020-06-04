#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_HOOK="$BASE_DIR/99-reload-polybar.hook"
readonly NEW_HOOK="/etc/pacman.d/hooks/99-reload-polybar.hook"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Polybar Pacman Hooks"
readonly FEATURE_DESC="Install polybar pacman hooks"
readonly PROVIDES=()
readonly NEW_FILES=("$NEW_HOOK")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()
readonly DEPENDS_PIP3=()



function check_install() {
    if [[ -f "$NEW_HOOK" ]]; then
        qecho "$FEATURE_NAME is installed"
        return 0
    fi

    echo "$FEATURE_NAME is not installed" >&2
    return 1
}

function install() {
    sudo install -Dm 644 "$BASE_HOOK" "$NEW_HOOK"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
