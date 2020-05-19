#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
DRACUT_CONF_DIR="/etc/dracut.conf.d"


feature_name="plymouth"
feature_desc="Install plymouth with deus_ex theme"

provides=()
new_files=("/usr/share/plymouth/themes/deus_ex")
modified_files=("/etc/plymouth/plymouthd.conf" \
    "$DRACUT_CONF_DIR/plymouth-dracut.conf")
    
temp_files=()

depends_aur=(plymouth)
depends_pacman=()



function check_install() {
    if diff $BASE_DIR/deus_ex /usr/share/plymouth/themes/deus_ex &&
        diff $BASE_DIR/plymouthd.conf /etc/plymouth/plymouthd.conf &&
        diff $BASE_DIR/plymouth-dracut.conf $DRACUT_CONF_DIR/plymouth-dracut.conf; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying theme..."
    sudo cp -r $BASE_DIR/deus_ex /usr/share/plymouth/themes/

    qecho "Copying plymouth.d..."
    sudo install -Dm 644 $BASE_DIR/plymouthd.conf /etc/plymouth/plymouthd.conf

    qecho "Copying plymouth-dracut.conf to $DRACUT_CONF_DIR..."
    sudo install -Dm 644 "$BASE_DIR/plymouth-dracut.conf" "$DRACUT_CONF_DIR/plymouth-dracut.conf"    

    qecho "Updating image..."
    sudo /usr/local/bin/dracut-install-default.sh
}

function post_install() {
    qecho "Disabling lightdm.service..."
    sudo systemctl disable -f $VERBOSITY_FLAG lightdm
    qecho "Enabling lightdm-plymouth.service"
    sudo systemctl enable -f ${SYSTEMD_FLAGS[*]} lightdm-plymouth
}

function uninstall() {
    qecho "Disbaling lightdm-plymouth.service"
    sudo systemctl disable -f ${SYSTEMD_FLAGS[*]} lightdm-plymouth

    qecho "Enabling lightdm.service..."
    sudo systemctl enable -f $VERBOSITY_FLAG lightdm

    qecho "Removing ${new_files[@]}..."
    rm -f "${new_files[@]} /etc/plymouth/plymouthd.conf"

    qecho "Updating image..."
    sudo /usr/local/bin/dracut-install-default.sh
}


source "$LAD_OS_DIR/common/feature_common.sh"
