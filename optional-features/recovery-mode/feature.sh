#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
CONF_DIR="$LAD_OS_DIR/conf/recovery-mode"

source "$LAD_OS_DIR/common/feature_header.sh"

REFIND_DIR="/boot/EFI/refind"
REFIND_CONF="$REFIND_DIR/refind.conf"
REFIND_RECOVERY_CONF="$BASE_DIR/refind-recovery.conf"

MOUNT_POINT="/var/tmp/recovery"

EFI_BINARIES=( \
    "$MOUNT_POINT/shellx64_v2.efi" \
    "$MOUNT_POINT/shellx64_v1.efi" \
    "$MOUNT_POINT/boot/x86_64/vmlinuz" \
)

feature_name="Recovery Mode"
feature_desc="Create recovery mode option in bootloader"

conflicts=()

provides=()
new_files=( \
    "$REFIND_DIR/refind-recovery.conf" \
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
modified_files=("$REFIND_CONF")
temp_files=()

depends_aur=()
depends_pacman=(dosfstools refind)
depends_pip3=()


function check_boot_space() {
    local free_space recovery_size part_path
    part_path="$1"

    free_space="$(sudo blockdev --getsize64 "$part_path")"
    recovery_size="$(du -d0 "$CONF_DIR/recovery" | cut -f1)"

    if [[ "$free_space" -gt "$recovery_size" ]]; then
        vecho "There is enough space on the boot partition to copy the recovery files"
        return 0
    else
        vecho "There is not enough space on the boot partition to copy the recovery files"
        return 1
    fi
}


function check_install() {
    if ! grep -q "$REFIND_CONF" -e "^include refind-recovery.conf$"; then
        echo "$feature_name is not installed" >&2
        return 1
    fi

    sudo mount "LABEL=RECOVERY" "$MOUNT_POINT"

    for f in "${new_files[@]}"; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            sudo umount "$MOUNT_POINT"
            return 1
        fi
    done

    sudo umount "$MOUNT_POINT"
    qecho "$feature_name is installed"
    return 0
}

function install() {
    local part_path recovery_size

    recovery_size="$(du -hd0 "$CONF_DIR/recovery" | cut -f1)"

    qecho "This feature requires a $recovery_size partition"
    read -rp "Enter the device path to the recovery partition: " part_path
    read -rp "Please confirm that $part_path is the recovery partition [y/N]: " resp

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

    qecho "Labelling $part_path RECOVERY..."
    sudo fatlabel "$part_path" RECOVERY

    qecho "Mounting $part_path at $MOUNT_POINT..."
    sudo mount "$part_path" "$MOUNT_POINT"

    if check_boot_space "$part_path"; then
        qecho "Copying recovery mode files to $MOUNT_POINT"
        sudo cp -rfT "$CONF_DIR/recovery" "$MOUNT_POINT"
    else
        echo "There is not enough space to copy the recovery files"
        echo "You need at least $recovery_size to install $feature_name"
        exit 1
    fi

    qecho "Copying configuration files to $REFIND_DIR..."
    sudo install -Dm 755 "$REFIND_RECOVERY_CONF" "$REFIND_DIR/refind-recovery.conf"

    if ! grep -q "$REFIND_CONF" -e "^include refind-recovery.conf$"; then
        qecho "Adding include to $REFIND_CONF..."
        sudo sed -i "$REFIND_CONF" \
            -e '1 i\include refind-recovery.conf'
    else
        qecho "Include command already in $REFIND_CONF"
    fi

    qecho "Done"
}

function post_install() {
    local key crt

    if sudo test -f "/root/sb-keys/db/db.key" && sudo test -f "/root/sb-keys/db/db.crt"; then
        qecho "Found custom secure boot keys"
        key="/root/sb-keys/db/db.key"
        crt="/root/sb-keys/db/db.crt"
    elif sudo test -f "/root/sb-keys/MOK/MOK.key" && sudo test -f "/root/sb-keys/MOK/MOK.crt"; then
        qecho "Found shim secure boot installation"
        key="/root/sb-keys/MOK/MOK.key"
        crt="/root/sb-keys/MOK/MOK.crt"
    fi

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
    qecho "Removing ${new_files[*]}..."
    sudo rm -rf "${new_files[@]}"

    qecho "Removing include command from $REFIND_CONF..."
    sudo sed -i "$REFIND_CONF" -e "s/^include refind-recovery.conf$//"
}

source "$LAD_OS_DIR/common/feature_footer.sh"

# vim:ft=sh
