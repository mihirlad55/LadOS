#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/weather-polybar-module"

source "$LAD_OS_DIR/common/feature_header.sh"

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
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function check_conf() {
    if [[ -e "$KEY_PATH" ]] && [[ "$(cat "$KEY_PATH")" != "" ]]; then
        qecho "Configuration key found at $KEY_PATH"
        return 0
    else
        echo "No configuration found or not in correct format at $KEY_PATH" >&2
        return 1
    fi
}

function install() {
    if ! check_conf; then
        echo "No key file found in $CONF_DIR"
        read -p "Please enter the openweathermap key: " key

        KEY_PATH="/tmp/openweathermap.key"

        qecho "Copying key to $INSTALL_PATH"
        echo "$key" > "$KEY_PATH"
    fi

    qecho "Copying key to $INSTALL_PATH"
    command install -Dm 600 "$KEY_PATH" "$INSTALL_PATH"

    qecho "Done copying key"
}

function cleanup() {
    qecho "Removing ${temp_files[@]}..."
    rm -f ${temp_files[@]}
}

function uninstall() {
    qecho "Removing ${new_files[@]}..."
    rm -f "${new_files[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
