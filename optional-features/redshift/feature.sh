#!/usr/bin/bash


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
GEOCLUE_CONF_PATH="/etc/geoclue/geoclue.conf"
GEOCLUE_CONF_ADD_PATH="$BASE_DIR/geoclue.conf.add"

source "$LAD_OS_DIR/common/feature_header.sh"

feature_name="redshift"
feature_desc="Install redshift with geoclue for location"

provides=()
new_files=()
modified_files=("/etc/geoclue/geoclue.conf")
temp_files=()

depends_aur=()
depends_pacman=(redshift geoclue2)


function check_geoclue_conf() {
    geoclue_conf_add_first_line="$(head -n1 "$GEOCLUE_CONF_ADD_PATH")"
    num_of_lines="$(wc -l "$GEOCLUE_CONF_ADD_PATH" | cut -d' ' -f1)"
    after_context=$(( num_of_lines - 1 ))
    redshift_entry="$(grep -F "$geoclue_conf_add_first_line" -A $after_context "$GEOCLUE_CONF_PATH")"
    echo "$redshift_entry" | diff "$GEOCLUE_CONF_ADD_PATH" - > /dev/null
}

function check_install() {
    if check_geoclue_conf; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    if ! check_geoclue_conf; then
        # Allow redshift to use geoclue
        qecho "Adding redshift directive to $GEOCLUE_CONF_PATH"

        echo | sudo tee -a "$GEOCLUE_CONF_PATH" > /dev/null
        < "$GEOCLUE_CONF_ADD_PATH" sudo tee -a "$GEOCLUE_CONF_PATH" > /dev/null
    else
        qecho "Redshift directive already in $GEOCLUE_CONF_PATH"
    fi

    qecho "Done installing redshift"
}

function uninstall() {
    qecho "Removing redshift directive from $GEOCLUE_CONF_PATH..."
    text="$(diff \
        --suppress-common-lines \
        -D --GTYPE-group-format='' \
        redshift/geoclue.conf.add /etc/geoclue/geoclue.conf)"
    
    echo "$text" | sudo tee "$GEOCLUE_CONF_PATH" > /dev/null
}


source "$LAD_OS_DIR/common/feature_footer.sh"
