#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"
readonly TMP_ST_DIR="/tmp/st"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="st"
readonly FEATURE_DESC="Install st (Simple Terminal)"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "/usr/local/bin/st" \
    "/usr/local/share/applications/st.desktop" \
    "/usr/local/share/man/man1/st.1" \
)
readonly MODIFIED_FILES=("/usr/share/terminfo")
readonly TEMP_FILES=("$TMP_ST_DIR")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()

readonly ST_URL="https://github.com/mihirlad55/st"



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

function prepare() {
    if [[ ! -d "$TMP_ST_DIR" ]]; then
        qecho "Cloning st..."
        git clone "${GIT_FLAGS[@]}" "$ST_URL" "$TMP_ST_DIR"
    fi
}

function install() {
    qecho "Making st..."
    (cd "$TMP_ST_DIR" && sudo make clean install)
}

function cleanup() {
    qecho "Removing $TMP_ST_DIR..."
    rm -rf "$TMP_ST_DIR"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
