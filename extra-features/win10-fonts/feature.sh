#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/win10-fonts"

REPO_PATH="$HOME/.cache/yay"

feature_name="win10-fonts"
feature_desc="Install windows 10 fonts"

provides=(ttf-ms-win10)
new_files=()
modified_files=()
temp_files=("$REPO_PATH/ttf-ms-win10" \
    "/tmp/win10-fonts.zip")

depends_aur=()
depends_pacman=()
depends_pip3=()


function check_install() {
    if pacman -Q ttf-ms-win10 > /dev/null; then
        echo "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi

}

function check_defaults() {
    if [[ -d "$CONF_DIR" ]] && [[ "$(ls $CONF_DIR)" != "" ]]; then
        echo "Found win10-fonts"
        echo "Defaults are set"
        return 0
    else
        echo "win10-fonts not found"
        echo "Defaults are not set"
        return 1
    fi
}

function load_defaults() {
    mkdir -p "$REPO_PATH/ttf-ms-win10"
    cp -rf $CONF_DIR/* $REPO_PATH/ttf-ms-win10/
}

function prepare() {
    mkdir -p "$REPO_PATH"

    git clone https://aur.archlinux.org/ttf-ms-win10.git $REPO_PATH/ttf-ms-win10
}

function install() {
    if ! check_defaults; then
        echo "Enter url to windows 10 fonts zip file if available, otherwise leave blank"
        read url

        if [[ "$url" != "" ]]; then
            curl $url --output /tmp/win10-fonts.zip
            unzip -o /tmp/win10-fonts.zip -d $REPO_PATH/ttf-ms-win10
        else
            echo "No url provided"
            exit 1
        fi
    fi

    yay -S --mflags --skipinteg --needed --noconfirm ttf-ms-win10
}

function cleanup() {
    echo "Removing ${temp_files[@]}..."
    rm -rf ${temp_files[@]}
    echo "Removed ${temp_files[@]}"
}


source "$LAD_OS_DIR/common/feature_common.sh"
