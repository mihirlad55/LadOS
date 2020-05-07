#!/usr/bin/bash

BASE_DIR="$(dirname "$0")"
REQUIRED_FEATURES_DIR="$BASE_DIR/../required-features"
EXTRA_FEATURES_DIR="$BASE_DIR/../extra-features"

function pause() {
    read -p "Press enter to continue..."
}

function prompt() {
    while true; do
        echo "$1 [Y/n]"
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

    local install_extra=1
    if prompt "Install extra packages as well?"; then
        install_extra=0
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

        if $install_extra && [[ "$req" = "extra" ]] || [[ "$req" = "required" ]]; then
            if [[ "$typ" = "system" ]]; then
                pacman_packages=("${package_list[@]}" "$name")
            elif [[ "$typ" = "aur" ]]; then
                aur_packages=("${package_list[@]}" "$name")
            fi
        fi
    done

    sudo pacman -Syyu
    
    sudo pacman -S ${pacman_packages[@]}
}

function install_required_features() {
    local features=($(ls $REQUIRED_FEATURES_DIR))

    echo "Installing required features..."
    for feature in ${features[@]}; do
        if ! (echo $feature | grep "yay" || echo $feature | grep "sudoers"); then
            echo "Installing $feature..."
            $REQUIRED_FEATURES_DIR/$feature/install.sh
        fi
    done

    echo "Done installing required features"
}

function install_extra_features() {
    local features=($(ls $EXTRA_FEATURES_DIR))

    echo "Installing extra features..."

    local i=1
    for feature in ${features[@]}; do
        echo "$i. $feature"
        i=$((i+1))
    done

    echo -n "Enter features to exclude (i.e. 1 2 3): "
    read input
    local exclusions=($input)
    
    local selected_features=()

    for i in ${exclusions[@]}; do
        excluded_feature="${features[$(($i-1))]}"
        excluded_features=("${excluded_features[@]}" "$excluded_feature")
    done

    echo "Excluding features ${excluded_features[@]}"

    for feature in ${features[@]}; do
        if ! echo ${excluded_features[@]} | grep $feature &> /dev/null; then
            echo "Installing $feature..."
            $EXTRA_FEATURES_DIR/$feature/install.sh
        fi
    done

    echo "Done installing extra features"
}


enable_community_repo

install_yay

install_packages

install_required_features

install_extra_features
