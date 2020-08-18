#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

LAD_OS_URL="https://github.com/mihirlad55/LadOS"

set -e -u

install_dir=recovery
work_dir=work
out_dir=out
gpg_key=""

verbose=""
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && pwd )"

umask 0022

_usage ()
{
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -D <install_dir>   Set an install_dir (directory inside iso)"
    echo "                        Default: ${install_dir}"
    echo "    -w <work_dir>      Set the working directory"
    echo "                        Default: ${work_dir}"
    echo "    -v                 Enable verbose output"
    echo "    -h                 This help message"
    exit "${1}"
}

# Helper function to run make_*() only one time per architecture.
run_once() {
    if [[ ! -e "${work_dir}/build.${1}" ]]; then
        "$1"
        touch "${work_dir}/build.${1}"
    fi
}

# Setup custom pacman.conf with current cache directories.
make_pacman_conf() {
    local _cache_dirs
    _cache_dirs=("$(pacman -v 2>&1 | grep '^Cache Dirs:' | sed 's/Cache Dirs:\s*//g')")
    sed -r "s|^#?\\s*CacheDir.+|CacheDir = $(echo -n "${_cache_dirs[@]}")|g" \
        "${script_path}/pacman.conf" > "${work_dir}/pacman.conf"
}

# Prepare working directory and copy custom airootfs files (airootfs)
make_custom_airootfs() {
    local _airootfs="${work_dir}/x86_64/airootfs"
    mkdir -p -- "${_airootfs}"

    if [[ -d "${script_path}/airootfs" ]]; then
        cp -af --no-preserve=ownership -- "${script_path}/airootfs/." "${_airootfs}"

        [[ -e "${_airootfs}/etc/shadow" ]] && chmod -f 0400 -- "${_airootfs}/etc/shadow"
        [[ -e "${_airootfs}/etc/gshadow" ]] && chmod -f 0400 -- "${_airootfs}/etc/gshadow"

        # Set up user home directories and permissions
        if [[ -e "${_airootfs}/etc/passwd" ]]; then
            while IFS=':' read -a passwd -r; do
                [[ "${passwd[5]}" == '/' ]] && continue

                if [[ -d "${_airootfs}${passwd[5]}" ]]; then
                    chown -hR -- "${passwd[2]}:${passwd[3]}" "${_airootfs}${passwd[5]}"
                    chmod -f 0750 -- "${_airootfs}${passwd[5]}"
                else
                    install -d -m 0750 -o "${passwd[2]}" -g "${passwd[3]}" -- "${_airootfs}${passwd[5]}"
                fi
             done < "${_airootfs}/etc/passwd"
        fi
    fi
}

# Packages (airootfs)
make_packages() {
    if [[ "${gpg_key}" ]]; then
      gpg --export "${gpg_key}" > "${work_dir}/gpgkey"
      exec 17<>"${work_dir}/gpgkey"
    fi
    if [ -n "${verbose}" ]; then
        ARCHISO_GNUPG_FD="${gpg_key:+17}" mkarchiso -v -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" \
            -p "$(grep -h -v '^#' "${script_path}/packages.x86_64"| sed ':a;N;$!ba;s/\n/ /g')" install
    else
        ARCHISO_GNUPG_FD="${gpg_key:+17}" mkarchiso -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" \
            -p "$(grep -h -v '^#' "${script_path}/packages.x86_64"| sed ':a;N;$!ba;s/\n/ /g')" install
    fi
    if [[ "${gpg_key}" ]]; then
      exec 17<&-
    fi
}

# Customize installation (airootfs)
make_customize_airootfs() {
    if [[ -e "${script_path}/airootfs/etc/passwd" ]]; then
        while IFS=':' read -a passwd -r; do
            [[ "${passwd[5]}" == '/' ]] && continue
            cp -RdT --preserve=mode,timestamps,links -- "${work_dir}/x86_64/airootfs/etc/skel" "${work_dir}/x86_64/airootfs${passwd[5]}"
            chown -hR -- "${passwd[2]}:${passwd[3]}" "${work_dir}/x86_64/airootfs${passwd[5]}"
        done < "${script_path}/airootfs/etc/passwd"
    fi

    # Clone LadOS into airootfs
    git clone "$LAD_OS_URL" "${work_dir}/x86_64/airootfs/LadOS"

    if [[ -e "${work_dir}/x86_64/airootfs/root/customize_airootfs.sh" ]]; then
        if [ -n "${verbose}" ]; then
            mkarchiso -v -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" \
                -r '/root/customize_airootfs.sh' run
        else
            mkarchiso -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" \
                -r '/root/customize_airootfs.sh' run
        fi
        rm "${work_dir}/x86_64/airootfs/root/customize_airootfs.sh"
    fi
}

