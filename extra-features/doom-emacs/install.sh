#!/usr/bin/bash

git clone --depth 1 https://github.com/hlissner/doom-emacs $HOME/.emacs.d

echo "Installing doom emacs"

$HOME/.emacs.d/bin/doom install

echo "Syncing doom emacs"
$HOME/.emacs.d/bin/doom sync

echo "Done installing doom emacs"
