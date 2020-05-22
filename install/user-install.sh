#!/usr/bin/bash

BASE_DIR="$( readlink -f "$(dirname "$0")" )"
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/install_common.sh"

OPTIONAL_FEATURES_SELECTED=()


function enable_community_repo() {
    msg "Enabling community repo..."
    
    local path_to_feature
    path_to_feature=("$REQUIRED_FEATURES_DIR"/*enable-community-pacman/feature.sh)

    "${path_to_feature[0]}" "${VERBOSITY_FLAG}" --no-service-start full
}

function install_yay() {
    msg "Installing yay..."

    if pacman -Si yay &> /dev/null; then
        msg2 "Installing yay through cache..."
        sudo pacman -S yay --needed --noconfirm
    else
        msg2 "Making and installing yay..."
        local path_to_feature
        path_to_feature=("$REQUIRED_FEATURES_DIR"/*yay/feature.sh)

        "${path_to_feature[0]}" "${VERBOSITY_FLAG}" --no-service-start full
    fi
}

function install_packages() {
    msg "Installing packages..."

    local install_optional=0
    if [[ "$CONF_INSTALL_OPTIONAL" = "yes" ]]  ||
      prompt "Install optional packages as well?"; then
        install_optional=1
    fi

    IFS=$'\n'
    local packages
    mapfile -t packages < "$LAD_OS_DIR"/packages.csv

    local pacman_packages=()
    local aur_packages=()

    for package in "${packages[@]}"; do
        local name desc typ req
        name=$(echo "$package" | cut -d',' -f1)
        desc=$(echo "$package" | cut -d',' -f2)
        typ=$(echo "$package" | cut -d',' -f3)
        req=$(echo "$package" | cut -d',' -f4)

        vecho "$name ($desc)"

        if [[ $install_optional -eq 1 ]] && [[ "$req" = "optional" ]] || [[ "$req" = "required" ]]; then
            if [[ "$typ" = "system" ]]; then
                pacman_packages=("${pacman_packages[@]}" "$name")
            elif [[ "$typ" = "aur" ]]; then
                aur_packages=("${aur_packages[@]}" "$name")
            fi
        fi
    done

    msg2 "Syncing pacman..."
    sudo pacman -Syu --noconfirm
    
    if [[ -d "$PKG_CACHE_DIR" ]]; then
        msg2 "Installing all packages using cache..."
        sudo pacman -S "${pacman_packages[@]}" "${aur_packages[@]}" \
            --noconfirm --needed --cachedir "$PKG_CACHE_DIR"
    else
        msg2 "Installing pacman packages..."
        sudo pacman -S "${pacman_packages[@]}" --noconfirm --needed

        msg2 "Building and installing AUR packages..."
        yay -S "${aur_packages[@]}" --noconfirm --needed
    fi
}

function install_required_features() {
    msg "Installing required features..."

    local features total
    mapfile -t features < <(ls "$REQUIRED_FEATURES_DIR")
    total="${#features[@]}"

    for i in "${!features[@]}"; do
        feature="${features[i]}"
	i=$((i+1))
        progress="($i/$total)"

        if ! (echo "$feature" | grep -e "yay" -e "sudoers" -e "dracut"); then
            msg2 "$progress Installing $feature..."
            
            "$REQUIRED_FEATURES_DIR"/"$feature"/feature.sh "${VERBOSITY_FLAG}" --no-service-start full_no_check

            if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
                pause
            fi
        fi
    done
}

function get_excluded_features() {
    local features
    mapfile -t features < <(ls "$OPTIONAL_FEATURES_DIR")

    if [[ "$CONF_EXCLUDE_FEATURES" != "" ]]; then
        excluded=("${CONF_EXCLUDE_FEATURES[@]}")
    else
        local i=1
        for feature in "${features[@]}"; do
            echo "$i. $feature"
            i=$((i+1))
        done

        local exclusions
        exclusions="$(ask_words "Enter features to exclude (i.e. 1 2 3)")"
        
        for i in "${exclusions[@]}"; do
            excluded_feature="${features[ $(( i-1 )) ]}"
            excluded=("${excluded[@]}" "$excluded_feature")
        done
    fi

    echo "${excluded[@]}"
}

function install_optional_features() {
    msg "Installing optional features..."

    local features excluded feature_path excluded i total
    mapfile -t features < <(ls "$OPTIONAL_FEATURES_DIR")

    i=0
    excluded=($(get_excluded_features))

    total=$(( ${#features[@]} - ${#excluded[@]} ))

    vecho "Excluding features ${excluded[*]}"

    for feature in "${features[@]}"; do
        if ! echo "${excluded[@]}" | grep -q "$feature"; then
            i=$((i+1))
            progress="($i/$total)"

            feature_path="$OPTIONAL_FEATURES_DIR/$feature/feature.sh"
            mapfile -t conflicts < <("$feature_path" $VERBOSITY_FLAG conflicts)

            for c in "${conflicts[@]}"; do
                if ! echo "${excluded[*]}" | grep -q "$c"; then
                    plain "$c conflicts with $feature"
                    if prompt "Would you like to exclude $c and continue to install $feature?"; then
                        excluded=("${excluded[@]}" "$c")
                    else
                        excluded=("${excluded[@]}" "${feature[@]}")
                        exclude_this=1
                    fi
                fi
            done

            if [[ "$excluded_this" -eq 1 ]]; then
                exclude_this=0
                continue
            fi

            OPTIONAL_FEATURES_SELECTED=("${OPTIONAL_FEATURES_SELECTED[@]}" "$feature")

            msg2 "$progress Installing $feature..."
            "$feature_path" "${VERBOSITY_FLAG}" --no-service-start full_no_check

            if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
                pause
            fi
        fi
    done
}

function check_required_features() {
    msg "Checking required features..."

    local required
    mapfile -t required < <(ls "$REQUIRED_FEATURES_DIR")

    for i in "${!required[@]}"; do
        feature="${required[i]}"
        progress="($((i+1))/${#required[@]})"

        msg2 "$progress Checking $feature..."

        "$REQUIRED_FEATURES_DIR"/"$feature"/feature.sh "${VERBOSITY_FLAG}" check_install
        res="$?"

        if [[ "$?" -gt 0 ]]; then
            error "$feature is not installed."
            exit 1
        fi

        if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
            pause
        fi
    done
}

function check_optional_features() {
    msg "Checking optional features..."

    local optional
    optional=("${OPTIONAL_FEATURES_SELECTED[@]}")

    for i in "${!optional[@]}"; do
        feature="${optional[i]}"
        progress="($((i+1))/${#optional[@]})"

        msg2 "$progress Checking $feature..."

        "$OPTIONAL_FEATURES_DIR"/"$feature"/feature.sh "${VERBOSITY_FLAG}" check_install
        res="$?"

        if [[ "$?" -gt 0 ]]; then
            error "$feature is not installed."
            exit 1
        fi

        if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
            pause
        fi
    done
}

function disable_localrepo() {
    msg "Disabling localrepo..."
    sudo sed -i /etc/pacman.conf -e '\;Include = /LadOS/install/localrepo.conf;d'
}


function remove_temp_sudoers() {
    msg "Removing temp sudoers..."
    sudo rm -f /etc/sudoers.d/20-sudoers-temp
}

function review() {
    msg "Configuration review..."
    
    local pacman_mirrors fstab dracut_conf locale lang hostname hosts
    local default_user required_features optional_features

    pacman_mirrors="$(cat /etc/pacman.d/mirrorlist)"
    fstab="$(cat /etc/fstab)"
    timezone="$(readlink -f /etc/localtime)"
    locale="$(grep -P -o "^[^#].*" /etc/locale.gen)"
    hostname="$(cat /etc/hostname)"
    hosts="$(cat /etc/hosts)"
    default_user="$USER"
    required_features="$(ls "$REQUIRED_FEATURES_DIR")"
    optional_features="${OPTIONAL_FEATURES_SELECTED[*]}"
    dracut_conf="$(cat /etc/dracut.conf.d/*.conf)"
    lang="$(source /etc/locale.conf; echo "$LANG")"

    msg2 "Pacman mirrors:"
    echo "$pacman_mirrors"

    msg2 "fstab:"
    echo "$fstab"

    msg2 "Dracut Configuration:"
    echo "$dracut_conf"

    msg2 "Locale:"
    echo "$locale"

    msg2 "Lang"
    echo "$lang"

    msg2 "Hostname:"
    echo "$hostname"

    msg2 "Hosts:"
    echo "$hosts"

    msg2 "Default User:"
    echo "$default_user"

    msg2 "Installed Required Features:"
    echo $required_features

    msg2 "Installed Optional Features:"
    echo $optional_features

    pause
}



enable_community_repo

install_yay

install_packages

install_required_features

install_optional_features

check_required_features

check_optional_features

disable_localrepo

remove_temp_sudoers

review