# Prepare kernel/initramfs ${install_dir}/boot/
make_boot() {
    mkdir -p "${work_dir}/iso/${install_dir}/boot/x86_64"
    cp "${work_dir}/x86_64/airootfs/boot/archiso.img" "${work_dir}/iso/${install_dir}/boot/x86_64/"
    cp "${work_dir}/x86_64/airootfs/boot/vmlinuz-linux" "${work_dir}/iso/${install_dir}/boot/x86_64/"
}

# Add other aditional/extra files to ${install_dir}/boot/
make_boot_extra() {
    if [[ -e "${work_dir}/x86_64/airootfs/boot/memtest86+/memtest.bin" ]]; then
        # rename for PXE: https://wiki.archlinux.org/index.php/Syslinux#Using_memtest
        cp "${work_dir}/x86_64/airootfs/boot/memtest86+/memtest.bin" "${work_dir}/iso/${install_dir}/boot/memtest"
        mkdir -p "${work_dir}/iso/${install_dir}/boot/licenses/memtest86+/"
        cp "${work_dir}/x86_64/airootfs/usr/share/licenses/common/GPL2/license.txt" \
            "${work_dir}/iso/${install_dir}/boot/licenses/memtest86+/"
    fi
    if [[ -e "${work_dir}/x86_64/airootfs/boot/intel-ucode.img" ]]; then
        cp "${work_dir}/x86_64/airootfs/boot/intel-ucode.img" "${work_dir}/iso/${install_dir}/boot/"
        mkdir -p "${work_dir}/iso/${install_dir}/boot/licenses/intel-ucode/"
        cp "${work_dir}/x86_64/airootfs/usr/share/licenses/intel-ucode/"* \
            "${work_dir}/iso/${install_dir}/boot/licenses/intel-ucode/"
    fi
    if [[ -e "${work_dir}/x86_64/airootfs/boot/amd-ucode.img" ]]; then
        cp "${work_dir}/x86_64/airootfs/boot/amd-ucode.img" "${work_dir}/iso/${install_dir}/boot/"
        mkdir -p "${work_dir}/iso/${install_dir}/boot/licenses/amd-ucode/"
        cp "${work_dir}/x86_64/airootfs/usr/share/licenses/amd-ucode/"* \
            "${work_dir}/iso/${install_dir}/boot/licenses/amd-ucode/"
    fi

    # edk2-shell based UEFI shell
    # shellx64.efi is picked up automatically when on /
    cp "${work_dir}/x86_64/airootfs/usr/share/edk2-shell/x64/Shell_Full.efi" "${work_dir}/iso/shellx64.efi"
}

# Build airootfs filesystem image
make_prepare() {
    cp -a -l -f "${work_dir}/x86_64/airootfs" "${work_dir}"
    if [ -n "${verbose}" ]; then
        mkarchiso -v -w "${work_dir}" -D "${install_dir}" pkglist
        mkarchiso -v -w "${work_dir}" -D "${install_dir}" ${gpg_key:+-g ${gpg_key}} prepare
    else
        mkarchiso -w "${work_dir}" -D "${install_dir}" pkglist
        mkarchiso -w "${work_dir}" -D "${install_dir}" ${gpg_key:+-g ${gpg_key}} prepare
    fi
    rm -rf "${work_dir}/airootfs"
    # rm -rf "${work_dir}/x86_64/airootfs" (if low space, this helps)
}

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
    _usage 1
fi

while getopts 'D:w:g:vh' arg; do
    case "${arg}" in
        D) install_dir="${OPTARG}" ;;
        w) work_dir="${OPTARG}" ;;
        g) gpg_key="${OPTARG}" ;;
        v) verbose="-v" ;;
        h) _usage 0 ;;
        *)
           echo "Invalid argument '${arg}'"
           _usage 1
           ;;
    esac
done

mkdir -p "${work_dir}"

run_once make_pacman_conf
run_once make_custom_airootfs
run_once make_packages
run_once make_customize_airootfs
run_once make_boot
run_once make_boot_extra
run_once make_prepare
