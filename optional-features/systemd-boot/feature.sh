#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"
readonly ENTRIES_DIR="/boot/loader/entries"
readonly BASE_ARCH_CONF="$BASE_DIR/arch.conf"
readonly NEW_ARCH_CONF="$ENTRIES_DIR/arch.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="systemd-boot"
readonly FEATURE_DESC="Install systemd-boot"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_ARCH_CONF" \
    "/boot/EFI/systemd/systemd-bootx64.efi" \
    "/boot/EFI/BOOT/BOOTX64.EFI" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(intel-ucode amd-ucode)



function check_install() {
    if diff "$NEW_ARCH_CONF" "$BASE_ARCH_CONF" > /dev/null; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    sudo bootctl install

    qecho "Installing boot entry>.."
    sudo mkdir -p "$ENTRIES_DIR"
    sudo install -Dm 755 "$BASE_ARCH_CONF" "$NEW_ARCH_CONF"
}

function uninstall() {
    sudo bootctl uninstall

    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
