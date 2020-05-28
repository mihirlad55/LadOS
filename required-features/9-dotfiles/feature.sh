#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly CONF_DIR="$( readlink -f "$LAD_OS_DIR/conf/dotfiles")"
readonly CONF_SH="$CONF_DIR/conf.sh"
readonly MOD_DOOM_CONFIG="$HOME/.doom.d/config.el"
readonly MOD_GIT_CONFIG="$HOME/.gitconfig"
readonly TMP_DOTFILES_DIR="/tmp/dotfiles"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Mihirlad55's Dotfiles"
readonly FEATURE_DESC="Install mihirlad55's dotfiles with some additional \
configuration"
readonly PROVIDES=()
readonly NEW_FILES=()
readonly MODIFIED_FILES=("/home/$USER")
readonly TEMP_FILES=("$TMP_DOTFILES_DIR")
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(git zsh xorg-xrdb)

readonly DOTFILES_URL="https://github.com/mihirlad55/dotfiles"



function update_git_doom_config() {
    local name email editor

    name="$1"
    email="$2"
    editor="$3"

    git config --global user.name "$name"
    git config --global user.email "$email"
    git config --global core.editor "$editor"

    qecho "Name, email, and editor have been set globally for git."

    sed -i "$HOME/.doom.d/config.el" -e \
        "s/user-full-name \"\"$/user-full-name \"$name\"/"
    sed -i "$HOME/.doom.d/config.el" -e \
        "s/user-mail-address \"\"/user-mail-address \"$email\"/"
}

function check_conf() {
    if [[ -f "$CONF_SH" ]]; then
        source "$CONF_SH"
    fi

    if [[ "$CONF_FULL_NAME" != "" ]] &&
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

function load_conf() {
    source "$CONF_SH"
}

function check_install() {
    head="$(cat "$HOME/.git/HEAD")"
    default_shell="$(grep "^$USER" /etc/passwd | cut -d":" -f7)"

    git_config_name="$(grep name "$MOD_GIT_CONFIG" \
        | cut -d'=' -f2 \
        | awk '{$1=$1;print}')"
    git_config_email="$(grep email "$MOD_GIT_CONFIG" \
        | cut -d'=' -f2 \
        | awk '{$1=$1;print}')"
    git_config_editor="$(grep editor "$MOD_GIT_CONFIG" \
        | cut -d'=' -f2 \
        | awk '{$1=$1;print}')"

    doom_config_name="$(grep -e 'user-full-name' "$MOD_DOOM_CONFIG" \
        | grep -o '".*"' \
        | sed 's/"//g')"
    doom_config_email="$(grep -e 'user-mail-address' "$MOD_DOOM_CONFIG" \
        | grep -o '".*"' \
        | sed 's/"//g')"

    if [[ "$head" = "ref: refs/heads/arch-dwm" ]] &&
        [[ "$default_shell" = "/usr/bin/zsh" ]] &&
        [[ "$git_config_name" != "" ]] &&
        [[ "$git_config_email" != "" ]] &&
        [[ "$git_config_editor" != "" ]] &&
        [[ "$doom_config_name" != "" ]] &&
        [[ "$doom_config_email" != "" ]]; then
        qecho "$FEATURE_NAME is installed"
        return 0
    fi

    echo "$FEATURE_NAME is not installed" >&2
    return 1
}

function prepare() {
    if [[ ! -d "$TMP_DOTFILES_DIR" ]]; then
        qecho "Cloning dotfiles..."
        git clone "${GIT_FLAGS[@]}" "$DOTFILES_URL" "$TMP_DOTFILES_DIR"
    fi

    qecho "Updating submodules..."
    (
        cd "$TMP_DOTFILES_DIR"
        git submodule "${V_FLAG[@]}" init
        git submodule update "${V_FLAG[@]}" --init
    )
}

function install() {
    qecho "Copying $TMP_DOTFILES_DIR to $HOME/"
    cp -rf "$TMP_DOTFILES_DIR"/. "$HOME"

    qecho "Installing neovim plugins..."
    nvim -c "PlugInstall | qa"

    qecho "Installing zsh plguins..."
    zsh -c "source $HOME/.zshrc; exit"

    vecho "Done installing dotfiles"
}

function post_install() {
    local name email editor

    qecho "Changing shell to zsh..."
    sudo chsh -s /usr/bin/zsh "$USER"

    qecho "Setting up git and doom emacs..."
    if [[ "$CONF_FULL_NAME" != "" ]]; then
        name="$CONF_FULL_NAME"
    else
        read -rp "What is your full name: " name
    fi

    if [[ "$CONF_EMAIL" != "" ]]; then
        email="$CONF_EMAIL"
    else
        read -rp "What is your email: " email
    fi

    if [[ "$CONF_EDITOR" != "" ]]; then
        editor="$CONF_EDITOR"
    else
        read -rp "What is your main editor: " editor
    fi

    update_git_doom_config "$name" "$email" "$editor"

    vecho "Name and email have been set for Doom Emacs"
}

function cleanup() {
    qecho "Removing $TMP_DOTFILES_DIR..."
    rm -rf "$TMP_DOTFILES_DIR"
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
