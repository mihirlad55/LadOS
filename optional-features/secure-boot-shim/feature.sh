#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/secure-boot-shim"
readonly PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
readonly DRACUT_CONF_DIR="/etc/dracut.conf.d"
readonly SHIM_SIGNED_DIR="/usr/share/shim-signed"
readonly SHIM_SIGNED_EFI="$SHIM_SIGNED_DIR/shimx64.efi"
readonly MMX_SIGNED_EFI="$SHIM_SIGNED_DIR/mmx64.efi"
readonly DRACUT_INSTALL_SH="/usr/local/bin/dracut-install-default.sh"
readonly BASE_PACMAN_HOOK="$BASE_DIR/99-secure-boot-shim.hook"
readonly BASE_SIGN_LOADERS_SH="$BASE_DIR/sign-loaders.sh"
readonly BASE_DRACUT_CONF="$BASE_DIR/sb-dracut.conf"
readonly NEW_PACMAN_HOOK="$PACMAN_HOOKS_DIR/99-secure-boot-shim.hook"
readonly NEW_SIGN_LOADERS_SH="/usr/local/bin/sign-loaders.sh"
readonly NEW_DRACUT_CONF="$DRACUT_CONF_DIR/sb-dracut.conf"
readonly NEW_SHIM_SIGNED_EFI="/boot/EFI/BOOT/BOOTX64.efi"
readonly NEW_MMX_SIGNED_EFI="/boot/EFI/BOOT/mmx64.efi"
readonly NEW_ROOT_KEYS_DIR="/root/sb-keys"
readonly NEW_MOK_DIR="$NEW_ROOT_KEYS_DIR/MOK"
readonly NEW_MOK_KEY="$NEW_ROOT_KEYS_DIR/MOK.key"
readonly NEW_MOK_CRT="$NEW_ROOT_KEYS_DIR/MOK.crt"
readonly TMP_MOK_DIR="/tmp/MOK"
readonly TMP_MOK_KEY="$TMP_MOK_DIR/MOK.key"
readonly TMP_MOK_CRT="$TMP_MOK_DIR/MOK.crt"
readonly CONF_MOK_DIR="$CONF_DIR/MOK"
readonly CONF_MOK_KEY="$CONF_MOK_DIR/MOK.key"
readonly CONF_MOK_CRT="$CONF_MOK_DIR/MOK.crt"
readonly EFI_BINARIES=( \
    "/boot/vmlinuz-linux" \
    "/boot/EFI/BOOT/BOOTX64.EFI" \
    "/boot/EFI/refind/refind_x64.efi" \
    "/boot/EFI/systemd/systemd-bootx64.efi" \
    "/boot/linux.efi" \
    "/boot/linux-fallback.efi" \
)

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="secure-boot-shim"
readonly FEATURE_DESC="Setup secure boot using shim"
readonly CONFLICTS=('secure-boot-custom' 'secure-boot-preloader')
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_MOK_DIR" \
    "$NEW_MOK_KEY" \
    "$NEW_MOK_CRT" \
    "$NEW_SHIM_SIGNED_EFI" \
    "$NEW_MMX_SIGNED_EFI" \
)
readonly MODIFIED_FILES=("${EFI_BINARIES[@]}")
readonly TEMP_FILES=("$TMP_MOK_DIR")
readonly DEPENDS_AUR=(shim-signed)
readonly DEPENDS_PACMAN=(sbsigntools)
readonly DEPENDS_PIP3=()



################################################################################
# Check if any of the given paths exist and are not empty
#   Globals:
#     None
#   Arguments:
#      Paths to files, each path is a separate arugment
#   Outputs:
#      Prints if files at path exist/dont't exist and if they are empty only
#      with higher script verbosity
#   Returns:
#      0 if all paths are to files that exist and are non-empty
#      1 if any of the paths are to non-existent files or empty files
################################################################################
function is_not_empty() {
    local path contents

    for path in "$@"; do
        if [[ -f "$path" ]]; then
            vecho "$path exists"
            mapfile -t contents < "$path"

            if [[ "${contents[*]}" = "" ]]; then
                vecho "$path is empty"
                return 1
            fi
        else
            vecho "$path does not exist"
            return 1
        fi
    done

    return 0
}

function check_conf() {
    if is_not_empty "$CONF_MOK_KEY" "$CONF_MOK_CRT"; then
        qecho "Configuration is set correctly"        
        return 0
    else
        qecho "Configuration is not set correctly"
        return 1
    fi
}

function load_conf() {
    qecho "Copying keys from $CONF_DIR to /tmp"
    cp -rfT "$CONF_MOK_DIR" "$TMP_MOK_DIR"
}

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

function prepare() {
    if ! is_not_empty "$TMP_MOK_KEY" "$TMP_MOK_CRT"; then
        qecho "Creating machine owner key..."
        openssl req -newkey rsa:4096 -nodes -keyout "$TMP_MOK_KEY" \
            -new -x509 -sha256 -days3650 \
            -subj "/CN=$USER's Machine Owner Key/" -out "$TMP_MOK_CRT"
    else
        qecho "Machine owner keys found at $TMP_MOK_DIR. Not regenerating."
    fi
}

function install() {
    local bin

    qecho "Installing shim efi binaries to /boot..."
    sudo install -Dm 755 "$SHIM_SIGNED_EFI" "$NEW_SHIM_SIGNED_EFI"
    sudo install -Dm 755 "$MMX_SIGNED_EFI" "$NEW_MMX_SIGNED_EFI"

    qecho "Signing EFI binaries..."

    for bin in "${EFI_BINARIES[@]}"; do
        if [[ -f "$bin" ]]; then
            if ! sbverify --cert "$TMP_MOK_CRT" "$bin"; then
                qecho "Signing $bin with signature database key..."
                sudo sbsign --key "$TMP_MOK_KEY" --cert "$TMP_MOK_CRT" \
                    --output "$bin" "$bin"
            else
                qecho "$bin is already signed. Not signing."
            fi
        else
            qecho "Not signing $bin. Not found."
        fi
    done

    qecho "Copying $BASE_PACMAN_HOOK to $NEW_PACMAN_HOOK..."
    sudo install -Dm 644 "$BASE_PACMAN_HOOK" "$NEW_PACMAN_HOOK"

    qecho "Copying $BASE_SIGN_LOADERS_SH to $NEW_SIGN_LOADERS_SH..."
    sudo install -Dm 700 "$BASE_SIGN_LOADERS_SH" "$NEW_SIGN_LOADERS_SH"

    qecho "Copying $BASE_DRACUT_CONF to $NEW_DRACUT_CONF..."
    sudo install -Dm 644 "$BASE_DRACUT_CONF" "$NEW_DRACUT_CONF"
}

function post_install() {
    qecho "Moving all keys to $NEW_ROOT_KEYS_DIR..."    
    sudo rm -rf "$NEW_ROOT_KEYS_DIR"
    sudo mkdir -p "$NEW_ROOT_KEYS_DIR"
    sudo mv -ft "$NEW_ROOT_KEYS_DIR" "$TMP_MOK_DIR"

    qecho "Setting strict permissions on $NEW_ROOT_KEYS_DIR"
    sudo chown -R root:root "$NEW_ROOT_KEYS_DIR"
    sudo chmod -R go-rwx "$NEW_ROOT_KEYS_DIR"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -rf "${NEW_FILES[@]}"

    qecho "Regenerating dracut image..."
    sudo "$DRACUT_INSTALL_SH"
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    sudo rm -rf "${TEMP_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
