#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
readonly FIXES_DIR="$BASE_DIR/fixes"
readonly REQUIRED_FEATURES_DIR="$BASE_DIR/required-features"
readonly OPTIONAL_FEATURES_DIR="$BASE_DIR/optional-features"
readonly SCRIPTS_DIR="$BASE_DIR/scripts"



################################################################################
# Display menu to user with title and options
#   Globals:
#     None
#   Arguments:
#     title, Title of menu
#     <option name> <option_function>... Unlimited pairs of option names and
#     functions to call when corresponding option is selected. Each option name
#     and function are separate arguments, but must be provided in pairs.
#   Outputs:
#     Prompts user with list of options
#   Returns:
#     0 if successful
################################################################################
function show_menu() {
    local option num_of_options i name name_idx func_idx

    title="-----$1-----"
    shift

    option=0
    num_of_options=$(( $# / 2 ))

    while true; do
        i=1

        echo "$title"

        while (( i <= num_of_options )); do
            name_idx="$(( i * 2 - 1 ))"
            name="${!name_idx}"

            echo "$i. $name"

            i=$(( i + 1 ))
        done

        read -rp "Option: " option

        if echo "$option" | grep -q -P "^[0-9]+$"; then
            if (( option > num_of_options )); then
                continue
            fi
        else
            continue
        fi

        func_idx=$(( option * 2 ))
        "${!func_idx}"
    done
}

function main_menu() {
    show_menu "Main Menu" \
        "Install Arch Linux" "install_arch" \
        "Install Required Features" "required_features_menu" \
        "Install Optional Features" "optional_features_menu" \
        "Fixes" "fixes_menu" \
        "Scripts" "scripts_menu" \
        "Exit" "exit"
}

function install_arch() {
    $BASE_DIR/install/install.sh
}

function fixes_menu() {
    show_menu "Fixes" \
        "Fix oh-my-zsh" "sh $FIXES_DIR/fix-oh-my-zsh.sh" \
        "Fix suspend" "sh $FIXES_DIR/fix-suspend.sh" \
        "Fix time" "sh $FIXES_DIR/fix-time.sh" \
        "Fix DNS on ArchLinuxArm" "sh $FIXES_DIR/fix-rpi0w-archlinuxarm-dns.sh" \
        "Go Back" "return"
}

function scripts_menu() {
    show_menu "Scripts" \
        "Setup DS4" "sh $SCRIPTS_DIR/setup-ds4.sh" \
        "Change Dunst Theme" "sh $SCRIPTS_DIR/dunst_xr_theme_changer.sh" \
        "Colors_esc" "sh $SCRIPTS_DIR/colors_esc.sh" \
        "Go Back" "return"
}

function required_features_menu() {
    local features menu_cmd feature feature_path name desc

    mapfile -t features < <(ls "$REQUIRED_FEATURES_DIR")

    menu_cmd=()

    # Build menu command with option names and path to install script
    for feature in "${features[@]}"; do
        feature_path="$REQUIRED_FEATURES_DIR/$feature/feature.sh"

        name="$("$feature_path" name)"
        desc="$("$feature_path" desc)"
        menu_cmd=("${menu_cmd[@]}" "$name" "$feature_path full")
    done

    show_menu "Install Required Features" \
        "${menu_cmd[@]}" \
        "Go Back" "return"
}

function optional_features_menu() {
    local features menu_cmd feature feature_path name desc

    mapfile -t features < <(ls "$OPTIONAL_FEATURES_DIR")

    menu_cmd=()

    # Build menu command with option names and path to install script
    for feature in "${features[@]}"; do
        feature_path="$OPTIONAL_FEATURES_DIR/$feature/feature.sh"

        name="$("$feature_path" name)"
        desc="$("$feature_path" desc)"
        menu_cmd=("${menu_cmd[@]}" "$name" "$feature_path full")
    done

    show_menu "Install Optional Features" \
        "${menu_cmd[@]}" \
        "Go Back" "return"
}


main_menu
