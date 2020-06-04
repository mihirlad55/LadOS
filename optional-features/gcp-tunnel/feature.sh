#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/gcp-tunnel"
readonly BASE_ENV="$BASE_DIR/gcp-tunnel.env"
readonly BASE_SERVICE="$BASE_DIR/gcp-tunnel.service"
readonly CONF_ENV="$CONF_DIR/gcp-tunnel.env"
readonly MOD_SSHD_CONFIG="/etc/ssh/sshd_config"
readonly TMP_ENV="/tmp/gcp-tunnel.env"
readonly NEW_ENV="/etc/gcp-tunnel.env"
readonly NEW_SERVICE="/etc/systemd/system/gcp-tunnel.service"
readonly ROOT_SSH_PRIV_KEY="/root/.ssh/id_rsa"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="GCP Tunnel"
readonly FEATURE_DESC="Install gcp-tunnel which remote forwards your \
computer's SSH port to a Google Cloud Platform instance allowing it \
to be accessible over the Internet"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_ENV" \
    "$NEW_SERVICE" \
    "$MOD_SSHD_CONFIG" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_ENV")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(openssh)

port=



function check_conf() (
    if [[ -f "$CONF_ENV" ]]; then
        source "$CONF_ENV"
    fi

    if [[ "$HOSTNAME" =  "" ]] ||
        [[ "$REMOTE_USERNAME" = "" ]] ||
        [[ "$LOCAL_PORT" = "" ]] ||
        [[ "$REMOTE_PORT" = "" ]] ||
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
    local f

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
    port=$(grep -P "^#*Port [0-9]*$" "$MOD_SSHD_CONFIG")

    if ! check_conf; then
        cp -f "$BASE_ENV" "$TMP_ENV"

        echo -n "Enter a port to run sshd on (blank to leave default: $port): "
        read -r new_port

        if [[ "$new_port" != "" ]]; then
            port="$new_port"
        fi

        # Update port in gcp-tunnel.env
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
    # Update port setting in sshd config
    sudo sed -i "$MOD_SSHD_CONFIG" -e "s/^#*Port [0-9]*$/Port $port/"

    if ! sudo test -e "$ROOT_SSH_PRIV_KEY"; then
        echo "Warning: Root's SSH keys are not setup" >&2
    fi

    sudo install -Dm 644 "$BASE_SERVICE" "$NEW_SERVICE"

    if ! check_conf; then
        sudo install -Dm 600 "$TMP_ENV" "$NEW_ENV"
    else
        sudo install -Dm 600 "$CONF_ENV" "$NEW_ENV"
    fi
}

function post_install() {
    qecho "Enabling gcp-tunnel.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" gcp-tunnel.service

    qecho "Enabling sshd.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" sshd.service

    qecho "Done enabling services"
}

function cleanup() {
    qecho "Removing $TMP_ENV"
    rm -f "$TMP_ENV"
}

function uninstall() {
    qecho "Disabling gcp-tunnel.service..."
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" gcp-tunnel.service

    qecho "Disabling sshd.service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" sshd.service

    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
