#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/gcp-tunnel"

feature_name="gcp-tunnel"
feature_desc="Install gcp-tunnel which remote forwards your computer's SSH port to a Google Cloud Platform instance allowing it to be accessible over the Internet"

provides=()
new_files=("/etc/gcp-tunnel.env" \
    "/etc/systemd/system/gcp-tunnel.service")
modified_files=()
temp_files=("/tmp/gcp-tunnel.env")

depends_aur=()
depends_pacman=(openssh)


function check_conf() (
    [[ -f "$CONF_DIR/gcp-tunnel.env" ]] && source "$CONF_DIR/gcp-tunnel.env"
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
    source "$CONF_DIR/gcp-tunnel.env"
}

function check_install() {
    for f in ${new_files[@]}; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function prepare() {
    cp $BASE_DIR/gcp-tunnel.env /tmp/gcp-tunnel.env

    port=$(egrep /etc/ssh/sshd_config -e "^Port [0-9]*$")

    if ! check_conf; then
        echo -n "Enter a port to run sshd on (blank to leave default: $port): "
        read new_port

        if [[ "$new_port" != "" ]]; then
            port="$new_port"
        fi

        sed -i /tmp/gcp-tunnel.env \
            -e "s/^LOCAL_PORT=[0-9]*$/LOCAL_PORT=$port/"

        echo "Opening environment file for updates..."
        read -p "Press enter to continue..."

        if [[ "$EDITOR" != "" ]]; then
            $EDITOR /tmp/gcp-tunnel.env
        else
            vim /tmp/gcp-tunnel.env
        fi
    else
        port="$LOCAL_PORT"
    fi
}

function install() {
    sudo sed -i /etc/ssh/sshd_config -e "s/^Port [0-9]*$/Port $port/"

    if ! sudo test -e "/root/.ssh/id_rsa"; then
        echo "Warning: Root's SSH keys are not setup" >&2
    fi

    sudo install -Dm 644 $BASE_DIR/gcp-tunnel.service /etc/systemd/system/gcp-tunnel.service
    sudo install -Dm 600 /tmp/gcp-tunnel.env /etc/gcp-tunnel.env
}

function post_install() {
    qecho "Enabling gcp-tunnel.service..."
    sudo systemctl enable -f ${SYSTEMD_FLAGS[*]} gcp-tunnel

    qecho "Enabling sshd.service"
    sudo systemctl enable ${SYSTEMD_FLAGS[*]} sshd

    qecho "Done enabling services"
}

function cleanup() {
    qecho "Removing /tmp/gcp-tunnel.env"
    rm -f /tmp/gcp-tunnel.env
}

function uninstall() {
    qecho "Disabling gcp-tunnel.service..."
    sudo systemctl disable ${SYSTEMD_FLAGS[*]} gcp-tunnel

    qecho "Disabling sshd.service"
    sudo systemctl disable ${SYSTEMD_FLAGS[*]} sshd

    qecho "Removing ${new_files[@]}..."
    rm -f "${new_files[@]}"
}

source "$LAD_OS_DIR/common/feature_common.sh"


