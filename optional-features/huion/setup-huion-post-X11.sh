#!/usr/bin/env bash


user="$(loginctl list-users | tail -n+2 | head -n1 | cut -d' ' -f2)"

sleep 2
export XAUTHORITY="/home/$user/.Xauthority"
export DISPLAY=:0

xsetwacom set 'HID 256c:006e Pen stylus' MapToOutput 960x1080+2880+0

xsetwacom set 'HID 256c:006e Pen stylus' Rotate ccw
