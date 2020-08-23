#!/usr/bin/env bash

readonly KEY_DIR="/root/sb-keys"
readonly DB_KEY="$KEY_DIR/db/db.key"
readonly DB_CRT="$KEY_DIR/db/db.crt"
readonly BACKUP_LOADER="/boot/EFI/BOOT/BOOTX64.EFI"
readonly REFIND_LOADER="/boot/EFI/refind/refind_x64.efi"
readonly SYSTEMD_LOADER="/boot/EFI/systemd/systemd-bootx64.efi"
readonly MICROSOFT_LOADERS=( \
    "/boot/EFI/Boot/bootx64.efi" \
    "/boot/EFI/Microsoft/Boot/bootmgr.efi" \
    "/boot/EFI/Microsoft/Boot/bootmgfw.efi" \
    "/boot/EFI/Microsoft/Boot/memtest.efi" \
)

readonly LOADERS=("$BACKUP_LOADER" "$REFIND_LOADER" "$SYSTEMD_LOADER" "${MICROSOFT_LOADERS[@]}")

for loader in "${LOADERS[@]}"; do
    if ! sbverify --cert "$DB_CRT" "$loader"; then
        echo "Signing $loader with signature database key..."
        sbsign --key "$DB_KEY" --cert "$DB_CRT" --output "$loader" "$loader"
    else
        echo "$loader is already signed."
    fi
done
