#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/install_common.sh"

# Marked readonly after set in connect_to_internet()
WIFI_ENABLED=



###############################################################################
# Generate crypttab file contents for encrypted partitions
# Globals:
#   None
# Arguments:
#   Path to mount point of new host system
# Outputs:
#   Contents of a crypttab file for new host system with password files for
#   each partition pointing to /root/<partition_name>.bin
#
# Returns:
#   0 if successful
###############################################################################

function gencrypttab() {
    local mountpoint path mnt part_uuid name password crypt_info keysize cipher
    local options

    mountpoint="$1"

    while IFS=$' ' read -r path uuid mnt <&3; do {
        mnt="${mnt%$mountpoint}"
        if [[ "$mnt" != "/" ]]; then

            part_uuid="$(lsblk -sno UUID,TYPE "$path" | sed -n 's/ *part//p')"

            name="${path#/dev/mapper/}"
            password="/root/${name}.bin"

            crypt_info="$(cryptsetup status "$name" | tr -s ' ' | sed 's/ *//')"
            keysize="$(echo "$crypt_info" | grep keysize |  cut -d' ' -f2)"
            cipher="$(echo "$crypt_info" | grep cipher | cut -d' ' -f2)"


            options="cipher=$cipher,size=$keysize"

            printf "%s\tUUID=%s\t%s\t%s\n" "$name" "$part_uuid" "$password" \
                "$options"
        fi

    } 3<&-
    done 3< <(lsblk -n -o PATH,UUID,TYPE,MOUNTPOINT | sed -n 's/ *crypt//2p')
}

function check_efi_mode() {
    msg "Checking if system booted in EFI mode..."
    if ls /sys/firmware/efi/efivars &> /dev/null; then
        msg2 "Verified EFI boot"
    else
        msg2 "System not booted in EFI mode"
        exit 1
    fi
}

function setup_partitions() {
    msg "Partition setup..."

    plain "Make sure you create the system partitions, format them, and mount"
    plain "root on /mnt with all the filesystems mounted on root"

    if [[ "$CONF_NOCONFIRM" = "no" ]]; then
        if ! prompt "Are the filesystems mounted?"; then
            msg2 "Please partition the drive and exit the shell once finished.."
            bash
        fi
    fi
}

function connect_to_internet() {
    msg "Checking internet connection..."
    if ! ping -c 1 www.google.com &> /dev/null; then
        if [[ "$CONF_USE_WIFI" = "yes" ]] || prompt "Setup WiFi for setup?"; then
            setup_wifi
            WIFI_ENABLED=1
        else
            WIFI_ENABLED=0
        fi
        readonly WIFI_ENABLED
    fi

    msg2 "Waiting for connection to Internet..."
    until ping -c 1 www.google.com &> /dev/null; do sleep 1; done
}

function setup_wifi() {
    local network_conf conf_path adapter

    msg "Setting up WiFI..."

    if [[ -f "$CONF_DIR/network.conf" ]]; then
        network_conf="$(cat "$CONF_DIR/network.conf")"
    fi

    conf_path="/tmp/wpa_supplicant.conf"

    # Boilerplate for running service
    echo "ctrl_interface=/run/wpa_supplicant" > "$conf_path"
    echo "update_config=1" >> $conf_path

    # Append contents of network.conf to file
    if [[ "$network_conf" != "" ]]; then
        echo "$network_conf" >> "$conf_path"
    else
        msg2 "Opening wpa_supplicant.conf to add network info..."
        pause
        vi $conf_path
    fi

    if [[ "$CONF_WIFI_ADAPTER" != "" ]]; then
        adapter="$CONF_WIFI_ADAPTER"
    else
        ip link
        adapter="$(ask "Enter name of WiFI adapter")"
    fi

    # Start wpa_supplicant and dhcpcd
    wpa_supplicant "${V_FLAG[@]}" -B -i"${adapter}" -c "$conf_path"
    dhcpcd "${V_FLAG[@]}"
}

function update_system_clock() {
    msg "Updating system clock..."
    timedatectl set-ntp true
}

