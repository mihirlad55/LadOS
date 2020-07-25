#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_SYSCTL_CONF="$BASE_DIR/sysctl.conf"
readonly BASE_DHCPCD_CONF_ADD="$BASE_DIR/dhcpcd.conf.add"
readonly BASE_RESOLV_CONF="$BASE_DIR/resolv.conf"
readonly CONF_DIR="$LAD_OS_DIR/conf/openvpn-expressvpn"
readonly CONF_CLIENT_DIR="$CONF_DIR/client"
readonly CONF_LOGIN_CONF="$CONF_CLIENT_DIR/login.conf"
readonly NEW_CLIENT_DIR="/etc/openvpn/client"
readonly NEW_LOGIN_CONF="$NEW_CLIENT_DIR/login.conf"
readonly NEW_SYSCTL_CONF="/etc/sysctl.conf"
readonly MOD_DHCPCD_CONF="/etc/dhcpcd.conf"
readonly NEW_RESOLV_CONF="/etc/resolv.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="openvpn-expressvpn"
readonly FEATURE_DESC="Install expressvpn configuration for openvpn"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_LOGIN_CONF" \
    "$NEW_CLIENT_DIR" \
    "$NEW_SYSCTL_CONF" \
    "$NEW_RESOLV_CONF" \
)
readonly MODIFIED_FILES=("$MOD_DHCPCD_CONF")
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(openvpn procps-ng)



# Change extension on expressvpn servers to .conf, simplify name to
# <state>-<num>.conf, and add login.conf to auth-user-pass line in conf.
function fix_server_files() {
    local servers name new_name s

    mapfile -t servers < <(find "$CONF_CLIENT_DIR" -iname "*.ovpn")

    qecho "Fixing server files"
    for s in "${servers[@]}"; do
        name="${s##**/}"
        new_name=$(echo "$name" |
            sed -e "s/my_expressvpn//" \
            -e "s/_//g" \
            -e "s/udp//" \
            -e "s/ovpn/conf/")
        sed -i "$s" -e "s/^auth-user-pass/& login.conf/"
        mv "$s" "$CONF_CLIENT_DIR/$new_name"
    done
}


# Check if dhcpcd.conf contains added configuration
function check_dhcpcd_conf() {
    # Get first line of added configuration
    dhcpcd_conf_add_first_line="$(head -n1 "$BASE_DHCPCD_CONF_ADD")"
    # Get number of lines of added configuration
    num_of_lines="$(wc -l "$BASE_DHCPCD_CONF_ADD" | cut -d' ' -f1)"
    # Number of lines after first line
    after_context=$(( num_of_lines - 1 ))
    # Get added configuration block from config
    dhcpcd_match="$(grep -F "$dhcpcd_conf_add_first_line" -A $after_context \
        "$MOD_DHCPCD_CONF")"
    # Compare added configuration to what should have been added
    echo "$dhcpcd_match" | diff "$BASE_DHCPCD_CONF_ADD" - > /dev/null
}

function check_conf() {
    local num_of_lines

    # Check if username and password are found in login.conf
    if [[ -f "$CONF_LOGIN_CONF" ]]; then
        num_of_lines="$(wc -l "$CONF_LOGIN_CONF" | cut -d' ' -f1)"

        if (( num_of_lines == 2 )); then
            qecho "Configuration at $CONF_LOGIN_CONF is set correctly"
            return 0
        fi
    fi

    echo "Configuration is not set or is not set correctly" >&2
    return 1
}

function check_install() {
    # Check if files in conf match files in install dir
    if ! sudo test -f "$NEW_LOGIN_CONF" ||
        ! [[ -f "$NEW_RESOLV_CONF" ]] ||
        ! [[ -f "$NEW_SYSCTL_CONF" ]] ||
        ! sudo diff --exclude=".gitignore" "$CONF_CLIENT_DIR" "$NEW_CLIENT_DIR" ||
        ! check_dhcpcd_conf; then
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi

    qecho "$FEATURE_NAME is installed"
    return 0
}

function prepare() {
    fix_server_files
}

function install() {
    sudo mkdir -p /etc/openvpn/client

    if ! check_conf; then
        echo "Get the username and password from"
        echo "https://www.expressvpn.com/sign-in"
        echo "Get the server configs from https://www.expressvpn.com/sign-in"
        echo "and copy them into client/"

        read -rp "Username: " username
        read -rp "Password: " password

        echo "$username" | sudo tee -a "$NEW_LOGIN_CONF" >/dev/null
        echo "$password" | sudo tee -a "$NEW_LOGIN_CONF" >/dev/null
    fi

    # Copy any server files to install dir
    if [[ "$(ls "$CONF_DIR/client")" != "" ]]; then
        qecho "Copying files from $CONF_CLIENT_DIR to $NEW_CLIENT_DIR..."
        sudo install -m 600 "$CONF_CLIENT_DIR"/* "$NEW_CLIENT_DIR"
    fi

    echo "Copying $BASE_SYSCTL_CONF to $NEW_SYSCTL_CONF..."
    sudo install -Dm644 "$BASE_SYSCTL_CONF" "$NEW_SYSCTL_CONF"
    sudo sysctl -p

    echo "Copying $BASE_RESOLV_CONF to $NEW_RESOLV_CONF..."
    sudo install -Dm644 "$BASE_RESOLV_CONF" "$NEW_RESOLV_CONF"

    if ! check_dhcpcd_conf; then
        echo "Modifying $MOD_DHCPCD_CONF..."
        < "$BASE_DHCPCD_CONF_ADD" sudo tee -a "$MOD_DHCPCD_CONF"
    fi

    echo "To start the vpn, run systemctl start openvpn-client@<server>"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
