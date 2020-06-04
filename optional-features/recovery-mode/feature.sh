#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly MOUNT_POINT="/var/tmp/recovery"
readonly CONF_DIR="$LAD_OS_DIR/conf/recovery-mode"
readonly CONF_RECOVERY_DIR="$CONF_DIR/recovery"
readonly REFIND_DIR="/boot/EFI/refind"
readonly MOD_REFIND_CONF="$REFIND_DIR/refind.conf"
readonly BASE_RECOVERY_CONF="$BASE_DIR/refind-recovery.conf"
readonly NEW_RECOVERY_CONF="$REFIND_DIR/refind-recovery.conf"
readonly DB_DIR="/root/sb-keys/db"
readonly DB_KEY="$DB_DIR/db.key"
readonly DB_CRT="$DB_DIR/db.crt"
readonly MOK_DIR="/root/sb-keys/MOK"
readonly MOK_KEY="$MOK_DIR/MOK.key"
readonly MOK_CRT="$MOK_DIR/MOK.crt"
readonly EFI_BINARIES=( \
    "$MOUNT_POINT/shellx64_v2.efi" \
    "$MOUNT_POINT/shellx64_v1.efi" \
    "$MOUNT_POINT/boot/x86_64/vmlinuz" \
)

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Recovery Mode"
readonly FEATURE_DESC="Create recovery mode option in bootloader"
readonly CONFLICTS=()
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_RECOVERY_CONF" \
    "$MOUNT_POINT" \
    "$MOUNT_POINT/shellx64_v2.efi" \
    "$MOUNT_POINT/shellx64_v1.efi" \
    "$MOUNT_POINT/x86_64" \
    "$MOUNT_POINT/pkglist.x86_64.txt" \
    "$MOUNT_POINT/x86_64/airootfs.sfs" \
    "$MOUNT_POINT/x86_64/airootfs.sha512" \
    "$MOUNT_POINT/boot" \
    "$MOUNT_POINT/boot/x86_64/archiso.img" \
    "$MOUNT_POINT/boot/x86_64/vmlinuz" \
    "$MOUNT_POINT/boot/memtest" \
    "$MOUNT_POINT/boot/memtest.COPYING" \
    "$MOUNT_POINT/boot/intel_ucode.img" \
    "$MOUNT_POINT/boot/intel_ucode.LICENSE" \
    "$MOUNT_POINT/boot/amd_ucode.img" \
    "$MOUNT_POINT/boot/amd_ucode.LICENSE" \
)
readonly MODIFIED_FILES=("$MOD_REFIND_CONF")
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(dosfstools refind)
readonly DEPENDS_PIP3=()

readonly RECOVERY_LABEL="RECOVERY"



function check_boot_space() {
    local free_space recovery_size part_path
    part_path="$1"

    free_space="$(sudo blockdev --getsize64 "$part_path")"
    recovery_size="$(du -d0 "$CONF_RECOVERY_DIR" | cut -f1)"

    # Check if partition is big enough
    if (( free_space > recovery_size )); then
        vecho "There is enough space on the boot partition to copy the"
        vecho "recovery files"
        return 0
    else
        vecho "There is not enough space on the boot partition to copy the"
        vecho "recovery files"
        return 1
    fi
}


function check_install() {
    local f

    # Check if include directive is in refind.conf
    if ! grep -q "$MOD_REFIND_CONF" -e "^include refind-recovery.conf$"; then
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi

    sudo mount "LABEL=$RECOVERY_LABEL" "$MOUNT_POINT"

    # Check if all files are installed
    for f in "${NEW_FILES[@]}"; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            sudo umount "$MOUNT_POINT"
            return 1
        fi
    done

    sudo umount "$MOUNT_POINT"
    qecho "$FEATURE_NAME is installed"
    return 0
}

function install() {
    local part_path recovery_size part_path resp

    recovery_size="$(du -hd0 "$CONF_RECOVERY_DIR" | cut -f1)"

    qecho "This feature requires a $recovery_size partition"
    read -rp "Enter the device path to the recovery partition: " part_path
    read -rp "Is $part_path is the recovery partition [y/N]: " resp

    if [[ "$resp" != "y" ]] && [[ "$resp" != "Y" ]]; then
        exit 1
    fi

    sudo mkdir -p "$MOUNT_POINT"

    qecho "Formatting $part_path..."
    if mount | grep -q "$part_path"; then
        qecho "$part_path is currently mounted. Unmounting..."
        sudo umount "$part_path"
    fi

    sudo mkfs.vfat -F32 "$part_path"

    qecho "Labelling $part_path $RECOVERY_LABEL..."
    sudo fatlabel "$part_path" "$RECOVERY_LABEL"

    qecho "Mounting $part_path at $MOUNT_POINT..."
    sudo mount "$part_path" "$MOUNT_POINT"

    if check_boot_space "$part_path"; then
        qecho "Copying recovery mode files to $MOUNT_POINT"
        sudo cp -rfT "$CONF_RECOVERY_DIR" "$MOUNT_POINT"
    else
        echo "There is not enough space to copy the recovery files"
        echo "You need at least $recovery_size to install $FEATURE_NAME"
        exit 1
    fi

    qecho "Copying configuration files to $REFIND_DIR..."
    sudo install -Dm 755 "$BASE_RECOVERY_CONF" "$NEW_RECOVERY_CONF"

    if ! grep -q "$MOD_REFIND_CONF" -e "^include refind-recovery.conf$"; then
        qecho "Adding include to $MOD_REFIND_CONF..."
        sudo sed -i "$MOD_REFIND_CONF" \
            -e '1 i\include refind-recovery.conf'
    else
        qecho "Include command already in $MOD_REFIND_CONF"
    fi

    qecho "Done"
}

function post_install() {
    local key crt bin

    # Check if secure boot MOK or DB keys are available
    if sudo test -f "$DB_KEY" && sudo test -f "$DB_CRT"; then
        qecho "Found custom secure boot keys"
        key="$DB_KEY"
        crt="$DB_CRT"
    elif sudo test -f "$MOK_KEY" && sudo test -f "$MOK_CRT"; then
        qecho "Found shim secure boot installation"
        key="$MOK_KEY"
        crt="$MOK_CRT"
    fi

    # Sign EFI binaries in recovery partition with secure boot keys
    if [[ -n "$key" ]] && [[ -n "$crt" ]]; then
        qecho "Signing recovery binaries..."
        for bin in "${EFI_BINARIES[@]}"; do
            if ! sudo sbverify --cert "$crt" "$bin"; then
                qecho "Signing $bin with signature database key..."
                sudo sbsign --key "$key" --cert "$crt" --output "$bin" "$bin"
            else
                qecho "$bin is already signed. Not signing."
            fi
        done
    fi
}

function cleanup() {
    qecho "Unmounting $MOUNT_POINT..."
    sudo umount "$MOUNT_POINT"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -rf "${NEW_FILES[@]}"

    qecho "Removing include command from $MOD_REFIND_CONF..."
    sudo sed -i "$MOD_REFIND_CONF" -e "s/^include refind-recovery.conf$//"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
