#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly PRELOADER_SIGNED_DIR="/usr/share/preloader-signed"
readonly PRELOADER_EFI="$PRELOADER_SIGNED_DIR/PreLoader.efi"
readonly PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
readonly BASE_PRELOADER_HOOK="$BASE_DIR/50-refind-install-preloader.hook"
readonly NEW_PRELOADER_HOOK="$PACMAN_HOOKS_DIR/50-refind-install-preloader.hook"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Secure Boot Using Preloader"
readonly FEATURE_DESC="Setup secure boot using preloader"
readonly CONFLICTS=('secure-boot-custom' 'secure-boot-shim')
readonly PROVIDES=()
readonly NEW_FILES=( \
    "/boot/EFI/refind/PreLoader.efi" \
    "/boot/EFI/refind/HashTool.efi" \
    "/boot/EFI/refind/loader.efi" \
    "$NEW_PRELOADER_HOOK"
)
readonly MODIFIED_FILES=("/boot/EFI/refind/refinx_x64.efi")
readonly TEMP_FILES=()
readonly DEPENDS_AUR=(preloader-signed)
readonly DEPENDS_PACMAN=()
readonly DEPENDS_PIP3=()



function check_install() {
    local f

    for f in "${NEW_FILES[@]}"; do
        if ! sudo test -f "$f"; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    qecho "$FEATURE_NAME is installed"
    return 0
}

function install() {
    qecho "Installing preloader efi binaries to /boot..."
    sudo refind-install --preloader "$PRELOADER_EFI"

    qecho "Disabling default refind hook..."
    sudo mv "$PACMAN_HOOKS_DIR"/50-refind-install.{hook,disabled}

    qecho "Copying refind-install hook to $PACMAN_HOOKS_DIR..."
    sudo install -Dm 644 "$BASE_PRELOADER_HOOK" "$NEW_PRELOADER_HOOK"
}


function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"

    qecho "Reinstalling rEFInd..."
    sudo refind-install

    qecho "Re-enabling default refind hook..."
    sudo mv "$PACMAN_HOOKS_DIR"/50-refind-install.{disabled,hook}
}


source "$LAD_OS_DIR/common/feature_footer.sh"
