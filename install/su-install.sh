#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
CONF_DIR="$LAD_OS_DIR/conf/install"
REQUIRED_FEATURES_DIR="$LAD_OS_DIR/required-features"
EXTRA_FEATURES_DIR="$LAD_OS_DIR/extra-features"
LOCAL_REPO_PATH="$LAD_OS_DIR/localrepo"
PKG_CACHE_DIR="$LOCAL_REPO_PATH/pkg"

source "$CONF_DIR/defaults.sh"


function pause() {
    read -p "Press enter to continue..."
}

function prompt() {
    while true; do
        read -p "$1 [Y/n] " resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

function enable_community_repo() {
    echo "Enabling community repo..."
    
    $REQUIRED_FEATURES_DIR/*enable-community-pacman/feature.sh full

    echo "Enabled community repo"
}

function install_yay() {
    echo "Installing yay..."

    echo "Attempting to install yay through cache..."
    if ! sudo pacman -S yay --needed --noconfirm; then
        echo "Yay could not be installed through cache"
        $REQUIRED_FEATURES_DIR/*yay/feature.sh full
    fi

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
    
    if [[ -d "$PKG_CACHE_DIR" ]]; then
        echo "Attempting to install pacman using cache..."
        sudo pacman -S ${pacman_packages[@]} ${aur_packages[@]} \
            --noconfirm --needed --cachedir "$PKG_CACHE_DIR"
    else
        echo "Installing pacman packages..."
        sudo pacman -S ${pacman_packages[@]} --noconfirm --needed

        echo "Installing AUR packages..."
        yay -S ${aur_packages[@]} --noconfirm --needed
    fi
}

function install_required_features() {
    local features=($(ls $REQUIRED_FEATURES_DIR))

    echo "Installing required features..."
    for feature in ${features[@]}; do
        if ! (echo $feature | grep "yay" || echo $feature | grep "sudoers"); then
            echo "Installing $feature..."
            $REQUIRED_FEATURES_DIR/$feature/feature.sh full

            if [[ "$DEFAULTS_NOCONFIRM" = "no" ]]; then
                pause
            fi
        fi
    done

    echo "Done installing required features"
}

function get_excluded_features() {
    local features=($(ls $EXTRA_FEATURES_DIR))

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

    echo "${excluded_features[@]}"
}

function install_extra_features() {
    local features=($(ls $EXTRA_FEATURES_DIR))

    echo "Installing extra features..."

    local excluded_features=($(get_excluded_features))
    echo "Excluding features ${excluded_features[@]}"

    for feature in ${features[@]}; do
        if ! echo ${excluded_features[@]} | grep $feature &> /dev/null; then
            echo "Installing $feature..."
            $EXTRA_FEATURES_DIR/$feature/feature.sh full

            if [[ "$DEFAULTS_NOCONFIRM" = "no" ]]; then
                pause
            fi
        fi
    done

    echo "Done installing extra features"
}

function check_all_features() {
    local required_features=($(ls $REQUIRED_FEATURES_DIR))
    local extra_features=($(ls $EXTRA_FEATURES_DIR))
    local excluded_features=($(get_excluded_features))

    echo "Not checking excluded features ${excluded_features[@]}"
    echo "Verifying feature installations..."

    echo "Checking required features..."
    for feature in ${required_features[@]}; do
        if ! echo ${excluded_features[@]} | grep $feature &> /dev/null; then
            echo "Checking $feature..."
            $REQUIRED_FEATURES_DIR/$feature/feature.sh check_install

            if [[ "$DEFAULTS_NOCONFIRM" = "no" ]]; then
                pause
            fi
        fi
    done

    echo "Checking extra features..."
    for feature in ${extra_features[@]}; do
        if ! echo ${excluded_features[@]} | grep $feature &> /dev/null; then
            echo "Checking $feature..."
            $EXTRA_FEATURES_DIR/$feature/feature.sh check_install

            if [[ "$DEFAULTS_NOCONFIRM" = "no" ]]; then
                pause
            fi
        fi
    done

    echo "Done checking features"
}

function disable_localrepo() {
    sudo sed -i /etc/pacman.conf -e '\;Include = /LadOS/install/localrepo.conf\;d'
}

function remove_temp_sudoers() {
    sudo rm -f /etc/sudoers.d/20-sudoers-temp
}


enable_community_repo

enable_local_repo

install_yay

install_packages

install_required_features

install_extra_features

check_all_features

disable_localrepo

remove_temp_sudoers
