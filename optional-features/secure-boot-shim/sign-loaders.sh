#!/usr/bin/env bash

readonly KEY_DIR="/root/sb-keys"
readonly MOK_KEY="$KEY_DIR/MOK/MOK.key"
readonly MOK_CRT="$KEY_DIR/MOK/MOK.crt"

readonly BACKUP_LOADER="/boot/EFI/BOOT/BOOTX64.EFI"
readonly REFIND_LOADER="/boot/EFI/refind/refind_x64.efi"
readonly SYSTEMD_LOADER="/boot/EFI/systemd/systemd-bootx64.efi"

readonly LOADERS=("$BACKUP_LOADER" "$REFIND_LOADER" "$SYSTEMD_LOADER")

for loader in "${LOADERS[@]}"; do
    if ! sbverify --cert "$MOK_CRT" "$loader"; then
        echo "Signing $loader with signature database key..."
        sbsign --key "$MOK_KEY" --cert "$MOK_CRT" --output "$loader" "$loader"
    else
        echo "$loader is already signed."
    fi
done
