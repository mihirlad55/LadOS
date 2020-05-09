#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
REQUIRED_FEATURES_DIR="$BASE_DIR/../required-features"
EXTRA_FEATURES_DIR="$BASE_DIR/../extra-features"

source "$BASE_DIR/conf/defaults.sh"


function pause() {
    read -p "Press enter to continue..."
}

function prompt() {
    while true; do
        echo -n "$1 [Y/n] "
        read resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

function enable_community_repo() {
    echo "Enabling community repo..."
    
    $REQUIRED_FEATURES_DIR/*enable-community-pacman/install.sh

    echo "Enabled community repo"
}

function install_yay() {
    echo "Installing yay..."

    $REQUIRED_FEATURES_DIR/*yay/install.sh

    echo "Done installing yay"
}

function install_packages() {
    echo "Beginning to install pacman packages..."

    local install_extra=0
    if [[ "$DEFAULTS_INSTALL_EXTRA" = "yes" ]]; then
        install_extra=1
    elif prompt "Install extra packages as well?"; then
        install_extra=1
    fi

    IFS=$'\n'
    packages=($(cat $BASE_DIR/../packages.csv))

    local pacman_packages=()
    local aur_packages=()

    for package in ${packages[@]}; do
        local name=$(echo $package | cut -d',' -f1)
        local desc=$(echo $package | cut -d',' -f2)
        local typ=$(echo $package | cut -d',' -f3)
        local req=$(echo $package | cut -d',' -f4)

        echo "$name ($desc)"

        if [[ $install_extra -eq 1 ]] && [[ "$req" = "extra" ]] || [[ "$req" = "required" ]]; then
            if [[ "$typ" = "system" ]]; then
                pacman_packages=("${pacman_packages[@]}" "$name")
            elif [[ "$typ" = "aur" ]]; then
                aur_packages=("${aur_packages[@]}" "$name")
            fi
        fi
    done

    echo "Syncing pacman"
    sudo pacman -Syu --noconfirm
    
    echo "Installing pacman packages..."
    sudo pacman -S ${pacman_packages[@]} --noconfirm --needed

    echo "Installing AUR packages..."
    yay -S ${aur_packages[@]} --noconfirm --needed
}

function install_required_features() {
    local features=($(ls $REQUIRED_FEATURES_DIR))

    echo "Installing required features..."
    for feature in ${features[@]}; do
        if ! (echo $feature | grep "yay" || echo $feature | grep "sudoers"); then
            echo "Installing $feature..."
            $REQUIRED_FEATURES_DIR/$feature/install.sh

            if [[ "$DEFAULTS_NOCONFIRM" = "no" ]]; then
                pause
            fi
        fi
    done

    echo "Done installing required features"
}

function install_extra_features() {
    local features=($(ls $EXTRA_FEATURES_DIR))

    echo "Installing extra features..."

    if [[ "$DEFAULTS_EXCLUDE_FEATURES" != "" ]]; then
        excluded_features=("${DEFAULTS_EXCLUDE_FEATURES[@]}")
    else
        local i=1
        for feature in ${features[@]}; do
            echo "$i. $feature"
            i=$((i+1))
        done

        IFS=$' '
        echo -n "Enter features to exclude (i.e. 1 2 3): "
        read input
        local exclusions=($input)
        
        local selected_features=()

        for i in ${exclusions[@]}; do
            excluded_feature="${features[$(($i-1))]}"
            excluded_features=("${excluded_features[@]}" "$excluded_feature")
        done
    fi


    echo "Excluding features ${excluded_features[@]}"

    for feature in ${features[@]}; do
        if ! echo ${excluded_features[@]} | grep $feature &> /dev/null; then
            echo "Installing $feature..."
            $EXTRA_FEATURES_DIR/$feature/install.sh

            if [[ "$DEFAULTS_NOCONFIRM" = "no" ]]; then
                pause
            fi
        fi
    done

    echo "Done installing extra features"
}

function remove_temp_sudoers() {
    sudo rm -f /etc/sudoers.d/20-sudoers-temp
}


enable_community_repo

install_yay

install_packages

install_required_features

install_extra_features

remove_temp_sudoers
