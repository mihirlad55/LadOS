#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"

virsh destroy --domain ArchLinux
virsh undefine --nvram --domain ArchLinux

mkdir -p "$HOME/shared"
mkdir -p "$HOME/virtual-machines"

virt-install \
    --connect qemu:///session \
    --name ArchLinux \
    --description "Arch Linux" \
    --os-type="Linux" \
    --os-variant="archlinux" \
    --ram=1024 \
    --vcpus=2 \
    --cpu host-model-only \
    --disk path="$HOME"/virtual-machines/archlinux.qcow2,bus=virtio,size=20,format=qcow2 \
    --check path_in_use=off \
    --cdrom "$BASE_DIR"/LadOS*.iso \
    --boot uefi \
    --graphics spice \
    --filesystem "$HOME/shared,shared"

# To mount filesystem on guest
# mount -t 9p -o trans=virtio shared /shared -oversion=9p2000.L
