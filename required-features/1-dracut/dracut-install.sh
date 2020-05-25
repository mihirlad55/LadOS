#!/usr/bin/env bash

cmdline="$(cat /etc/cmdline.d/* | tr '\n' ' ')"

args=('--force' '--uefi' '--hostonly' '--no-hostonly-cmdline' \
    '--kernel-cmdline' "$cmdline")

while read -r line; do
    echo $line
    if [[ "$line" == 'usr/lib/modules/'+([^/])'/pkgbase' ]]; then
        echo "next"
		read -r pkgbase < "/${line}"
		kver="${line#'usr/lib/modules/'}"
		kver="${kver%'/pkgbase'}"

        # Backup image
        cp -f /boot/${pkgbase}.efi /boot/${pkgbase}-fallback.efi

		dracut "${args[@]}" "/boot/${pkgbase}.efi" --kver "$kver"
	fi
done
