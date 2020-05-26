#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/restic-b2"

source "$LAD_OS_DIR/common/feature_header.sh"

SYSTEMD_DIR="/etc/systemd/system"
INSTALL_DIR="/root"

feature_name="restic-b2"
feature_desc="Install restic with B2 configuration"

provides=()
new_files=( \
    "$INSTALL_DIR" \
    "$INSTALL_DIR/backup/b2.png" \
    "$INSTALL_DIR/b2.png" \
    "$INSTALL_DIR/backup.sh" \
    "$INSTALL_DIR/excludes.txt" \
    "$INSTALL_DIR/includes.txt" \
    "$INSTALL_DIR/prune.sh" \
    "$INSTALL_DIR/unset-constants.sh" \
    "$INSTALL_DIR/utils.sh" \
    "$SYSTEMD_DIR" \
    "$SYSTEMD_DIR/b2-backup.service " \
    "$SYSTEMD_DIR/b2-backup.timer " \
    "$SYSTEMD_DIR/b2-prune.service " \
    "$SYSTEMD_DIR/b2-prune.timer " \
)
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(restic)


function check_conf() (
    [[ -f "$CONF_DIR/constants.sh" ]] && source "$CONF_DIR/constants.sh"
    res="$?"

    if [[ "$?" -eq 0 ]]; then
        qecho "Configuration is set correctly"
        return 0
    else
        echo "Configuration is not set properly" >&2
        return 1
    fi
)

function load_conf() {
    qecho "Reading configuration from $CONF_DIR/constants.sh"
    source "$CONF_DIR/constants.sh"
}

function check_install() {
    source "$TARGET_CONSTANTS_PATH"

    if [[ "$NOTIFY_USER" != "" ]] &&
        [[ "$B2_KEY_NAME" != "" ]] &&
        [[ "$B2_BUCKET" != "" ]] &&
        [[ "$B2_ACCOUNT_ID" != "" ]] &&
        [[ "$B2_ACCOUNT_KEY" != "" ]] &&
        [[ "$RESTIC_PASSWORD" != "" ]]; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function prepare() {
    if [[ "$NOTIFY_USER" = "" ]]; then
        echo "Notify user not defined"
        echo -n "Enter the username of the user to send notifications to: "
        read NOTIFY_USER
    fi

    if [[ "$B2_KEY_NAME" = "" ]]; then
        echo "B2 key not defined"
        echo -n "Enter the B2 key name: "
        read B2_KEY_NAME
    fi

    if [[ "$B2_BUCKET" = "" ]]; then
        echo "B2 bucket not defined"
        echo -n "Enter the B2 bucket name: "
        read B2_BUCKET
    fi

    if [[ "$B2_ACCOUNT_ID" = "" ]]; then
        echo "B2 account ID not defined"
        echo -n "Enter the B2 account ID: "
        read B2_ACCOUNT_ID
    fi

    if [[ "$B2_ACCOUNT_KEY" = "" ]]; then
        echo "B2 account key not defined"
        echo -n "Enter the B2 account key: "
        read B2_ACCOUNT_KEY
    fi

    if [[ "$RESTIC_PASSWORD" = "" ]]; then
        echo "Restic password not defined"
        echo -n "Enter the restic password: "
        read RESTIC_PASSWORD
    fi

    qecho "Copying constants.sh to /tmp and applying configuration..."
    cp "$CONF_DIR/constants.sh" "/tmp/constants.sh"

    sed -i "/tmp/constants.sh" \
        -e "s/B2_KEY_NAME=.*$/B2_KEY_NAME='$B2_KEY_NAME'/" \
        -e "s/B2_BUCKET=.*$/B2_BUCKET='$B2_BUCKET'/" \
        -e "s/B2_ACCOUNT_ID=.*$/B2_ACCOUNT_ID='$B2_ACCOUNT_ID'/" \
        -e "s/B2_ACCOUNT_KEY=.*$/B2_ACCOUNT_KEY='$B2_ACCOUNT_KEY'/" \
        -e "s/RESTIC_PASSWORD=.*$/RESTIC_PASSWORD='$RESTIC_PASSWORD'/"
}

function install() {
    qecho "Copying backup scripts to $INSTALL_DIR..."
    sudo cp -rft "$INSTALL_DIR" "$BASE_DIR/backup"

    qecho "Copying service and timer files to $SYSTEMD_DIR..."
    sudo install -Dm 644 "$BASE_DIR/systemd/b2-backup.service" "$SYSTEMD_DIR/b2-backup.service"
    sudo install -Dm 644 "$BASE_DIR/systemd/b2-prune.service" "$SYSTEMD_DIR/b2-prune.service"
    sudo install -Dm 644 "$BASE_DIR/systemd/b2-backup.timer" "$SYSTEMD_DIR/b2-backup.timer"
    sudo install -Dm 644 "$BASE_DIR/systemd/b2-prune.timer" "$SYSTEMD_DIR/b2-prune.timer"

    qecho "Copying constants.sh to $INSTALL_DIR/backup"
    sudo mv "/tmp/constants.sh" "$INSTALL_DIR/backup"

    qecho "Done copying configuration for restic"
}

function post_install() {
    qecho "Enabling systemd timers..."
    sudo systemctl enable $SYSTEMD_FLAGS b2-backup.timer
    sudo systemctl enable $SYSTEMD_FLAGS b2-prune.timer
}

function uninstall() {
    qecho "Removing ${new_files[@]}..."
    sudo rm -rf "${new_files[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
