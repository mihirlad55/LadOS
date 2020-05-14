#!/usr/bin/bash

VERBOSE=
QUIET=
DEFAULT_OUT="/dev/fd/1"
VERBOSITY_FLAG=
SILENT_FLAG=

# If user is root or sudo does not exist, don't use sudo
shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=


function qecho() {
    [[ ! -n "$QUIET" ]] && echo "$@"
}

function vecho() {
    [[ -n "$VERBOSE" ]] && echo "$@"
}

function print_usage() {
    echo "usage: feature.sh [ -q | -v ] [ full | full_no_check | name | desc | check_conf | load_conf | check_install | prepare | install | post_install | cleanup | install_dependencies | help ]"
}

function install_dependencies() {
    if [[ "${depends_pacman[@]}" != "" ]]; then
        qecho "Installing ${depends_pacman[@]}..."
        # Reinstall warnings go to stderr
        sudo pacman -S ${depends_pacman[@]} --noconfirm --needed &> "$DEFAULT_OUT"
    fi

    if [[ "${depends_aur[@]}" != "" ]]; then
        qecho "Installing ${depends_aur[@]}..."
        # Some normal output goes to stderr
        yay -S ${depends_aur[@]} --noconfirm --needed &> "$DEFAULT_OUT"
    fi

    if [[ "${depends_pip3[@]}" != "" ]]; then
        if ! command -v pip3 > /dev/null; then
            sudo pacman -S python-pip --noconfirm --needed > "$DEFAULT_OUT"
        fi

        qecho "Installing ${depends_pip3[@]}..."
        sudo pip3 install ${depends_pip3[@]} > "$DEFAULT_OUT"
    fi
}


if [[ "$1" = "-v" ]]; then
    VERBOSE=1
    shift
elif [[ "$1" = "-q" ]]; then
    QUIET=1
    DEFAULT_OUT="/dev/null"
    VERBOSITY_FLAG="-q"
    SILENT_FLAG="-s"
    shift
fi

case "$1" in
    full | full_no_check)
        if type -p check_conf && type -p load_conf; then
            qecho "Checking and loading configuration..."
            check_conf && load_conf
        fi

        if type -p install_dependencies; then
            install_dependencies
        fi

        if type -p prepare; then
            qecho "Beginning prepare..."
            prepare
        fi

        qecho "Installing feature..."
        install

        if type -p post_install; then
            qecho "Starting post_install..."
            post_install
        fi

        if type -p cleanup; then
            qecho "Starting cleanup..."
            cleanup
        fi

        if [[ "$1" = "full" ]] && type -p check_install; then
            qecho "Checking if feature was installed correctly..."
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
            qecho "Starting $1..."
            $1
            res="$?"
            qecho "Done $1"
            exit "$res"
        else
            qecho "$1 is not defined for this feature"
            exit 1
        fi
        ;;

    install_dependencies)
        if [[ "${depends_pacman[@]}" != "" ]] || [[ "${depends_aur[@]}" != "" ]]; then
            install_dependencies
        else
            qecho "No dependencies to install"
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
