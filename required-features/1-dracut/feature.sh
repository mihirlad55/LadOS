#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

DRACUT_MAIN_CONF_PATH="$BASE_DIR/main-dracut.conf"
DRACUT_CONF_DIR="/etc/dracut.conf.d"
PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
BIN_INSTALL_DIR="/usr/local/bin"


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
    "$DRACUT_CONF_DIR/cmdline-dracut.conf")
modified_files=()
temp_files=("/tmp/main-dracut.conf" \
    "/tmp/cmdline-dracut.conf")

depends_aur=()
depends_pacman=("dracut")
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
    swap_uuid=$(cat /etc/fstab | \
        grep -P -e "UUID=[a-zA-Z0-9\-]*[\t ]+none[\t ]+swap" | \
        grep -o -P 'UUID=[a-zA-Z0-9\-]*' | \
        sed 's/UUID=//')

    root_uuid=$(cat /etc/fstab | \
        grep -P -e "UUID=[a-zA-Z0-9\-]*[\t ]+/[\t ]+" | \
        grep -o -P 'UUID=[a-zA-Z0-9\-]*' | \
        sed 's/UUID=//')

    cmdline="add_efi_memmap splash quiet loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0"

    cmdline="root=UUID=$root_uuid resume=UUID=$swap_uuid $cmdline"

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
    echo "drivers+=\"${drivers[*]}\"" >> /tmp/main-dracut.conf

    qecho "Generating cmdline..."
    cmdline="$(get_cmdline)"
    vecho "cmdline=$cmdline"
    echo "kernel_cmdline=\"$cmdline\"" > /tmp/cmdline-dracut.conf
}

function install() {
    qecho "Copying dracut confs to $DRACUT_CONF_DIR..."
    sudo install -Dm 644 "/tmp/main-dracut.conf" "$DRACUT_CONF_DIR/main-dracut.conf"
    sudo install -Dm 644 "/tmp/cmdline-dracut.conf" "$DRACUT_CONF_DIR/cmdline-dracut.conf"

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

source "$LAD_OS_DIR/common/feature_common.sh"

# vim:ft=sh
