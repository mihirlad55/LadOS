#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly DRACUT_CONF_DIR="/etc/dracut.conf.d"
readonly PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
readonly BIN_INSTALL_DIR="/usr/local/bin"
readonly CMDLINE_DIR="/etc/cmdline.d"
readonly BASE_INSTALL_SH="$BASE_DIR/dracut-install.sh"
readonly BASE_REMOVE_SH="$BASE_DIR/dracut-remove.sh"
readonly BASE_INSTALL_DEFAULT_SH="$BASE_DIR/dracut-install-default.sh"
readonly BASE_INSTALL_HOOK="$BASE_DIR/90-dracut-install.hook"
readonly BASE_REMOVE_HOOK="$BASE_DIR/60-dracut-remove.hook"
readonly BASE_DRACUT_CONF="$BASE_DIR/main-dracut.conf"
readonly BASE_CMDLINE_CONF="$BASE_DIR/main-cmdline.conf"
readonly NEW_INSTALL_SH="$BIN_INSTALL_DIR/dracut-install.sh"
readonly NEW_REMOVE_SH="$BIN_INSTALL_DIR/dracut-remove.sh"
readonly NEW_INSTALL_DEFAULT_SH="$BIN_INSTALL_DIR/dracut-install-default.sh"
readonly NEW_INSTALL_HOOK="$PACMAN_HOOKS_DIR/90-dracut-install.hook"
readonly NEW_REMOVE_HOOK="$PACMAN_HOOKS_DIR/60-dracut-remove.hook"
readonly NEW_DRACUT_CONF="$DRACUT_CONF_DIR/main-dracut.conf"
readonly NEW_CMDLINE_CONF="$CMDLINE_DIR/main.conf"
readonly TMP_DRACUT_CONF="/tmp/main-dracut.conf"
readonly TMP_CMDLINE_CONF="/tmp/main-cmdline.conf"
readonly MKINITCPIO_INSTALL_HOOK="$PACMAN_HOOKS_DIR/90-mkinitcpio-install.hook"
readonly MKINITCPIO_REMOVE_HOOK="$PACMAN_HOOKS_DIR/60-mkinitcpio-remove.hook"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Dracut"
readonly FEATURE_DESC="Framework for creating initramfs"
readonly CONFLICTS=()
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_INSTALL_SH" \
    "$NEW_REMOVE_SH" \
    "$NEW_INSTALL_DEFAULT_SH" \
    "$NEW_INSTALL_HOOK" \
    "$NEW_REMOVE_HOOK" \
    "$NEW_DRACUT_CONF" \
    "$NEW_CMDLINE_CONF" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=( \
    "$TMP_DRACUT_CONF" \
    "$TMP_CMDLINE_CONF" \
)
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=("dracut" "binutils")
readonly DEPENDS_PIP3=()



# Create list of gpu drivers to include
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

# Install ucode for CPU
function install_ucode() {
    local model_line

    model_line="$(lscpu | grep 'Model name:')"

    if echo "$model_line" | grep -q -i 'intel'; then
        sudo pacman -S intel-ucode --needed --noconfirm
    elif echo "$model_line" | grep -q -i 'amd'; then
        sudo pacman -S amd-ucode --needed --noconfirm
    fi
}

# Symlinking /dev/null to the mkinitcpio install/remove hooks in the etc
# pacman hooks directory disables the hook
function disable_mkinitcpio() {
    sudo mkdir -p "$PACMAN_HOOKS_DIR"
    sudo ln -sf /dev/null "$MKINITCPIO_INSTALL_HOOK"
    sudo ln -sf /dev/null "$MKINITCPIO_REMOVE_HOOK"
}

# Remove the symlinks
function enable_mkinitcpio() {
    sudo rm -f "$MKINITCPIO_INSTALL_HOOK"
    sudo rm -f "$MKINITCPIO_REMOVE_HOOK"
}

