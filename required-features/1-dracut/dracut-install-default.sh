#!/usr/bin/env bash

cmdline="$(cat /etc/cmdline.d/* | tr '\n' ' ')"

args=('--force' '--uefi' '--hostonly' '--no-hostonly-cmdline' \
    '--kernel-cmdline' "$cmdline")

kver="$(uname -r)"
read -r pkgbase < /usr/lib/modules/$kver/pkgbase

# Backup image
cp -f /boot/${pkgbase}.efi /boot/${pkgbase}-fallback.efi

dracut "${args[@]}" "/boot/${pkgbase}.efi" --kver "$kver"
