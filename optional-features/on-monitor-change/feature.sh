#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_RULES="$BASE_DIR/50-monitor.rules"
readonly BASE_SH="$BASE_DIR/fix-monitor-layout"
readonly BASE_SVC="$BASE_DIR/on-monitor-change@.service"
readonly NEW_RULES="/etc/udev/rules.d/50-monitor.rules"
readonly NEW_SH="/usr/local/bin/fix-monitor-layout"
readonly NEW_SVC="/etc/systemd/user/on-monitor-change@.service"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="On Monitor Change Service"
readonly FEATURE_DESC="Install on-monitor-change udev rule and service that \
automatically outputs to newly connected monitors and restarts polybar"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_RULES" \
    "$NEW_SH" \
    "$NEW_SVC" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(xorg-xrandr)



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

function install() {
    qecho "Installing configuration files..."
    sudo install -Dm 755 "$BASE_RULES" "$NEW_RULES"
    sudo install -Dm 755 "$BASE_SH" "$NEW_SH"
    sudo install -Dm 644 "$BASE_SVC" "$NEW_SVC"
}

function post_install() {
    qecho "Reloading udev rules..."
    sudo udevadm control --reload
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
