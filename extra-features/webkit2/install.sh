#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

sudo pacman -S lightdm-webkit2-greeter accountsservice --needed --noconfirm

echo "Changing greeter session in /etc/lightdm/lightdm.conf"
sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-webkit2-greeter/' /etc/lightdm/lightdm.conf

if [[ -f "$BASE_DIR/$USER.png" ]]; then
    sudo install -Dm 644 "$BASE_DIR/$USER.png" /var/lib/AccountsService/icons/$USER.png
else
    echo "To change greeter avatar, copy png to /var/lib/AccountsService/icons/$USER.png"
fi

echo "Creating /var/lib/AccountsService/user/$USER ini"
echo "[User]" | sudo tee /var/lib/AccountsService/users/$USER > /dev/null
echo "Icon=/var/lib/AccountsService/icons/$USER.png" | 
    sudo tee -a /var/lib/AccountsService/users/$USER > /dev/null

if [[ -d "$BASE_DIR/backgrounds" ]]; then
    echo "Copying backgrounds from $BASE_DIR/backgrounds to /usr/share/backgrounds/"
    sudo install -m 644 $BASE_DIR/backgrounds/* /usr/share/backgrounds/
    echo "You will have to set the background from the login screen"
else
    echo "To add backgrounds, copy backgrounds to /usr/share/backgrounds"
    echo "Make sure the avatar and background are readable by everyone"
fi

echo "Done installing lightdm-webkit2-greeter"
