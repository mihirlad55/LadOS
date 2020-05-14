#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
FIXES_DIR="$BASE_DIR/fixes"
REQUIRED_FEATURES_DIR="$BASE_DIR/required-features"
OPTIONAL_FEATURES_DIR="$BASE_DIR/optional-features"
SCRIPTS_DIR="$BASE_DIR/scripts"


function show_menu() {
    local option=0

    title="-----$1-----"
    shift

    local num_of_options=$(($#/2))

    while true; do
        local i=1
        echo $title
        while [[ "$i" -le $num_of_options ]]; do
            local name=$(($i*2-1))
            echo "$i. ${!name}"
            i=$(($i+1))
        done
        echo -n "Option: "
        read option

        func_num=$(($option*2))
        eval ${!func_num}
    done
}

function main_menu() {
    show_menu "Main Menu" \
        "Install Arch Linux" "install_arch" \
        "Install Required Features" "required_features_menu" \
        "Install Optional Features" "optional_features_menu" \
        "Fixes" "fixes_menu" \
        "Scripts" "scripts_menu" \
        "Exit" "exit 0"
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
    features=$(ls $REQUIRED_FEATURES_DIR)
    
    IFS=$'\n'

    menu_cmd=""

    for feature in $features; do
        name="$($REQUIRED_FEATURES_DIR/$feature/feature.sh name)"
        desc="$($REQUIRED_FEATURES_DIR/$feature/feature.sh desc)"
        menu_option="$name,$REQUIRED_FEATURES_DIR/$feature/feature.sh full" 
        menu_cmd="${menu_cmd}${menu_option},"
    done

    IFS=$','

    show_menu "Install Required Features" \
        $menu_cmd \
        "Go Back" "return"
}

function optional_features_menu() {
    features=$(ls $OPTIONAL_FEATURES_DIR)
    
    IFS=$'\n'

    menu_cmd=""

    for feature in $features; do
        name="$($OPTIONAL_FEATURES_DIR/$feature/feature.sh name)"
        desc="$($OPTIONAL_FEATURES_DIR/$feature/feature.sh desc)"
        menu_option="$name,$OPTIONAL_FEATURES_DIR/$feature/feature.sh full" 
        menu_cmd="${menu_cmd}${menu_option},"
    done

    IFS=$','

    show_menu "Install Optional Features" \
        $menu_cmd \
        "Go Back" "return"
}

main_menu

