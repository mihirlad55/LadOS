#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_VIFMRUN_SH="$BASE_DIR/vifmrun"
readonly BASE_VIFMIMG_SH="$BASE_DIR/vifmimg"
readonly NEW_VIFMRUN_SH="/usr/local/bin/vifmrun"
readonly NEW_VIFMIMG_SH="$HOME/.vifm/scripts/vifmimg"
readonly MOD_VIFM_DESKTOP="/usr/share/applications/vifm.desktop"
readonly TMP_EPUB_THUMBNAILER_DIR="/tmp/epub-thumbnailer"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="vifm"
readonly FEATURE_DESC="Install vifm with image previews"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_VIFMIMG_SH" \
    "$NEW_VIFMRUN_SH" \
)
readonly MODIFIED_FILES=("$MOD_VIFM_DESKTOP")
readonly TEMP_FILES=("$TMP_EPUB_THUMBNAILER_DIR")
readonly DEPENDS_AUR=(fontpreview)
readonly DEPENDS_PACMAN=( \
    ffmpeg \
    ffmpegthumbnailer \
    vifm \
    python \
    python-pip \
    poppler \
)
readonly DEPENDS_PIP3=()

readonly EPUB_THUMBNAILER_URL="https://github.com/marianosimone/epub-thumbnailer"



function check_install() {
    if command -v epub-thumbnailer &> /dev/null &&
        [[ -f "$NEW_VIFMRUN_SH" ]] &&
        [[ -f "$NEW_VIFMIMG_SH" ]] &&
        grep -q -P "$MOD_VIFM_DESKTOP" -e "Exec=vifmrun\b"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    if [[ ! -d "$TMP_EPUB_THUMBNAILER_DIR" ]]; then
        qecho "Cloning epub-thumbnailer..."
        git clone "${GIT_FLAGS[@]}" "$EPUB_THUMBNAILER_URL" \
            "$TMP_EPUB_THUMBNAILER_DIR"
    fi

    qecho "Installing epub-thumbnailer..."
    # Returns 1 if can't find desktop environment
    sudo python "$TMP_EPUB_THUMBNAILER_DIR/install.py" install || true

    qecho "Installing vifmimg and vifmrun..."
    sudo install -Dm 755 "$BASE_VIFMRUN_SH" "$NEW_VIFMRUN_SH"
    command install -Dm 755 "$BASE_VIFMIMG_SH" "$NEW_VIFMIMG_SH"

    qecho "Updating vifm.desktop..."
    sudo sed -i 's/Exec=vifm\b/Exec=vifmrun/' "$MOD_VIFM_DESKTOP"
}

function cleanup() {
    qecho "Removing /tmp/epub-thumbnailer..."
    rm -rf /tmp/epub-thumbnailer
}

function uninstall() {
    if [[ ! -d "$TMP_EPUB_THUMBNAILER_DIR" ]]; then
        qecho "Cloning epub-thumbnailer..."
        git clone "${GIT_FLAGS[@]}" "$EPUB_THUMBNAILER_URL" \
            "$TMP_EPUB_THUMBNAILER_DIR"
    fi

    qecho "Uninstalling epub-thumbnailer..."
    sudo python "$TMP_EPUB_THUMBNAILER_DIR/install.py" uninstall
    sudo rm -rf "$TMP_EPUB_THUMBNAILER_DIR"

    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"

    qecho "Reverting vifm.desktop..."
    sudo sed -i 's/Exec=vifmrun\b/Exec=vifm/' "$MOD_VIFM_DESKTOP"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
