#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/restic-b2"
readonly SYSTEMD_DIR="/etc/systemd/system"
readonly INSTALL_DIR="/root"
readonly CONF_CONSTANTS_SH="$CONF_DIR/constants.sh"
readonly CONF_EXCLUDES_TXT="$CONF_DIR/excludes.txt"
readonly CONF_INCLUDES_TXT="$CONF_DIR/includes.txt"
readonly BASE_BACKUP_DIR="$BASE_DIR/backup"
readonly BASE_SYSTEMD_DIR="$BASE_DIR/systemd"
readonly NEW_BACKUP_DIR="$INSTALL_DIR/backup"
readonly NEW_CONSTANTS_SH="$NEW_BACKUP_DIR/constants.sh"
readonly NEW_EXCLUDES_TXT="$NEW_BACKUP_DIR/excludes.txt"
readonly NEW_INCLUDES_TXT="$NEW_BACKUP_DIR/includes.txt"
readonly TMP_CONSTANTS_SH="/tmp/constants.sh"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Restic B2 Backup Scripts"
readonly FEATURE_DESC="Install restic with B2 configuration"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_BACKUP_DIR" \
    "$NEW_BACKUP_DIR/b2.png" \
    "$NEW_BACKUP_DIR/backup.sh" \
    "$NEW_BACKUP_DIR/excludes.txt" \
    "$NEW_BACKUP_DIR/includes.txt" \
    "$NEW_BACKUP_DIR/prune.sh" \
    "$NEW_BACKUP_DIR/unset-constants.sh" \
    "$NEW_BACKUP_DIR/utils.sh" \
    "$SYSTEMD_DIR/b2-backup.service" \
    "$SYSTEMD_DIR/b2-backup.timer" \
    "$SYSTEMD_DIR/b2-prune.service" \
    "$SYSTEMD_DIR/b2-prune.timer" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=("$TMP_CONSTANTS_SH")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(restic)



function check_conf() (
    if [[ -f "$CONF_CONSTANTS_SH" ]] &&
        [[ -f "$CONF_INCLUDES_TXT" ]] &&
        [[ -f "$CONF_EXCLUDES_TXT" ]]; then
        source "$CONF_CONSTANTS_SH"

        qecho "Configuration is set correctly"
        return 0
    else
        echo "Configuration is not set properly" >&2
        return 1
    fi
)

function load_conf() {
    qecho "Reading configuration from $CONF_CONSTANTS_SH"
    source "$CONF_CONSTANTS_SH"
}

function check_install() {
    local f

    for f in "${NEW_FILES[@]}"; do
        if ! sudo test -e "$f"; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    qecho "$FEATURE_NAME is installed"
    return 0
}

function prepare() {
    if [[ "$NOTIFY_USER" = "" ]]; then
        echo "Notify user not defined"
        echo -n "Enter the username of the user to send notifications to: "
        read -r NOTIFY_USER
    fi

    if [[ "$B2_KEY_NAME" = "" ]]; then
        echo "B2 key not defined"
        read -rp "Enter the B2 key name: " B2_KEY_NAME
    fi

    if [[ "$B2_BUCKET" = "" ]]; then
        echo "B2 bucket not defined"
        read -rp "Enter the B2 bucket name: " B2_BUCKET
    fi

    if [[ "$B2_ACCOUNT_ID" = "" ]]; then
        echo "B2 account ID not defined"
        read -rp "Enter the B2 account ID: " B2_ACCOUNT_ID
    fi

    if [[ "$B2_ACCOUNT_KEY" = "" ]]; then
        echo "B2 account key not defined"
        read -rp "Enter the B2 account key: " B2_ACCOUNT_KEY
    fi

    if [[ "$RESTIC_PASSWORD" = "" ]]; then
        echo "Restic password not defined"
        read -rp "Enter the restic password: " RESTIC_PASSWORD
    fi

    qecho "Copying constants.sh to /tmp and applying configuration..."
    cp -f "$CONF_CONSTANTS_SH" "$TMP_CONSTANTS_SH"

    sed -i "$TMP_CONSTANTS_SH" \
        -e "s/B2_KEY_NAME=.*$/B2_KEY_NAME='$B2_KEY_NAME'/" \
        -e "s/B2_BUCKET=.*$/B2_BUCKET='$B2_BUCKET'/" \
        -e "s/B2_ACCOUNT_ID=.*$/B2_ACCOUNT_ID='$B2_ACCOUNT_ID'/" \
        -e "s/B2_ACCOUNT_KEY=.*$/B2_ACCOUNT_KEY='$B2_ACCOUNT_KEY'/" \
        -e "s/RESTIC_PASSWORD=.*$/RESTIC_PASSWORD='$RESTIC_PASSWORD'/"
}

function install() {
    qecho "Copying backup scripts to $INSTALL_DIR..."
    sudo cp -rfT "$BASE_BACKUP_DIR" "$NEW_BACKUP_DIR"

    qecho "Copying service and timer files to $SYSTEMD_DIR..."
    sudo cp -rfT "$BASE_SYSTEMD_DIR" "$SYSTEMD_DIR"

    qecho "Copying constants.sh to $NEW_CONSTANTS_SH"
    sudo mv "$TMP_CONSTANTS_SH" "$NEW_CONSTANTS_SH"

    qecho "Copying $CONF_INCLUDES_TXT to $NEW_INCLUDES_TXT..."
    sudo cp -f "$CONF_INCLUDES_TXT" "$NEW_INCLUDES_TXT"
    
    qecho "Copying $CONF_EXCLUDES_TXT to $NEW_EXCLUDES_TXT..."
    sudo cp -f "$CONF_EXCLUDES_TXT" "$NEW_EXCLUDES_TXT"

    qecho "Done copying configuration for restic"
}

function post_install() {
    qecho "Enabling systemd timers..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" b2-backup.timer
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" b2-prune.timer
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -rf "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
