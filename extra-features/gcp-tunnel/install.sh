#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
CONF_DIR="$(readlink -f "$BASE_DIR/../../conf/gcp-tunnel")"

source "$CONF_DIR/gcp-tunnel.env"


sudo pacman -S openssh --needed --noconfirm

port=$(egrep /etc/ssh/sshd_config -e "^Port [0-9]*$")

if [[ "$HOSTNAME" =  "" ]] ||
    [[ "$REMOTE_USERNAME" = "" ]] ||
    [[ "$LOCAL_PORT" = "" ]] ||
    [[ "$REMOTE_PORT" = "" ]] ||
    [[ "$PRIVATE_KEY_PATH" = "" ]]; then

    echo -n "Enter a port to run sshd on (blank to leave default: $port): "
    read new_port

    if [[ "$new_port" != "" ]]; then
        port="$new_port"
    fi

    cp $BASE_DIR/gcp-tunnel.env /tmp/gcp-tunnel.env
    sed -i /tmp/gcp-tunnel.env \
        -e "s/^LOCAL_PORT=[0-9]*$/LOCAL_PORT=$port/"

    echo "Opening environment file for updates..."
    read -p "Press enter to continue..."

    if [[ "$EDITOR" != "" ]]; then
        $EDITOR /tmp/gcp-tunnel.env
    else
        vim /tmp/gcp-tunnel.env
    fi
else
    port="$LOCAL_PORT"

    cp "$BASE_DIR/gcp-tunnel.env" "/tmp/gcp-tunnel.env"
fi

sudo sed -i /etc/ssh/sshd_config -e "s/^Port [0-9]*$/Port $port/"

if ! sudo test -e "/root/.ssh/id_rsa"; then
    echo "Warning: Root's SSH keys are not setup"
fi

sudo install -Dm 644 $BASE_DIR/gcp-tunnel.service /etc/systemd/system/gcp-tunnel.service
sudo install -Dm 644 /tmp/gcp-tunnel.env /etc/gcp-tunnel.env

rm /tmp/gcp-tunnel.env

sudo systemctl enable --now gcp-tunnel
sudo systemctl enable --now sshd
