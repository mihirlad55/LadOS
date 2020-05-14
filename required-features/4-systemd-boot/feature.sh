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
temp_files=("/tmp/arch.conf")

depends_aur=()
depends_pacman=(intel-ucode amd-ucode)


function get_options_line() {
    swap_path=$(cat /etc/fstab | grep -P -B 1 \
        -e "UUID=[a-zA-Z0-9\-]*[\t ]+none[\t ]+swap" | head -n1 | sed 's/# *//')
    root_path=$(cat /etc/fstab | grep -P -B 1 \
        -e "UUID=[a-zA-Z0-9\-]*[\t ]+/[\t ]+" | head -n1 | sed 's/# *//')

    partuuid=$(blkid -s PARTUUID -o value $root_path)

    options="options root=PARTUUID=$partuuid rw add_efi_memmap resume=$swap_path"

    echo "$options"
}

function check_install() {
    options="$(get_options_line)"

    contents="$(cat $BASE_DIR/arch.conf | sed -e "s;^options root=.*$;$options;")"

    if diff /boot/loader/entries/arch.conf <(echo "$contents") > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function prepare() {
    cp $BASE_DIR/arch.conf /tmp/arch.conf

    options="$(get_options_line)"

    sed -i /tmp/arch.conf -e "s;^options root=.*$;$options;"

    echo "Opening configuration files for any changes. The root PARTUUID has already been set along with the swap paritition path for resume"
    read -p "Press enter to continue..."

    if [[ "$EDITOR" != "" ]]; then
        $EDITOR /tmp/arch.conf
    else
        vim /tmp/arch.conf
    fi
}

function install() {
    sudo bootctl install

    qecho "Installing boot entry>.."
    sudo mkdir -p /boot/loader/entries
    sudo install -Dm 755 /tmp/arch.conf /boot/loader/entries/arch.conf
}


function cleanup() {
    qecho "Removing /tmp/arch.conf..."
    rm -f /tmp/arch.conf
}

source "$LAD_OS_DIR/common/feature_common.sh"

