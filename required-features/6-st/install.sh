#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"

CUR_DIR="$PWD"

git clone https://github.com/mihirlad55/st /tmp/st
cd /tmp/st
sudo make clean install

cd "$CUR_DIR"
rm -rf /tmp/st
