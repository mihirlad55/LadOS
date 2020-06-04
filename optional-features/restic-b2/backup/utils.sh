#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
readonly ICON_PATH="$BASE_DIR/b2.png"

source "$BASE_DIR/constants.sh"

readonly NOTIFY_UID="$(id -u "$NOTIFY_USER")"

function notify() {
    local summary body urgency
    summary="Restic B2 Backup"
    body="$1"
    urgency="${2:-normal}"

    echo "$body"

    sudo -u "$NOTIFY_USER" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$NOTIFY_UID/bus" \
        notify-send "$summary" "$body" -u normal -i "$ICON_PATH"
}
