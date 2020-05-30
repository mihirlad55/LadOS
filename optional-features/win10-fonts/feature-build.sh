#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/win10-fonts"
readonly CACHE_DIR="$HOME/.cache/yay"
readonly BASE_FILES_TXT="$BASE_DIR/files.txt"
readonly TMP_FONTS_DIR="/tmp/ttf-ms-win10"
readonly TMP_FONTS_ZIP="/tmp/win10-fonts.zip"
readonly TMP_PKG_DIR="$CACHE_DIR/ttf-ms-win10"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Windows 10 TTF Fonts (make)"
readonly FEATURE_DESC="Install windows 10 fonts (by making)"
readonly PROVIDES=(ttf-ms-win10)
readonly NEW_FILES=()
readonly MODIFIED_FILES=()
readonly TEMP_FILES=( \
    "$TMP_PKG_DIR" \
    "$TMP_FONTS_DIR" \
    "$TMP_FONTS_DIR" \
)
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()
readonly DEPENDS_PIP3=()

readonly TTF_MS_WIN10_URL="https://aur.archlinux.org/ttf-ms-win10.git"



function check_install() {
    if pacman -Q ttf-ms-win10 > /dev/null; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function check_conf() {
    if [[ -d "$CONF_DIR" ]] && diff "$BASE_FILES_TXT" <(ls "$CONF_DIR"); then
        qecho "Found win10-fonts"
        qecho "Configuration is set"
        return 0
    else
        echo "win10-fonts not found" >&2
        echo "Configuration is not set" >&2
        return 1
    fi
}

function load_conf() {
    qecho "Copying fonts to $TMP_FONTS_DIR..."
    mkdir -p "$TMP_FONTS_DIR"
    cp -rf "$CONF_DIR"/* "$TMP_FONTS_DIR"
}

function prepare() {
    local url

    if [[ ! -d "$TMP_PKG_DIR" ]]; then
        qecho "Cloning ttf-ms-win10 package..."
        git clone "${GIT_FLAGS[@]}" "$TTF_MS_WIN10_URL" "$TMP_PKG_DIR"
    fi

    if ! check_conf; then
        read -rp "Enter url to windows 10 fonts zip file: " url

        if [[ "$url" != "" ]]; then
            qecho "Downloading windows 10 fonts zip..."
            curl "${S_FLAG[@]}" "$url" --output "$TMP_FONTS_ZIP"
            qecho "Unzipping windows 10 fonts..."
            unzip -o "$TMP_FONTS_ZIP" -d "$TMP_FONTS_DIR"
        else
            echo "No url provided" >&2
            exit 1
        fi
    fi

    qecho "Copying fonts from $TMP_FONTS_DIR to $TMP_PKG_DIR..."
    (shopt -s dotglob && cp -rf "$TMP_FONTS_DIR"/* "$TMP_PKG_DIR")


    qecho "Making package..."
    (cd "$TMP_PKG_DIR" && makepkg --skipinteg --noconfirm)
}

function install() {
    qecho "Installing package..."
    (cd "$TMP_PKG_DIR" && makepkg -si --noconfirm)
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    rm -rf "${TEMP_FILES[@]}"
}

function uninstall() {
    qecho "Uninstalling ttf-ms-win10..."
    sudo pacman -Rsu --noconfirm "${PROVIDES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
