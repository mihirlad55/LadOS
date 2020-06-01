#!/usr/bin/bash

export DISPLAY=:0
readonly status="$2"

function notify() {
    local summary body urgency uid
    summary="WPA Supplicant"
    body="$1"
    uid="$2"
    username="$3"
    urgency="${4:-normal}"

    echo "$body"

    sudo -u "$username" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        notify-send "$summary" "$body" -u "$urgency" -i "$ICON_PATH"
}



while IFS=$' ' read -r uid username <&3; do {
    case "$status" in
        CONNECTED)
            notify "Connection established" "$uid" "$username" 
            ;;
        DISCONNECTED)
            notify "Connection lost" "$uid" "$username" critical
        ;;
    esac
} 3<&-
done 3< <(loginctl list-users | tail -n+2 | head -n+1)
