#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
INSTALL_CONF_DIR="$LAD_OS_DIR/conf/install"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="wpa_supplicant"
feature_desc="Install wpa_supplicant and configuration for network card"

provides=()
new_files=("/etc/wpa_supplicant/")
modified_files=()
temp_files=("/tmp/wpa_supplicant.conf")

depends_aur=()
depends_pacman=(wpa_supplicant dhcpcd)
depends_pip3=()


function check_install() {
    if pacman -Q wpa_supplicant > /dev/null &&
        pacman -Q dhcpcd > /dev/null &&
        test -f /etc/wpa_supplicant/wpa_supplicant-*.conf; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function check_conf() {
    if [[ -f "$INSTALL_CONF_DIR/network.conf" ]] &&
        [[ "$(cat "$INSTALL_CONF_DIR/network.conf")" != "" ]]; then
        qecho "Configuration found at $INSTALL_CONF_DIR/network.conf"
        return 0
    else
        echo "No configuration found at $INSTALL_CONF_DIR/network.conf" >&2
        return 1
    fi
}

function prepare() {
    ip link
    echo "Note that the name of this card may change when you boot into the system"
    read -rp "Enter name of network card: " card

    echo "ctrl_interface=/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
    echo "update_config=1" >> /tmp/wpa_supplicant.conf

    if check_conf; then
        cat "$INSTALL_CONF_DIR/network.conf" >> /tmp/wpa_supplicant.conf
    fi

    echo "Opening wpa_supplicant file..."
    read -rp "Press enter to continue..."
    if [[ "$EDITOR" != "" ]]; then
        "$EDITOR" /tmp/wpa_supplicant.conf
    else
        vim /tmp/wpa_supplicant.conf
    fi
}

function install() {
    qecho "Copying /tmp/wpa_supplicant.conf to /etc/wpa_supplciant/wpa_supplicant-${card}.conf..."
    sudo install -Dm 600 /tmp/wpa_supplicant.conf "/etc/wpa_supplicant/wpa_supplicant-${card}.conf"
}

function post_install() {
    qecho "Enabling wpa_supplicant@${card}.service and dhcpcd.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" "wpa_supplicant@${card}.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" dhcpcd.service
    qecho "Enabled wpa_supplicant@${card}.service and dhcpcd.service"
}

function cleanup() {
    qecho "Removing ${temp_files[*]}..."
    rm -rf "${temp_files[@]}"
}

function uninstall() {
    ip link
    read -rp "Enter name of network card: " card

    qecho "Disabling wpa_supplicant@${card}.service and dhcpcd.service..."
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" "wpa_supplicant@${card}.service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" dhcpcd.service

    qecho "Removing /etc/wpa_supplicant/wpa_supplicant-${card}.conf..." 
    sudo rm -rf "/etc/wpa_supplicant/wpa_supplicant-${card}.conf"
}

source "$LAD_OS_DIR/common/feature_footer.sh"
