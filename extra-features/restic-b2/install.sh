#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
CONF_DIR="$( readlink -f "$BASE_DIR/../../conf/restic" )"

TARGET_CONSTANTS_PATH="$HOME/.scripts/backup/constants.sh"

sudo pacman -S restic --needed --noconfirm

echo "Reading defaults from $CONF_DIR/constants.sh"
source "$CONF_DIR/constants.sh"

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


echo "Copying configuration to $TARGET_CONSTANTS_PATH"

sed -i "$TARGET_CONSTANTS_PATH" -e "s/B2_KEY_NAME=.*$/B2_KEY_NAME='$B2_KEY_NAME'/"
sed -i "$TARGET_CONSTANTS_PATH" -e "s/B2_BUCKET=.*$/B2_BUCKET='$B2_BUCKET'/"
sed -i "$TARGET_CONSTANTS_PATH" -e "s/B2_ACCOUNT_ID=.*$/B2_ACCOUNT_ID='$B2_ACCOUNT_ID'/"
sed -i "$TARGET_CONSTANTS_PATH" -e "s/B2_ACCOUNT_KEY=.*$/B2_ACCOUNT_KEY='$B2_ACCOUNT_KEY'/"
sed -i "$TARGET_CONSTANTS_PATH" -e "s/RESTIC_PASSWORD=.*$/RESTIC_PASSWORD='$RESTIC_PASSWORD'/"

echo "Done copying configuration for restic"
