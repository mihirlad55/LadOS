#!/usr/bin/env bash

KEY_DIR="/root/sb-keys"
DB_KEY="$KEY_DIR/db/db.key"
DB_CRT="$KEY_DIR/db/db.crt"

BACKUP_LOADER="/boot/EFI/BOOT/BOOTX64.EFI"
REFIND_LOADER="/boot/EFI/refind/refind_x64.efi"
SYSTEMD_LOADER="/boot/EFI/systemd/systemd-bootx64.efi"

LOADERS=("$BACKUP_LOADER" "$REFIND_LOADER" "$SYSTEMD_LOADER")

for loader in "${LOADERS[@]}"; do
    if ! sbverify --cert "$DB_CRT" "$loader"; then
        echo "Signing $loader with signature database key..."
        sbsign --key "$DB_KEY" --cert "$DB_CRT" --output "$loader" "$loader"
    else
        echo "$loader is already signed."
    fi
done
