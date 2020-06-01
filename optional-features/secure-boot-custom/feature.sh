#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/secure-boot-custom"
readonly PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
readonly DRACUT_CONF_DIR="/etc/dracut.conf.d"
readonly BASE_SIGN_LOADERS_SH="$BASE_DIR/sign-loaders.sh"
readonly BASE_PACMAN_HOOK="$BASE_DIR/99-secure-boot-custom.hook"
readonly BASE_DRACUT_CONF="$BASE_DIR/sb-dracut.conf"
readonly NEW_BOOT_KEYS_DIR="/boot/sb-keys"
readonly NEW_ROOT_KEYS_DIR="/root/sb-keys"
readonly NEW_SIGN_LOADERS_SH="/usr/local/bin/sign-loaders.sh"
readonly NEW_PACMAN_HOOK="$PACMAN_HOOKS_DIR/90-secure-boot-custom.hook"
readonly NEW_DRACUT_CONF="$DRACUT_CONF_DIR/sb-dracut.conf"
readonly TMP_GUID_TXT="/tmp/GUID.txt"
readonly TMP_PK_DIR="/tmp/PK"
readonly TMP_PK_KEY="$TMP_PK_DIR/PK.key"
readonly TMP_PK_CER="$TMP_PK_DIR/PK.cer"
readonly TMP_PK_CRT="$TMP_PK_DIR/PK.crt"
readonly TMP_PK_ESL="$TMP_PK_DIR/PK.esl"
readonly TMP_PK_AUTH="$TMP_PK_DIR/PK.auth"
readonly TMP_KEK_DIR="/tmp/KEK"
readonly TMP_KEK_KEY="$TMP_KEK_DIR/KEK.key"
readonly TMP_KEK_CER="$TMP_KEK_DIR/KEK.cer"
readonly TMP_KEK_CRT="$TMP_KEK_DIR/KEK.crt"
readonly TMP_KEK_ESL="$TMP_KEK_DIR/KEK.esl"
readonly TMP_KEK_AUTH="$TMP_KEK_DIR/KEK.auth"
readonly TMP_DB_DIR="/tmp/db"
readonly TMP_DB_KEY="$TMP_DB_DIR/db.key"
readonly TMP_DB_CER="$TMP_DB_DIR/db.cer"
readonly TMP_DB_CRT="$TMP_DB_DIR/db.crt"
readonly TMP_DB_ESL="$TMP_DB_DIR/db.esl"
readonly TMP_DB_AUTH="$TMP_DB_DIR/db.auth"
readonly CONF_GUID_TXT="$CONF_DIR/GUID.txt"
readonly CONF_PK_DIR="$CONF_DIR/PK"
readonly CONF_PK_KEY="$CONF_PK_DIR/PK.key"
readonly CONF_PK_CER="$CONF_PK_DIR/PK.cer"
readonly CONF_PK_CRT="$CONF_PK_DIR/PK.crt"
readonly CONF_PK_ESL="$CONF_PK_DIR/PK.esl"
readonly CONF_PK_AUTH="$CONF_PK_DIR/PK.auth"
readonly CONF_KEK_DIR="$CONF_DIR/KEK"
readonly CONF_KEK_KEY="$CONF_KEK_DIR/KEK.key"
readonly CONF_KEK_CER="$CONF_KEK_DIR/KEK.cer"
readonly CONF_KEK_CRT="$CONF_KEK_DIR/KEK.crt"
readonly CONF_KEK_ESL="$CONF_KEK_DIR/KEK.esl"
readonly CONF_KEK_AUTH="$CONF_KEK_DIR/KEK.auth"
readonly CONF_DB_DIR="$CONF_DIR/db"
readonly CONF_DB_KEY="$CONF_DB_DIR/db.key"
readonly CONF_DB_CER="$CONF_DB_DIR/db.cer"
readonly CONF_DB_CRT="$CONF_DB_DIR/db.crt"
readonly CONF_DB_ESL="$CONF_DB_DIR/db.esl"
readonly CONF_DB_AUTH="$CONF_DB_DIR/db.auth"
readonly DRACUT_INSTALL_SH="/usr/local/bin/dracut-install-default.sh"
readonly EFI_BINARIES=( \
    "/boot/vmlinuz-linux" \
    "/boot/EFI/BOOT/BOOTX64.EFI" \
    "/boot/EFI/refind/refind_x64.efi" \
    "/boot/EFI/systemd/systemd-bootx64.efi" \
    "/boot/linux.efi" \
    "/boot/linux-fallback.efi" \
)

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Secure Boot (Custom Keys)"
readonly FEATURE_DESC="Setup computer to auto-sign bootloader for secure boot \
using custom keys"
readonly CONFLICTS=('secure-boot-shim' 'secure-boot-preloader')
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_BOOT_KEYS_DIR/PK.auth" \
    "$NEW_BOOT_KEYS_DIR/KEK.auth" \
    "$NEW_BOOT_KEYS_DIR/db.auth" \
    "$NEW_ROOT_KEYS_DIR/GUID.txt" \
    "$NEW_ROOT_KEYS_DIR/PK/" \
    "$NEW_ROOT_KEYS_DIR/PK/PK.key" \
    "$NEW_ROOT_KEYS_DIR/PK/PK.crt" \
    "$NEW_ROOT_KEYS_DIR/PK/PK.cer" \
    "$NEW_ROOT_KEYS_DIR/PK/PK.esl" \
    "$NEW_ROOT_KEYS_DIR/PK/PK.auth" \
    "$NEW_ROOT_KEYS_DIR/KEK/" \
    "$NEW_ROOT_KEYS_DIR/KEK/KEK.key" \
    "$NEW_ROOT_KEYS_DIR/KEK/KEK.crt" \
    "$NEW_ROOT_KEYS_DIR/KEK/KEK.cer" \
    "$NEW_ROOT_KEYS_DIR/KEK/KEK.esl" \
    "$NEW_ROOT_KEYS_DIR/KEK/KEK.auth" \
    "$NEW_ROOT_KEYS_DIR/db/" \
    "$NEW_ROOT_KEYS_DIR/db/db.key" \
    "$NEW_ROOT_KEYS_DIR/db/db.crt" \
    "$NEW_ROOT_KEYS_DIR/db/db.cer" \
    "$NEW_ROOT_KEYS_DIR/db/db.esl" \
    "$NEW_ROOT_KEYS_DIR/db/db.auth" \
    "$NEW_SIGN_LOADERS_SH" \
    "$NEW_DRACUT_CONF" \
    "$NEW_PACMAN_HOOK" \
)
readonly MODIFIED_FILES=("${EFI_BINARIES[@]}")
readonly TEMP_FILES=( \
    "$TMP_GUID_TXT" \
    "$TMP_PK_DIR" \
    "$TMP_KEK_DIR" \
    "$TMP_DB_DIR" \
)
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(openssl efitools sbsigntools)
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

