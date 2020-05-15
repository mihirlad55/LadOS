#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
REQUIRED_FEATURES_DIR="$LAD_OS_DIR/required-features"
OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"

VERBOSE=
QUIET=
DEFAULT_OUT="/dev/fd/1"
VERBOSITY_FLAG=
SILENT_FLAG=
SYSTEMD_FLAGS=()

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
    echo "usage: feature.sh [ -q | -v ] [ --no-service-start ] [ full | full_no_check | name | desc | conflicts | check_conf | load_conf | check_install | prepare | install | post_install | cleanup | install_dependencies | check_conflicts | help ]"
}

function check_conflicts() {
    for c in "${conflicts[@]}"; do
        local feature_path
        feature_path="$REQUIRED_FEATURES_DIR/$c"
        if [[ -d "$REQUIRED_FEATURES_DIR/$c" ]] &&
            "$REQUIRED_FEATURES_DIR"/"$c"/feature.sh -q check_install &> "$DEFAULT_OUT" ||
            [[ -d "$OPTIONAL_FEATURES_DIR/$c" ]] &&
            "$OPTIONAL_FEATURES_DIR"/"$c"/feature.sh -q check_install &> "$DEFAULT_OUT"; then
            echo "Cannot install $feature_name. It conflicts with $c"
            return 1
        fi
    done

    return 0
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

        if check_conflicts; then
            qecho "Installing feature..."
            install
        else
            exit 1
        fi

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