# Generate main kernel command line arguments for dracut
function get_cmdline() {
    local swap_uuid swap_offset root_uuid root_fstype root_flags cmdline
    local root_source mapper_name luks_uuid

    swap_uuid="$(findmnt -no UUID -T /swapfile)"
    swap_offset="$(sudo filefrag -v /swapfile \
        | awk '{ if($1=="0:"){print $4} }' \
        | sed 's/\.//g')"

    root_uuid=$(findmnt -no UUID --target /)

    root_fstype=$(findmnt -no FSTYPE --target /)

    root_flags="rw,relatime"

    cmdline="root=UUID=$root_uuid rootfstype=$root_fstype rootflags=$root_flags"
    cmdline="$cmdline add_efi_memmap resume=UUID=$swap_uuid"
    cmdline="$cmdline swap_file_offset=$swap_offset"

    root_source="$(findmnt -no SOURCE --target /)"

    # For encrypted root partition
    if sudo cryptsetup status "$root_source" | grep -q "LUKS"; then
        mapper_name="${root_source#/dev/mapper/}"
        luks_uuid="$(lsblk -sno UUID,TYPE "$root_source" \
            | grep part \
            | cut -d' ' -f1)"

        cmdline="rd.luks.name=$luks_uuid=$mapper_name $cmdline"
    fi

    echo "$cmdline"
}

function check_install() {
    local f

    for f in "${NEW_FILES[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    qecho "$FEATURE_NAME is installed"
    return 0
}

function prepare() {
    local drivers cmdline

    vecho "Copying $BASE_DRACUT_CONF to $TMP_DRACUT_CONF..."
    cp -f "$BASE_DRACUT_CONF" "$TMP_DRACUT_CONF"

    mapfile -t drivers < <(get_gpu_drivers)
    qecho "Adding ${drivers[*]} to main-dracut.conf..."
    echo "add_drivers+=\" ${drivers[*]} \"" >> "$TMP_DRACUT_CONF"

    qecho "Generating cmdline..."
    cmdline="$(get_cmdline)"
    vecho "cmdline=$cmdline"
    echo "$cmdline" > "$TMP_CMDLINE_CONF"
}

function install() {
    qecho "Copying dracut conf to $DRACUT_CONF_DIR..."
    sudo install -Dm 644 "$TMP_DRACUT_CONF" "$NEW_DRACUT_CONF"

    qecho "Copying cmdline to $CMDLINE_DIR..."
    sudo install -Dm 644 "$TMP_CMDLINE_CONF" "$NEW_CMDLINE_CONF"

    qecho "Copying dracut hooks to $PACMAN_HOOKS_DIR"
    sudo mkdir -p "/etc/pacman.d/hooks"
    sudo install -Dm 644 "$BASE_INSTALL_HOOK" "$NEW_INSTALL_HOOK"
    sudo install -Dm 644 "$BASE_REMOVE_HOOK" "$NEW_REMOVE_HOOK"

    qecho "Copying dracut executables to $BIN_INSTALL_DIR..."
    sudo install -Dm 755 "$BASE_INSTALL_SH" "$NEW_INSTALL_SH"
    sudo install -Dm 755 "$BASE_INSTALL_DEFAULT_SH" "$NEW_INSTALL_DEFAULT_SH"
    sudo install -Dm 755 "$BASE_REMOVE_SH" "$NEW_REMOVE_SH"
}

function post_install() {
    qecho "Installing ucode..."
    install_ucode

    qecho "Generating image..."
    sudo "$NEW_INSTALL_DEFAULT_SH"

    qecho "Disabling mkinitcpio pacman hooks..."
    disable_mkinitcpio
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    rm -f "${TEMP_FILES[@]}"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"

    qecho "Enabling mkinitcpio pacman hooks..."
    enable_mkinitcpio
}


source "$LAD_OS_DIR/common/feature_footer.sh"
