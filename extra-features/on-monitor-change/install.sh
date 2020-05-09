#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"

sudo install -Dm 755 $BASE_DIR/50-monitor.rules /etc/udev/rules.d/50-monitor.rules
sudo install -Dm 755 $BASE_DIR/restart-polybar /usr/local/bin/restart-polybar
sudo install -Dm 755 $BASE_DIR/fix-monitor-layout /usr/local/bin/fix-monitor-layout

sudo install -Dm 644 $BASE_DIR/on-monitor-change@.service /etc/systemd/user/on-monitor-change@.service

sudo udevadm control --reload

