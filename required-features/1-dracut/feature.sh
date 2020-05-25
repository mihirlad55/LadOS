#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

DRACUT_MAIN_CONF_PATH="$BASE_DIR/main-dracut.conf"
DRACUT_CONF_DIR="/etc/dracut.conf.d"
PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
BIN_INSTALL_DIR="/usr/local/bin"

CMDLINE_DIR="/etc/cmdline.d"
CMDLINE_FILE="$CMDLINE_DIR/main.conf"

feature_name="Dracut"
feature_desc="Framework for creating initramfs"

conflicts=()

provides=()
new_files=("$BIN_INSTALL_DIR/dracut-install.sh" \
    "$BIN_INSTALL_DIR/dracut-install-default.sh" \
    "$BIN_INSTALL_DIR/dracut-remove.sh" \
    "$PACMAN_HOOKS_DIR/90-dracut-install.hook" \
    "$PACMAN_HOOKS_DIR/60-dracut-remove.hook" \
    "$DRACUT_CONF_DIR/main-dracut.conf" \
    "$CMDLINE_FILE")
modified_files=()
temp_files=("/tmp/main-dracut.conf" \
    "/tmp/main-cmdline.conf")

depends_aur=()
#depends_pacman=("dracut" "binutils")
depends_pip3=()



function get_gpu_drivers() {
    local pci_info drivers

    pci_info=$(lspci | cut -d' ' -f2- | grep -e '^VGA' -e '3D' -e 'Display')
    drivers=()

    if echo "$pci_info" | grep -q -i 'amd'; then
        drivers=("${drivers[@]}" "amdgpu")
    fi

    if echo "$pci_info" | grep -q -i 'intel'; then
        drivers=("${drivers[@]}" "i915")
    fi

    if echo "$pci_info" | grep -q -i "nvidia"; then
        drivers=("${drivers[@]}" "nouveau")
    fi

    echo "${drivers[@]}"
}

function install_ucode() {
    model_line="$(lscpu | grep 'Model name:')"

    if echo "$model_line" | grep -q -i 'intel'; then
        sudo pacman -S intel-ucode --needed --noconfirm
    elif echo "$model_line" | grep -q -i 'amd'; then
        sudo pacman -S amd-ucode --needed --noconfirm
    fi
}

function disable_mkinitcpio() {
    sudo mkdir -p "$PACMAN_HOOKS_DIR"
    sudo ln -sf /dev/null "$PACMAN_HOOKS_DIR/90-mkinitcpio-install.hook"
    sudo ln -sf /dev/null "$PACMAN_HOOKS_DIR/60-mkinitcpio-remove.hook"
}

function enable_mkinitcpio() {
    sudo rm -f "$PACMAN_HOOKS_DIR/90-mkinitcpio-install.hook"
    sudo rm -f "$PACMAN_HOOKS_DIR/60-mkinitcpio-remove.hook"
}

function get_cmdline() {
    swap_uuid="$(findmnt -no UUID -T /swapfile)"
    swap_offset="$(sudo filefrag -v /swapfile | \
        awk '{ if($1=="0:"){print $4} }' | \
        sed 's/\.//g')"

    root_uuid=$(findmnt -no UUID --target /)

    root_fstype=$(findmnt -no FSTYPE --target /)

    root_flags="rw,relatime"

    cmdline="root=UUID=$root_uuid rootfstype=$root_fstype rootflags=$root_flags add_efi_memmap resume=UUID=$swap_uuid swap_file_offset=$swap_offset"

    root_source="$(findmnt -no SOURCE --target /)"

    # encrypted partition
    if sudo cryptsetup status "$root_source" | grep -q "LUKS"; then
        mapper_name="${root_source#/dev/mapper/}"
        luks_uuid="$(lsblk -sno UUID,TYPE "$root_source" | \
            grep part | \
            cut -d' ' -f1)"

        cmdline="rd.luks.name=$luks_uuid=$mapper_name $cmdline"
    fi

    echo "$cmdline"
}

function check_install() {
    for f in ${new_files[@]}; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$feature_name is not installed" >&2
            return 1
        fi
    done

    qecho "$feature_name is installed"
    return 0
}

function prepare() {
    local drivers cmdline

    vecho "Copying $DRACUT_MAIN_CONF_PATH to /tmp/main-dracut.conf..."
    cp -f "$DRACUT_MAIN_CONF_PATH" /tmp/main-dracut.conf

    drivers=( $(get_gpu_drivers) )
    qecho "Adding ${drivers[*]} to main-dracut.conf..."
    echo "add_drivers+=\" ${drivers[*]} \"" >> /tmp/main-dracut.conf

    qecho "Generating cmdline..."
    cmdline="$(get_cmdline)"
    vecho "cmdline=$cmdline"
    echo "$cmdline" > /tmp/main-cmdline.conf
}

function install() {
    qecho "Copying dracut conf to $DRACUT_CONF_DIR..."
    sudo install -Dm 644 "/tmp/main-dracut.conf" "$DRACUT_CONF_DIR/main-dracut.conf"

    qecho "Copying cmdline to $CMDLINE_DIR..."
    sudo install -Dm 644 "/tmp/main-cmdline.conf" "$CMDLINE_FILE"

    qecho "Copying dracut hooks to $PACMAN_HOOKS_DIR"
    sudo mkdir -p "/etc/pacman.d/hooks"
    sudo install -Dm 644 "$BASE_DIR/90-dracut-install.hook" "$PACMAN_HOOKS_DIR/90-dracut-install.hook"
    sudo install -Dm 644 "$BASE_DIR/60-dracut-remove.hook" "$PACMAN_HOOKS_DIR/60-dracut-remove.hook"

    qecho "Copying dracut executables to $BIN_INSTALL_DIR..."
    sudo install -Dm 755 "$BASE_DIR/dracut-install.sh" "$BIN_INSTALL_DIR/dracut-install.sh"
    sudo install -Dm 755 "$BASE_DIR/dracut-install-default.sh" "$BIN_INSTALL_DIR/dracut-install-default.sh"
    sudo install -Dm 755 "$BASE_DIR/dracut-remove.sh" "$BIN_INSTALL_DIR/dracut-remove.sh"
}

function post_install() {
    qecho "Installing ucode..."
    install_ucode

    qecho "Generating image..."
    sudo $BIN_INSTALL_DIR/dracut-install-default.sh

    qecho "Disabling mkinitcpio pacman hooks..."
    disable_mkinitcpio
}

function cleanup() {
    qecho "Removing ${temp_files[*]}..."
    rm -f "${temp_files[@]}"
}

function uninstall() {
    qecho "Removing ${new_files[*]}..."
    sudo rm -f "${new_files[@]}"

    qecho "Enabling mkinitcpio pacman hooks..."
    enable_mkinitcpio
}

source "$LAD_OS_DIR/common/feature_footer.sh"

# vim:ft=sh