function generate_key_files() {
    local guid key_name key_dir key_type signing_key
    local key_key key_cer key_crt key_esl key_auth

    guid="$1"
    key_name="$2"
    key_dir="$3"
    key_type="$4"
    signing_key_key="$5"
    signing_key_crt="$6"

    key_key="$key_dir/$key_name.key"
    key_crt="$key_dir/$key_name.crt"
    key_cer="$key_dir/$key_name.cer"
    key_esl="$key_dir/$key_name.esl"
    key_auth="$key_dir/$key_name.auth"


    # Generate private key and PEM certificate
    if ! is_not_empty "$key_key" "$key_crt"; then
        qecho "Generating $key_type private key and PEM certificate"
        openssl req -newkey rsa:4096 -nodes -keyout "$key_key" -new -x509 \
            -sha256 -days 3650 -subj "/CN=$USER's $key_type/" -out "$key_crt"
    else
        qecho "$key_key and $key_crt found. Not generating new key pair."
    fi

    # Generate DER certificate
    if ! is_not_empty "$key_cer"; then
        qecho "Generating $key_type DER certificate"
        openssl x509 -outform DER -in "$key_crt" -out "$key_cer"
    else
        qecho "Found $key_cer. Not generating new DER certificate."
    fi

    # Generate efi sig list
    if ! is_not_empty "$key_esl"; then
        qecho "Generating new $key_type EFI Signature List file"
        cert-to-efi-sig-list -g "$guid" "$key_cer" "$key_esl"
    else
        qecho "Found $key_esl. Not generating new EFI signature list file."
    fi

    # Sign EFI sig list
    if ! is_not_empty "$key_auth"; then
        qecho "Signing $key_type EFI signature list file"
        sign-efi-sig-list -g "$guid" -k "$signing_key_key" \
            -c "$signing_key_crt" "$key_name" "$key_esl" "$key_auth" 
    else
        qecho "Found $key_auth. Not generating new auth file"
    fi
}


