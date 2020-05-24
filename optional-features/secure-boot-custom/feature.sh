#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/secure-boot-custom"
PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
DRACUT_CONF_DIR="/etc/dracut.conf.d"
BOOT_KEYS_PATH="/boot/sb-keys"
ROOT_KEYS_PATH="/root/sb-keys"

source "$LAD_OS_DIR/common/feature_header.sh"

GUID_PATH="/tmp/GUID.txt"

PK_DIR="/tmp/PK"
PK_KEY="$PK_DIR/PK.key"
PK_CER="$PK_DIR/PK.cer"
PK_CRT="$PK_DIR/PK.crt"
PK_ESL="$PK_DIR/PK.esl"
PK_AUTH="$PK_DIR/PK.auth"

KEK_DIR="/tmp/KEK"
KEK_KEY="$KEK_DIR/KEK.key"
KEK_CER="$KEK_DIR/KEK.cer"
KEK_CRT="$KEK_DIR/KEK.crt"
KEK_ESL="$KEK_DIR/KEK.esl"
KEK_AUTH="$KEK_DIR/KEK.auth"

DB_DIR="/tmp/db"
DB_KEY="$DB_DIR/db.key"
DB_CER="$DB_DIR/db.cer"
DB_CRT="$DB_DIR/db.crt"
DB_ESL="$DB_DIR/db.esl"
DB_AUTH="$DB_DIR/db.auth"

EFI_BINARIES=("/boot/vmlinuz-linux" \
    "/boot/EFI/BOOT/BOOTX64.EFI" \
    "/boot/EFI/refind/refind_x64.efi" \
    "/boot/EFI/systemd/systemd-bootx64.efi" \
    "/boot/linux.efi" \
    "/boot/linux-fallback.efi")


feature_name="Secure Boot (Custom Keys)"
feature_desc="Setup computer to auto-sign bootloader for secure boot using custom keys"

conflicts=('secure-boot-shim' 'secure-boot-preloader')

provides=()

new_files=( \
    "$BOOT_KEYS_PATH/PK.auth" \
    "$BOOT_KEYS_PATH/KEK.auth" \
    "$BOOT_KEYS_PATH/db.auth" \
    "$ROOT_KEYS_PATH/GUID.txt" \
    "$ROOT_KEYS_PATH/PK/PK.key" \
    "$ROOT_KEYS_PATH/PK/PK.crt" \
    "$ROOT_KEYS_PATH/PK/PK.cer" \
    "$ROOT_KEYS_PATH/PK/PK.esl" \
    "$ROOT_KEYS_PATH/PK/PK.auth" \
    "$ROOT_KEYS_PATH/KEK/KEK.key" \
    "$ROOT_KEYS_PATH/KEK/KEK.crt" \
    "$ROOT_KEYS_PATH/KEK/KEK.cer" \
    "$ROOT_KEYS_PATH/KEK/KEK.esl" \
    "$ROOT_KEYS_PATH/KEK/KEK.auth" \
    "$ROOT_KEYS_PATH/db/db.key" \
    "$ROOT_KEYS_PATH/db/db.crt" \
    "$ROOT_KEYS_PATH/db/db.cer" \
    "$ROOT_KEYS_PATH/db/db.esl" \
    "$ROOT_KEYS_PATH/db/db.auth" \
    "/usr/local/bin/sign-loaders.sh" \
    "$DRACUT_CONF_DIR/sb-dracut.conf" \
    "$PACMAN_HOOKS_DIR/99-secure-boot-custom.hook" \
)

modified_files=("${EFI_BINARIES[@]}")
temp_files=( \
    "$GUID_PATH" \
    "$PK_DIR" \
    "$KEK_DIR" \
    "$DB_DIR" \
)

