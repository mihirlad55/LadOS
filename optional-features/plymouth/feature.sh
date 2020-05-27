#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
DRACUT_CONF_DIR="/etc/dracut.conf.d"
CMDLINE_DIR="/etc/cmdline.d"
CMDLINE_FILE="$CMDLINE_DIR/plymouth.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="plymouth"
feature_desc="Install plymouth with deus_ex theme"

provides=()
new_files=(
    "/usr/share/plymouth/themes/deus_ex" \
    "$DRACUT_CONF_DIR/plymouth-dracut.conf" \
    "$CMDLINE_FILE" \
)
modified_files=("/etc/plymouth/plymouthd.conf")
    
temp_files=()

depends_aur=(plymouth)
depends_pacman=()



function check_install() {
    if diff "$BASE_DIR/deus_ex" /usr/share/plymouth/themes/deus_ex &&
        diff "$BASE_DIR/plymouthd.conf" /etc/plymouth/plymouthd.conf &&
        diff "$BASE_DIR/plymouth-dracut.conf" "$DRACUT_CONF_DIR/plymouth-dracut.conf" &&
        diff "$BASE_DIR/plymouth-cmdline.conf" "$CMDLINE_FILE"; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying theme..."
    sudo cp -rft /usr/share/plymouth/themes "$BASE_DIR/deus_ex"

    qecho "Copying plymouth.d..."
    sudo install -Dm 644 "$BASE_DIR/plymouthd.conf" /etc/plymouth/plymouthd.conf

    qecho "Copying plymouth-dracut.conf to $DRACUT_CONF_DIR..."
    sudo install -Dm 644 "$BASE_DIR/plymouth-dracut.conf" "$DRACUT_CONF_DIR/plymouth-dracut.conf"    

    qecho "Copying plymouth-cmdline.conf to $CMDLINE_DIR..."
    sudo install -Dm 644 "$BASE_DIR/plymouth-cmdline.conf" "$CMDLINE_FILE"

    qecho "Updating image..."
    sudo /usr/local/bin/dracut-install-default.sh
}

function post_install() {
    qecho "Disabling lightdm.service..."
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" lightdm
    qecho "Enabling lightdm-plymouth.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" lightdm-plymouth
}

function uninstall() {
    qecho "Disbaling lightdm-plymouth.service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" lightdm-plymouth

    qecho "Enabling lightdm.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" lightdm

    qecho "Removing ${new_files[*]}..."
    rm -f "${new_files[@]}"

    qecho "Removing /etc/plymouth/plymouthd.conf..."
    rm -f "/etc/plymouth/plymouthd.conf"

    qecho "Updating image..."
    sudo /usr/local/bin/dracut-install-default.sh
}


source "$LAD_OS_DIR/common/feature_footer.sh"
