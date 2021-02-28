#!/usr/bin/env bash

cmdline="$(cat /etc/cmdline.d/* | tr '\n' ' ')"

args=('--force' '--uefi' '--hostonly' '--no-hostonly-cmdline' \
    '--kernel-cmdline' "$cmdline")

args_fallback=('--force' '--uefi' '--no-hostonly' '--no-hostonly-cmdline' \
  '--kernel-cmdline' "$cmdline")

while read -r line; do
    if [[ "$line" == 'usr/lib/modules/'+([^/])'/pkgbase' ]]; then
		read -r pkgbase < "/${line}"
		kver="${line#'usr/lib/modules/'}"
		kver="${kver%'/pkgbase'}"

        # Fallback image
		dracut "${args_fallback[@]}" "/boot/${pkgbase}-fallback.efi" \
          --kver "$kver"

		dracut "${args[@]}" "/boot/${pkgbase}.efi" --kver "$kver"
	fi
done
