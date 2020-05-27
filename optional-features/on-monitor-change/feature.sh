#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="on-monitor-change"
feature_desc="Install on-monitor-change udev rule and service that automatically outputs to newly connected monitors and restarts polybar"

provides=()
new_files=("/etc/udev/rules.d/50-monitor.rules" \
    "/usr/local/bin/fix-monitor-layout" \
    "/etc/systemd/user/on-monitor-change@.service")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(xorg-xrandr)


function check_install() {
    for f in "${new_files[@]}"; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function install() {
    qecho "Installing configuration files..."
    sudo install -Dm 755 "$BASE_DIR/50-monitor.rules" /etc/udev/rules.d/50-monitor.rules
    sudo install -Dm 755 "$BASE_DIR/fix-monitor-layout" /usr/local/bin/fix-monitor-layout
    sudo install -Dm 644 "$BASE_DIR/on-monitor-change@.service" /etc/systemd/user/on-monitor-change@.service
}

function post_install() {
    qecho "Reloading udev rules..."
    sudo udevadm control --reload
}

function uninstall() {
    qecho "Removing ${new_files[*]}..."
    rm -f "${new_files[@]}"
}

source "$LAD_OS_DIR/common/feature_footer.sh"
