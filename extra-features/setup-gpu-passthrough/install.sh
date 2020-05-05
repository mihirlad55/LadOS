#!/usr/bin/bash

BASE_DIR=$(dirname "$0")

NEW_MODULES=("vfio_pci" "vfio" "vfio_iommu_type1" "vfio_virqfd")

echo "Adding ${NEW_MODULES[@]} to /etc/mkinitcpio.conf, if not present"
source /etc/mkinitcpio.conf
for module in ${NEW_MODULES[@]}; do
    if ! echo ${MODULES[@]} | grep "$module" > /dev/null; then
        echo $MODULES
        echo "$module not found in mkinitcpio.conf"

        echo "Adding $module to mkinitcpio.conf"
        MODULES=( "${MODULES[@]}" "$module" )
    else
        echo "$module found in mkinitcpio.conf."
    fi
done

echo "Updating /etc/mkinitcpio.conf..."
MODULES_LINE="MODULES=(${MODULES[@]})"
sudo sed -i '/etc/mkinitcpio.conf' -e "s/^MODULES=([a-z0-9 ]*)$/$MODULES_LINE/"

echo "Rebuilding initframfs..."

sudo mkinitcpio -P linux

sudo install -Dm 644 $BASE_DIR/nothunderbolt.conf /etc/modprobe.d/nothunderbolt.conf

echo "Done"
echo "Make sure you have virtualization enabled in your BIOS"
