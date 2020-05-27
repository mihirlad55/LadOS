#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"

source "$LAD_OS_DIR/common/feature_header.sh"

PRELOADER_SIGNED_DIR="/usr/share/preloader-signed"
PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
REFIND_INSTALL_HOOK="$BASE_DIR/50-refind-install-preloader.hook"

feature_name="secure-boot-preloader"
feature_desc="Setup secure boot using preloader"

conflicts=('secure-boot-custom' 'secure-boot-shim')

provides=()

new_files=( \
    "/boot/EFI/refind/PreLoader.efi" \
    "/boot/EFI/refind/HashTool.efi" \
    "/boot/EFI/refind/loader.efi" \
    "$PACMAN_HOOKS_DIR/50-refind-install-preloader.hook"
)
modified_files=("/boot/EFI/refind/refinx_x64.efi")
temp_files=()

depends_aur=(preloader-signed)
depends_pacman=()
depends_pip3=()


function check_install() {
    for f in "${new_files[@]}"; do
        if ! sudo test -f "$f"; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function install() {
    qecho "Installing preloader efi binaries to /boot..."
    sudo refind-install --preloader "$PRELOADER_SIGNED_DIR/PreLoader.efi"

    qecho "Disabling default refind hook..."
    sudo mv "$PACMAN_HOOKS_DIR"/50-refind-install.{hook,disabled}

    qecho "Copying refind-install hook to $PACMAN_HOOKS_DIR..."
    sudo install -Dm 644 "$REFIND_INSTALL_HOOK" "$PACMAN_HOOKS_DIR/50-refind-install-preloader.hook"
}


function uninstall() {
    qecho "Removing ${new_files[*]}..."
    sudo rm -f "${new_files[@]}"

    qecho "Reinstalling rEFInd..."
    sudo refind-install

    qecho "Re-enabling default refind hook..."
    sudo mv "$PACMAN_HOOKS_DIR"/50-refind-install.{disabled,hook}
}

source "$LAD_OS_DIR/common/feature_footer.sh"

