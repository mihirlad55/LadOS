#!/usr/bin/env bash

while read -r line; do
	if [[ "$line" == 'usr/lib/modules/'+([^/])'/pkgbase' ]]; then
		read -r pkgbase < "/${line}"
		rm -f "/boot/vmlinuz-${pkgbase}" "/boot/${pkgbase}.efi"
        rm -f "/boot/${pkgbase}-fallback.efi"
	fi
done
