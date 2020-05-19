#!/usr/bin/env bash

args=('--force' '--uefi')

kver="$(uname -r)"
read -r pkgbase < /usr/lib/modules/$kver/pkgbase

dracut "${args[@]}" --hostonly "/boot/${pkgbase}.efi" --kver "$kver"
dracut "${args[@]}" --no-hostonly "/boot/${pkgbase}-fallback.efi" --kver "$kver"
