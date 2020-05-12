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
    if egrep /etc/mkinitcpio.conf -e "plymouth" > /dev/null &&
        diff $BASE_DIR/deus_ex /usr/share/plymouth/themes/deus_ex &&
        diff $BASE_DIR/plymouthd.conf /etc/plymouth/plymouthd.conf; then
        echo "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi
}

function add_mkinitcpio_hook() {
    module="$1"

    if ! egrep /etc/mkinitcpio.conf -e "$module" > /dev/null; then
        echo "No $module hook found in mkinitcpio.conf"
        source /etc/mkinitcpio.conf
        HOOKS=( "${HOOKS[@]:0:2}" "$module" "${HOOKS[@]:2}" )

        IFS=$' '
        HOOKS_LINE="HOOKS=(${HOOKS[*]})"

        echo "Adding $module to HOOKS array..."
        sudo sed -i '/etc/mkinitcpio.conf' -e "s/^HOOKS=([a-z ]*)$/$HOOKS_LINE/"
    else
        echo "$module hook already added to mkinitcpio.conf"
    fi
}

function install() {
    sudo cp -r $BASE_DIR/deus_ex /usr/share/plymouth/themes/
    sudo install -Dm 644 $BASE_DIR/plymouthd.conf /etc/plymouth/plymouthd.conf

    add_mkinitcpio_hook "plymouth"

    sudo mkinitcpio -P linux
}

function post_install() {
    echo "Disabling lightdm.service..."
    sudo systemctl disable lightdm
    echo "Enabling lightdm-plymouth.service"
    sudo systemctl enable lightdm-plymouth
}


source "$LAD_OS_DIR/common/feature_common.sh"
