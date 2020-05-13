#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
GEOCLUE_CONF_PATH="/etc/geoclue/geoclue.conf"
TEMP_GEOCLUE_CONF_PATH="/tmp/geoclue.conf"

feature_name="redshift"
feature_desc="Install redshift with geoclue for location"

provides=()
new_files=()
modified_files=("/etc/geoclue/geoclue.conf")
temp_files=("$TEMP_GEOCLUE_CONF_PATH")

depends_aur=()
depends_pacman=(redshift geoclue2)


function check_install() {
    if grep "\[redshift\]" /etc/geoclue/geoclue.conf > /dev/null; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    # Allow redshift to use geoclue
    qecho "Adding redshift directive to $GEOCLUE_CONF_PATH"

    echo "[redshift]" > $TEMP_GEOCLUE_CONF_PATH
    echo "allowed=true" >> $TEMP_GEOCLUE_CONF_PATH
    echo "system=false" >> $TEMP_GEOCLUE_CONF_PATH
    echo "users=" >> $TEMP_GEOCLUE_CONF_PATH
    echo "url=https://location.services.mozilla.com/v1/geolocate?key=geoclue" \
        >> $TEMP_GEOCLUE_CONF_PATH
    
    sudo tee -a $GEOCLUE_CONF_PATH < "$TEMP_GEOCLUE_CONF_PATH" > /dev/null

    qecho "Done installing redshift"
}

function cleanup() {
    qecho "Removing $TEMP_GEOCLUE_CONF_PATH..."
    rm -f "$TEMP_GEOCLUE_CONF_PATH"
}

source "$LAD_OS_DIR/common/feature_common.sh"
