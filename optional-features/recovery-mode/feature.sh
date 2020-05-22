#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/recovery-mode"

source "$LAD_OS_DIR/common/feature_header.sh"

REFIND_DIR="/boot/EFI/refind"
REFIND_CONF="$REFIND_DIR/refind.conf"
REFIND_RECOVERY_CONF="$BASE_DIR/refind-recovery.conf"

EFI_BINARIES=( \
    "/boot/recovery/shellx64_v2.efi" \
    "/boot/recovery/shellx64_v1.efi" \
    "/boot/recovery/boot/x86_64/vmlinuz" \
)

feature_name="Recovery Mode"
feature_desc="Create recovery mode option in bootloader"

conflicts=()

provides=()
new_files=( \
    "$REFIND_DIR/refind-recovery.conf" \
    "/boot/recovery" \
    "/boot/recovery/shellx64_v2.efi" \
    "/boot/recovery/shellx64_v1.efi" \
    "/boot/recovery/x86_64" \
    "/boot/recovery/pkglist.x86_64.txt" \
    "/boot/recovery/x86_64/airootfs.sfs" \
    "/boot/recovery/x86_64/airootfs.sha512" \
    "/boot/recovery/boot" \
    "/boot/recovery/boot/x86_64/archiso.img" \
    "/boot/recovery/boot/x86_64/vmlinuz" \
    "/boot/recovery/boot/memtest" \
    "/boot/recovery/boot/memtest.COPYING" \
    "/boot/recovery/boot/intel_ucode.img" \
    "/boot/recovery/boot/intel_ucode.LICENSE" \
    "/boot/recovery/boot/amd_ucode.img" \
    "/boot/recovery/boot/amd_ucode.LICENSE" \
)
modified_files=("$REFIND_CONF")
temp_files=()

depends_aur=()
depends_pacman=(dosfstools refind)
depends_pip3=()


function check_boot_space() {
    free_space="$(df /boot | tail -n1 | awk '{print $4}')"
    recovery_size="$(du -d0 "$CONF_DIR/recovery" | cut -f1)"
    overwritable_space="$(du ${new_files[@]} -c | tail -n1 | cut -f1)"

    free_space=$((free_space + overwritable_space))

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

    for f in ${new_files[@]}; do
        if [[ ! -e "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function install() {
    if check_boot_space; then
        qecho "Copying recovery mode files to /boot"
        sudo cp -rfT "$CONF_DIR/recovery" "/boot/recovery"
    else
        recovery_size="$(du -hd0 "$CONF_DIR/recovery" | cut -f1)"
        echo "There is not enough space to copy the recovery files"
        echo "You need at least $recovery_size to install $feature_name"
        exit 1
    fi

    qecho "Copying configuration files to $REFIND_DIR..."
    sudo install -Dm 755 "$REFIND_RECOVERY_CONF" $REFIND_DIR/refind-recovery.conf

    if ! grep -q "$REFIND_CONF" -e "^include refind-recovery.conf$"; then
        qecho "Adding include to $REFIND_CONF..."
        sudo sed -i "$REFIND_CONF" \
            -e '1 i\include refind-recovery.conf'
    else
        qecho "Include command already in $REFIND_CONF"
    fi

    qecho "Labelling root partition as 'BOOT'"
    boot_path="$(cat /etc/fstab | \
        grep -B1 -P -e "UUID=[a-zA-Z0-9\-]*[\t ]+/boot[\t ]+" | \
        head -n1 | \
        sed 's/[# ]*//')"

    sudo fatlabel "$boot_path" "BOOT"

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

function uninstall() {
    qecho "Removing ${new_files[@]}..."
    sudo rm -rf "${new_files[@]}"

    qecho "Removing include command from $REFIND_CONF..."
    sudo sed -i "$REFIND_CONF" -e "s/^include refind-recovery.conf$//"
}

source "$LAD_OS_DIR/common/feature_footer.sh"

# vim:ft=sh