function check_conf() {
    if is_not_empty "$CONF_PK_KEY" "$CONF_PK_CRT" \
        "$CONF_KEK_KEY" "$CONF_KEK_CRT" \
        "$CONF_DB_KEY" "$CONF_DB_CRT"; then
            qecho "Configuration is set correctly"        
        return 0
    else
        qecho "Configuration is not set correctly"
        return 1
    fi
}

function load_conf() {
    qecho "Copying keys from $CONF_DIR to /tmp"
    cp -rfT "$CONF_PK_DIR" "$TMP_PK_DIR"
    cp -rfT "$CONF_KEK_DIR" "$TMP_KEK_DIR"
    cp -rfT "$CONF_DB_DIR" "$TMP_DB_DIR"
    cp -f "$CONF_GUID_TXT" "$TMP_GUID_TXT"
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
    local guid
    
    if [[ ! -f "$TMP_GUID_TXT" ]]; then
        qecho "Creating GUID..."
        guid="$(uuidgen --random)"
        echo "$guid" > "$TMP_GUID_TXT"
    else
        qecho "GUID found at $TMP_GUID_TXT. Not generating new one."
        read -r guid < "$TMP_GUID_TXT"
    fi

    mkdir -p "$TMP_PK_DIR" "$TMP_KEK_DIR" "$TMP_DB_DIR"

    qecho "Creating platform key..."
    generate_key_files "$guid" "PK" "$TMP_PK_DIR" "Platform Key" "$TMP_PK_KEY" \
        "$TMP_PK_CRT"

    qecho "Creating key exchange key..."
    generate_key_files "$guid" "KEK" "$TMP_KEK_DIR" "Key Exchange Key" \
        "$TMP_PK_KEY" "$TMP_PK_CRT"

    qecho "Creating signature database key..."
    generate_key_files "$guid" "db" "$TMP_DB_DIR" "Signature Database Key" \
        "$TMP_KEK_KEY" "$TMP_KEK_CRT"

    qecho "Done generating keys"
}

function install() {
    qecho "Signing EFI binaries..."

    for bin in "${EFI_BINARIES[@]}"; do
        if [[ -f "$bin" ]]; then
            if ! sbverify --cert "$TMP_DB_CRT" "$bin"; then
                qecho "Signing $bin with signature database key..."
                sudo sbsign --key "$TMP_DB_KEY" --cert "$TMP_DB_CRT" \
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
    qecho "Moving auth keys to boot for key enrollment..."
    sudo mkdir -p "$NEW_BOOT_KEYS_DIR"
    sudo cp -f "$TMP_PK_AUTH" "$TMP_KEK_AUTH" "$TMP_DB_AUTH" \
        "$NEW_BOOT_KEYS_DIR"

    qecho "Moving all keys to $NEW_ROOT_KEYS_DIR..."    
    sudo rm -rf "$NEW_ROOT_KEYS_DIR"
    sudo mkdir -p "$NEW_ROOT_KEYS_DIR"
    sudo mv -ft "$NEW_ROOT_KEYS_DIR" "$TMP_GUID_TXT" "$TMP_PK_DIR" \
        "$TMP_KEK_DIR" "$TMP_DB_DIR"

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
