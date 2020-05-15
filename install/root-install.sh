#!/usr/bin/bash

set -o errtrace
set -o pipefail
trap error_trap ERR


BASE_DIR="$( readlink -f "$(dirname "$0")" )"
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/install"
REQUIRED_FEATURES_DIR="$BASE_DIR/../required-features"

VERBOSITY_FLAG="-q"
VERBOSITY=


if [[ -f "$CONF_DIR/conf.sh" ]]; then source "$CONF_DIR/conf.sh";
else source "$CONF_DIR/conf.sh.sample"; fi

source "$LAD_OS_DIR/common/message.sh"



function error_trap() {
    error_code="$?"
    last_command="$BASH_COMMAND"
    command_caller="$(caller)"
    
    echo "$command_caller: \"$last_command\" returned error code $error_code" >&2

    exit $error_code
}

function enable_localrepo() {
    msg "Checking for localrepo..."
    if [[ -f "$LAD_OS_DIR/localrepo/localrepo.db" ]]; then
	if ! grep -q /etc/pacman.conf -e "LadOS"; then
	    msg2 "Found localrepo. Enabling..."
	    sed -i /etc/pacman.conf -e '1 i\Include = /LadOS/install/localrepo.conf'
	else
            msg2 "Localrepo already enabled"
	fi
        pacman -Sy
    fi
}

function update_mkinitcpio_modules() {
    [[ -n "$VERBOSITY" ]] && echo "Updating mkinitcpio..."

    NEW_MODULES=("$@")

    [[ -n "$VERBOSITY" ]] && echo "Adding ${NEW_MODULES[*]} to /etc/mkinitcpio.conf, if not present"

    source /etc/mkinitcpio.conf

    for module in "${NEW_MODULES[@]}"; do
        if ! echo "${MODULES[@]}" | grep -q "$module"; then
            [[ -n "$VERBOSITY" ]] && echo "$module not found in mkinitcpio.conf"

            [[ -n "$VERBOSITY" ]] && echo "Staging $module for addition"
            MODULES=( "${MODULES[@]}" "$module" )
        else
            [[ -n "$VERBOSITY" ]] && echo "$module already found"
        fi
    done

    [[ -n "$VERBOSITY" ]] && echo "Updating /etc/mkinitcpio.conf..."
    MODULES_LINE="MODULES=(${MODULES[*]})"
    sed -i '/etc/mkinitcpio.conf' -e "s/^MODULES=([a-z0-9 ]*)$/$MODULES_LINE/"
}

function set_timezone() (
    msg "Setting timezone..."

    local zone=
    local num=

    if [[ "$CONF_TIMEZONE_PATH" != "" ]]; then
        zone="$CONF_TIMEZONE_PATH"
    else
        IFS=$'\n'
        cd /usr/share/zoneinfo || exit 1
        while true; do
            local options
            mapfile -t options < <(ls)

            local i=1
            for option in "${options[@]}"; do
                echo "$i. $option"
                i=$((i+1))
            done
            num="$(ask "Select closest match")"

            re='^[0-9]+$'
            ! [[ $num =~ $re ]] && continue

            num=$((num-1))

            selection="${options[$num]}"

            if [[ -d "$selection" ]]; then
                cd "$selection" || exit 1
            elif [[ -e "$selection" ]]; then
                zone="${PWD}/${selection}"
                break
            fi
        done
    fi


    msg2 "$zone selected"
    
    ln -sf "$zone" /etc/localtime
)

function set_adjtime() {
    msg "Setting adjtime..."
    hwclock --systohc
}

function install_vim() {
    msg "Installing vim to edit config files..."

    pacman -S vim --noconfirm --needed
}

function set_locale() {
    msg "Setting locale..."

    if [[ "$CONF_LOCALE" != "" ]]; then
        sed -i /etc/locale.gen -e "/#$CONF_LOCALE/s/^# *//"
    else
        msg2 "Opening /etc/locale.gen. Uncomment the correct locale..."
        pause
        vim /etc/locale.gen
    fi

    locale-gen

    local lang
    lang=$(grep -E /etc/locale.gen -e '^[^#].*$' -m 1 | cut -d' ' -f1)

    echo "LANG=$lang" > /etc/locale.conf
}

