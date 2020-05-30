#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly MOD_GEOCLUE_CONF="/etc/geoclue/geoclue.conf"
readonly BASE_CONF_ADD="$BASE_DIR/geoclue.conf.add"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="redshift"
readonly FEATURE_DESC="Install redshift with geoclue for location"
readonly PROVIDES=()
readonly NEW_FILES=()
readonly MODIFIED_FILES=("$MOD_GEOCLUE_CONF")
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=(redshift geoclue2)



function check_geoclue_conf() {
    local geoclue_conf_add_first_line num_of_lines after_context redshift_entry

    geoclue_conf_add_first_line="$(head -n1 "$BASE_CONF_ADD")"
    num_of_lines="$(wc -l "$BASE_CONF_ADD" | cut -d' ' -f1)"
    after_context=$(( num_of_lines - 1 ))
    redshift_entry="$(grep -F "$geoclue_conf_add_first_line" \
        -A $after_context "$MOD_GEOCLUE_CONF")"
    echo "$redshift_entry" | diff "$BASE_CONF_ADD" - > /dev/null
}

function check_install() {
    if check_geoclue_conf; then
        qecho "$FEATURE_NAME is installed"
        return 0
    else
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi
}

function install() {
    if ! check_geoclue_conf; then
        # Allow redshift to use geoclue
        qecho "Adding redshift directive to $MOD_GEOCLUE_CONF"

        echo | sudo tee -a "$MOD_GEOCLUE_CONF" > /dev/null
        < "$BASE_CONF_ADD" sudo tee -a "$MOD_GEOCLUE_CONF" > /dev/null
    else
        qecho "Redshift directive already in $MOD_GEOCLUE_CONF"
    fi

    qecho "Done installing redshift"
}

function uninstall() {
    qecho "Removing redshift directive from $MOD_GEOCLUE_CONF..."
    text="$(diff \
        --suppress-common-lines \
        -D --GTYPE-group-format='' \
        "$BASE_CONF_ADD" \
        "$MOD_GEOCLUE_CONF")"
    
    echo "$text" | sudo tee "$MOD_GEOCLUE_CONF" > /dev/null
}


source "$LAD_OS_DIR/common/feature_footer.sh"
