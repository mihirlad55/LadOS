#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/openvpn-expressvpn"
LOGIN_CONF_PATH="$CONF_DIR/client/login.conf"
LOGIN_CONF_INSTALL_PATH="/etc/openvpn/client/login.conf"


feature_name="openvpn-expressvpn"
feature_desc="Install expressvpn configuration for openvpn"

provides=()
new_files=("/etc/openvpn/client")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(openvpn)


function fix_server_files() (
    cd "$CONF_DIR/client"

    if [[ $(echo *.ovpn) != "*.ovpn" ]]; then
        qecho "Fixing server files"
        for f in *.ovpn; do
            new_name=$(echo $f |
                sed "s/my_expressvpn//" |
                sed "s/_//g" |
                sed "s/udp//" |
                sed "s/ovpn/conf/")
            sed -i "$f" -e "s/^auth-user-pass/& login.conf/"
            mv $f $new_name
        done
    fi
)


function check_conf() (
    if [[ -f "$LOGIN_CONF_PATH" ]] && [[ "$(cat $LOGIN_CONF_PATH | wc -l)" -eq 2 ]]; then
        qecho "Configuration found at $LOGIN_CONF_PATH and are set correctly"
        return 0
    else
        echo "Configuration is not set or is not set correctly" >&2
        return 1
    fi
)

function check_install() {
    if sudo test -e "/etc/openvpn/client/login.conf" && 
        sudo diff --exclude=".gitignore" $CONF_DIR/client /etc/openvpn/client; then
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

        read -p "Username: " username

        read -p "Password: " password

        sudo touch /etc/openvpn/client/login.conf
        echo $username | sudo tee -a /etc/openvpn/client/login.conf >/dev/null
        echo $password | sudo tee -a /etc/openvpn/client/login.conf >/dev/null
    fi

    if [[ "$(ls $CONF_DIR/client)" != "" ]]; then
        qecho "Copying files from $CONF_DIR/client/ to /etc/openvpn/client"
        sudo install -m 600 $CONF_DIR/client/* /etc/openvpn/client/
    fi

    echo "To start the vpn, run systemctl start openvpn-client@<server>"
}

source "$LAD_OS_DIR/common/feature_common.sh"
