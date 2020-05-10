#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

NEW_MODULES=("vfio_pci" "vfio" "vfio_iommu_type1" "vfio_virqfd")

feature_name="setup-gpu-passthrough"
feature_desc="Setup GPU passthrough"

provides=()
new_files=("/etc/modprobe.d/nothunderbolt.conf")
modified_files=("/etc/mkinitcpio.conf")
temp_files=()

depends_aur=()
depends_pacman=()


function check_install() {
    for mod in ${NEW_MODULES[@]}; do
        if ! grep /etc/mkinitcpio.conf -e "$mod" > /dev/null; then
            echo "$mod is missing from mkinitcpio.conf"
            echo "$feature_name is not installed"
            return 1
        fi
    done

    if [[ ! -f "/etc/modprobe.d/nothunderbolt.conf" ]]; then
        echo "/etc/modprobe.d/nothunderbolt.conf is missing"
        echo "$feature_name is not installed"
        return 1
    fi

    echo "$feature_name is installed"
    return 0
}

function install() {
    echo "Adding ${NEW_MODULES[@]} to /etc/mkinitcpio.conf, if not present"
    source /etc/mkinitcpio.conf
    for module in ${NEW_MODULES[@]}; do
        if ! echo ${MODULES[@]} | grep "$module" > /dev/null; then
            echo $MODULES
            echo "$module not found in mkinitcpio.conf"

            echo "Adding $module to mkinitcpio.conf"
            MODULES=( "${MODULES[@]}" "$module" )
        else
            echo "$module found in mkinitcpio.conf."
        fi
    done

    echo "Updating /etc/mkinitcpio.conf..."
    MODULES_LINE="MODULES=(${MODULES[@]})"
    sudo sed -i '/etc/mkinitcpio.conf' -e "s/^MODULES=([a-z0-9 ]*)$/$MODULES_LINE/"

    echo "Rebuilding initframfs..."

    sudo mkinitcpio -P linux

    sudo install -Dm 644 $BASE_DIR/nothunderbolt.conf /etc/modprobe.d/nothunderbolt.conf

    echo "Done"
    echo "Make sure you have virtualization enabled in your BIOS"
}


source "$LAD_OS_DIR/common/feature_common.sh"