function set_hostname() {
    msg "Setting hostname..."
    local hostname

    if [[ "$CONF_HOSTNAME" != "" ]]; then
        hostname="$CONF_HOSTNAME"
    else
        hostname="$(ask "Enter a hostname for this computer")"
    fi

    echo "$hostname" > /etc/hostname
}

function setup_hosts() {
    msg "Setting up hosts file..."

    echo "127.0.0.1  localhost" > /etc/hosts
    echo "::1        localhost" >> /etc/hosts

    [[ -f "$CONF_DIR/hosts" ]] && hosts="$(cat "$CONF_DIR"/hosts)"

    if [[ "$hosts" != "" ]]; then
        echo "$hosts" >> /etc/hosts
    elif [[ "$CONF_EDIT_HOSTS" = "yes" ]]; then
        msg2 "Opening hosts file for additional configuration..."
        pause
        vim /etc/hosts
    fi
}

function update_mkinitcpio() {
    msg "Updating mkinitcpio..."
    pci_info=$(lspci | cut -d' ' -f2- | grep -e '^VGA' -e '3D' -e 'Display')
    NEW_MODULES=()

    if echo "$pci_info" | grep -q -i 'amd'; then
        NEW_MODULES=("${NEW_MODULES[@]}" "amdgpu")
    fi

    if echo "$pci_info" | grep -q -i 'intel'; then
        NEW_MODULES=("${NEW_MODULES[@]}" "i915")
    fi

    msg2 "Ensuring ${NEW_MODULES[*]} are present in mkinitcpio.conf"
    update_mkinitcpio_modules "${NEW_MODULES[@]}"
}

function create_initramfs() {
    msg "Creating initramfs..."
    mkinitcpio --nocolor -P linux
}

function sync_pacman() {
    pacman -Syyu --noconfirm
}

function install_sudo() {
    msg "Installing sudo..."

    "$REQUIRED_FEATURES_DIR"/1-sudoers/feature.sh "${VERBOSITY_FLAG}" --no-service-start full
}

function set_root_passwd() {
    msg "Setting root password..."

    if [[ "$CONF_ROOT_PASSWORD" != "" ]]; then
        echo "root:$CONF_ROOT_PASSWORD" | chpasswd
    else
        until passwd; do sleep 1s; done
    fi
}

function create_user_account() {
    msg "Creating new default user account..."

    local username

    if [[ "$CONF_USERNAME" != "" ]]; then
        username="$CONF_USERNAME"
    else
        username="$(ask "Enter username")"
    fi

    msg2 "Creating user $username..."
    useradd -m "$username"

    msg2 "Adding $username to group wheel..."
    usermod -a -G wheel "$username"

    msg2 "Setting password for $username..."
    if [[ "$CONF_PASSWORD" != "" ]]; then
        echo "$username:$CONF_PASSWORD" | chpasswd
    else
        until passwd "$username"; do sleep 1s; done
    fi

    # Temporary no password prompt for installation
    msg2 "Temporarily disabling $username's sudo password prompt..."
    echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/20-sudoers-temp

    # Store username in /tmp/default_user for second chroot
    echo "$username" > /tmp/default_user
}


if [[ "$1" = "-v" ]] || [[ "$CONF_VERBOSITY" -eq 1 ]]; then
    VERBOSITY=1
    VERBOSITY_FLAG=""
elif [[ "$1" = "-vv" ]] || [[ "$CONF_VERBOSITY" -eq 2 ]]; then
    VERBOSITY=2
    VERBOSITY_FLAG="-v"
fi

enable_localrepo

set_timezone

set_adjtime

install_vim

set_locale

set_hostname

setup_hosts

update_mkinitcpio

create_initramfs

sync_pacman

install_sudo

set_root_passwd

create_user_account
