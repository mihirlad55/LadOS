#!/usr/bin/sh

REMOTE_USER="portforward"
useradd -m $REMOTE_USER

mkdir /home/${REMOTE_USER}/.ssh
chmod 700 /home/${REMOTE_USER}/.ssh
touch /home/${REMOTE_USER}/.ssh/authorized_keys
chmod 600 /home/${REMOTE_USER}/.ssh/authorized_keys
chown ${REMOTE_USER}:${REMOTE_USER} -R /home/${REMOTE_USER}/.ssh

install -Dm 700 free-port /usr/local/bin/free-port

echo -n "Enter public key to authorize (blank for none): "
read public_key

[[ "$public_key" != "" ]] &&
    echo "$public_key" > /home/${REMOTE_USER}/.ssh/authorized_keys

echo -n "Enter a port to run sshd on (blank to leave default): "
read port

if [[ "$port" != "" ]]; then
    sed -i /etc/ssh/sshd_config -e "s/^Port [0-9]*$/Port $port/"
    systemctl restart sshd
fi
