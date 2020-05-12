#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$( readlink -f "$LAD_OS_DIR/conf/dotfiles")"

feature_name="Dotfiles"
feature_desc="Install mihirlad55's dotfiles with some additional configuration"

provides=()
new_files=()
modified_files=("/home/$USER")
temp_files=("/tmp/dotfiles")

depends_aur=()
depends_pacman=(git zsh xorg-xrdb)



function update_git_doom_config() {
    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global core.editor "$editor"

    echo "Name, email, and editor have been set globally for git."

    sed -i $HOME/.doom.d/config.el -e \
        "s/user-full-name \"\"$/user-full-name \"$name\"/"
    sed -i $HOME/.doom.d/config.el -e \
        "s/user-mail-address \"\"/user-mail-address \"$email\"/"
}

function check_conf() {
    source "$CONF_DIR/conf.sh"
    res="$?"

    if [[ "$res" -eq 0 ]] && 
        [[ "$CONF_FULL_NAME" != "" ]] &&
        [[ "$CONF_EMAIL" != "" ]] &&
        [[ "$CONF_EDITOR" != "" ]]; then
        echo "Configuration has been set correctly"
    else
        echo "Configuration has not been set correctly"
    fi

    unset CONF_FULL_NAME
    unset CONF_EMAIL
    unset CONF_EDITOR
}

# Load configuration settings from /conf
function load_conf() {
    source "$CONF_DIR/conf.sh"
}

# Check if the installation was successful
function check_install() {
    HEAD="$(cat $HOME/.git/HEAD)"
    DEFAULT_SHELL="$(grep "^$USER" /etc/passwd | cut -d":" -f7)"

    GIT_CONFIG_NAME="$(cat $HOME/.gitconfig | grep name | cut -d'=' -f2 | awk '{$1=$1;print}')"
    GIT_CONFIG_EMAIL="$(cat $HOME/.gitconfig | grep email | cut -d'=' -f2 | awk '{$1=$1;print}')"
    GIT_CONFIG_EDITOR="$(cat $HOME/.gitconfig | grep editor | cut -d'=' -f2 | awk '{$1=$1;print}')"

    DOOM_CONFIG_NAME="$(cat $HOME/.doom.d/config.el  | grep -e 'user-full-name' | grep -o '".*"' | sed 's/"//g')"
    DOOM_CONFIG_EMAIL="$(cat $HOME/.doom.d/config.el  | grep -e 'user-mail-address' | grep -o '".*"' | sed 's/"//g')"

    if [[ "$HEAD" = "ref: refs/heads/arch-dwm" ]] &&
        [[ "$DEFAULT_SHELL" = "/usr/bin/zsh" ]] &&
        [[ "$GIT_CONFIG_NAME" != "" ]] &&
        [[ "$GIT_CONFIG_EMAIL" != "" ]] &&
        [[ "$GIT_CONFIG_EDITOR" != "" ]] &&
        [[ "$DOOM_CONFIG_NAME" != "" ]] &&
        [[ "$DOOM_CONFIG_EMAIL" != "" ]]; then
        echo "$feature_name is installed"
        return 0
    fi

    echo "$feature_name is not installed"
    return 1
}

function prepare() {
    git clone https://github.com/mihirlad55/dotfiles /tmp/dotfiles
    (cd /tmp/dotfiles && git submodule init && git submodule update --init)
}

function install() {
    echo "Copying /tmp/dotfiles to $HOME/"
    cp -rf /tmp/dotfiles/. $HOME/

    echo "Installing neovim plugins..."
    nvim -c "PlugInstall | qa"

    echo "Installing zsh plguins..."
    zsh -c "source $HOME/.zshrc; exit"

    echo "Done installing dotfiles"
}

function post_install() {
    # Change shell to zsh
    chsh -s /usr/bin/zsh

    # Rebuild .Xresources DB
    xrdb ~/.Xresources

    echo "Setting up git and doom emacs..."
    if [[ "$CONF_FULL_NAME" != "" ]]; then
        name="$CONF_FULL_NAME"
    else
        echo -n "What is your full name: "
        read name
    fi

    if [[ "$CONF_EMAIL" != "" ]]; then
        email="$CONF_EMAIL"
    else
        echo -n "What is your email: "
        read email
    fi

    if [[ "$CONF_EDITOR" != "" ]]; then
        editor="$CONF_EDITOR"
    else
        echo -n "What is your main editor: "
        read editor
    fi

    update_git_doom_config

    echo "Name and email have been set for Doom Emacs"
}

function cleanup() {
    echo "Removing /tmp/dotfiles"
    rm -rf /tmp/dotfiles
}

source "$LAD_OS_DIR/common/feature_common.sh"



