#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/ssh-tunnel"
readonly BASE_ENV="$BASE_DIR/ssh-tunnel.env"
readonly BASE_SERVICE="$BASE_DIR/ssh-tunnel@.service"
readonly CONF_ENV="$CONF_DIR/ssh-tunnel.env"
readonly MOD_SSHD_CONFIG="/etc/ssh/sshd_config"
readonly TMP_ENV="/tmp/ssh-tunnel.env"
readonly NEW_ENV_DIR="/etc/"
readonly NEW_SERVICE="/etc/systemd/system/ssh-tunnel@.service"
readonly ROOT_SSH_PRIV_KEY="/root/.ssh/id_rsa"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="SSH Tunnel"
readonly FEATURE_DESC="Install ssh-tunnel which remote forwards your \
computer's ports to another server allowing it to be accessible over the \
Internet"
readonly PROVIDES=()
NEW_FILES=( \
    # Also see new files in $NEW_ENV_DIR
    "$NEW_SERVICE" \
    "$MOD_SSHD_CONFIG" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_ENV")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(openssh)

port=
service=""

function set_service_name() {
    if [[ "$service" == "" ]]; then
        echo -n "Enter the name of the service being forwarded: "
        read -r service
    fi
}

function check_conf() (
    if [[ -f "$CONF_ENV" ]]; then
        source "$CONF_ENV"
    fi

    if [[ "$HOSTNAME" =  "" ]] ||
        [[ "$REMOTE_USERNAME" = "" ]] ||
        [[ "$LOCAL_PORT" = "" ]] ||
        [[ "$REMOTE_PORT" = "" ]] ||
        [[ "$SSH_PORT" = "" ]] ||
        [[ "$PRIVATE_KEY_PATH" = "" ]]; then
        echo "Configuration not fully set" >&2
        return 1
    else
        qecho "Configuration is correctly set"
        return 0
    fi
)

function load_conf() {
    source "$CONF_ENV"
}

function check_install() {
    local f service_path env_path

    set_service_name
    env_path="$NEW_ENV_DIR/ssh-tunnel-$service.env"

    NEW_FILES=("${NEW_FILES[@]}" "$env_path")

    for f in "${NEW_FILES[@]}"; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    qecho "$FEATURE_NAME is installed"
    return 0
}

function prepare() {
    local new_port

    # Get ssh port from SSHD config
    port=$(grep -P "^#*Port [0-9]*$" "$MOD_SSHD_CONFIG" | sed 's/^Port //')

    set_service_name

    if ! check_conf; then
        cp -f "$BASE_ENV" "$TMP_ENV"

        echo -n "Enter a port to run sshd on (blank to leave default: $port): "
        read -r new_port

        if [[ "$new_port" != "" ]]; then
            port="$new_port"
        fi

        # Update port in ssh-tunnel.env
        sed -i "$TMP_ENV" -e "s/^LOCAL_PORT=[0-9]*$/LOCAL_PORT=$port/"

        echo "Opening environment file for updates..."
        read -rp "Press enter to continue..."

        if [[ "$EDITOR" != "" ]]; then
            "$EDITOR" "$TMP_ENV"
        else
            vim "$TMP_ENV"
        fi
    else
        port="$LOCAL_PORT"
    fi
}

function install() {
    local env_path

    # Update port setting in sshd config
    sudo sed -i "$MOD_SSHD_CONFIG" -e "s/^#*Port [0-9]*$/Port $port/"

    if ! sudo test -e "$ROOT_SSH_PRIV_KEY"; then
        echo "Warning: Root's SSH keys are not setup" >&2
    fi

    sudo install -Dm 644 "$BASE_SERVICE" "$NEW_SERVICE"

    env_path="$NEW_ENV_DIR/ssh-tunnel-$service.env"
    if ! check_conf; then
        sudo install -Dm 600 "$TMP_ENV" "$env_path"
    else
        sudo install -Dm 600 "$CONF_ENV" "$env_path"
    fi
}

function post_install() {
    set_service_name

    qecho "Enabling ssh-tunnel@$service.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" "ssh-tunnel@$service.service"

    qecho "Enabling sshd.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" sshd.service

    qecho "Done enabling services"
}

function cleanup() {
    qecho "Removing $TMP_ENV"
    rm -f "$TMP_ENV"
}

function uninstall() {
    set_service_name

    qecho "Disabling ssh-tunnel@$service.service..."
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" "ssh-tunnel@$service.service"

    qecho "Disabling sshd.service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" sshd.service

    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
