#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly TMP_DOOM_DIR="/tmp/doom-emacs"
readonly NEW_DOOM_DIR="$HOME/.emacs.d"
readonly NEW_DOOM_SH="$NEW_DOOM_DIR/doom"
 
source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Doom Emacs"
readonly FEATURE_DESC="Install doom emacs"
readonly PROVIDES=()
readonly NEW_FILES=("$NEW_DOOM_DIR")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_DOOM_DIR")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(emacs)

DOOM_EMACS_URL="https://github.com/hlissner/doom-emacs"



function check_install() {
    if "$NEW_DOOM_SH" sync; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    if [[ ! -d "$TMP_DOOM_DIR" ]]; then
        qecho "Cloning doom emacs..."
        git clone "${GIT_FLAGS[@]}" "$DOOM_EMACS_URL" "$TMP_DOOM_DIR"
    fi
    (shopt -s dotglob && cp -rf "$TMP_DOOM_DIR"/* "$NEW_DOOM_DIR")

    qecho "Installing doom emacs"
    "$NEW_DOOM_SH" -y install

    qecho "Syncing doom emacs"
    "$NEW_DOOM_SH" -y sync

    qecho "Done installing doom emacs"
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    rm -rf "${TEMP_FILES[@]}"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
