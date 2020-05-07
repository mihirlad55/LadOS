#!/usr/bin/bash

BASE_DIR=$(dirname "$0")

port=$(egrep /etc/ssh/sshd_config -e "^Port [0-9]*$")
echo -n "Enter a port to run sshd on (blank to leave default: $port): "
read new_port

if [[ "$new_port" != "" ]]; then
    port="$new_port"
    sudo sed -i /etc/ssh/sshd_config -e "s/^Port [0-9]*$/Port $port/"
fi

sed -i $BASE_DIR/gcp-tunnel.env \
    -e "s/^LOCAL_PORT=[0-9]*$/LOCAL_PORT=$port/"

echo "Opening environment file for updates..."
read -p "Press enter to continue..."

if [[ "$EDITOR" != "" ]]; then
    $EDITOR $BASE_DIR/gcp-tunnel.env
else
    vi $BASE_DIR/gcp-tunnel.env
fi

if ! sudo test -e "/root/.ssh/id_rsa"; then
    echo "Root's SSH keys are not setup"
    sudo ssh-keygen
fi

sudo install -Dm 644 $BASE_DIR/gcp-tunnel.service /etc/systemd/system/gcp-tunnel.service
sudo install -Dm 644 $BASE_DIR/gcp-tunnel.env /etc/gcp-tunnel.env

sudo systemctl enable gcp-tunnel
sudo systemctl start gcp-tunnel

sudo systemctl enable sshd
sudo systemctl restart sshd
