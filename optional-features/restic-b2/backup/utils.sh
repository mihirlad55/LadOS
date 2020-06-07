#!/usr/bin/bash

# Exit on error to avoid complications
set -o errtrace
set -o pipefail
trap error_trap ERR

if [[ -z "$BASE_DIR" ]]; then
    # Get absolute path to directory of script
    readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
fi

readonly ICON_PATH="/tmp/b2.png"
source "$BASE_DIR/constants.sh"
readonly NOTIFY_UID="$(id -u "$NOTIFY_USER")"

# So it is accessible by user
cp -f "$BASE_DIR/b2.png" "$ICON_PATH"



function notify() {
    local summary body urgency args
    summary="Restic B2 Backup"
    body="$1"; shift
    args=("$@")

    echo -e "$body" >&2

    if loginctl list-users | grep -q "$NOTIFY_USER"; then
        sudo -u "$NOTIFY_USER" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$NOTIFY_UID/bus" \
            dunstify -i "$ICON_PATH" "${args[@]}" "$summary" "$body"
    else
        echo "Not sending notification to $NOTIFY_USER. User is not logged on."
    fi
}

function error_trap() {
    error_code="$?"
    last_command="$BASH_COMMAND"
    command_caller="$(caller)"
    
    msg="$command_caller: \"$last_command\" returned error code $error_code"

    echo "$msg" >&2
    notify "$msg" -u critical

    exit $error_code
}

function is_locked() {
    local locks

    locks="$(restic list locks -q --no-lock)"

    if [[ "$locks" == "" ]]; then
        return 1
    else
        return 0
    fi
}
