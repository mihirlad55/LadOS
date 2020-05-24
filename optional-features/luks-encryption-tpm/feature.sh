#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

SECRET_FILE="/root/cryptroot.bin"
TMP_SECRET_FILE="/root/temp-cryptroot.bin"
POLICY_DIGEST_FILE="/tmp/policy.digest"
PRIMARY_CTX_FILE="/tmp/primary.context"
OBJ_PUB_FILE="/tmp/obj.pub"
OBJ_KEY_FILE="/tmp/obj.key"
LOAD_CTX_FILE="/tmp/load.context"
OBJ_ATTR="noda|adminwithpolicy|fixedparent|fixedtpm"
TPM_HANDLE="0x81000000"
PCR_POLICY="sha1:0,2,4,7"

KEY_SLOT=10

RESEAL_TPM_FILE="$BASE_DIR/reseal-tpm.sh"
RESEAL_TPM_SERVICE="$BASE_DIR/reseal-tpm.service"
TPMRM_RULES_FILE="$BASE_DIR/90-tpmrm.rules"

DRACUT_CONF_DIR="/etc/dracut.conf.d"
LUKS_DRACUT_CONF="$BASE_DIR/luks-dracut.conf"

feature_name="LUKS Encryption (using TPM)"
feature_desc="Encrypt hardrive using LUKS"

conflicts=()

provides=()

new_files=( \
    "$SECRET_FILE" \
    "$DRACUT_CONF_DIR/luks-dracut.conf" \
    "/usr/local/bin/reseal-tpm.sh" \
    "/etc/systemd/system/reseal-tpm.service" \
    "/etc/udev/rules.d/90-tpmrm.rules" \
)

modified_files=("$DRACUT_CONF_DIR/cmdline-dracut.conf")

temp_files=( \
    "$POLICY_DIGEST_FILE" \
    "$PRIMARY_CTX_FILE" \
    "$OBJ_PUB_FILE" \
    "$OBJ_KEY_FILE" \
    "$LOAD_CTX_FILE" \
    "$TMP_SECRET_FILE" \
)

depends_aur=() #dracut-luks-tpm2-module
depends_pacman=(tpm2-tools)
depends_pip3=()


function set_tpm_verbosity_flag() {
    if [[ -n "$QUIET" ]]; then
        echo "QUIET"
        TPM_VERBOSITY_FLAG="--quiet"
    else
        TPM_VEBOSITY_FLAG="--verbose"
    fi
}


function clear_tpm_handle() {
    local handle
    handle="$1"

    if sudo tpm2_readpublic ${TPM_VERBOSITY_FLAG} -c "$handle"; then
        qecho "TPM object found at handle $handle"
        qecho "Evicting object at $handle..."
        sudo tpm2_evictcontrol -C o -c $handle
    fi
}

function check_install() {
    set_tpm_verbosity_flag

    sudo tpm2_unseal ${TPM_VERBOSITY_FLAG} -c "$TPM_HANDLE" \
        -p "pcr:$PCR_POLICY" -o "$TMP_SECRET_FILE"

    if ! sudo diff "$TMP_SECRET_FILE" "$SECRET_FILE"; then
        sudo rm "$TMP_SECRET_FILE"
        qecho "$feature_name is not installed correctly."
        return 1
    fi

    for f in ${new_files[@]}; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed correctly."
    sudo rm "$TMP_SECRET_FILE"
    return 0
}

