#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
 

feature_name="Doom Emacs"
feature_desc="Install doom emacs"

provides=()
new_files=("$HOME/.emacs.d")
modified_files=()
temp_files=()

depends_aur=()
depends_pacman=(emacs)



function check_install() {
    if $HOME/.emacs.d/bin/doom sync; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Cloning doom emacs..."
    git clone --depth 1 $VERBOSITY_FLAG https://github.com/hlissner/doom-emacs $HOME/.emacs.d

    qecho "Installing doom emacs"
    $HOME/.emacs.d/bin/doom -y install > "$DEFAULT_OUT"

    qecho "Syncing doom emacs"
    $HOME/.emacs.d/bin/doom -y sync > "$DEFAULT_OUT"

    qecho "Done installing doom emacs"
}

source "$LAD_OS_DIR/common/feature_common.sh"
