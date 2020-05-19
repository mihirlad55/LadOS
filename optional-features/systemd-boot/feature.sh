#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="systemd-boot"
feature_desc="Install systemd-boot"

provides=()
new_files=("/boot/loader/entries/arch.conf" \
    "/boot/EFI/systemd/systemd-bootx64.efi" \
    "/boot/EFI/BOOT/BOOTX64.EFI")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(intel-ucode amd-ucode)



function check_install() {
    if diff /boot/loader/entries/arch.conf "$BASE_DIR/arch.conf" > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    # Normal output goes to stderr
    sudo bootctl install

    qecho "Installing boot entry>.."
    sudo mkdir -p /boot/loader/entries
    sudo install -Dm 755 $BASE_DIR/arch.conf /boot/loader/entries/arch.conf
}

function uninstall() {
    sudo bootctl uninstall

    qecho "Removing ${new_files[@]}..."
    sudo rm -f "${new_files[@]}"
}

source "$LAD_OS_DIR/common/feature_common.sh"

