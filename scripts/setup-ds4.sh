#!/bin/sh

echo "Starting bluetooth service..."
systemctl start bluetooth

echo "Starting ds4drv..."
echo "Hold the share and PS button to put the controller in pairing mode."
ds4drv
