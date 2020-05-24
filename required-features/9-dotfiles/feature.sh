#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$( readlink -f "$LAD_OS_DIR/conf/dotfiles")"

source "$LAD_OS_DIR/common/feature_header.sh"

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

    qecho "Name, email, and editor have been set globally for git."

    sed -i $HOME/.doom.d/config.el -e \
        "s/user-full-name \"\"$/user-full-name \"$name\"/"
    sed -i $HOME/.doom.d/config.el -e \
        "s/user-mail-address \"\"/user-mail-address \"$email\"/"
}

function check_conf() {
    [[ -f "$CONF_DIR/conf.sh" ]] && source "$CONF_DIR/conf.sh"
    res="$?"

    if [[ "$res" -eq 0 ]] && 
        [[ "$CONF_FULL_NAME" != "" ]] &&
        [[ "$CONF_EMAIL" != "" ]] &&
        [[ "$CONF_EDITOR" != "" ]]; then
        qecho "Configuration has been set correctly"
    else
        echo "Configuration has not been set correctly" >&2
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
        qecho "$feature_name is installed"
        return 0
    fi

    echo "$feature_name is not installed" >&2
    return 1
}

function prepare() {
    if [[ ! -d "/tmp/dotfiles" ]]; then
        qecho "Cloning dotfiles..."
        git clone --depth 1 $VERBOSITY_FLAG https://github.com/mihirlad55/dotfiles /tmp/dotfiles
    fi
    qecho "Updating submodules..."
    (cd /tmp/dotfiles && git submodule $VERBOSITY_FLAG init && git submodule update $VERBOSITY_FLAG --init)
}

function install() {
    qecho "Copying /tmp/dotfiles to $HOME/"
    cp -rf /tmp/dotfiles/. $HOME/

    qecho "Installing neovim plugins..."
    nvim -c "PlugInstall | qa"

    qecho "Installing zsh plguins..."
    zsh -c "source $HOME/.zshrc; exit"

    vecho "Done installing dotfiles"
}

function post_install() {
    qecho "Changing shell to zsh..."
    sudo chsh -s /usr/bin/zsh "$USER"

    qecho "Setting up git and doom emacs..."
    if [[ "$CONF_FULL_NAME" != "" ]]; then
        name="$CONF_FULL_NAME"
    else
        read -p "What is your full name: " name
    fi

    if [[ "$CONF_EMAIL" != "" ]]; then
        email="$CONF_EMAIL"
    else
        read -p "What is your email: " email
    fi

    if [[ "$CONF_EDITOR" != "" ]]; then
        editor="$CONF_EDITOR"
    else
        read -p "What is your main editor: " editor
    fi

    update_git_doom_config

    vecho "Name and email have been set for Doom Emacs"
}

function cleanup() {
    qecho "Removing /tmp/dotfiles"
    rm -rf /tmp/dotfiles
}

function uninstall() (
    local files

    cd "$HOME"
    mapfile -t files < <(git ls-tree -r HEAD --name-only)

    qecho "Removing dotfiles..."
    rm -rf "${files[@]}"
    rm -rf ".git"
)


source "$LAD_OS_DIR/common/feature_footer.sh"



