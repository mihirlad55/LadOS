#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/weather-polybar-module"
readonly INSTALL_DIR="$HOME/.apikeys"
readonly CONF_KEY_FILE="$CONF_DIR/openweathermap.key"
readonly NEW_KEY_FILE="$INSTALL_DIR/openweathermap.key"
readonly TMP_KEY_FILE="/tmp/openweathermap.key"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="weather-polybar-module"
readonly FEATURE_DESC="Install OpenWeatherMap API Key for polybar weather module"
readonly PROVIDES=()
readonly NEW_FILES=("$NEW_KEY_FILE")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_KEY_FILE")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()
readonly DEPENDS_PIP3=()



function check_install() {
    local key

    if [[ -f "$NEW_KEY_FILE" ]]; then
        key="$(cat "$NEW_KEY_FILE")"

        if [[ "$key" != "" ]]; then
            qecho "$FEATURE_NAME is installed"
            return 0
        fi
    fi

    echo "$FEATURE_NAME is not installed" >&2
    return 1
}

function check_conf() {
    local key
    if [[ -f "$CONF_KEY_FILE" ]]; then
        key="$(cat "$CONF_KEY_FILE")"

        if [[ "$key" != "" ]]; then
            qecho "Configuration key found at $CONF_KEY_FILE"
            return 0
        fi
    fi

    echo "No configuration found or not in correct format at $CONF_KEY_FILE" >&2
    return 1
}

function install() {
    local key

    if ! check_conf; then
        echo "No key file found in $CONF_DIR"
        read -rp "Please enter the openweathermap key: " key

        qecho "Writing key to $TMP_KEY_FILE..."
        echo "$key" > "$TMP_KEY_FILE"

        qecho "Copying $TMP_KEY_FILE to $NEW_KEY_FILE..."
        command install -Dm 600 "$TMP_KEY_FILE" "$NEW_KEY_FILE"
    else
        qecho "Copying $CONF_KEY_FILE to $NEW_KEY_FILE..."
        command install -Dm 600 "$CONF_KEY_FILE" "$NEW_KEY_FILE"
    fi

    qecho "Done copying key"
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    rm -f "${TEMP_FILES[@]}"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
