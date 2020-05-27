#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="cronie"
feature_desc="Install cronie and preset root crontab"

provides=()
new_files=("/var/spool/cron/root")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=("cronie")


function check_install() {
    qecho "Checking if root crontab matches $(cat "$BASE_DIR/root-cron")"
    if sudo diff /var/spool/cron/root "$BASE_DIR/root-cron"; then
        qecho "$feature_name is installed"
    else
        echo "$feature_name is not installed" >&2
    fi
}

function install() {
    qecho "Installing root crontab..."
    if [[ -n "$VERBOSITY" ]]; then cat "$BASE_DIR/root-cron"; fi
    sudo crontab "$BASE_DIR/root-cron"
}

function post_install() {
    qecho "Enabling cronie..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" cronie
}


source "$LAD_OS_DIR/common/feature_footer.sh"
