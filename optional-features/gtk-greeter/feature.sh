#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/gtk-greeter"
readonly CONF_USER_PNG="$CONF_DIR/user.png"
readonly CONF_LOGIN_PNG="$CONF_DIR/login.png"
readonly NEW_USER_PNG="/var/lib/AccountsService/icons/$USER.png"
readonly NEW_LOGIN_PNG="/usr/share/backgrounds/login.png"
readonly NEW_USER_INI="/var/lib/AccountsService/users/$USER"
readonly MOD_GTK_GREETER_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
readonly MOD_LIGHTDM_CONF="/etc/lightdm/lightdm.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="gtk-greeter"
readonly FEATURE_DESC="Install lightdm-gtk-greeter with user avatar and \
background and maia-gtk-theme"
readonly CONFLICTS=(webkit2-greeter)
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_USER_INI" \
    "$NEW_USER_PNG" \
    "$NEW_LOGIN_PNG" \
)
readonly MODIFIED_FILES=( \
    "$MOD_LIGHTDM_CONF" \
    "$MOD_GTK_GREETER_CONF" \
)
readonly TEMP_FILES=()
readonly DEPENDS_AUR=(maia-gtk-theme)
readonly DEPENDS_PACMAN=(lightdm-gtk-greeter accountsservice)
readonly DEPENDS_PIP3=()



function check_install() {
    if grep -q "$MOD_LIGHTDM_CONF" -e "^greeter-session=lightdm-gtk-greeter$" &&
        pacman -Q lightdm-gtk-greeter > /dev/null &&
        diff "$BASE_DIR/lightdm-gtk-greeter.conf" "$MOD_GTK_GREETER_CONF"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Copying lightdm-gtk-greeter to /etc/lightdm/..."
    sudo install -Dm 644 "$BASE_DIR/lightdm-gtk-greeter.conf" \
        "$MOD_GTK_GREETER_CONF"

    qecho "Changing greeter session in $MOD_LIGHTDM_CONF"
    sudo sed -i 's/#*greeter-session=.*$/greeter-session=lightdm-gtk-greeter/' \
        "$MOD_LIGHTDM_CONF"

    qecho "Creating $NEW_USER_INI ini"
    echo "[User]" | sudo tee "$NEW_USER_INI" > /dev/null
    echo "Icon=$NEW_LOGIN_PNG" | sudo tee -a "$NEW_USER_INI" > /dev/null

    if [[ -f "$CONF_LOGIN_PNG" ]]; then
        qecho "Copying login.png from $CONF_DIR to $NEW_LOGIN_PNG"
        sudo install -Dm 644 "$CONF_LOGIN_PNG" "$NEW_LOGIN_PNG"
    fi

    if [[ -f "$CONF_USER_PNG" ]]; then
        qecho "Copying user.png from $CONF_DIR to $NEW_USER_PNG..."
        sudo install -Dm 644 "$CONF_USER_PNG" "$NEW_USER_PNG"
    fi

    echo "To change greeter avatar, copy png to $NEW_USER_PNG"
    echo "To change background, copy background to $NEW_LOGIN_PNG"
    echo "Make sure the avatar and avatar are readable by everyone"

    qecho "Done installing lightdm-gtk-greeter"
}

function uninstall() {
    sudo sed -i 's/^greeter-session=lightdm-gtk-greeter$/#greeter-session=/' \
        "$MOD_LIGHTDM_CONF"

    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
