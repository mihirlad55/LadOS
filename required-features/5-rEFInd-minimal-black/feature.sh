#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly PACMAN_HOOKS_DIR="/etc/pacman.d/hooks"
readonly REFIND_DIR="/boot/EFI/refind"
readonly REFIND_THEMES_DIR="$REFIND_DIR/themes"
readonly REFIND_CONF_SAMPLE="/usr/share/refind/refind.conf-sample"
readonly BASE_CONF_ADD="$BASE_DIR/refind.conf.add"
readonly BASE_INSTALL_HOOK="$BASE_DIR/50-refind-install.hook"
readonly BASE_MANUAL_CONF="$BASE_DIR/refind-manual.conf"
readonly BASE_OPTIONS_CONF="$BASE_DIR/refind-options.conf"
readonly NEW_THEME_DIR="$REFIND_DIR/themes/rEFInd-minimal-black"
readonly NEW_REFIND_CONF="$REFIND_DIR/refind.conf"
readonly NEW_INSTALL_HOOK="$PACMAN_HOOKS_DIR/50-refind-install.hook"
readonly NEW_MANUAL_CONF="$REFIND_DIR/refind-manual.conf"
readonly NEW_OPTIONS_CONF="$REFIND_DIR/refind-options.conf"
readonly TMP_THEME_DIR="/tmp/rEFInd-minimal-black"
readonly TMP_MANUAL_CONF="/tmp/refind-manual.conf"
readonly TMP_OPTIONS_CONF="/tmp/refind-options.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="rEFInd Boot Manager with Minimal Black Theme"
readonly FEATURE_DESC="Install and setup rEFInd with minimal-black theme"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_THEME_DIR" \
    "$NEW_REFIND_CONF" \
    "$NEW_MANUAL_CONF" \
    "$NEW_OPTIONS_CONF" \
    "$NEW_INSTALL_HOOK" \
)
readonly MODIFIED_FILES=()
readonly TEMP_FILES=( \
    "$TMP_THEME_DIR" \
    "$TMP_MANUAL_CONF" \
    "$TMP_OPTIONS_CONF" \
)
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(refind)

readonly REFIND_THEME_URL="https://github.com/andersfischernielsen/rEFInd-minimal-black.git"



function check_refind_conf() {
    refind_conf_add_first_line="$(head -n1 "$BASE_CONF_ADD")"
    num_of_lines="$(wc -l "$BASE_CONF_ADD" | cut -d' ' -f1)"
    after_context=$(( num_of_lines - 1 ))
    refind_includes="$(grep -F "$refind_conf_add_first_line" -A $after_context \
        "$NEW_REFIND_CONF")"
    echo "$refind_includes" | diff "$BASE_CONF_ADD" - > /dev/null
}

function check_install() {
    if check_refind_conf &&
        [[ -f "$NEW_OPTIONS_CONF" ]] &&
        [[ -f "$NEW_MANUAL_CONF" ]] &&
        [[ -d "$NEW_THEME_DIR" ]] &&
        [[ -f "$NEW_INSTALL_HOOK" ]]; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function prepare() {
    qecho "Copying configuration files to /tmp..."
    cp -f "$BASE_OPTIONS_CONF" "$TMP_OPTIONS_CONF"
    cp -f "$BASE_MANUAL_CONF" "$TMP_MANUAL_CONF"
}

function install() {
    qecho "Running refind-install..."
    sudo refind-install

    qecho "Copying theme to $REFIND_THEMES_DIR..."
    sudo mkdir -p "$REFIND_THEMES_DIR"
    sudo rm -rf "$NEW_THEME_DIR"

    if [[ ! -d "$TMP_THEME_DIR" ]]; then
        git clone "${GIT_FLAGS[@]}" "$REFIND_THEME_URL" "$TMP_THEME_DIR"
    fi

    sudo mkdir -p "$NEW_THEME_DIR"

    (
        shopt -s dotglob;
        sudo cp -rf "$TMP_THEME_DIR"/* "$NEW_THEME_DIR"
    )

    echo "Opening configuration files for any changes. Default commandline"
    echo "options are set in dracut's configuration"
    read -rp "Press enter to continue..."

    if [[ "$EDITOR" != "" ]]; then
        "$EDITOR" "$TMP_OPTIONS_CONF"
        "$EDITOR" "$TMP_MANUAL_CONF"
    else
        vim "$TMP_OPTIONS_CONF"
        vim "$TMP_MANUAL_CONF"
    fi

    qecho "Copying configuration files to $REFIND_DIR..."
    sudo install -Dm 755 "$TMP_OPTIONS_CONF" "$NEW_OPTIONS_CONF"
    sudo install -Dm 755 "$TMP_MANUAL_CONF" "$NEW_MANUAL_CONF"
    sudo install -Dm 755 "$REFIND_CONF_SAMPLE" "$NEW_REFIND_CONF"

    < "\n$BASE_CONF_ADD" sudo tee -a "$NEW_REFIND_CONF" > /dev/null

    qecho "Copying refind-install hook to $PACMAN_HOOKS_DIR..."
    sudo install -Dm 644 "$BASE_INSTALL_HOOK" "$NEW_INSTALL_HOOK"

    qecho "Done"
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[*]}..."
    rm -rf "${TEMP_FILES[@]}"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    sudo rm -rf "${NEW_FILES[@]}"

}


source "$LAD_OS_DIR/common/feature_footer.sh"
