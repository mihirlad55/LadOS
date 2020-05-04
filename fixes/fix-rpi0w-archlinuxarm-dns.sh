#!/bin/sh

echo "DNSSEC=no" | sudo tee -a /etc/systemd/resolved.conf
echo Fixed resolved.conf...
