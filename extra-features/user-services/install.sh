#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

INSTALL_PATH="$HOME/.local/share/systemd/user"
TARGET_PATH="$HOME/.config/systemd/user/default.target.wants"
SERVICE_PATH="$BASE_DIR/services"

mkdir -p $INSTALL_PATH

echo "Copying service files..."
install -Dm 644 $SERVICE_PATH/battery-check-notify.service $INSTALL_PATH/battery-check-notify.service
install -Dm 644 $SERVICE_PATH/compton.service $INSTALL_PATH/compton.service
install -Dm 644 $SERVICE_PATH/dunst.service $INSTALL_PATH/dunst.service
install -Dm 644 $SERVICE_PATH/nitrogen-delayed.service $INSTALL_PATH/nitrogen-delayed.service
install -Dm 644 $SERVICE_PATH/nitrogen.service $INSTALL_PATH/nitrogen.service
install -Dm 644 $SERVICE_PATH/polybar.service $INSTALL_PATH/polybar.service
install -Dm 644 $SERVICE_PATH/redshift.service $INSTALL_PATH/redshift.service
install -Dm 644 $SERVICE_PATH/startup-application@.service $INSTALL_PATH/startup-application@.service
install -Dm 644 $SERVICE_PATH/update-notify.service $INSTALL_PATH/update-notify.service
install -Dm 644 $SERVICE_PATH/update-notify.timer $INSTALL_PATH/update-notify.timer
install -Dm 644 $SERVICE_PATH/xautolock.service $INSTALL_PATH/xautolock.service
install -Dm 644 $SERVICE_PATH/xbindkeys.service $INSTALL_PATH/xbindkeys.service
install -Dm 644 $SERVICE_PATH/startup.service $INSTALL_PATH/startup.service

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

echo "Editing logind.conf to kill user processes on logout..."
sudo sed -i /etc/systemd/logind.conf -e "s/^KillUserProcesses=.*$/KillUserProcesses=yes/"

echo "Done"
