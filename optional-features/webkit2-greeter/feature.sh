#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
CONF_DIR="$LAD_OS_DIR/conf/webkit2-greeter"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="webkit2-greeter"
feature_desc="Install lightdm-webkit2-greeter with user avatar and background"

conflicts=(gtk-greeter)

provides=()
new_files=("/var/lib/AccountsService/users/$USER" \
    "/var/lib/AccountsService/icons/$USER.png")
modified_files=("/etc/lightdm/lightdm.conf" \
    "/usr/share/backgrounds")
temp_files=()

depends_aur=()
depends_pacman=(lightdm-webkit2-greeter accountsservice)
depends_pip3=()


function check_install() {
    if grep -q /etc/lightdm/lightdm.conf -e "^greeter-session=lightdm-webkit2-greeter$" &&
        pacman -Q lightdm-webkit2-greeter > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi

}

function install() {
    qecho "Changing greeter session in /etc/lightdm/lightdm.conf"
    sudo sed -i 's/#*greeter-session=.*$/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf

    if [[ -f "$CONF_DIR/user.png" ]]; then
        sudo install -Dm 644 "$CONF_DIR/user.png" "/var/lib/AccountsService/icons/$USER.png"
    else
        echo "To change greeter avatar, copy png to /var/lib/AccountsService/icons/$USER.png"
    fi

    qecho "Creating /var/lib/AccountsService/user/$USER ini"
    echo "[User]" | sudo tee "/var/lib/AccountsService/users/$USER" > /dev/null
    echo "Icon=/var/lib/AccountsService/icons/$USER.png" | 
        sudo tee -a "/var/lib/AccountsService/users/$USER" > /dev/null

    if [[ "$(ls "$CONF_DIR/backgrounds")" != "" ]]; then
        qecho "Copying backgrounds from $CONF_DIR/backgrounds to /usr/share/backgrounds/"
        sudo install -m 644 "$CONF_DIR"/backgrounds/* /usr/share/backgrounds/
        qecho "You will have to set the background from the login screen"
    else
        echo "To add backgrounds, copy backgrounds to /usr/share/backgrounds"
        echo "Make sure the avatar and background are readable by everyone"
    fi

    qecho "Done installing lightdm-webkit2-greeter"
}

function uninstall() {
    local backgrounds

    qecho "Removing ${new_files[*]}..."
    rm -f "${new_files[@]}"

    qecho "Changing greeter session in /etc/lightdm/lightdm.conf"
    sudo sed -i 's/greeter-session=lightdm-webkit2-greeter$/#greeter-session=/' /etc/lightdm/lightdm.conf

    qecho "Removing backgrounds from /usr/share/backgrounds..."
    mapfile -t backgrounds < <(cd "$CONF_DIR/backgrounds" && find . -not -path '*/\.*' -type f)
    (cd /usr/share/backgrounds && rm -rf "${backgrounds[@]}")
}


source "$LAD_OS_DIR/common/feature_footer.sh"
