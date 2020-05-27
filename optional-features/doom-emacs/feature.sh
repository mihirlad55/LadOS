#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"
 
source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="Doom Emacs"
feature_desc="Install doom emacs"

provides=()
new_files=("$HOME/.emacs.d")
modified_files=()
temp_files=("/tmp/doom-emacs")

depends_aur=()
depends_pacman=(emacs)

DOOM_EMACS_URL="https://github.com/hlissner/doom-emacs"


function check_install() {
    if "$HOME/.emacs.d/bin/doom" sync; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Cloning doom emacs..."

    if [[ ! -d "/tmp/doom-emacs" ]]; then
        git clone --depth 1 "${V_FLAG[@]}" "$DOOM_EMACS_URL" "/tmp/doom-emacs"
    fi
    (shopt -s dotglob && cp -rf /tmp/doom-emacs/* "$HOME/.emacs.d")

    qecho "Installing doom emacs"
    "$HOME/.emacs.d/bin/doom" -y install

    qecho "Syncing doom emacs"
    "$HOME/.emacs.d/bin/doom" -y sync

    qecho "Done installing doom emacs"
}

function cleanup() {
    qecho "Removing ${temp_files[*]}..."
    rm -rf "${temp_files[@]}"
}

function uninstall() {
    qecho "Removing ${new_files[*]}..."
    rm -f "${new_files[@]}"
}

source "$LAD_OS_DIR/common/feature_footer.sh"
