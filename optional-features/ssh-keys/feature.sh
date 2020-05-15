#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/ssh-keys"

USER_SSH_DIR="$CONF_DIR/user/.ssh"
ROOT_SSH_DIR="$CONF_DIR/root/.ssh"

feature_name="ssh-keys"
feature_desc="Install existing ssh keys for your user and for root"

provides=()
new_files=("$HOME/.ssh/id_rsa" \
    "$HOME/.ssh/config" \ 
    "$HOME/.ssh/authorized_keys" \ 
    "$HOME/.ssh/id_rsa.pub" \ 
    "$HOME/.ssh/known_hosts" \
    "/root/.ssh/id_rsa" \ 
    "/root/.ssh/config" \ 
    "/root/.ssh/authorized_keys" \ 
    "/root/.ssh/id_rsa.pub" \ 
    "/root/.ssh/known_hosts")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(openssh)

function install_exists() {
    source_file="$1"; shift
    target_file="$1"; shift
    flags=("$@")

    if [[ -f "$source_file" ]]; then
        command install "${flags[@]}" 
    fi
}

function check_install() {
    if diff "$HOME/.ssh" "$USER_SSH_DIR" &&
        sudo diff "/root/.ssh" "$ROOT_SSH_DIR"; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    if [[ -d "$CONF_DIR/user/.ssh" ]] &&
        [[ -d "$CONF_DIR/root/.ssh" ]]; then
        
        qecho "Copying user ssh files to $HOME/.ssh..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        [[ -f "$USER_SSH_DIR/id_rsa" ]] &&
            command install -Dm 600 "$USER_SSH_DIR/id_rsa" "$HOME/.ssh/id_rsa"
        [[ -f "$USER_SSH_DIR/config" ]] &&
            command install -Dm 600 "$USER_SSH_DIR/config" "$HOME/.ssh/config"
        [[ -f "$USER_SSH_DIR/authorized_keys" ]] &&
            command install -Dm 600 "$USER_SSH_DIR/authorized_keys" "$HOME/.ssh/authorized_keys"
        [[ -f "$USER_SSH_DIR/id_rsa.pub" ]] &&
            command install -Dm 644 "$USER_SSH_DIR/id_rsa.pub" "$HOME/.ssh/id_rsa.pub"
        [[ -f "$USER_SSH_DIR/known_hosts" ]] &&
            command install -Dm 644 "$USER_SSH_DIR/known_hosts" "$HOME/.ssh/known_hosts"
        chown -R $USER "$HOME/.ssh"

        qecho "Copying root ssh files to /root/.ssh"
        sudo mkdir -p "/root/.ssh"
        sudo chmod 700 "/root/.ssh"
        [[ -f "$ROOT_SSH_DIR/id_rsa" ]] &&
            sudo install -Dm 600 "$ROOT_SSH_DIR/id_rsa" "/root/.ssh/id_rsa"
        [[ -f "$ROOT_SSH_DIR/config" ]] &&
            sudo install -Dm 600 "$ROOT_SSH_DIR/config" "/root/.ssh/config"
        [[ -f "$ROOT_SSH_DIR/authorized_keys" ]] &&
            sudo install -Dm 600 "$ROOT_SSH_DIR/authorized_keys" "/root/.ssh/authorized_keys"
        [[ -f "$ROOT_SSH_DIR/id_rsa.pub" ]] &&
            sudo install -Dm 644 "$ROOT_SSH_DIR/id_rsa.pub" "/root/.ssh/id_rsa.pub"
        [[ -f "$ROOT_SSH_DIR/known_hosts" ]] &&
            sudo install -Dm 644 "$ROOT_SSH_DIR/known_hosts" "/root/.ssh/known_hosts"
        sudo chown -R root "/root/.ssh"

        qecho "Done copying ssh files"
    else
        echo "Root or user .ssh folder missing" >&2
        return 1
    fi
}


source "$LAD_OS_DIR/common/feature_common.sh"