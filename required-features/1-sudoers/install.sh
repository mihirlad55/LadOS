#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

echo "Adding custom sudo file..."
sudo install -Dm 644 $BASE_DIR/10-sudoers-custom /etc/sudoers.d/10-sudoers-custom