depends_aur=()
depends_pacman=(openssl efitools sbsigntools)
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
    KEY_CRT="$KEY_DIR/$KEY_NAME.crt"
    KEY_CER="$KEY_DIR/$KEY_NAME.cer"
    KEY_ESL="$KEY_DIR/$KEY_NAME.esl"
    KEY_AUTH="$KEY_DIR/$KEY_NAME.auth"


    # Generate private key and PEM certificate
    if ! is_not_empty "$KEY_KEY" "$KEY_CRT"; then
        qecho "Generating $KEY_TYPE private key and PEM certificate"
        openssl req -newkey rsa:4096 -nodes -keyout "$KEY_KEY" -new -x509 \
            -sha256 -days 3650 -subj "/CN=$USER's $KEY_TYPE/" -out "$KEY_CRT"
    else
        qecho "$KEY_KEY and $KEY_CRT found. Not generating new key pair."
    fi

    # Generate DER certificate
    if ! is_not_empty "$KEY_CER"; then
        qecho "Generating $KEY_TYPE DER certificate"
        openssl x509 -outform DER -in "$KEY_CRT" -out "$KEY_CER"
    else
        qecho "Found $KEY_CER. Not generating new DER certificate."
    fi

    # Generate efi sig list
    if ! is_not_empty "$KEY_ESL"; then
        qecho "Generating new $KEY_TYPE EFI Signature List file"
        cert-to-efi-sig-list -g "$GUID" "$KEY_CER" "$KEY_ESL"
    else
        qecho "Found $KEY_ESL. Not generating new EFI signature list file."
    fi

    # Sign EFI sig list
    if ! is_not_empty "$KEY_AUTH"; then
        qecho "Signing $KEY_TYPE EFI signature list file"
        sign-efi-sig-list -g "$GUID" -k "$SIGNING_KEY_KEY" \
            -c "$SIGNING_KEY_CRT" "$KEY_NAME" "$KEY_ESL" "$KEY_AUTH" 
    else
        qecho "Found $KEY_AUTH. Not generating new auth file"
    fi
}


function check_conf() {
    if is_not_empty "$CONF_DIR/PK/PK.key" "$CONF_DIR/PK/PK.crt" \
        "$CONF_DIR/KEK/KEK.key" "$CONF_DIR/KEK/KEK.crt" \
        "$CONF_DIR/db/db.key" "$CONF_DIR/db/db.crt" \
        "$CONF_DIR/GUID.txt"; then
            qecho "Configuration is set correctly"        
        return 0
    else
        qecho "Configuration is not set correctly"
        return 1
    fi
}

function load_conf() {
    qecho "Copying keys from $CONF_DIR to /tmp"
    cp -rfT "$CONF_DIR/PK" "$PK_DIR"
    cp -rfT "$CONF_DIR/KEK" "$KEK_DIR"
    cp -rfT "$CONF_DIR/db" "$DB_DIR"
    cp -f "$CONF_DIR/GUID.txt" "$GUID_PATH"
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
    local GUID
    
    if [[ ! -f "$GUID_PATH" ]]; then
        qecho "Creating GUID..."
        GUID="$(uuidgen --random)"
        echo "$GUID" > "$GUID_PATH"
    else
        qecho "GUID found at $GUID_PATH. Not generating new one."
        read -r GUID < "$GUID_PATH"
    fi

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
            if ! sbverify --cert "$DB_CRT" "$bin"; then
                qecho "Signing $bin with signature database key..."
                sudo sbsign --key "$DB_KEY" --cert "$DB_CRT" --output "$bin" "$bin"
            else
                qecho "$bin is already signed. Not signing."
            fi
        else
            qecho "Not signing $bin. Not found."
        fi
    done

    qecho "Copying 99-secure-boot-custom.hook to $PACMAN_HOOKS_DIR..."
    sudo install -Dm 644 "$BASE_DIR/99-secure-boot-custom.hook" "$PACMAN_HOOKS_DIR/99-secure-boot-custom.hook"

    qecho "Copying sign-loaders.sh to /usr/local/bin..."
    sudo install -Dm 700 "$BASE_DIR/sign-loaders.sh" /usr/local/bin/sign-loaders.sh

    qecho "Copying sb-dracut.conf to $DRACUT_CONF_DIR..."
    sudo install -Dm 644 "$BASE_DIR/sb-dracut.conf" "$DRACUT_CONF_DIR/sb-dracut.conf"
}

function post_install() {
    qecho "Moving auth keys to boot for key enrollment..."
    sudo mkdir -p "$BOOT_KEYS_PATH"
    sudo cp -f "$PK_AUTH" "$KEK_AUTH" "$DB_AUTH" "$BOOT_KEYS_PATH"

    qecho "Moving all keys to $ROOT_KEYS_PATH..."    
    sudo rm -rf "$ROOT_KEYS_PATH"
    sudo mkdir -p "$ROOT_KEYS_PATH"
    sudo mv -ft "$ROOT_KEYS_PATH" "$GUID_PATH" "$PK_DIR" "$KEK_DIR" "$DB_DIR"

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


source "$LAD_OS_DIR/common/feature_footer.sh"

