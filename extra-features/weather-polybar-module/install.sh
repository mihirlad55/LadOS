#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
CONF_DIR="$(readlink -f "$BASE_DIR/../../conf/weather-polybar-module")"

KEY_PATH="$CONF_DIR/openweathermap.key"
INSTALL_PATH="$HOME/.apikeys/openweathermap.key"

if [[ -e "$KEY_PATH" ]]; then
    key="$(cat "$KEY_PATH")"

    if [[ "$key" != "" ]]; then
        echo "Found openweathermap key"
        echo "Copying key to $INSTALL_PATH"
        install -Dm 600 "$KEY_PATH" "$INSTALL_PATH"
        exit 0
    fi
fi

echo "No key file found in $CONF_DIR"
echo -n "Please enter the openweathermap key: "
read key

KEY_PATH="/tmp/openweathermap.key"

echo "Copying key to $INSTALL_PATH"
echo "$key" > "$KEY_PATH"
install -Dm 600 "$KEY_PATH" "$INSTALL_PATH"
rm "$KEY_PATH"

echo "Done copying key"
