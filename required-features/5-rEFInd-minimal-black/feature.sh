#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/feature_header.sh"

PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"

REFIND_CONF_ADD="$BASE_DIR/refind.conf.add"
REFIND_INSTALL_HOOK="$BASE_DIR/50-refind-install.hook"
REFIND_THEME_URL="https://github.com/andersfischernielsen/rEFInd-minimal-black.git"
REFIND_PATH="/boot/EFI/refind"
REFIND_CONF="$REFIND_PATH/refind.conf"
REFIND_THEME_PATH="$REFIND_PATH/themes/rEFInd-minimal-black"


feature_name="rEFInd-minimal-black"
feature_desc="Install and setup rEFInd with minimal-black theme"

provides=()
new_files=("/boot/EFI/refind/themes" \
    "/boot/EFI/refind/refind.conf" \
    "/boot/EFI/refind/refind-manual.conf" \
    "/boot/EFI/refind/refind-options.conf" \
    "$PACMAN_HOOKS_DIR/50-refind-install.hook")
modified_files=()
temp_files=("/tmp/refind-options.conf" \
    "/tmp/refind-manual.conf" \
    "/tmp/rEFInd-minimal-black")

depends_aur=()
depends_pacman=(refind)


function check_refind_conf() {
    refind_conf_add_first_line="$(head -n1 "$REFIND_CONF_ADD")"
    num_of_lines="$(wc -l "$REFIND_CONF_ADD" | cut -d' ' -f1)"
    after_context=$(( num_of_lines - 1 ))
    refind_includes="$(grep -F "$refind_conf_add_first_line" -A $after_context "$REFIND_CONF")"
    echo "$refind_includes" | diff "$REFIND_CONF_ADD" - > /dev/null
}

function check_install() {
    if check_refind_conf &&
        [[ -f "/boot/EFI/refind/refind-options.conf" ]] &&
        [[ -f "/boot/EFI/refind/refind-manual.conf" ]] &&
        [[ -d "/boot/EFI/refind/themes/rEFInd-minimal-black" ]] &&
        [[ -f "$PACMAN_HOOKS_DIR/50-refind-install.hook" ]]; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function prepare() {
    qecho "Copying configuration files to /tmp..."
    cp -f "$BASE_DIR/refind-options.conf" /tmp/refind-options.conf
    cp -f "$BASE_DIR/refind-manual.conf" /tmp/refind-manual.conf
}

function install() {
    qecho "Running refind-install..."
    sudo refind-install

    qecho "Copying theme to $REFIND_PATH/themes..."
    sudo mkdir -p "$REFIND_PATH"/themes
    sudo rm -rf "$REFIND_THEME_PATH"

    if [[ ! -d "/tmp/rEFInd-minimal-black" ]]; then
        git clone --depth 1 "${V_FLAG[@]}" "$REFIND_THEME_URL" /tmp/rEFInd-minimal-black
    fi

    sudo mkdir -p "$REFIND_THEME_PATH"
    (shopt -s dotglob; sudo cp -rf /tmp/rEFInd-minimal-black/* "$REFIND_THEME_PATH")

    echo "Opening configuration files for any changes. Default commandline options are set in dracut's configuration"
    read -rp "Press enter to continue..."

    if [[ "$EDITOR" != "" ]]; then
        $EDITOR /tmp/refind-options.conf
        $EDITOR /tmp/refind-manual.conf
    else
        vim /tmp/refind-options.conf
        vim /tmp/refind-manual.conf
    fi

    qecho "Copying configuration files to $REFIND_PATH..."
    sudo install -Dm 755 /tmp/refind-options.conf $REFIND_PATH/refind-options.conf
    sudo install -Dm 755 /tmp/refind-manual.conf $REFIND_PATH/refind-manual.conf
    sudo install -Dm 755 /usr/share/refind/refind.conf-sample $REFIND_PATH/refind.conf

    echo | sudo tee -a "$REFIND_CONF" > /dev/null
    < "$REFIND_CONF_ADD" sudo tee -a "$REFIND_CONF" > /dev/null

    qecho "Copying refind-install hook to $PACMAN_HOOKS_DIR..."
    sudo install -Dm 644 "$REFIND_INSTALL_HOOK" "$PACMAN_HOOKS_DIR/50-refind-install.hook"

    qecho "Done"
}

function cleanup() {
    qecho "Removing ${temp_files[*]}..."
    rm -rf "${temp_files[@]}"
}

function uninstall() {
    qecho "Removing ${new_files[*]}..."
    sudo rm -rf "${new_files[@]}"

}


source "$LAD_OS_DIR/common/feature_footer.sh"
