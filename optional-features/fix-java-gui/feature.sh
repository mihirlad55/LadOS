#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly MOD_JRE_SH="/etc/profile.d/jre.sh"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Fix Java GUI"
readonly FEATURE_DESC="Fix GUI problems with Java apps"
readonly PROVIDES=()
readonly NEW_FILES=()
readonly MODIFIED_FILES=("$MOD_JRE_SH")
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(xorg-server)

readonly EXPORT_LINE="export _JAVA_AWT_WM_NONREPARENTING=1"

function check_install() {
    if grep -q "$EXPORT_LINE" "$MOD_JRE_SH"; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Updating $MOD_JRE_SH..."
    echo "$EXPORT_LINE" | sudo tee -a "$MOD_JRE_SH" &> \
      /dev/null
}

function uninstall() {
    qecho "Rolling back $MOD_JRE_SH..."
    sudo sed --silent -i -e "/$EXPORT_LINE/d" "$MOD_JRE_SH"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
