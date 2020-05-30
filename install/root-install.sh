#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/install_common.sh"


function enable_localrepo() {
    msg "Checking for localrepo..."
    if [[ -f "$LAD_OS_DIR/localrepo/localrepo.db" ]]; then
        if ! grep -q /etc/pacman.conf -e "LadOS"; then
            msg2 "Found localrepo. Enabling..."
            sed -i /etc/pacman.conf \
                -e '1 i\Include = /LadOS/install/localrepo.conf'
        else
            msg2 "Localrepo already enabled"
        fi
        pacman -Sy
    fi
}

function set_timezone() (
    local zone num option options i selection re

    msg "Setting timezone..."

    if [[ "$CONF_TIMEZONE_PATH" != "" ]]; then
        zone="$CONF_TIMEZONE_PATH"
    else
        IFS=$'\n'
        cd /usr/share/zoneinfo || exit 1
        while true; do
            mapfile -t options < <(ls)

            i=1
            for option in "${options[@]}"; do
                echo "$i. $option"
                i=$((i+1))
            done
            ask "Select closest match"
            read -r num

            re='^[0-9]+$'
            if ! [[ $num =~ $re ]]; then continue; fi

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
    local lang

    msg "Setting locale..."

    if [[ "$CONF_LOCALE" != "" ]]; then
        sed -i /etc/locale.gen -e "/#$CONF_LOCALE/s/^# *//"
    else
        msg2 "Opening /etc/locale.gen. Uncomment the correct locale..."
        pause
        vim /etc/locale.gen
    fi

    locale-gen

    lang=$(grep -E /etc/locale.gen -e '^[^#].*$' -m 1 | cut -d' ' -f1)

    echo "LANG=$lang" > /etc/locale.conf
}

function set_hostname() {
    local hostname

    msg "Setting hostname..."

    if [[ "$CONF_HOSTNAME" != "" ]]; then
        hostname="$CONF_HOSTNAME"
    else
        ask "Enter a hostname for this computer"
        read -r hostname
    fi

    echo "$hostname" > /etc/hostname
}

function setup_hosts() {
    local hosts

    msg "Setting up hosts file..."

    echo "127.0.0.1  localhost" > /etc/hosts
    echo "::1        localhost" >> /etc/hosts

    if [[ -f "$CONF_DIR/hosts" ]]; then
        hosts="$(cat "$CONF_DIR"/hosts)"
    fi

    if [[ "$hosts" != "" ]]; then
        echo "$hosts" >> /etc/hosts
    elif [[ "$CONF_EDIT_HOSTS" = "yes" ]]; then
        msg2 "Opening hosts file for additional configuration..."
        pause
        vim /etc/hosts
    fi
}

function install_dracut() {
    msg "Installing dracut..."

    "$REQUIRED_FEATURES_DIR"/*dracut/feature.sh "${F_FLAGS[@]}" full
}

function sync_pacman() {
    pacman -Syyu --noconfirm
}

function install_sudo() {
    msg "Installing sudo..."

    "$REQUIRED_FEATURES_DIR"/*sudoers/feature.sh "${F_FLAGS[@]}" full
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
    local users
    
    msg "Creating new default user account..."

    if [[ "$CONF_USERNAME" != "" ]]; then
        username="$CONF_USERNAME"
    else
        ask "Enter username"
        read -r username
    fi

    mapfile -t users < <(cut -d':' -f1 /etc/passwd)

    if echo "${users[*]}" | grep -q "$username"; then
        msg2 "$username already exists"
    else
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
    fi

    # Temporary no password prompt for installation
    msg2 "Temporarily disabling $username's sudo password prompt..."
    echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/20-sudoers-temp
}

function start_user_install() {
    msg "Preparing for user install..."

    msg2 "Switching user to $username..."
    su -P -c "/LadOS/install/user-install.sh ${V_FLAG[@]}" - "$username"
}


enable_localrepo

set_timezone

set_adjtime

install_vim

set_locale

set_hostname

setup_hosts

install_dracut

sync_pacman

install_sudo

set_root_passwd

create_user_account

start_user_install
