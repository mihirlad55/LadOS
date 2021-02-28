#!/usr/bin/env bash

cmdline="$(cat /etc/cmdline.d/* | tr '\n' ' ')"

args=('--force' '--uefi' '--hostonly' '--no-hostonly-cmdline' \
    '--kernel-cmdline' "$cmdline")

args_fallback=('--force' '--uefi' '--no-hostonly' '--no-hostonly-cmdline' \
  '--kernel-cmdline' "$cmdline")

# Use ls to get installed version. When chrooted from an archiso, uname -r
# returns kernel version of archiso instead of the new system

kver="$(ls /usr/lib/modules | head -n1)"
read -r pkgbase < "/usr/lib/modules/$kver/pkgbase"

# Fallback image
dracut "${args_fallback[@]}" "/boot/${pkgbase}-fallback.efi" \
  --kver "$kver"

dracut "${args[@]}" "/boot/${pkgbase}.efi" --kver "$kver"
