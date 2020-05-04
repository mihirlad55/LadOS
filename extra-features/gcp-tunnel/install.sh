#!/bin/sh

BASE_DIR=$(dirname "$0")

port=$(egrep /etc/ssh/sshd_config -e "^Port [0-9]*$")
echo -n "Enter a port to run sshd on (blank to leave default: $port): "
read port

if [[ "$port" != "" ]]; then
    sudo sed -i /etc/ssh/sshd_config -e "s/^Port [0-9]*$/Port $port/"
    sed -i $BASE_DIR/gcp-tunnel.service \
        -e "s/^Environment=LOCAL_PORT=[0-9]*$/Environment=LOCAL_PORT=$port/"
fi

echo "Opening service file for any environment variable updates..."
read -p "Press enter to continue..."

if [[ "$EDITOR" != "" ]]; then
    $EDITOR $BASE_DIR/gcp-tunnel.service
else
    vi $BASE_DIR/gcp-tunnel.service
fi

sudo install -Dm 644 $BASE_DIR/gcp-tunnel.service /etc/systemd/system/gcp-tunnel.service

sudo systemctl enable gcp-tunnel
sudo systemctl start gcp-tunnel

sudo systemctl enable sshd
sudo systemctl restart sshd
