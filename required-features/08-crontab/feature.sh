#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_ROOT_CRON="$BASE_DIR/root-cron"
readonly MOD_ROOT_CRON="/var/spool/cron/root"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="cronie"
readonly FEATURE_DESC="Install cronie and preset root crontab"
readonly PROVIDES=()
readonly NEW_FILES=("$MOD_ROOT_CRON")
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=("cronie")



function check_install() {
    qecho "Checking if root crontab matches $(cat "$BASE_ROOT_CRON")"
    if sudo diff "$MOD_ROOT_CRON" "$BASE_ROOT_CRON"; then
        qecho "$FEATURE_NAME is installed"
    else
        echo "$FEATURE_NAME is not installed" >&2
    fi
}

function install() {
    qecho "Installing root crontab..."
    if [[ -n "$VERBOSITY" ]]; then cat "$BASE_ROOT_CRON"; fi
    sudo crontab "$BASE_ROOT_CRON"
}

function post_install() {
    qecho "Enabling cronie..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" cronie
}


source "$LAD_OS_DIR/common/feature_footer.sh"
