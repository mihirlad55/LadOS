#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

yay -S plymouth --needed --noconfirm

sudo cp -r $BASE_DIR/deus_ex /usr/share/plymouth/themes/
sudo install -Dm 644 $BASE_DIR/plymouthd.conf /etc/plymouth/plymouthd.conf

sudo systemctl disable lightdm
sudo systemctl enable lightdm-plymouth

if ! egrep /etc/mkinitcpio.conf -e "plymouth" > /dev/null; then
    echo "No plymouth hook found in mkinitcpio.conf"
    source /etc/mkinitcpio.conf
    HOOKS=( "${HOOKS[@]:0:2}" "plymouth" "${HOOKS[@]:2}" )

    IFS=$' '
    HOOKS_LINE="HOOKS=(${HOOKS[*]})"

    echo "Adding plymouth to HOOKS array..."
    sudo sed -i '/etc/mkinitcpio.conf' -e "s/^HOOKS=([a-z ]*)$/$HOOKS_LINE/"
else
    echo "Plymouth hook already added to mkinitcpio.conf"
fi

sudo mkinitcpio -P linux

echo "Done"
