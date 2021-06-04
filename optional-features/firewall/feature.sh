#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly BASE_NFTABLES_RULES="$BASE_DIR/nftables.conf"
readonly NEW_NFTABLES_RULES="/etc/nftables.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Firewall"
readonly FEATURE_DESC="Install IP Tables Rules"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_IPTABLES_RULES" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(iptables-nft sshguard)
readonly DEPENDS_PIP3=()

function pre_depends() {
    if pacman -Q "iptables" > /dev/null && ! pacman -Q "iptables-nft"; then
        sudo pacman -Rdd iptables
        sudo pacman -S iptables-nft --noconfirm --needed
    fi
}

function check_install() {
    if pacman -Q "$DEPENDS_PACMAN" > /dev/null &&
      diff "$BASE_NFTABLES_RULES" "$NEW_NFTABLES_RULES"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying "$BASE_NFTABLES_RULES" to $NEW_NFTABLES_RULES..."
    sudo install -Dm 644 "$BASE_NFTABLES_RULES" "$NEW_NFTABLES_RULES"

    qecho "Editing sshguard.conf to use nftables..."
    sudo sed -i \
      's/^BACKEND=.*$/BACKEND="\/usr\/lib\/sshguard\/sshg-fw-nft-sets"/' \
      /etc/sshguard.conf
}

function post_install() {
    qecho "Enabling nftables.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" nftables.service

    qecho "Enabling sshguard.service"
    sudo systemctl enable "${SYSTEMD_FLAGS[@]}" sshguard.service
}

function uninstall() {
    qecho "Disabling nftables.service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" nftables.service

    qecho "Disabling sshguard.service"
    sudo systemctl disable "${SYSTEMD_FLAGS[@]}" sshguard.service

    qecho "Removing $NEW_NFTABLES_RULES..."
    sudo rm -f "$NEW_NFTABLES_RULES"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
