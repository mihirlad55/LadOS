#!/usr/bin/bash

VERBOSE=
QUIET=


# If user is root or sudo does not exist, don't use sudo
shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

function print_usage() {
    echo "usage: feature.sh [-q | -v ] [ full | full_no_check | name | desc | check_conf | load_conf | check_install | prepare | install | post_install | cleanup | install_dependencies | help ]"
}

function install_dependencies() {
    if [[ "${depends_pacman[@]}" != "" ]]; then
        [[ ! -n "$QUIET" ]] && echo "Installing ${depends_pacman[@]}..."
        sudo pacman -S ${depends_pacman[@]} --noconfirm --needed
    fi

    if [[ "${depends_aur[@]}" != "" ]]; then
        [[ ! -n "$QUIET" ]] && echo "Installing ${depends_aur[@]}..."
        yay -S ${depends_aur[@]} --noconfirm --needed
    fi

    if [[ "${depends_pip3[@]}" != "" ]]; then
        if ! command -v pip3 > /dev/null; then
            sudo pacman -S python-pip --noconfirm --needed
        fi

        [[ ! -n "$QUIET" ]] && echo "Installing ${depends_pip3[@]}..."
        sudo pip3 install ${depends_pip3[@]}
    fi
}

function qecho() {
    [[ ! -n "$QUIET" ]] && echo "$@"
}

function vecho() {
    [[ -n "$VERBOSE" ]] && echo "$@"
}


if echo "$@" | grep -q "-v"; then
    $@="$(echo "$@" | sed 's/-v//')"
    VERBOSE=1
fi

if echo "$@" | grep -q "-q"; then
    $@="$(echo "$@" | sed 's/-q//')"
    QUIET=1
fi

case "$1" in
    full | full_no_check)
        if type -p check_conf && type -p load_conf; then
            [[ ! -n "$QUIET" ]] && echo "Checking and loading configuration..."
            check_conf && load_conf
        fi

        if type -p install_dependencies; then
            install_dependencies
        fi

        if type -p prepare; then
            [[ ! -n "$QUIET" ]] && echo "Beginning prepare..."
            prepare
        fi

        [[ ! -n "$QUIET" ]] && echo "Installing feature..."
        install

        if type -p post_install; then
            [[ ! -n "$QUIET" ]] && echo "Starting post_install..."
            post_install
        fi

        if type -p cleanup; then
            [[ ! -n "$QUIET" ]] && echo "Starting cleanup..."
            cleanup
        fi

        if [[ "$1" = "full_no_check" ]] && type -p check_install; then
            [[ ! -n "$QUIET" ]] && echo "Checking if feature was installed correctly..."
            check_install
        fi

        ;;
    name)
        echo "$feature_name"
        ;;
    desc)
        echo "$feature_desc"
        ;;
    check_conf | load_conf | check_install | prepare | install |  post_install \
        | cleanup)
        if type -p "$1"; then
            [[ ! -n "$QUIET" ]] && echo "Starting $1..."
            $1
            res="$?"
            [[ ! -n "$QUIET" ]] && echo "Done $1"
            exit "$res"
        else
            [[ ! -n "$QUIET" ]] && echo "$1 is not defined for this feature"
            exit 1
        fi
        ;;

    install_dependencies)
        if [[ "${depends_pacman[@]}" != "" ]] || [[ "${depends_aur[@]}" != "" ]]; then
            install_dependencies
        else
            [[ ! -n "$QUIET" ]] && echo "No dependencies to install"
            exit 1
        fi
        ;;

    help)
        print_usage
        ;;
    *)
        print_usage
        exit 1
esac