function install() {
    local root_path

    set_tpm_verbosity_flag

    qecho "Generating new secret for LUKS..."
    sudo dd if=/dev/random of="$SECRET_FILE" bs=32 count=1

    root_path=$(cat /etc/fstab | \
        grep -B 1 -P -e "UUID=[a-zA-Z0-9\-]*[\t ]+/[\t ]+" | \
        head -n1 | \
        sed 's/[# ]*//')

    root_dev="$(sudo cryptsetup status "$root_path" | grep device | tr -s ' ' | sed 's/^ *//' | cut -d' ' -f2)"

    qecho "Clearing key slot 10..."
    sudo cryptsetup luksKillSlot "$root_dev" "$KEY_SLOT" || true

    qecho "Adding new key to LUKS..."
    sudo cryptsetup luksAddKey --key-slot "$KEY_SLOT" "$root_dev" "$SECRET_FILE"

    clear_tpm_handle "$TPM_HANDLE"

    qecho "Sealing secret in TPM..."
    sudo tpm2_createpolicy ${TPM_VERBOSITY_FLAG} --policy-pcr -l "$PCR_POLICY" \
        -L "$POLICY_DIGEST_FILE"

    sudo tpm2_createprimary ${TPM_VERBOSITY_FLAG} -C e -g sha1 -G rsa \
        -c "$PRIMARY_CTX_FILE"

    sudo tpm2_create ${TPM_VERBOSITY_FLAG} -g sha256 -u "$OBJ_PUB_FILE" \
        -r "$OBJ_KEY_FILE" -C "$PRIMARY_CTX_FILE" -L "$POLICY_DIGEST_FILE" \
        -a "$OBJ_ATTR" -i "$SECRET_FILE"

    sudo tpm2_load ${TPM_VERBOSITY_FLAG} -C "$PRIMARY_CTX_FILE" \
        -u "$OBJ_PUB_FILE" -r "$OBJ_KEY_FILE" -c "$LOAD_CTX_FILE"

    sudo tpm2_evictcontrol ${TPM_VERBOSITY_FLAG} -C o -c "$LOAD_CTX_FILE" \
        "$TPM_HANDLE"

    sudo install -Dm 644 "$LUKS_DRACUT_CONF" "$DRACUT_CONF_DIR/luks-dracut.conf"

    kernel_cmdline_add="rd.luks_tpm2_handle=$TPM_HANDLE rd.luks_tpm2_auth=pcr:$PCR_POLICY"

    if ! grep -q -F "$kernel_cmdline_add" "$DRACUT_CONF_DIR/cmdline-dracut.conf"; then
        qecho "Adding kernel cmdline options to $DRACUT_CONF_DIR/cmdline-dracut.conf"

        source "$DRACUT_CONF_DIR/cmdline-dracut.conf"

        kernel_cmdline="kernel_cmdline=\"$kernel_cmdline $kernel_cmdline_add\""

        echo "$kernel_cmdline" | sudo tee "$DRACUT_CONF_DIR/cmdline-dracut.conf" >/dev/null
    else
        qecho "luks_tpm2 kernel cmdline options already present in $DRACUT_CONF_DIR/cmdline-dracut.conf"
    fi

    sudo install -Dm 700 "$RESEAL_TPM_FILE" "/usr/local/bin/reseal-tpm.sh"
    sudo install -Dm 644 "$RESEAL_TPM_SERVICE" "/etc/systemd/system/reseal-tpm.service"
    sudo install -Dm 644 "$TPMRM_RULES_FILE" "/etc/udev/rules.d/90-tpmrm.rules"
}

function post_install() {
    qecho "Enabling reseal-tpm.service..."
    sudo systemctl $SYSTEMD_FLAGS enable reseal-tpm.service
}

function cleanup() {
    set_tpm_verbosity_flag

    qecho "Removing ${temp_files[*]}..."
    sudo rm -f "${temp_files[@]}"
}

function uninstall() {
    set_tpm_verbosity_flag

    qecho "Clearing $TPM_HANDLE..."
    clear_tpm_object "$TPM_HANDLE"

    qecho "Removing ${new_files[*]}..."
    sudo rm -f "${new_files[@]}"

    kernel_cmdline_add=" rd\.luks_tpm2_handle=$TPM_HANDLE rd\.luks_tpm2_auth=pcr:$PCR_POLICY"
    sudo sed -i "$DRACUT_CONF_DIR/cmdline-dracut.conf" -e "s/$kernel_cmdline//"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
