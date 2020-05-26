#!/bin/bash

LAD_OS_URL="https://github.com/mihirlad55/LadOS"

set -e -u

install_dir=recovery
work_dir=work
gpg_key=

verbose=""
script_path=$(readlink -f ${0%/*})

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
    exit ${1}
}

# Helper function to run make_*() only one time per architecture.
run_once() {
    if [[ ! -e ${work_dir}/build.${1} ]]; then
        $1
        touch ${work_dir}/build.${1}
    fi
}

# Setup custom pacman.conf with current cache directories.
make_pacman_conf() {
    local _cache_dirs
    _cache_dirs=($(pacman -v 2>&1 | grep '^Cache Dirs:' | sed 's/Cache Dirs:\s*//g'))
    sed -r "s|^#?\\s*CacheDir.+|CacheDir = $(echo -n ${_cache_dirs[@]})|g" ${script_path}/pacman.conf > ${work_dir}/pacman.conf
}

# Base installation, plus needed packages (airootfs)
make_basefs() {
    mkarchiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" init
    mkarchiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -p "haveged intel-ucode amd-ucode memtest86+ mkinitcpio-nfs-utils nbd zsh efitools" install
}

# Additional packages (airootfs)
make_packages() {
    mkarchiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -p "$(grep -h -v ^# ${script_path}/packages.x86_64)" install
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
make_setup_mkinitcpio() {
    local _hook
    mkdir -p ${work_dir}/x86_64/airootfs/etc/initcpio/hooks
    mkdir -p ${work_dir}/x86_64/airootfs/etc/initcpio/install
    for _hook in archiso archiso_shutdown archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_loop_mnt; do
        cp /usr/lib/initcpio/hooks/${_hook} ${work_dir}/x86_64/airootfs/etc/initcpio/hooks
        cp /usr/lib/initcpio/install/${_hook} ${work_dir}/x86_64/airootfs/etc/initcpio/install
    done
    sed -i "s|/usr/lib/initcpio/|/etc/initcpio/|g" ${work_dir}/x86_64/airootfs/etc/initcpio/install/archiso_shutdown
    cp /usr/lib/initcpio/install/archiso_kms ${work_dir}/x86_64/airootfs/etc/initcpio/install
    cp /usr/lib/initcpio/archiso_shutdown ${work_dir}/x86_64/airootfs/etc/initcpio
    cp ${script_path}/mkinitcpio.conf ${work_dir}/x86_64/airootfs/etc/mkinitcpio-archiso.conf
    gnupg_fd=
    if [[ ${gpg_key} ]]; then
      gpg --export ${gpg_key} >${work_dir}/gpgkey
      exec 17<>${work_dir}/gpgkey
    fi
    
    ARCHISO_GNUPG_FD=${gpg_key:+17} mkarchiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' run
    if [[ ${gpg_key} ]]; then
      exec 17<&-
    fi
}

# Customize installation (airootfs)
make_customize_airootfs() {
    cp -af ${script_path}/airootfs ${work_dir}/x86_64

    cp ${script_path}/pacman.conf ${work_dir}/x86_64/airootfs/etc

    # Clone LadOS into airootfs
    git clone "$LAD_OS_URL" "${work_dir}/x86_64/airootfs/LadOS"

    curl -o ${work_dir}/x86_64/airootfs/etc/pacman.d/mirrorlist 'https://www.archlinux.org/mirrorlist/?country=all&protocol=http&use_mirror_status=on'

    lynx -dump -nolist 'https://wiki.archlinux.org/index.php/Installation_Guide?action=render' >> ${work_dir}/x86_64/airootfs/root/install.txt

    mkarchiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -r '/root/customize_airootfs.sh' run
    rm ${work_dir}/x86_64/airootfs/root/customize_airootfs.sh
}

# Prepare kernel/initramfs ${install_dir}/boot/
make_boot() {
    mkdir -p ${work_dir}/iso/${install_dir}/boot/x86_64
    cp ${work_dir}/x86_64/airootfs/boot/archiso.img ${work_dir}/iso/${install_dir}/boot/x86_64/archiso.img
    cp ${work_dir}/x86_64/airootfs/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/x86_64/vmlinuz
}

# Add other aditional/extra files to ${install_dir}/boot/
make_boot_extra() {
    cp ${work_dir}/x86_64/airootfs/boot/memtest86+/memtest.bin ${work_dir}/iso/${install_dir}/boot/memtest
    cp ${work_dir}/x86_64/airootfs/usr/share/licenses/common/GPL2/license.txt ${work_dir}/iso/${install_dir}/boot/memtest.COPYING
    cp ${work_dir}/x86_64/airootfs/boot/intel-ucode.img ${work_dir}/iso/${install_dir}/boot/intel_ucode.img
    cp ${work_dir}/x86_64/airootfs/usr/share/licenses/intel-ucode/LICENSE ${work_dir}/iso/${install_dir}/boot/intel_ucode.LICENSE
    cp ${work_dir}/x86_64/airootfs/boot/amd-ucode.img ${work_dir}/iso/${install_dir}/boot/amd_ucode.img
    cp ${work_dir}/x86_64/airootfs/usr/share/licenses/amd-ucode/LICENSE ${work_dir}/iso/${install_dir}/boot/amd_ucode.LICENSE

    # EFI Shell 2.0 for UEFI 2.3+
    curl -o ${work_dir}/iso/${install_dir}/shellx64_v2.efi \
        https://raw.githubusercontent.com/tianocore/edk2/UDK2018/ShellBinPkg/UefiShell/X64/Shell.efi
    # EFI Shell 1.0 for non UEFI 2.3+
    curl -o ${work_dir}/iso/${install_dir}/shellx64_v1.efi \
        https://raw.githubusercontent.com/tianocore/edk2/UDK2018/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
}


# Build airootfs filesystem image
make_prepare() {
    cp -a -l -f ${work_dir}/x86_64/airootfs ${work_dir}
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" pkglist
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" ${gpg_key:+-g ${gpg_key}} prepare
    rm -rf ${work_dir}/airootfs
    # rm -rf ${work_dir}/x86_64/airootfs (if low space, this helps)
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

mkdir -p ${work_dir}

run_once make_pacman_conf
run_once make_basefs
run_once make_packages
run_once make_setup_mkinitcpio
run_once make_customize_airootfs
run_once make_boot
run_once make_boot_extra
run_once make_prepare
