#!/usr/bin/bash

set -o errtrace
set -o pipefail
trap error_trap ERR


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
REQUIRED_FEATURES_DIR="$LAD_OS_DIR/required-features"
OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"

VERBOSE=
QUIET=
DEFAULT_OUT="/dev/stdout"
VERBOSITY_FLAG=
SILENT_FLAG=
SYSTEMD_FLAGS=()


# If user is root or sudo does not exist, don't use sudo
shopt -s expand_aliases
if [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null; then
	echo "$USER"
	echo $(command -v sudo)
    echo "Aliasing sudo to nothing"
    alias sudo=
fi



function error_trap() {
    error_code="$?"
    last_command="$BASH_COMMAND"
    command_caller="$(caller)"

    echo "$command_caller: \"$last_command\" returned error code $error_code" >&2

    exit $error_code
}

function qecho() {
    if [[ ! -n "$QUIET" ]]; then echo "$@"; fi
}

function vecho() {
    if [[ -n "$VERBOSE" ]]; then echo "$@"; fi
}

function prompt() {
    local mesg resp
    mesg="$1"

    while true; do
        read -p "$mesg [Y/n]: " resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

function print_usage() {
    echo -n "usage: feature.sh [ -q | -v ] [ --no-service-start ] [ full | "
    echo -n "full_no_check | name | desc | conflicts | check_conf | load_conf "
    echo -n "| check_install | prepare | install | uninstall | post_install | "
    echo "cleanup | install_dependencies | check_conflicts | help ]"
}

function check_conflicts() {
    for c in "${conflicts[@]}"; do
        local feature_path
        feature_path="$REQUIRED_FEATURES_DIR/$c"
        if [[ -d "$REQUIRED_FEATURES_DIR/$c" ]] &&
            "$REQUIRED_FEATURES_DIR"/"$c"/feature.sh -q check_install &> "$DEFAULT_OUT" ||
            [[ -d "$OPTIONAL_FEATURES_DIR/$c" ]] &&
            "$OPTIONAL_FEATURES_DIR"/"$c"/feature.sh -q check_install &> "$DEFAULT_OUT"; then
            qecho "Cannot install $feature_name. It conflicts with $c"
            return 1
        fi
    done

    return 0
}

function has_dependencies() {
    if [[ "${depends_pacman[@]}${depends_aur[@]}${depends_pip3[@]}" = "" ]]; then
        return 1
    else
        return 0
    fi
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

function uninstall_dependencies() {
    if [[ "${depends_pacman[@]}" != "" ]]; then
        qecho "Uninstalling ${depends_pacman[@]}..."
        # Some warnings go to stderr
        sudo pacman -Rsu ${depends_pacman[@]} --noconfirm &> "$DEFAULT_OUT"
    fi

    if [[ "${depends_aur[@]}" != "" ]]; then
        qecho "Installing ${depends_aur[@]}..."
        # Some normal output goes to stderr
        yay -Rsu ${depends_aur[@]} --noconfirm &> "$DEFAULT_OUT"
    fi

    if [[ "${depends_pip3[@]}" != "" ]]; then
        qecho "Installing ${depends_pip3[@]}..."
        sudo pip3 uninstall ${depends_pip3[@]} > "$DEFAULT_OUT"
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
    SYSTEMD_FLAGS=("${SYSTEMD_FLAGS[@]}" "-q")
    shift
fi

if [[ "$1" = "--no-service-start" ]]; then
    shift
else
    SYSTEMD_FLAGS=("${SYSTEMD_FLAGS[@]}" "--now")
fi

if [[ "$#" -ne 1 ]]; then
    print_usage
    exit 1
fi

case "$1" in
    full | full_no_check)
        if ! check_conflicts; then
            exit 1
        fi

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

    conflicts)
        echo "${conflicts[*]}"
        ;;

    check_conf | load_conf | check_install | prepare | install |  post_install \
        | cleanup | check_conflicts)
        if type -p "$1"; then
            qecho "Starting $1..."
            res=0
            $1 || res=$?
            qecho "Done $1"
            exit "$res"
        else
            qecho "$1 is not defined for this feature"
            exit 1
        fi
        ;;

    uninstall)
        if ! check_install &> /dev/null; then
            echo "$feature_name is not installed"
            exit 1
        fi

        if prompt "Are you sure you want to uninstall $feature_name?"; then
            echo "Uninstalling $feature_name..."

            if has_dependencies; then
                echo -n "$feature_name depends on ${depends_pacman[@]} "
                echo "${depends_aur[@]} ${depends_pip3[@]}"
                if prompt "Would you like to uninstall these dependencies?"; then
                    uninstall_dependencies
                fi
            fi

            if type -p uninstall; then
                uninstall
            fi

            echo "Finished uninstalling $feature_name"
        fi
        ;;

    install_dependencies)
        if has_dependencies; then
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
