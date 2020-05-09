#!/usr/bin/bash

BASE_DIR="$(readlink -f "$(dirname "$0")" )"
LOGIN_CONF_PATH="$BASE_DIR/client/login.conf"
LOGIN_CONF_INSTALL_PATH="/etc/openvpn/client/login.conf"

function fix_server_files() {
    CUR_DIR="$PWD"

    cd "$BASE_DIR/client"
    for f in *.ovpn; do
        new_name=$(echo $f |
            sed "s/my_expressvpn//" |
            sed "s/_//g" |
            sed "s/udp//" |
            sed "s/ovpn/conf/")
        sed -i "$f" -e "s/^auth-user-pass/& login.conf/"
        mv $f $new_name
    done

    cd "$CUR_DIR"
}


sudo pacman -S openvpn --needed --noconfirm

fix_server_files

echo "To start the vpn, run systemctl start openvpn-client@<server>"

if [[ -f "$LOGIN_CONF_PATH" ]]; then
    echo "$LOGIN_CONF_PATH found"
    login="$(cat "$LOGIN_CONF_PATH")"

    if [[ "$login" != "" ]]; then
        sudo mkdir -p /etc/openvpn/client
        echo "Copying files from $BASE_DIR/client/ to /etc/openvpn/client"
        sudo install -m 600 $BASE_DIR/client/* /etc/openvpn/client/

        exit 0
    fi
fi

echo "Get the username and password from https://www.expressvpn.com/sign-in"
echo "Get the server configs from https://www.expressvpn.com/sign-in and copy them into client/"

echo -n "Username: "
read username

echo -n "Password: "
read password

# Copy config files
echo "Copying config files..."
sudo mkdir /etc/openvpn/client
sudo install -m 600 $BASE_DIR/client/* /etc/openvpn/client/

sudo touch /etc/openvpn/client/login.conf
echo $username | sudo tee -a /etc/openvpn/client/login.conf
echo $password | sudo tee -a /etc/openvpn/client/login.conf
