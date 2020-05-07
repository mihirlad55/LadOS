#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"
REQUIRED_FEATURES_DIR="$BASE_DIR/../required-features"

function pause() {
    read -p "Press enter to continue..."
}

function update_mkinitcpio_modules() {
    NEW_MODULES=("$@")
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
    sed -i '/etc/mkinitcpio.conf' -e "s/^MODULES=([a-z0-9 ]*)$/$MODULES_LINE/"
}

function set_timezone() {
    local CURR_DIR="$PWD"

    local zone=
    local num=

    IFS=$'\n'
    cd /usr/share/zoneinfo
    while true; do
        local options=($(ls))
        local i=1
        for option in ${options[@]}; do
            echo "$i. $option"
            i=$(($i+1))
        done
        echo -n "Select closest match: "
        read num

	re='^[0-9]+$'
	if ! [[ $num =~ $re ]]; then
            continue
	fi
        num=$(($num-1))

	echo $num
        selection="${options[$num]}"
	echo "Selected $selection"
        if [[ -d "$selection" ]]; then
            echo "Navigating to $selection..."
            cd $selection
        elif [[ -e "$selection" ]]; then
            zone="${PWD}/${selection}"
            break
        fi
    done

    echo "You selected $zone. Now symlinking $zone to /etc/localtime..."
    
    ln -sf "$zone" /etc/localtime

    cd "$CURR_DIR"
}

function set_adjtime() {
    echo "Setting adjtime"
    hwclock --systohc
    echo "Set adjtime"
}

function set_locale() {
    echo "Opening /etc/locale.gen... Uncomment the correct locale..."
    pause

    pacman -S vim --noconfirm --needed
    vim /etc/locale.gen

    locale-gen

    local lang=$(cat /etc/locale.gen | egrep '^[^#].*$' -m 1 | cut -d' ' -f1)

    echo "LANG=$lang" > /etc/locale.conf

    echo "Locale is set"
}

function set_hostname() {
    local hostname

    echo -n "Enter a hostname for this computer: "
    read hostname

    echo $hostname > /etc/hostname

    echo "$hostname has been set in /etc/hostname"
}

function setup_hosts() {
    echo "Setting up default hosts file..."

    echo "127.0.0.1  localhost" > /etc/hosts
    echo "::1        localhost" >> /etc/hosts

    echo "Opening hosts file for additional configuration..."
    pause
    vim /etc/hosts
}

function update_mkinitcpio() {
    pci_info=$(lspci | cut -d' ' -f2- | grep -e '^VGA' -e '3D' -e 'Display')
    NEW_MODULES=()

    if echo $pci_info | grep -i 'amd'; then
        NEW_MODULES=("${NEW_MODULES[@]}" "amdgpu")
    fi

    if echo $pci_info | grep -i 'intel'; then
        NEW_MODULES=("${NEW_MODULES[@]}" "i915")
    fi

    update_mkinitcpio_modules ${NEW_MODULES[@]}
}

function create_initramfs() {
    echo "Making initframfs..."
    mkinitcpio -P linux
    echo "Done making initramfs"
}

function set_root_passwd() {
    echo "Set root password"
    until passwd; do sleep 1s; done
    echo "Root password set"
}

function create_user_account() {
    echo "Creating new default user account..."
    echo -n "Enter username: "
    read username

    echo "Creating user $username"
    useradd -m $username

    echo "Set password for $username"

    until passwd $username; do sleep 1s; done

    echo "Password set for $username"
}

function setup_sudo_and_su() {
    pacman -Syyu --noconfirm

    echo "Installing sudo..."
    $REQUIRED_FEATURES_DIR/1-sudoers/install.sh

    usermod -a -G wheel "$username"
    echo "Added $username to group wheel"

    echo "Changing user to $username..."
    cp -r /root/LadOS /home/$username
    chown -R $username /home/$username/LadOS
    su -P -c "/home/$username/LadOS/install/su-install.sh" - mihirlad55
}

set_timezone

set_adjtime

set_locale

set_hostname

setup_hosts

update_mkinitcpio

create_initramfs

set_root_passwd

create_user_account

setup_sudo_and_su
