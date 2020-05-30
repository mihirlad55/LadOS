#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"

source "$LAD_OS_DIR/common/install_common.sh"

optional_features_selected=()


function err_proceed() {
    error "$@"
    if prompt "Would you like to proceed?"; then
        return 0
    fi
    exit 1
}

function enable_community_repo() {
    msg "Enabling community repo..."
    
    local path_to_feature
    path_to_feature=("$REQUIRED_FEATURES_DIR"/*enable-community-pacman/feature.sh)

    "${path_to_feature[0]}" "${F_FLAGS[@]}" full
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

        "${path_to_feature[0]}" "${F_FLAGS[@]}" full
    fi
}

function install_packages() {
    local install_optional pacman_packages aur_packages name desc typ req
    msg "Installing packages..."

    if [[ "$CONF_INSTALL_OPTIONAL" = "yes" ]]  ||
      prompt "Install optional packages as well?"; then
        install_optional=1
    fi

    while IFS=',' read name desc typ req; do
        vecho "$name ($desc)"

        if [[ -n "$install_optional" ]] && [[ "$req" = "optional" ]] ||
          [[ "$req" = "required" ]]; then
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
    local feature features progress total i

    msg "Installing required features..."

    mapfile -t features < <(ls "$REQUIRED_FEATURES_DIR")
    total="${#features[@]}"

    for i in "${!features[@]}"; do
        feature="${features[i]}"
        i=$(( i + 1 ))
        progress="($i/$total)"

        if ! echo "$feature" | grep -e "yay" -e "sudoers" -e "dracut"; then
            msg2 "$progress Installing $feature..."
            
            "$REQUIRED_FEATURES_DIR"/"$feature"/feature.sh "${F_FLAGS[@]}" \
                full_no_check

            if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
                pause
            fi
        fi
    done
}

function is_feature_valid() {
    local name
    name="$1"

    if [[ ! -d "$OPTIONAL_FEATURES_DIR/$name" ]] || \
        [[ ! -d "$REQUIRED_FEATURES_DIR/$name" ]]; then
        return 1
    fi
    return 0
}

function get_excluded_features() {
    local features conf_excluded excluded excluded_nums f i

    mapfile -t features < <(ls "$OPTIONAL_FEATURES_DIR")

    if [[ "$CONF_EXCLUDE_FEATURES" != "" ]]; then
        conf_excluded=("${CONF_EXCLUDE_FEATURES[@]}")
        excluded=()

        for f in "${conf_excluded[@]}"; do
            if ! is_feature_valid "$f"; then
                warn "$f is not a valid feature. Not adding to exclusions."
            else
                excluded=("${excluded[@]}" "$f")
            fi
        done
    else
        i=1
        for f in "${features[@]}"; do
            echo "$i. $f"
            i=$((i+1))
        done

        excluded_nums="$(ask_words "Enter features to exclude (i.e. 1 2 3)")"
        
        for i in "${excluded_nums[@]}"; do
            excluded=("${excluded[@]}" "${features[ $(( i-1 )) ]}")
        done
    fi

    echo "${excluded[@]}"
}

function install_optional_features() {
    local features feature excluded feature_path excluded i total c exclude_this
    local conflicts

    msg "Installing optional features..."

    mapfile -t features < <(ls "$OPTIONAL_FEATURES_DIR")
    mapfile -t excluded < <(get_excluded_features)

    i=0

    total=$(( ${#features[@]} - ${#excluded[@]} ))

    vecho "Excluding features ${excluded[*]}"

    for feature in "${features[@]}"; do
        if ! echo "${excluded[@]}" | grep -q "$feature"; then
            feature_path="$OPTIONAL_FEATURES_DIR/$feature/feature.sh"

            i=$((i+1))
            progress="($i/$total)"

            mapfile -t conflicts < <("$feature_path" "${V_FLAG[@]}" conflicts)

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

            if (( "$exclude_this" == 1 )); then
                exclude_this=0
                continue
            fi

            optional_features_selected=("${optional_features_selected[@]}" "$feature")

            msg2 "$progress Installing $feature..."
            if ! "$feature_path" "${F_FLAGS[@]}" full_no_check; then
                err_proceed "$feature failed to install"
            fi

            if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
                pause
            fi
        fi
    done
}

function check_required_features() {
    local required progress feature feature_path i

    msg "Checking required features..."

    mapfile -t required < <(ls "$REQUIRED_FEATURES_DIR")

    for i in "${!required[@]}"; do
        feature="${required[i]}"
        feature_path="$REQUIRED_FEATURES_DIR/$feature/feature.sh"
        progress="($((i+1))/${#required[@]})"

        msg2 "$progress Checking $feature..."

        if ! "$feature_path" "${F_FLAGS[@]}" check_install; then
            error "$feature is not installed."
            exit 1
        fi

        if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
            pause
        fi
    done
}

function check_optional_features() {
    local optional progress feature feature_path i

    msg "Checking optional features..."

    optional=("${optional_features_selected[@]}")

    for i in "${!optional[@]}"; do
        feature="${optional[i]}"
        feature_path="$OPTIONAL_FEATURES_DIR/$feature/feature.sh"
        progress="($((i+1))/${#optional[@]})"

        msg2 "$progress Checking $feature..."

        if ! "$feature_path" "${F_FLAGS[@]}" check_install; then
            err_proceed "$feature does not seem to be installed correctly"
        fi

        if [[ "$CONF_NOCONFIRM" != "yes" ]]; then
            pause
        fi
    done
}

function disable_localrepo() {
    msg "Disabling localrepo..."
    sudo sed -i /etc/pacman.conf -e \
        '\;Include = /LadOS/install/localrepo.conf;d'
}


function remove_temp_sudoers() {
    msg "Removing temp sudoers..."
    sudo rm -f /etc/sudoers.d/20-sudoers-temp
}

function review() {
    msg "Configuration review..."
    
    local pacman_mirrors fstab timezone dracut_conf locale lang hostname hosts
    local default_user required_features optional_features

    pacman_mirrors="$(cat /etc/pacman.d/mirrorlist)"
    fstab="$(cat /etc/fstab)"
    timezone="$(readlink -f /etc/localtime)"
    locale="$(grep -P -o "^[^#].*" /etc/locale.gen)"
    hostname="$(cat /etc/hostname)"
    hosts="$(cat /etc/hosts)"
    default_user="$USER"
    required_features="$(ls "$REQUIRED_FEATURES_DIR")"
    optional_features="${optional_features_selected[*]}"
    dracut_conf="$(cat /etc/dracut.conf.d/*.conf)"
    lang="$(source /etc/locale.conf; echo "$LANG")"

    msg2 "Pacman mirrors:"
    echo "$pacman_mirrors"

    msg2 "fstab:"
    echo "$fstab"

    msg2 "Timezone:"
    echo "$timezone"

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
    echo "$required_features" | tr '\n' ' '

    msg2 "Installed Optional Features:"
    echo "$optional_features" | tr '\n' ' '

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
