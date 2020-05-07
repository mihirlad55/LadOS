#!/usr/bin/bash


sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=suspend/' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=suspend/' /etc/systemd/logind.conf
