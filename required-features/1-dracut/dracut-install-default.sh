#!/usr/bin/env bash

args=('--force' '--uefi' '--hostonly' '--no-hostonly-cmdline')

kver="$(uname -r)"
read -r pkgbase < /usr/lib/modules/$kver/pkgbase

# Backup image
cp -f /boot/${pkgbase}.efi /boot/${pkgbase}-fallback.efi

dracut "${args[@]}" "/boot/${pkgbase}.efi" --kver "$kver"
