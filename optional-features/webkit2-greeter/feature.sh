#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$LAD_OS_DIR/conf/webkit2-greeter"
readonly CONF_BG_DIR="$CONF_DIR/backgrounds"
readonly CONF_USER_PNG="$CONF_DIR/user.png"
readonly NEW_USER_PNG="/var/lib/AccountsService/icons/$USER.png"
readonly NEW_LOGIN_PNG="/usr/share/backgrounds/login.png"
readonly NEW_USER_INI="/var/lib/AccountsService/users/$USER"
readonly MOD_LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
readonly MOD_BG_DIR="/usr/share/backgrounds"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="LightDM Webkit2 Greeter"
readonly FEATURE_DESC="Install lightdm-webkit2-greeter with user avatar and \
background"
readonly CONFLICTS=(gtk-greeter)
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_USER_INI" \
    "$NEW_USER_PNG" \
    "$NEW_LOGIN_PNG" \
)
readonly MODIFIED_FILES=( \
    "$MOD_LIGHTDM_CONF" \
    "$MOD_BG_DIR" \
)
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(lightdm-webkit2-greeter accountsservice)
readonly DEPENDS_PIP3=()



function check_install() {
    # Check if lightdm-webkit2-greeter is set as main session in lightdm.conf
    if grep -q "$MOD_LIGHTDM_CONF" -e "^greeter-session=lightdm-webkit2-greeter$" &&
        pacman -Q lightdm-webkit2-greeter > /dev/null; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Changing greeter session in $MOD_LIGHTDM_CONF"
    sudo sed \ 
        -i 's/#*greeter-session=.*$/greeter-session=lightdm-webkit2-greeter/' \
        "$MOD_LIGHTDM_CONF"

    if [[ -f "$CONF_USER_PNG" ]]; then
        qecho "Copying user.png from $CONF_DIR to $NEW_USER_PNG..."
        sudo install -Dm 644 "$CONF_DIR/user.png" "$NEW_USER_PNG"
    fi

    qecho "Creating $NEW_USER_INI ini"
    echo "[User]" | sudo tee "$NEW_USER_INI" > /dev/null
    echo "Icon=$NEW_LOGIN_PNG" | sudo tee -a "$NEW_USER_INI" > /dev/null

    if [[ "$(ls "$CONF_BG_DIR")" != "" ]]; then
        qecho "Copying backgrounds from $CONF_BG_DIR to $MOD_BG_DIR..."
        sudo install -m 644 "$CONF_BG_DIR"/* "$MOD_BG_DIR"
        qecho "You will have to set the background from the login screen"
    fi

    echo "To change greeter avatar, copy png to $NEW_USER_PNG"
    echo "To add backgrounds, copy backgrounds to $MOD_BG_DIR..."
    echo "Make sure the avatar and avatar are readable by everyone"

    qecho "Done installing lightdm-webkit2-greeter"
}

function uninstall() {
    local backgrounds

    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"

    # Comment out greeter-session in lightdm.conf
    qecho "Changing greeter session in /etc/lightdm/lightdm.conf"
    sudo sed \
        -i 's/greeter-session=lightdm-webkit2-greeter$/#greeter-session=/' \
        "$MOD_LIGHTDM_CONF"

    qecho "Removing backgrounds from /usr/share/backgrounds..."
    # Get paths to backgrounds in backgrounds directory
    mapfile -t backgrounds < <(cd "$CONF_BG_DIR" && find . -not -path '*/\.*' \
        -type f)

    (cd "$MOD_BG_DIR" && rm -rf "${backgrounds[@]}")
}


source "$LAD_OS_DIR/common/feature_footer.sh"
