#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="custom-signed-bootloader"
feature_desc="Setup computer to auto-sign bootloader for secure boot using custom keys"

conflicts=()

provides=()

new_files=("$ROOT_KEYS_PATH/PK" \
    "$ROOT_KEYS_PATH/KEK" \
    "$ROOT_KEYS_PATH/db" \
    "$BOOT_KEYS_PATH/GUID.txt" \
    "$BOOT_KEYS_PATH/PK.auth" \
    "$BOOT_KEYS_PATH/KEK.auth" \
    "$BOOT_KEYS_PATH/db.auth")

modified_files=("${EFI_BINARIES[@]}")
temp_files=()

depends_aur=()
depends_pacman=(openssl efitools sbsigntools)
depends_pip3=()

GUID_PATH="$BASE_DIR/GUID.txt"

PK_DIR="$BASE_DIR/PK"
PK_KEY="$PK_DIR/PK.key"
PK_CER="$PK_DIR/PK.cer"
PK_CRT="$PK_DIR/PK.crt"
PK_ESL="$PK_DIR/PK.esl"
PK_AUTH="$PK_DIR/PK.auth"

KEK_DIR="$BASE_DIR/KEK"
KEK_KEY="$KEK_DIR/KEK.key"
KEK_CER="$KEK_DIR/KEK.cer"
KEK_CRT="$KEK_DIR/KEK.crt"
KEK_ESL="$KEK_DIR/KEK.esl"
KEK_AUTH="$KEK_DIR/KEK.auth"

DB_DIR="$BASE_DIR/db"
DB_KEY="$DB_DIR/db.key"
DB_CER="$DB_DIR/db.cer"
DB_CRT="$DB_DIR/db.crt"
DB_ESL="$DB_DIR/db.esl"
DB_AUTH="$DB_DIR/db.auth"

EFI_BINARIES=("/boot/vmlinuz-linux" \
    "/boot/initramfs-linux.img" \
    "/boot/EFI/BOOT/BOOTX64.EFI" \
    "/boot/EFI/refind/refind_x64.efi" \
    "/boot/EFI/systemd/systemd-bootx64.efi")

BOOT_KEYS_PATH="/boot/sb-keys"
ROOT_KEYS_PATH="/root/sb-keys"



function generate_key_files() {
    local GUID KEY_NAME KEY_DIR KEY_TYPE SIGNING_KEY
    local KEY_KEY KEY_CER KEY_CRT KEY_ESL KEY_AUTH

    GUID="$1"
    KEY_NAME="$2"
    KEY_DIR="$3"
    KEY_TYPE="$4"
    SIGNING_KEY_KEY="$5"
    SIGNING_KEY_CRT="$6"

    KEY_KEY="$KEY_DIR/$KEY_NAME.key"
    KEY_CER="$KEY_DIR/$KEY_NAME.cer"
    KEY_CRT="$KEY_DIR/$KEY_NAME.crt"
    KEY_ESL="$KEY_DIR/$KEY_NAME.esl"
    KEY_AUTH="$KEY_DIR/$KEY_NAME.auth"

    # Generate private key and PEM certificate
    openssl req -newkey rsa:4096 -nodes -keyout "$KEY_KEY" -new -x509 -sha256 \
        -days 3650 -subj "/CN=$USER's $KEY_TYPE/" -out "$KEY_CER"

    # Generate DER certificate
    openssl x509 -outform DER -in "$KEY_CRT" -out "$KEY_CER"

    # Generate EFI sig list
    cert-to-efi-sig-list -g "$GUID" "$KEY_CER" "$KEY_ESL"

    # Sign EFI sig list
    sign-efi-sig-list -g "$GUID" -k "$SIGNING_KEY_KEY" -c "$SIGNING_KEY_CRT" \
        "$KEY_NAME" "$KEY_ESL" "$KEY_AUTH" 
}


# TODO: load conf with old keys
#function check_conf() {
#
#}

#function load_conf() {
#
#}

#function check_install() {
#
#}

function prepare() {
    qecho "Creating GUID..."
    local GUID
    
    GUID="$(uuidgen --random)"
    echo "$GUID" > "$GUID_PATH"

    mkdir -p "$PK_DIR" "$KEK_DIR" "$DB_DIR"

    qecho "Creating platform key..."
    generate_key_files "$GUID" "PK" "$PK_DIR" "Platform Key" "$PK_KEY" "$PK_CRT"

    qecho "Creating key exchange key..."
    generate_key_files "$GUID" "KEK" "$KEK_DIR" "Key Exchange Key" "$PK_KEY" "$PK_CRT"

    qecho "Creating signature database key..."
    generate_key_files "$GUID" "db" "$DB_DIR" "Signature Database Key" "$KEK_KEY" "$KEK_CRT"

    qecho "Done generating keys"
}

function install() {
    qecho "Signing EFI binaries..."

    for bin in "${EFI_BINARIES[@]}"; do
        if [[ -f "$bin" ]]; then
            qecho "Signing $bin with signature database key..."
            sudo sbsign --key "$DB_KEY" --cert "$DB_CRT" --output "$bin" "$bin"
        else
            qecho "Not signing $bin. Not found."
        fi
    done
}

function post_install() {
    qecho "Moving auth keys to boot for key enrollment..."
    sudo mkdir -p "$BOOT_KEYS_PATH"
    sudo cp -f "$PK_AUTH" "$KEK_AUTH" "$DB_AUTH" "$BOOT_KEYS_PATH"

    qecho "Moving all keys to /root/sb-keys..."    
    sudo mkdir -p "$ROOT_KEYS_PATH"
    sudo mv -rf "$GUID_PATH" "$PK_DIR" "$KEK_DIR" "$DB_DIR" "$ROOT_KEYS_PATH"
}


function uninstall() {
    sudo rm -rf "${new_files[@]}"

}


source "$LAD_OS_DIR/common/feature_common.sh"

