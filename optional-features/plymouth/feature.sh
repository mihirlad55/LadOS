#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"


feature_name="plymouth"
feature_desc="Install plymouth with deus_ex theme"

provides=()
new_files=("/usr/share/plymouth/themes/deus_ex")
modified_files=("/etc/plymouth/plymouthd.conf" \
    "/etc/mkinitcpio.conf")
temp_files=()

depends_aur=(plymouth)
depends_pacman=()



function check_install() {
    if egrep -q /etc/mkinitcpio.conf -e "plymouth" &&
        diff $BASE_DIR/deus_ex /usr/share/plymouth/themes/deus_ex > "$DEFAULT_OUT" &&
        diff $BASE_DIR/plymouthd.conf /etc/plymouth/plymouthd.conf > "$DEFAULT_OUT"; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function add_mkinitcpio_hook() {
    module="$1"

    if ! egrep -q /etc/mkinitcpio.conf -e "$module"; then
        vecho "No $module hook found in mkinitcpio.conf"
        source /etc/mkinitcpio.conf
        HOOKS=( "${HOOKS[@]:0:2}" "$module" "${HOOKS[@]:2}" )

        IFS=$' '
        HOOKS_LINE="HOOKS=(${HOOKS[*]})"

        vecho "Adding $module to HOOKS array..."
        sudo sed -i '/etc/mkinitcpio.conf' -e "s/^HOOKS=([a-z ]*)$/$HOOKS_LINE/"
    else
        vecho "$module hook already added to mkinitcpio.conf"
    fi
}

function install() {
    qecho "Copying theme..."
    sudo cp -r $BASE_DIR/deus_ex /usr/share/plymouth/themes/

    qecho "Copying plymouth.d..."
    sudo install -Dm 644 $BASE_DIR/plymouthd.conf /etc/plymouth/plymouthd.conf

    qecho "Adding plymouth hook to mkinitcpio..."
    add_mkinitcpio_hook "plymouth"

    qecho "Updating mkinitcpio..."
    sudo mkinitcpio --nocolor -P linux > "$DEFAULT_OUT"
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

    qecho "Removing plymouth hook..."
    sudo sed -i /etc/mkinitcpio.conf -e "s/plymouth //"

    qecho "Removing ${new_files[@]}..."
    rm -f "${new_files[@]} /etc/plymouth/plymouthd.conf"
}


source "$LAD_OS_DIR/common/feature_common.sh"
