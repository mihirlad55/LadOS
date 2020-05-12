#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

INSTALL_PATH="$HOME/.local/share/systemd/user"
TARGET_PATH="$HOME/.config/systemd/user/default.target.wants"
SERVICE_PATH="$BASE_DIR/services"

feature_name="user-services"
feature_desc="Install custom user-services for applications"

provides=()
new_files=("$INSTALL_PATH/battery-check-notify.service" \
           "$INSTALL_PATH/compton.service" \
           "$INSTALL_PATH/dunst.service" \
           "$INSTALL_PATH/nitrogen-delayed.service" \
           "$INSTALL_PATH/nitrogen.service" \
           "$INSTALL_PATH/polybar.service" \
           "$INSTALL_PATH/redshift.service" \
           "$INSTALL_PATH/startup-application@.service" \
           "$INSTALL_PATH/update-notify.service" \
           "$INSTALL_PATH/update-notify.timer" \
           "$INSTALL_PATH/xautolock.service" \
           "$INSTALL_PATH/xbindkeys.service" \
           "$INSTALL_PATH/startup.service")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=()


function check_install() {
    for f in ${new_files[@]}; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing"
            echo "$feature_name is not installed"
            return 1
        fi
    done

    if ! grep /etc/systemd/logind.conf -e "^KillUserProcesses=yes$" > /dev/null; then
        echo "KillUserProcesses=yes not in /etc/systemd/logind.conf"
        echo "$feature_name is not installed"
        return 1
    fi

    echo "$feature_name is installed"
    return 0
}

function install() {
    mkdir -p $INSTALL_PATH

    echo "Copying service files..."
    command install -Dm 644 $SERVICE_PATH/battery-check-notify.service $INSTALL_PATH/battery-check-notify.service
    command install -Dm 644 $SERVICE_PATH/compton.service $INSTALL_PATH/compton.service
    command install -Dm 644 $SERVICE_PATH/dunst.service $INSTALL_PATH/dunst.service
    command install -Dm 644 $SERVICE_PATH/nitrogen-delayed.service $INSTALL_PATH/nitrogen-delayed.service
    command install -Dm 644 $SERVICE_PATH/nitrogen.service $INSTALL_PATH/nitrogen.service
    command install -Dm 644 $SERVICE_PATH/polybar.service $INSTALL_PATH/polybar.service
    command install -Dm 644 $SERVICE_PATH/redshift.service $INSTALL_PATH/redshift.service
    command install -Dm 644 $SERVICE_PATH/startup-application@.service $INSTALL_PATH/startup-application@.service
    command install -Dm 644 $SERVICE_PATH/update-notify.service $INSTALL_PATH/update-notify.service
    command install -Dm 644 $SERVICE_PATH/update-notify.timer $INSTALL_PATH/update-notify.timer
    command install -Dm 644 $SERVICE_PATH/xautolock.service $INSTALL_PATH/xautolock.service
    command install -Dm 644 $SERVICE_PATH/xbindkeys.service $INSTALL_PATH/xbindkeys.service
    command install -Dm 644 $SERVICE_PATH/startup.service $INSTALL_PATH/startup.service

    echo "Editing logind.conf to kill user processes on logout..."
    sudo sed -i /etc/systemd/logind.conf -e "s/[# ]*KillUserProcesses=.*$/KillUserProcesses=yes/"
}

function post_install() {
    echo "Enabling services..."
    mkdir -p $TARGET_PATH
    ln -sP $INSTALL_PATH/battery-check-notify.service $TARGET_PATH/battery-check-notify.service
    ln -sP $INSTALL_PATH/compton.service $TARGET_PATH/compton.service
    ln -sP $INSTALL_PATH/dunst.service $TARGET_PATH/dunst.service
    ln -sP $INSTALL_PATH/nitrogen-delayed.service $TARGET_PATH/nitrogen-delayed.service
    ln -sP $INSTALL_PATH/nitrogen.service $TARGET_PATH/nitrogen.service
    ln -sP $INSTALL_PATH/polybar.service $TARGET_PATH/polybar.service
    ln -sP $INSTALL_PATH/redshift.service $TARGET_PATH/redshift.service
    ln -sP $INSTALL_PATH/startup-application@.service $TARGET_PATH/startup-application@slack.service
    ln -sP $INSTALL_PATH/startup-application@.service $TARGET_PATH/startup-application@mailspring.service
    ln -sP $INSTALL_PATH/startup-application@.service $TARGET_PATH/startup-application@franz.service
    ln -sP $INSTALL_PATH/update-notify.timer $TARGET_PATH/update-notify.timer
    ln -sP $INSTALL_PATH/xautolock.service $TARGET_PATH/xautolock.service
    ln -sP $INSTALL_PATH/xbindkeys.service $TARGET_PATH/xbindkeys.service
    ln -sP $INSTALL_PATH/startup.service $TARGET_PATH/startup.service

    ln -sP /usr/lib/systemd/user/insync.service $TARGET_PATH/insync.service
    ln -sP /usr/lib/systemd/user/spotify-listener.service $TARGET_PATH/spotify-listener.service

    echo "Done"
}


source "$LAD_OS_DIR/common/feature_common.sh"
