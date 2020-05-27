#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
CONF_DIR="$LAD_OS_DIR/conf/openvpn-expressvpn"
LOGIN_CONF_PATH="$CONF_DIR/client/login.conf"
LOGIN_CONF_INSTALL_PATH="/etc/openvpn/client/login.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="openvpn-expressvpn"
feature_desc="Install expressvpn configuration for openvpn"

provides=()
new_files=("/etc/openvpn/client")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(openvpn)


function fix_server_files() {
    local servers name new_name

    mapfile -t servers < <(find "$CONF_DIR/client" -iname "*.ovpn")

    qecho "Fixing server files"
    for s in "${servers[@]}"; do
        name="${s##**/}"
        new_name=$(echo "$name" |
            sed -e "s/my_expressvpn//" \
            -e "s/_//g" \
            -e "s/udp//" \
            -e "s/ovpn/conf/")
        sed -i "$s" -e "s/^auth-user-pass/& login.conf/"
        mv "$s" "$CONF_DIR/client/$new_name"
    done
}


function check_conf() (
    if [[ -f "$LOGIN_CONF_PATH" ]] && [[ "$(wc -l "$LOGIN_CONF_PATH")" -eq 2 ]]; then
        qecho "Configuration found at $LOGIN_CONF_PATH and are set correctly"
        return 0
    else
        echo "Configuration is not set or is not set correctly" >&2
        return 1
    fi
)

function check_install() {
    if sudo test -f "/etc/openvpn/client/login.conf" && 
        sudo diff --exclude=".gitignore" "$CONF_DIR/client" /etc/openvpn/client; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function prepare() {
    fix_server_files
}

function install() {
    sudo mkdir -p /etc/openvpn/client

    if ! check_conf; then
        echo "Get the username and password from https://www.expressvpn.com/sign-in"
        echo "Get the server configs from https://www.expressvpn.com/sign-in and copy them into client/"

        read -rp "Username: " username
        read -rp "Password: " password

        echo "$username" | sudo tee -a /etc/openvpn/client/login.conf >/dev/null
        echo "$password" | sudo tee -a /etc/openvpn/client/login.conf >/dev/null
    fi

    if [[ "$(ls "$CONF_DIR/client")" != "" ]]; then
        qecho "Copying files from $CONF_DIR/client/ to /etc/openvpn/client"
        sudo install -m 600 "$CONF_DIR"/client/* /etc/openvpn/client/
    fi

    echo "To start the vpn, run systemctl start openvpn-client@<server>"
}

function uninstall() {
    qecho "Removing ${new_files[*]}..."
    rm -f "${new_files[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
