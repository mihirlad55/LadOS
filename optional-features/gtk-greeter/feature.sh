#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/gtk-greeter"

feature_name="gtk-greeter"
feature_desc="Install lightdm-gtk-greeter with user avatar and background and maia-gtk-theme"

conflicts=(webkit-greeter)

provides=()
new_files=("/var/lib/AccountsService/users/$USER" \
    "/var/lib/AccountsService/icons/$USER.png" \
    "/usr/share/backgrounds/login.png")
modified_files=("/etc/lightdm/lightdm.conf" \
    "/etc/lightdm/lightdm-gtk-greeter.conf")
temp_files=()

depends_aur=(maia-gtk-theme)
depends_pacman=(lightdm-gtk-greeter accountsservice)
depends_pip3=()


function check_install() {
    if grep -q /etc/lightdm/lightdm.conf -e "^greeter-session=lightdm-gtk-greeter$" &&
        pacman -Q lightdm-gtk-greeter > /dev/null &&
        diff "$BASE_DIR/lightdm-gtk-greeter.conf" "/etc/lightdm/lightdm-gtk-greeter.conf"; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi

}

function install() {
    qecho "Copying lightdm-gtk-greeter to /etc/lightdm/..."
    sudo install -Dm 644 "$BASE_DIR/lightdm-gtk-greeter.conf" "/etc/lightdm/lightdm-gtk-greeter.conf"

    qecho "Changing greeter session in /etc/lightdm/lightdm.conf"
    sudo sed -i 's/#*greeter-session=.*$/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf

    if [[ -f "$CONF_DIR/user.png" ]]; then
        sudo install -Dm 644 "$CONF_DIR/user.png" /var/lib/AccountsService/icons/$USER.png
    fi

    qecho "Creating /var/lib/AccountsService/user/$USER ini"
    echo "[User]" | sudo tee /var/lib/AccountsService/users/$USER > /dev/null
    echo "Icon=/var/lib/AccountsService/icons/$USER.png" | 
        sudo tee -a /var/lib/AccountsService/users/$USER > /dev/null

    if [[ -f "$CONF_DIR/login.png" ]]; then
        qecho "Copying login.png from $CONF_DIR to /usr/share/backgrounds/"
        sudo install -Dm 644 $CONF_DIR/login.png /usr/share/backgrounds/login.png
    fi

    echo "To change greeter avatar, copy png to /var/lib/AccountsService/icons/$USER.png"
    echo "To change background, copy background to /usr/share/backgrounds/login.png"
    echo "Make sure the avatar and avatar are readable by everyone"

    qecho "Done installing lightdm-gtk-greeter"
}

function uninstall() {
    sudo sed -i 's/^greeter-session=lightdm-gtk-greeter$/#greeter-session=/' /etc/lightdm/lightdm.conf

    qecho "Removing ${new_files[@]}..."
    rm -f "${new_files[@]}"
}


source "$LAD_OS_DIR/common/feature_common.sh"
