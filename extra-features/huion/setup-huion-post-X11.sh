#!/usr/bin/env bash

sleep 2
export XAUTHORITY=/home/mihirlad55/.Xauthority
export DISPLAY=:0

xsetwacom set 'HID 256c:006e Pen stylus' MapToOutput 960x1080+2880+0

xsetwacom set 'HID 256c:006e Pen stylus' Rotate ccw
