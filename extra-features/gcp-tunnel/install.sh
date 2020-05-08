#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

sudo pacman -S openssh --needed --noconfirm

port=$(egrep /etc/ssh/sshd_config -e "^Port [0-9]*$")
echo -n "Enter a port to run sshd on (blank to leave default: $port): "
read new_port

if [[ "$new_port" != "" ]]; then
    port="$new_port"
    sudo sed -i /etc/ssh/sshd_config -e "s/^Port [0-9]*$/Port $port/"
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

if ! sudo test -e "/root/.ssh/id_rsa"; then
    echo "Root's SSH keys are not setup"
    sudo ssh-keygen
fi

sudo install -Dm 644 $BASE_DIR/gcp-tunnel.service /etc/systemd/system/gcp-tunnel.service
sudo install -Dm 644 /tmp/gcp-tunnel.env /etc/gcp-tunnel.env

rm /tmp/gcp-tunnel.env

sudo systemctl enable --now gcp-tunnel
sudo systemctl enable --now sshd
