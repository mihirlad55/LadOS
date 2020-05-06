#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

INSTALL_PATH="$HOME/.local/share/systemd/user"
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
systemctl --user enable battery-check-notify.service
systemctl --user enable compton.service
systemctl --user enable dunst.service
systemctl --user enable nitrogen-delayed.service
systemctl --user enable nitrogen.service
systemctl --user enable polybar.service
systemctl --user enable redshift.service
systemctl --user enable startup-application@slack.service
systemctl --user enable startup-application@mailspring.service
systemctl --user enable startup-application@franz.service
systemctl --user enable update-notify.timer
systemctl --user enable xautolock.service
systemctl --user enable xbindkeys.service
systemctl --user enable startup.service
systemctl --user enable insync.service

echo "Editing logind.conf to kill user processes on logout..."
sudo sed -i /etc/systemd/logind.conf -e "s/^KillUserProcesses=.*$/KillUserProcesses=yes/"

echo "Done"
