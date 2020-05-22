#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/restic-b2"
TARGET_CONSTANTS_PATH="$HOME/.scripts/backup/constants.sh"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="restic-b2"
feature_desc="Install restic with B2 configuration"

provides=()
new_files=()
modified_files=("$TARGET_CONSTANTS_PATH")
temp_files=()

depends_aur=()
depends_pacman=(restic)


function check_conf() (
    [[ -f "$CONF_DIR/constants.sh" ]] && source "$CONF_DIR/constants.sh"
    res="$?"

    if [[ "$?" -eq 0 ]]; then
        qecho "Configuration is formatted correctly"
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

    if [[ "$B2_KEY_NAME" != "" ]] &&
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
}

function install() {
    qecho "Copying configuration to $TARGET_CONSTANTS_PATH"

    sed -i "$TARGET_CONSTANTS_PATH" \
        -e "s/B2_KEY_NAME=.*$/B2_KEY_NAME='$B2_KEY_NAME'/" \
        -e "s/B2_BUCKET=.*$/B2_BUCKET='$B2_BUCKET'/" \
        -e "s/B2_ACCOUNT_ID=.*$/B2_ACCOUNT_ID='$B2_ACCOUNT_ID'/" \
        -e "s/B2_ACCOUNT_KEY=.*$/B2_ACCOUNT_KEY='$B2_ACCOUNT_KEY'/" \
        -e "s/RESTIC_PASSWORD=.*$/RESTIC_PASSWORD='$RESTIC_PASSWORD'/"

    qecho "Done copying configuration for restic"
}

function uninstall() {
    qecho "Resetting configuration at $TARGET_CONSTANTS_PATH..."
    sed -i "$TARGET_CONSTANTS_PATH" \
        -e "s/^B2_KEY_NAME=.*/B2_KEY_NAME=/" \
        -e "s/^B2_BUCKET=.*/B2_BUCKET=/" \
        -e "s/^B2_ACCOUNT_ID=.*/B2_ACCOUNT_ID=/" \
        -e "s/^B2_ACCOUNT_KEY=.*/B2_ACCOUNT_KEY=/" \
        -e "s/^RESTIC_PASSWORD=.*/RESTIC_PASSWORD="
}


source "$LAD_OS_DIR/common/feature_footer.sh"