function rank_mirrors() {
    local country

    msg "Ranking pacman mirrors..."

    if [[ "$CONF_COUNTRY_CODE" != "" ]]; then
        country="$CONF_COUNTRY_CODE"        
    else
        country="$(ask "Enter your country code (i.e. US)")"
    fi

    msg2 "Beginning mirror ranking..." "(This may take a minute)"
    curl -sL "https://www.archlinux.org/mirrorlist/?country=${country}&protocol=https&use_mirror_status=on" \
        | sed -e 's/^#Server/Server/' -e '/^#/d' \
        | "$BASE_DIR"/rankmirrors -n 5 -m 1 - \
        > /etc/pacman.d/mirrorlist

    msg2 "Top 5 $country mirrors saved in /etc/pacman.d/mirrorlist"
}

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

function create_swap_file() {
    local total_mem swap_path

    msg "Creating swap file..."

    if [[ -f /mnt/swapfile ]] && findmnt --target /mnt/swapfile > /dev/null; then
        msg2 "Swap file already exists at /mnt/swapfile"
	return
    else
        rm -f /mnt/swapfile
    fi

    total_mem="$(free -m | grep Mem | tr -s ' ' | cut -d' ' -f2)"
    swap_path="/mnt/swapfile"

    msg2 "Allocating ${total_mem}MiB file at $swap_path..."
    dd if=/dev/zero of="$swap_path" bs=1M count="$total_mem" status=progress

    msg2 "Setting permissions on $swap_path"
    chmod 600 "$swap_path"

    msg2 "Making swap..."
    mkswap "$swap_path"

    msg2 "Turning on swap..."
    swapon "$swap_path"
}

function base_install() {
    msg "Starting base install..."

    if mount | grep -q /mnt; then
        pacstrap /mnt base linux linux-firmware
    else
        error "Parititions not mounted on /mnt. Please mount the filesystems."
        exit 1
    fi
}

function generate_fstab() {
    msg "Generating fstab..."
    genfstab -U /mnt > /mnt/etc/fstab
}

function generate_crypttab() {
    local name names secret_file part_path

    msg "Generating crypttab..."

    if ! lsblk | grep -q crypt; then
        msg2 "No encrypted partitions detected, continuing..."
        return
    fi

    # Get name of each crypt partition
    mapfile -t paths < <(lsblk -n -o PATH,TYPE | sed -n 's/ *crypt//2p')

    # Generate password file for each partition
    for path in "${paths[@]}"; do
        msg2 "Generating password file for $name partition"
        name="${path#/dev/mapper/}"

        # Get path to physical partition
        part_path="$(lsblk -sno PATH,TYPE "$path" \
            | grep 'part' \
            |  tr -s ' ' \
            | cut -d' ' -f1)"

        # Path to secret file for $name partition
        secret_file="/mnt/root/${name}.bin"

        msg3 "Generating password for $name at $secret_file..."
        dd if=/dev/urandom of="$secret_file" bs=32 count=1

        msg3 "Adding password using cryptsetup..."
        cryptsetup luksAddKey "$part_path" "$secret_file"
    done

    msg2 "Generating crypttab file..."
    gencrypttab /mnt > /mnt/etc/crypttab
    chmod 600 /mnt/etc/crypttab
}

function start_root_install() {
    msg "Preparing for root install..."

    msg2 "Copying LadOS to new system..."
    cp -rft "/mnt" "$LAD_OS_DIR"
    chmod -R go=u /mnt/LadOS

    if [[ "$WIFI_ENABLED" -eq 1 ]]; then
        msg2 "Copying wpa_supplicant to new system..."
        mkdir -p /mnt/etc/wpa_supplicant
        install -Dm 644 /tmp/wpa_supplicant.conf \
            /etc/wpa_supplicant/wpa_supplicant.conf
    fi

    msg2 "Arch-chrooting to system as root..."
    arch-chroot /mnt /LadOS/install/root-install.sh "${V_FLAG[@]}"
}



check_efi_mode

setup_partitions

connect_to_internet

update_system_clock

rank_mirrors

enable_localrepo

create_swap_file

base_install

generate_fstab

generate_crypttab

start_root_install
