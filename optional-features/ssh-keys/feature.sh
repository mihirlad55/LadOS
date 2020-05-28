#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/ssh-keys"
readonly CONF_USER_SSH_DIR="$CONF_DIR/user/.ssh"
readonly CONF_USER_SSH_KEY="$CONF_USER_SSH_DIR/id_rsa"
readonly CONF_USER_SSH_PUB="$CONF_USER_SSH_DIR/id_rsa.pub"
readonly CONF_USER_SSH_AUTH="$CONF_USER_SSH_DIR/authorized_keys"
readonly CONF_USER_SSH_HOSTS="$CONF_USER_SSH_DIR/known_hosts"
readonly CONF_USER_SSH_CONFIG="$CONF_USER_SSH_DIR/config"
readonly CONF_ROOT_SSH_DIR="$CONF_DIR/root/.ssh"
readonly CONF_ROOT_SSH_KEY="$CONF_ROOT_SSH_DIR/id_rsa"
readonly CONF_ROOT_SSH_PUB="$CONF_ROOT_SSH_DIR/id_rsa.pub"
readonly CONF_ROOT_SSH_AUTH="$CONF_ROOT_SSH_DIR/authorized_keys"
readonly CONF_ROOT_SSH_HOSTS="$CONF_ROOT_SSH_DIR/known_hosts"
readonly CONF_ROOT_SSH_CONFIG="$CONF_ROOT_SSH_DIR/config"
readonly NEW_USER_SSH_DIR="$HOME/.ssh"
readonly NEW_USER_SSH_KEY="$NEW_USER_SSH_DIR/id_rsa"
readonly NEW_USER_SSH_PUB="$NEW_USER_SSH_DIR/id_rsa.pub"
readonly NEW_USER_SSH_AUTH="$NEW_USER_SSH_DIR/authorized_keys"
readonly NEW_USER_SSH_HOSTS="$NEW_USER_SSH_DIR/known_hosts"
readonly NEW_USER_SSH_CONFIG="$NEW_USER_SSH_DIR/config"
readonly NEW_ROOT_SSH_DIR="/root/.ssh"
readonly NEW_ROOT_SSH_KEY="$NEW_ROOT_SSH_DIR/id_rsa"
readonly NEW_ROOT_SSH_PUB="$NEW_ROOT_SSH_DIR/id_rsa.pub"
readonly NEW_ROOT_SSH_AUTH="$NEW_ROOT_SSH_DIR/authorized_keys"
readonly NEW_ROOT_SSH_HOSTS="$NEW_ROOT_SSH_DIR/known_hosts"
readonly NEW_ROOT_SSH_CONFIG="$NEW_ROOT_SSH_DIR/config"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Import Root and User SSH Keys"
readonly FEATURE_DESC="Install existing ssh keys for your user and for root"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_USER_SSH_DIR" \
    "$NEW_USER_SSH_KEY" \
    "$NEW_USER_SSH_PUB" \
    "$NEW_USER_SSH_AUTH" \
    "$NEW_USER_SSH_HOSTS" \
    "$NEW_USER_SSH_CONFIG" \
    "$NEW_ROOT_SSH_DIR" \
    "$NEW_ROOT_SSH_KEY" \
    "$NEW_ROOT_SSH_PUB" \
    "$NEW_ROOT_SSH_AUTH" \
    "$NEW_ROOT_SSH_HOSTS" \
    "$NEW_ROOT_SSH_CONFIG" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(openssh)



function install_exists() {
    source_file="$1"; shift
    target_file="$1"; shift
    flags=("$@")

    if [[ -f "$source_file" ]]; then
        command install "${flags[@]}" 
    fi
}

function check_install() {
    if diff "$NEW_USER_SSH_DIR" "$CONF_USER_SSH_DIR" &&
        sudo diff "$NEW_ROOT_SSH_DIR" "$CONF_ROOT_SSH_DIR"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    if [[ -d "$CONF_USER_SSH_DIR" ]] && [[ -d "$CONF_ROOT_SSH_DIR" ]]; then
        qecho "Copying user ssh files to $NEW_USER_SSH_DIR..."
        mkdir -p "$NEW_USER_SSH_DIR"
        chmod 700 "$NEW_USER_SSH_DIR"

        if [[ -f "$CONF_USER_SSH_KEY" ]]; then
            command install -Dm 600 "$CONF_USER_SSH_KEY" "$NEW_USER_SSH_KEY"
        fi

        if [[ -f "$CONF_USER_SSH_CONFIG" ]]; then
            command install -Dm 600 "$CONF_USER_SSH_CONFIG" \
                "$NEW_USER_SSH_CONFIG"
        fi

        if [[ -f "$CONF_USER_SSH_AUTH" ]]; then
            command install -Dm 600 "$CONF_USER_SSH_AUTH" "$NEW_USER_SSH_AUTH"
        fi

        if [[ -f "$CONF_USER_SSH_PUB" ]]; then
            command install -Dm 644 "$CONF_USER_SSH_PUB" "$NEW_USER_SSH_PUB"
        fi

        if [[ -f "$CONF_USER_SSH_HOSTS" ]]; then
            command install -Dm 644 "$CONF_USER_SSH_HOSTS" "$NEW_USER_SSH_HOSTS"
        fi

        chown -R "$USER" "$CONF_USER_SSH_DIR"

        qecho "Copying root ssh files to $CONF_ROOT_SSH_DIR"
        sudo mkdir -p "$CONF_ROOT_SSH_DIR"
        sudo chmod 700 "$CONF_ROOT_SSH_DIR"

        if [[ -f "$CONF_ROOT_SSH_KEY" ]]; then
            command install -Dm 600 "$CONF_ROOT_SSH_KEY" "$NEW_ROOT_SSH_KEY"
        fi

        if [[ -f "$CONF_ROOT_SSH_CONFIG" ]]; then
            command install -Dm 600 "$CONF_ROOT_SSH_CONFIG" \
                "$NEW_ROOT_SSH_CONFIG"
        fi

        if [[ -f "$CONF_ROOT_SSH_AUTH" ]]; then
            command install -Dm 600 "$CONF_ROOT_SSH_AUTH" "$NEW_ROOT_SSH_AUTH"
        fi

        if [[ -f "$CONF_ROOT_SSH_PUB" ]]; then
            command install -Dm 644 "$CONF_ROOT_SSH_PUB" "$NEW_ROOT_SSH_PUB"
        fi

        if [[ -f "$CONF_ROOT_SSH_HOSTS" ]]; then
            command install -Dm 644 "$CONF_ROOT_SSH_HOSTS" "$NEW_ROOT_SSH_HOSTS"
        fi

        sudo chown -R root "$NEW_ROOT_SSH_DIR"

        qecho "Done copying ssh files"
    else
        echo "Root or user .ssh folder missing" >&2
        return 1
    fi
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
