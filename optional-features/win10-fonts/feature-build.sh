#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/win10-fonts"

REPO_PATH="$HOME/.cache/yay"
TEMP_PATH="/tmp/ttf-ms-win10"

feature_name="win10-fonts"
feature_desc="Install windows 10 fonts (by making)"

provides=(ttf-ms-win10)
new_files=()
modified_files=()
temp_files=("$REPO_PATH/ttf-ms-win10" \
    "/tmp/win10-fonts.zip" \
    "$TEMP_PATH")

depends_aur=()
depends_pacman=()
depends_pip3=()


function check_install() {
    if pacman -Q ttf-ms-win10 > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi

}

function check_conf() {
    if [[ -d "$CONF_DIR" ]] && [[ "$(ls $CONF_DIR)" != "" ]]; then
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
    qecho "Copying fonts to $REPO_PATH/ttf-ms-win10..."
    mkdir -p "$REPO_PATH/ttf-ms-win10"
    cp -rf $CONF_DIR/* $REPO_PATH/ttf-ms-win10/
}

function prepare() {
    # Copy hidden files
    shopt -s dotglob nullglob

    mkdir -p "$REPO_PATH/ttf-ms-win10"

    qecho "Cloning ttf-ms-win10 package..."
    git clone https://aur.archlinux.org/ttf-ms-win10.git $TEMP_PATH

    mv -f $TEMP_PATH/* $REPO_PATH/ttf-ms-win10/

    if ! check_conf; then
        echo "Enter url to windows 10 fonts zip file if available, otherwise leave blank"
        read url

        if [[ "$url" != "" ]]; then
            curl $url --output /tmp/win10-fonts.zip
            unzip -o /tmp/win10-fonts.zip -d $REPO_PATH/ttf-ms-win10
        else
            echo "No url provided" >&2
            exit 1
        fi
    fi

    qecho "Making package..."
    (cd $REPO_PATH/ttf-ms-win10 && makepkg --skipinteg)
}

function install() {
    qecho "Installing package..."
    (cd $REPO_PATH/ttf-ms-win10 && makepkg -si)
}

function cleanup() {
    qecho "Removing ${temp_files[@]}..."
    rm -rf ${temp_files[@]}
}


source "$LAD_OS_DIR/common/feature_common.sh"
