#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/secure-boot-shim"
SHIM_SIGNED_PATH="/usr/share/shim-signed"
PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
DRACUT_CONF_DIR="/etc/dracut.conf.d"
ROOT_KEYS_PATH="/root/sb-keys"

EFI_BINARIES=("/boot/vmlinuz-linux" \
    "/boot/EFI/BOOT/BOOTX64.EFI" \
    "/boot/EFI/refind/refind_x64.efi" \
    "/boot/EFI/systemd/systemd-bootx64.efi" \
    "/boot/linux.efi" \
    "/boot/linux-fallback.efi")

MOK_DIR="/tmp/MOK"
MOK_KEY="$MOK_DIR/MOK.key"
MOK_CRT="$MOK_DIR/MOK.crt"

feature_name="secure-boot-shim"
feature_desc="Setup secure boot using shim"

conflicts=('secure-boot-custom' 'secure-boot-preloader')

provides=()

new_files=( \
    "$ROOT_KEYS_PATH/MOK/MOK.key" \
    "$ROOT_KEYS_PATH/MOK/MOK.crt" \
)
modified_files=("${EFI_BINARIES[@]}")
temp_files=("$MOK_DIR")

depends_aur=(shim-signed)
depends_pacman=(sbsigntools)
depends_pip3=()



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
    if is_not_empty "$CONF_DIR/MOK/MOK.key" "$CONF_DIR/MOK/MOK.crt"; then
        qecho "Configuration is set correctly"        
        return 0
    else
        qecho "Configuration is not set correctly"
        return 1
    fi
}

function load_conf() {
    qecho "Copying keys from $CONF_DIR to /tmp"
    cp -rfT "$CONF_DIR/MOK" "$MOK_DIR"
}

function check_install() {
    for f in ${new_files[@]}; do
        if ! sudo test -f "$f"; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function prepare() {
    if ! is_not_empty "$MOK_KEY" "$MOK_CRT"; then
        qecho "Creating machine owner key..."
        openssl req -newkey rsa:4096 -nodes -keyout "$MOK_KEY" -new -x509 -sha256 \
            -days3650 -subj "/CN=$USER's Machine Owner Key/" -out "$MOK_CRT"
    else
        qecho "Machine owner keys found at $MOK_DIR. Not regenerating."
    fi
}

function install() {
    qecho "Installing shim efi binaries to /boot..."
    sudo install -Dm 655 "$SHIM_SIGNED_PATH/shimx64.efi" /boot/EFI/BOOT/BOOTX64.efi
    sudo install -Dm 655 "$SHIM_SIGNED_PATH/mmx64.efi" /boot/EFI/BOOT/mmx64.efi

    qecho "Signing EFI binaries..."

    for bin in "${EFI_BINARIES[@]}"; do
        if [[ -f "$bin" ]]; then
            if ! sbverify --cert "$MOK_CRT" "$bin"; then
                qecho "Signing $bin with signature database key..."
                sudo sbsign --key "$MOK_KEY" --cert "$MOK_CRT" --output "$bin" "$bin"
            else
                qecho "$bin is already signed. Not signing."
            fi
        else
            qecho "Not signing $bin. Not found."
        fi
    done

    qecho "Copying 99-secure-boot-custom.hook to $PACMAN_HOOKS_DIR..."
    sudo install -Dm 644 "$BASE_DIR/99-secure-boot-shim.hook" "$PACMAN_HOOKS_DIR/99-secure-boot-shim.hook"

    qecho "Copying sign-loaders.sh to /usr/local/bin..."
    sudo install -Dm 700 "$BASE_DIR/sign-loaders.sh" /usr/local/bin/sign-loaders.sh

    qecho "Copying sb-dracut.conf to $DRACUT_CONF_DIR..."
    sudo install -Dm 644 "$BASE_DIR/sb-dracut.conf" "$DRACUT_CONF_DIR/sb-dracut.conf"
}

function post_install() {
    qecho "Moving all keys to $ROOT_KEYS_PATH..."    
    sudo rm -rf "$ROOT_KEYS_PATH"
    sudo mkdir -p "$ROOT_KEYS_PATH"
    sudo mv -ft "$ROOT_KEYS_PATH" "$MOK_DIR"

    qecho "Setting strict permissions on $ROOT_KEYS_PATH"
    sudo chown -R root:root "$ROOT_KEYS_PATH"
    sudo chmod -R go-rwx "$ROOT_KEYS_PATH"
}

function uninstall() {
    qecho "Removing ${new_files[@]}..."
    sudo rm -rf "${new_files[@]}"

    qecho "Regenerating dracut image..."
    sudo /usr/local/bin/dracut-install-default.sh
}

function cleanup() {
    qecho "Removing ${temp_files[@]}..."
    sudo rm -rf "${temp_files[@]}"
}


source "$LAD_OS_DIR/common/feature_common.sh"

