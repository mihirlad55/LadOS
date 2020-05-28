#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly TMP_SECRET_BIN="/root/temp-cryptroot.bin"
readonly TMP_POLICY_DIGEST="/tmp/policy.digest"
readonly TMP_PRIMARY_CTX="/tmp/primary.context"
readonly TMP_OBJ_PUB="/tmp/obj.pub"
readonly TMP_OBJ_KEY="/tmp/obj.key"
readonly TMP_LOAD_CTX="/tmp/load.context"
readonly TMP_CMDLINE_CONF="/tmp/luks-tpm2-cmdline.conf"
readonly BASE_RESEAL_SH="$BASE_DIR/reseal-tpm.sh"
readonly BASE_RESEAL_SVC="$BASE_DIR/reseal-tpm.service"
readonly BASE_TPMRM_RULES="$BASE_DIR/90-tpmrm.rules"
readonly BASE_DRACUT_CONF="$BASE_DIR/luks-dracut.conf"
readonly NEW_CMDLINE_CONF="/etc/cmdline.d/luks-tpm2.conf"
readonly NEW_SECRET_BIN="/root/cryptroot.bin"
readonly NEW_DRACUT_CONF="/etc/dracut.conf.d/luks-dracut.conf"
readonly NEW_RESEAL_SH="/usr/local/bin/reseal-tpm.sh"
readonly NEW_RESEAL_SVC="/etc/systemd/system/reseal-tpm.service"
readonly NEW_TPMRM_RULES="/etc/udev/rules.d/90-tpmrm.rules"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="LUKS Encryption (using TPM)"
readonly FEATURE_DESC="Encrypt hardrive using LUKS"
readonly CONFLICTS=()
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_SECRET_BIN" \
    "$NEW_DRACUT_CONF" \
    "$NEW_CMDLINE_CONF" \
    "$NEW_RESEAL_SH" \
    "$NEW_RESEAL_SVC" \
    "$NEW_TPMRM_RULES" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=( \
    "$TMP_POLICY_DIGEST" \
    "$TMP_PRIMARY_CTX" \
    "$TMP_OBJ_PUB" \
    "$TMP_OBJ_KEY" \
    "$TMP_LOAD_CTX" \
    "$TMP_SECRET_BIN" \
    "$TMP_CMDLINE_CONF" \
)
readonly DEPENDS_AUR=(dracut-luks-tpm2)
readonly DEPENDS_PACMAN=(tpm2-tools)
readonly DEPENDS_PIP3=()

readonly OBJ_ATTR="noda|adminwithpolicy|fixedparent|fixedtpm"
readonly TPM_HANDLE="0x81000000"
readonly PCR_POLICY="sha1:0,2,4,7"
readonly KEY_SLOT=10

# Readonly after set
TPM_FLAGS=



function set_tpm_verbosity_flag() {
    if [[ -n "$QUIET" ]]; then
        TPM_FLAGS=("--quiet")
    else
        TPM_FLAGS=("--verbose")
    fi
    readonly TPM_FLAGS
}


function clear_tpm_handle() {
    local handle
    handle="$1"

    if sudo tpm2_readpublic "${TPM_FLAGS[@]}" -c "$handle"; then
        qecho "TPM object found at handle $handle"
        qecho "Evicting object at $handle..."
        sudo tpm2_evictcontrol -C o -c "$handle"
    fi
}

function check_install() {
    local f

    set_tpm_verbosity_flag

    sudo tpm2_unseal "${TPM_FLAGS[@]}" -c "$TPM_HANDLE" -p "pcr:$PCR_POLICY" \
        -o "$TMP_SECRET_BIN"

    if ! sudo diff "$TMP_SECRET_BIN" "$NEW_SECRET_BIN"; then
        sudo rm "$TMP_SECRET_BIN"
        qecho "$FEATURE_NAME is not installed correctly."
        return 1
    fi

    for f in "${NEW_FILES[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    qecho "$FEATURE_NAME is installed correctly."
    sudo rm "$TMP_SECRET_BIN"
    return 0
}

function install() {
    local root_path root_dev cmdline

    set_tpm_verbosity_flag

    qecho "Generating new secret for LUKS..."
    sudo dd if=/dev/random of="$NEW_SECRET_BIN" bs=32 count=1

    root_path=$(findmnt -no SOURCE --target /)
    root_dev="$(lsblk -sno PATH,TYPE "$root_path" | grep part | cut -d' ' -f1)"

    qecho "Clearing key slot 10..."
    sudo cryptsetup luksKillSlot "$root_dev" "$KEY_SLOT" || true

    qecho "Adding new key to LUKS..."
    sudo cryptsetup luksAddKey --key-slot "$KEY_SLOT" "$root_dev" \
        "$NEW_SECRET_BIN"

    clear_tpm_handle "$TPM_HANDLE"

    qecho "Sealing secret in TPM..."
    sudo tpm2_createpolicy "${TPM_FLAGS[@]}" --policy-pcr -l "$PCR_POLICY" \
        -L "$TMP_POLICY_DIGEST"

    sudo tpm2_createprimary "${TPM_FLAGS[@]}" -C e -g sha1 -G rsa \
        -c "$TMP_PRIMARY_CTX"

    sudo tpm2_create "${TPM_FLAGS[@]}" -g sha256 -u "$TMP_OBJ_PUB" \
        -r "$TMP_OBJ_KEY" -C "$TMP_PRIMARY_CTX" -L "$TMP_POLICY_DIGEST" \
        -a "$OBJ_ATTR" -i "$NEW_SECRET_BIN"

    sudo tpm2_load "${TPM_FLAGS[@]}" -C "$TMP_PRIMARY_CTX" -u "$TMP_OBJ_PUB" \
        -r "$TMP_OBJ_KEY" -c "$TMP_LOAD_CTX"

    sudo tpm2_evictcontrol "${TPM_FLAGS[@]}" -C o -c "$TMP_LOAD_CTX" \
        "$TPM_HANDLE"

    sudo install -Dm 644 "$BASE_DRACUT_CONF" "$NEW_DRACUT_CONF"

    cmdline="rd.luks_tpm2_handle=$TPM_HANDLE rd.luks_tpm2_auth=pcr:$PCR_POLICY"
    cmdline="$cmdline rd.luks.key=$NEW_SECRET_BIN"

    echo "$cmdline" > "$TMP_CMDLINE_CONF"
    sudo install -Dm 644 "$TMP_CMDLINE_CONF" "$NEW_CMDLINE_CONF"

    sudo install -Dm 700 "$BASE_RESEAL_SH" "$NEW_RESEAL_SH"
    sudo install -Dm 644 "$BASE_RESEAL_SVC" "$NEW_RESEAL_SVC"
    sudo install -Dm 644 "$BASE_TPMRM_RULES" "$NEW_TPMRM_RULES"
}

function post_install() {
    qecho "Enabling reseal-tpm.service..."
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" reseal-tpm.service
}

function cleanup() {
    set_tpm_verbosity_flag

    qecho "Removing ${TEMP_FILES[*]}..."
    sudo rm -f "${TEMP_FILES[@]}"
}

function uninstall() {
    set_tpm_verbosity_flag

    qecho "Clearing $TPM_HANDLE..."
    clear_tpm_object "$TPM_HANDLE"

    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
