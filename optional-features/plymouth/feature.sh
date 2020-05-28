#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_DEUS_EX_DIR="$BASE_DIR/deus_ex"
readonly BASE_PLYMOUTHD_CONF="$BASE_DIR/plymouthd.conf"
readonly BASE_CMDLINE_CONF="$BASE_DIR/plymouth-cmdline.conf"
readonly BASE_DRACUT_CONF="$BASE_DIR/plymouth-dracut.conf"
readonly NEW_CMDLINE_CONF="/etc/cmdline.d/plymouth.conf"
readonly NEW_DRACUT_CONF="/etc/dracut.conf.d/plymouth-dracut.conf"
readonly NEW_DEUS_EX_DIR="/usr/share/plymouth/themes/deus_ex"
readonly MOD_PLYMOUTHD_CONF="/etc/plymouth/plymouthd.conf"
readonly DRACUT_INSTALL_SH="/usr/local/bin/dracut-install-default.sh"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Plymouth"
readonly FEATURE_DESC="Install plymouth with deus_ex theme"

readonly PROVIDES=()
readonly NEW_FILES=(
    "$NEW_DEUS_EX_DIR" \
    "$NEW_DRACUT_CONF" \
    "$NEW_CMDLINE_CONF" \
)
readonly MODIFIED_FILES=("$MOD_PLYMOUTHD_CONF")
    
readonly TEMP_FILES=()

readonly DEPENDS_AUR=(plymouth)
readonly DEPENDS_PACMAN=()



function check_install() {
    if diff "$BASE_DEUS_EX_DIR" "$NEW_DEUS_EX_DIR" &&
        diff "$BASE_PLYMOUTHD_CONF" "$MOD_PLYMOUTHD_CONF" &&
        diff "$BASE_DRACUT_CONF" "$NEW_DRACUT_CONF" &&
        diff "$BASE_CMDLINE_CONF" "$NEW_CMDLINE_CONF"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying theme..."
    sudo cp -rfT "$BASE_DEUS_EX_DIR" "$NEW_DEUS_EX_DIR"

    qecho "Copying $BASE_PLYMOUTHD_CONF to $MOD_PLYMOUTHD_CONF..."
    sudo install -Dm 644 "$BASE_PLYMOUTHD_CONF" "$MOD_PLYMOUTHD_CONF"

    qecho "Copying $BASE_DRACUT_CONF to $NEW_DRACUT_CONF..."
    sudo install -Dm 644 "$BASE_DRACUT_CONF" "$NEW_DRACUT_CONF"    

    qecho "Copying $BASE_CMDLINE_CONF to $NEW_CMDLINE_CONF..."
    sudo install -Dm 644 "$BASE_CMDLINE_CONF" "$NEW_CMDLINE_CONF"

    qecho "Updating image..."
    sudo "$DRACUT_INSTALL_SH"
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

    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"

    qecho "Removing $MOD_PLYMOUTHD_CONF..."
    rm -f "$MOD_PLYMOUTHD_CONF"

    qecho "Updating image..."
    sudo "$DRACUT_INSTALL_SH"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
