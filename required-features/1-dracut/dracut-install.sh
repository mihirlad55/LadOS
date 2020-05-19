#!/usr/bin/env bash

args=('--force' '--uefi')

while read -r line; do
    echo $line
    if [[ "$line" == 'usr/lib/modules/'+([^/])'/pkgbase' ]]; then
        echo "next"
		read -r pkgbase < "/${line}"
		kver="${line#'usr/lib/modules/'}"
		kver="${kver%'/pkgbase'}"

		install -Dm0644 "/${line%'/pkgbase'}/vmlinuz" "/boot/vmlinuz-${pkgbase}"
		dracut "${args[@]}" --hostonly "/boot/${pkgbase}.efi" --kver "$kver"
		dracut "${args[@]}" --no-hostonly "/boot/${pkgbase}-fallback.efi" --kver "$kver"
	fi
done
