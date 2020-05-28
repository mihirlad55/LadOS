#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/wpa-supplicant"
readonly CONF_NETWORK_CONF="$CONF_DIR/network.conf"
readonly NEW_WPA_SUPPLICANT_DIR="/etc/wpa_supplicant"
readonly TMP_WPA_SUPPLICANT_CONF="/tmp/wpa_supplicant.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="WPA Supplicant"
readonly FEATURE_DESC="Install wpa_supplicant with existing configuration"
readonly PROVIDES=()
readonly NEW_FILES=("$NEW_WPA_SUPPLICANT_DIR")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_NETWORK_CONF")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(wpa_supplicant dhcpcd)
readonly DEPENDS_PIP3=()



function check_install() {
    if pacman -Q wpa_supplicant > /dev/null &&
        pacman -Q dhcpcd > /dev/null &&
        test -f "$NEW_WPA_SUPPLICANT_DIR"/wpa_supplicant-*.conf; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function check_conf() {
    local conf

    if [[ -f "$CONF_NETWORK_CONF" ]]; then
        conf="$(cat "$CONF_NETWORK_CONF")"

        if [[ "$conf" != "" ]]; then
            qecho "Configuration found at $CONF_NETWORK_CONF"
            return 0
        fi
    fi

    echo "No configuration found at $CONF_NETWORK_CONF" >&2
    return 1
}

function prepare() {
    ip link
    echo "Note that the name of this card may change when you boot the system"
    read -rp "Enter name of network card: " card

    echo "ctrl_interface=/run/wpa_supplicant" > "$TMP_WPA_SUPPLICANT_CONF"
    echo "update_config=1" >> "$TMP_WPA_SUPPLICANT_CONF"

    if check_conf; then
        cat "$CONF_NETWORK_CONF" >> "$TMP_WPA_SUPPLICANT_CONF"
    fi

    echo "Opening wpa_supplicant file..."
    read -rp "Press enter to continue..."
    if [[ "$EDITOR" != "" ]]; then
        "$EDITOR" "$TMP_WPA_SUPPLICANT_CONF"
    else
        vim "$TMP_WPA_SUPPLICANT_CONF"
    fi
}

function install() {
    local name new_wpa_supplicant_conf

    name="wpa_supplicant-${card}.conf"
    new_wpa_supplicant_conf="$NEW_WPA_SUPPLICANT_DIR/$name"
    qecho "Copying "$TMP_WPA_SUPPLICANT_CONF" to $new_wpa_supplicant_conf..."
    sudo install -Dm 600 "$TMP_WPA_SUPPLICANT_CONF" "$new_wpa_supplicant_conf"
}

function post_install() {
    local service

    service="wpa_supplicant@${card}.service"

    qecho "Enabling $service and dhcpcd.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" "$service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" dhcpcd.service
    qecho "Enabled $service and dhcpcd.service"
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    rm -rf "${TEMP_FILES[@]}"
}

function uninstall() {
    local card service name new_wpa_supplicant_conf

    ip link
    read -rp "Enter name of network card: " card

    service="wpa_supplicant@${card}.service"
    name="wpa_supplicant-${card}.conf"
    new_wpa_supplicant_conf="$NEW_WPA_SUPPLICANT_DIR/$name"

    qecho "Disabling $service and dhcpcd.service..."
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" "$service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" dhcpcd.service

    qecho "Removing $new_wpa_supplicant_conf..." 
    sudo rm -rf "$new_wpa_supplicant_conf"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
