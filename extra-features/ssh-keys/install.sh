#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"
USER_SSH_DIR="$BASE_DIR/user/.ssh"
ROOT_SSH_DIR="$BASE_DIR/root/.ssh"

if [[ -d "$BASE_DIR/user/.ssh" ]] &&
    [[ -d "$BASE_DIR/root/.ssh" ]]; then
    
    echo "Copying user ssh files to $HOME/.ssh..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    install -Dm 600 "$USER_SSH_DIR/id_rsa" "$HOME/.ssh/id_rsa"
    install -Dm 600 "$USER_SSH_DIR/config" "$HOME/.ssh/config"
    install -Dm 600 "$USER_SSH_DIR/authorized_keys" "$HOME/.ssh/authorized_keys"
    install -Dm 644 "$USER_SSH_DIR/id_rsa.pub" "$HOME/.ssh/id_rsa.pub"
    install -Dm 644 "$USER_SSH_DIR/known_hosts" "$HOME/.ssh/known_hosts"
    chown -R $USER "$HOME/.ssh"

    echo "Copying root ssh files to /root/.ssh"
    sudo mkdir -p "/root/.ssh"
    sudo chmod 700 "/root/.ssh"
    sudo install -Dm 600 "$ROOT_SSH_DIR/id_rsa" "/root/.ssh/id_rsa"
    sudo install -Dm 600 "$ROOT_SSH_DIR/config" "/root/.ssh/config"
    sudo install -Dm 600 "$ROOT_SSH_DIR/authorized_keys" "/root/.ssh/authorized_keys"
    sudo install -Dm 644 "$ROOT_SSH_DIR/id_rsa.pub" "/root/.ssh/id_rsa.pub"
    sudo install -Dm 644 "$ROOT_SSH_DIR/known_hosts" "/root/.ssh/known_hosts"
    sudo chown -R root "/root/.ssh"

    echo "Done copying ssh files"
else
    echo "Root or user .ssh folder missing"
fi
