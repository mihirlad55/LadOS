#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

sudo install -Dm 755 $BASE_PATH/50-monitor.rules /etc/udev/rules.d/50-monitor.rules
sudo install -Dm 755 $BASE_PATH/restart-polybar /usr/local/bin/restart-polybar
sudo install -Dm 755 $BASE_PATH/fix-monitor-layout /usr/local/bin/fix-monitor-layout

sudo install -Dm 644 $BASE_PATH/on-monitor-change@.service /etc/systemd/user/on-monitor-change@.service

sudo udevadm control --reload

