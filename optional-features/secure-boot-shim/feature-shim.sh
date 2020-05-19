#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="signed-bootloader"
feature_desc="Setup computer to auto-sign bootloader for secure boot"

conflicts=()

provides=()

new_files=()
modified_files=()
temp_files=()

depends_aur=(shim-signed)
depends_pacman=(sbsigntools)
depends_pip3=()



function check_conf() {

}

function load_conf() {

}

function check_install() {

}

function prepare() {
    qecho "Creating machine owner key..."
    openssl req -newkey rsa:4096 -nodes -keyout MOK.key -new -x509 -sha256 \
        -days3650 -subj "/CN=$USER's Machine Owner Key/" -out MOK.crt
}

function install() {
    sudo install -Dm 655 /usr/share/shim-signed/shimx64.efi /boot/EFI/BOOT/BOOTX64.efi
    sudo install -Dm 655 /usr/share/shim-signed/mmx64.efi /boot/EFI/BOOT/mmx64.efi

    sbsign --key MOK.key --cert MOK.crt --output /boot/vmlinuz-linux /boot/vmlinuz-linux
    sbsign --key MOK.key --cert MOK.crt --output /boot/vmlinuz-linux /boot/vmlinuz-linux
}

function post_install() {

}

function cleanup() {

}

function uninstall() {

}


source "$LAD_OS_DIR/common/feature_common.sh"

