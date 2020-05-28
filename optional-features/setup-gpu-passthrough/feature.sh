#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly MOD_MKINITCPIO_CONF="/etc/mkinitcpio.conf"
readonly BASE_NOTHUNDERBOLT_CONF="$BASE_DIR/nothunderbolt.conf"
readonly NEW_NOTHUNDERBOLT_CONF="/etc/modprobe.d/nothunderbolt.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="setup-gpu-passthrough"
readonly FEATURE_DESC="Setup GPU passthrough"
readonly PROVIDES=()
readonly NEW_FILES=("$NEW_NOTHUNDERBOLT_CONF")
readonly MODIFIED_FILES=("$MOD_MKINITCPIO_CONF")
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()

readonly NEW_MODULES=("vfio_pci" "vfio" "vfio_iommu_type1" "vfio_virqfd")



function check_install() {
    local mod

    for mod in "${NEW_MODULES[@]}"; do
        if ! grep -q "$MOD_MKINITCPIO_CONF" -e "$mod"; then
            echo "$mod is missing from mkinitcpio.conf" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    if [[ ! -f "$NEW_NOTHUNDERBOLT_CONF" ]]; then
        echo "$NEW_NOTHUNDERBOLT_CONF is missing" >&2
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi

    qecho "$FEATURE_NAME is installed"
    return 0
}

function install() (
    qecho "Adding ${NEW_MODULES[*]} to $MOD_MKINITCPIO_CONF, if not present"
    source "$MOD_MKINITCPIO_CONF"

    for module in "${NEW_MODULES[@]}"; do
        if ! echo "${MODULES[*]}" | grep -q -e "$module"; then
            vecho "$MODULES"
            vecho "$module not found in mkinitcpio.conf"

            vecho "Adding $module to mkinitcpio.conf"
            MODULES=( "${MODULES[@]}" "$module" )
        else
            vecho "$module found in mkinitcpio.conf."
        fi
    done

    qecho "Updating $MOD_MKINITCPIO_CONF..."
    MODULES_LINE="MODULES=(${MODULES[*]})"
    sudo sed -i '/etc/mkinitcpio.conf' \
        -e "s/^MODULES=([a-z0-9 ]*)$/$MODULES_LINE/"

    qecho "Rebuilding initframfs..."
    sudo mkinitcpio --nocolor -P linux

    qecho "Copying nothunderbolt.conf to /etc/modprobe.d..."
    sudo install -Dm 644 "$BASE_NOTHUNDERBOLT_CONF" "$NEW_NOTHUNDERBOLT_CONF"

    qecho "Done"
    echo "Make sure you have virtualization enabled in your BIOS"
)

function uninstall() {
    qecho "Removing hooks..."
    for mod in "${NEW_MODULES[@]}"; do
        sudo sed -i "$MOD_MKINITCPIO_CONF" -e "s/$mod //"
    done

    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
