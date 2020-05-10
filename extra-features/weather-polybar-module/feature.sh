#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/weather-polybar-module"

KEY_PATH="$CONF_DIR/openweathermap.key"
INSTALL_PATH="$HOME/.apikeys/openweathermap.key"

feature_name="weather-polybar-module"
feature_desc="Install OpenWeatherMap API Key for polybar weather module"

provides=()
new_files=("$HOME/.apikeys/openweathermap.key")
modified_files=()
temp_files=("/tmp/openweathermap.key")

depends_aur=()
depends_pacman=()
depends_pip3=()


function check_install() {
    if [[ "$(cat "$HOME/.apikeys/openweathermap.key")" != "" ]]; then
        echo "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi
}

function check_defaults() {
    if [[ -e "$KEY_PATH" ]] && [[ "$(cat "$KEY_PATH")" != "" ]]; then
        echo "Default key found at $KEY_PATH"
        return 0
    else
        echo "No default found or not in correct format at $KEY_PATH"
        return 1
    fi
}

function install() {
    if ! check_defaults; then
        echo "No key file found in $CONF_DIR"
        echo -n "Please enter the openweathermap key: "
        read key

        KEY_PATH="/tmp/openweathermap.key"

        echo "Copying key to $INSTALL_PATH"
        echo "$key" > "$KEY_PATH"
    fi

    echo "Copying key to $INSTALL_PATH"
    command install -Dm 600 "$KEY_PATH" "$INSTALL_PATH"

    echo "Done copying key"
}

function cleanup() {
    echo "Removing ${temp_files[@]}..."
    rm -f ${temp_files[@]}
    echo "Removed ${temp_files[@]}"
}

source "$LAD_OS_DIR/common/feature_common.sh"
