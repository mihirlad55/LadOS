#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
GEOCLUE_CONF_PATH="/etc/geoclue/geoclue.conf"

feature_name="redshift"
feature_desc="Install redshift with geoclue for location"

provides=()
new_files=()
modified_files=("/etc/geoclue/geoclue.conf")
temp_files=()

depends_aur=()
depends_pacman=(redshift geoclue2)


function check_install() {
    if grep "\[redshift\]" /etc/geoclue/geoclue.conf > /dev/null; then
        echo "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed"
        return 1
    fi
}

function install() {
    # Allow redshift to use geoclue
    echo "Adding the following to $GEOCLUE_CONF_PATH..."
    echo "[redshift]" | sudo tee -a $GEOCLUE_CONF_PATH
    echo "allowed=true" | sudo tee -a $GEOCLUE_CONF_PATH
    echo "system=false" | sudo tee -a $GEOCLUE_CONF_PATH
    echo "users=" | sudo tee -a $GEOCLUE_CONF_PATH
    echo "url=https://location.services.mozilla.com/v1/geolocate?key=geoclue" |
        sudo tee -a $GEOCLUE_CONF_PATH
    
    echo "Done installing redshift"
}

source "$LAD_OS_DIR/common/feature_common.sh"
