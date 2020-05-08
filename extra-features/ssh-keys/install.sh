#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"
DEFAULT_USER_SSH_DIR="$BASE_DIR/default-user/.ssh"
ROOT_SSH_DIR="$BASE_DIR/root/.ssh"

if [[ -d "$BASE_DIR/default-user/.ssh" ]] &&
    [[ -d "$BASE_DIR/root/.ssh"]]; then
    
    echo "Copying default-user ssh files to $HOME/.ssh..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    install -Dm 600 "$DEFAULT_USER_SSH_DIR/id_rsa" "$HOME/.ssh/id_rsa"
    install -Dm 600 "$DEFAULT_USER_SSH_DIR/config" "$HOME/.ssh/config"
    install -Dm 600 "$DEFAULT_USER_SSH_DIR/authorized_keys" "$HOME/.ssh/authorized_keys"
    install -Dm 644 "$DEFAULT_USER_SSH_DIR/id_rsa.pub" "$HOME/.ssh/id_rsa.pub"
    install -Dm 644 "$DEFAULT_USER_SSH_DIR/known_hosts" "$HOME/.ssh/known_hosts"

    echo "Copying root ssh files to /root/.ssh"
    mkdir -p "/root/.ssh"
    chmod 700 "/root/.ssh"
    install -Dm 600 "$ROOT_SSH_DIR/id_rsa" "/root/.ssh/id_rsa"
    install -Dm 600 "$ROOT_SSH_DIR/config" "/root/.ssh/config"
    install -Dm 600 "$ROOT_SSH_DIR/authorized_keys" "/root/.ssh/authorized_keys"
    install -Dm 644 "$ROOT_SSH_DIR/id_rsa.pub" "/root/.ssh/id_rsa.pub"
    install -Dm 644 "$ROOT_SSH_DIR/known_hosts" "/root/.ssh/known_hosts"

    echo "Done copying ssh files"
else
    echo "Root or default-user .ssh folder missing"
fi
