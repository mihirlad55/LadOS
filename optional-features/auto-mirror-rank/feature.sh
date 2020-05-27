#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"

source "$LAD_OS_DIR/common/feature_header.sh"

SERVICE_FILE="/etc/systemd/system/auto-mirror-rank.service"
UPDATE_PACMAN_MIRRORS_SCRIPT="/usr/local/bin/update-pacman-mirrors"

feature_name="Auto Mirror Rank"
feature_desc="Rank pacman mirrors on startup"

conflicts=()

provides=()
new_files=("$SERVICE_FILE" "$UPDATE_PACMAN_MIRRORS_FILE")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(pacman-contrib)
depends_pip3=()



function check_install() {
    for f in "${new_files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function install() {
    qecho "Copying update-pacman-mirrors to /usr/local/bin..."
    sudo install -Dm 755 "$BASE_DIR/update-pacman-mirrors" "$UPDATE_PACMAN_MIRRORS_SCRIPT"

    qecho "Copying auto-mirror-rank.service to /etc/systemd/system..."
    sudo install -Dm 644 "$BASE_DIR/auto-mirror-rank.service" "$SERVICE_FILE"
}

function post_install() {
    qecho "Enabling auto-mirror-rank.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" "auto-mirror-rank.service"
}

function uninstall() {
    qecho "Removing ${new_files[*]}..."
    sudo rm -f "${new_files[@]}"
}

source "$LAD_OS_DIR/common/feature_footer.sh"

# vim:ft=sh
