#!/usr/bin/bash

function error_trap() {
    error_code="$?"
    echo "$(caller): \"$BASH_COMMAND\" returned error code $error_code" >&2
    exit $error_code
}

set -o errtrace
set -o pipefail
trap error_trap ERR


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//')"
REQUIRED_FEATURES_DIR="$LAD_OS_DIR/required-features"
OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"

VERBOSE=
QUIET=
V_FLAG=()     # Verbosity flag and also use arrays to avoid SC2086
S_FLAG=()     # Silent flag
SYSTEMD_FLAGS=("-f")

## Set in file that sources this file ##
feature_name=
feature_desc=
conflicts=()
provides=()
new_files=()
modified_files=()
temp_files=()
depends_aur=()
depends_pacman=()
depends_pip3=()
########################################

# If user is root or sudo does not exist, don't use sudo
shopt -s expand_aliases
if [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null; then
    vecho "Aliasing sudo to command"
    alias sudo='command'
fi



function qecho() {
    if [[ -z "$QUIET" ]]; then echo "$@"; fi
}

function vecho() {
    if [[ -n "$VERBOSE" ]]; then echo "$@"; fi
}

function prompt() {
    local mesg resp
    mesg="$1"

    while true; do
        read -rp "$mesg [y/n]: " resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

function print_usage() {
    echo "usage: $0 [ -q | -v ] [ --no-service-start ] <action>"
    echo
    echo "  Actions:"
    echo "    full                  Do a full install of the feature including"
    echo "                          the following actions in the specified"
    echo "                          order: check_conflicts, check_conf,"
    echo "                          load_conf, install_dependencies, prepare,"
    echo "                          install, post_install, check_install"
    echo
    echo "    full_no_check         Do a full install as specified above, but"
    echo "                          without a install check"
    echo
    echo "    name                  Print name of feature"
    echo
    echo "    desc                  Print description of feature"
    echo
    echo "    conflicts             Print names of features this feature"
    echo "                          conflicts with"
    echo
    echo "    check_conf            Check if feature's configuration is set"
    echo "                          correctly"
    echo
    echo "    load_conf             Load the feature's configuration. Note:"
    echo "                          if this feature's configuration is loaded"
    echo "                          into memory and not as files, the"
    echo "                          configuration will not persist for any"
    echo "                          actions that follow"
    echo
    echo "    check_install         Check if the feature is installed correctly"
    echo
    echo "    prepare               Prepare the feature for installation. This"
    echo "                          step involves no permenant changes to your"
    echo "                          system"
    echo
    echo "    install               Install the feature"
    echo
    echo "    uninstall             Uninstall the feature"
    echo
    echo "    post_install          Perform post-installation actions such as"
    echo "                          enabling services"
    echo
    echo "    cleanup               Remove temporary files and any artifacts"
    echo "                          produced by any other feature actions that"
    echo "                          were only required by the installation"
    echo
    echo "    install_dependencies  Install pacman, AUR, or python packages"
    echo "                          that this feature depends on"
    echo
    echo "    check_conflicts       Check if any conflicting features are"
    echo "                          installed"
    echo
    echo "    help                  Display this message"
    echo
    echo
    echo "  Options:"
    echo "   --no-service-start     Don't start systemd services"
    echo "   -q                     Hide normal output"
    echo "   -v                     Show verbose output"
    echo
}

function check_conflicts() {
    for c in "${conflicts[@]}"; do
        if [[ -d "$REQUIRED_FEATURES_DIR/$c" ]] &&
            "$REQUIRED_FEATURES_DIR"/"$c"/feature.sh -q check_install &> /dev/null ||
            [[ -d "$OPTIONAL_FEATURES_DIR/$c" ]] &&
            "$OPTIONAL_FEATURES_DIR"/"$c"/feature.sh -q check_install &> /dev/null; then
            qecho "Cannot install $feature_name. It conflicts with $c"
            return 1
        fi
    done

    return 0
}

function has_dependencies() {
    if [[ "${depends_pacman[*]}${depends_aur[*]}${depends_pip3[*]}" = "" ]]; then
        return 1
    else
        return 0
    fi
}

function install_dependencies() {
    if [[ "${depends_pacman[*]}" != "" ]]; then
        qecho "Installing ${depends_pacman[*]}..."
        # Reinstall warnings go to stderr
        sudo pacman -S "${depends_pacman[@]}" --noconfirm --needed
    fi

    if [[ "${depends_aur[*]}" != "" ]]; then
        qecho "Installing ${depends_aur[*]}..."
        yay -S "${depends_aur[@]}" --noconfirm --needed
    fi

    if [[ "${depends_pip3[*]}" != "" ]]; then
        if ! command -v pip3 > /dev/null; then
            sudo pacman -S python-pip --noconfirm --needed
        fi

        qecho "Installing ${depends_pip3[*]}..."
        sudo pip3 install "${depends_pip3[@]}"
    fi
}

function uninstall_dependencies() {
    if [[ "${depends_pacman[*]}" != "" ]]; then
        qecho "Uninstalling ${depends_pacman[*]}..."
        sudo pacman -Rsu "${depends_pacman[@]}" --noconfirm
    fi

    if [[ "${depends_aur[*]}" != "" ]]; then
        qecho "Installing ${depends_aur[*]}..."
        # Some normal output goes to stderr
        yay -Rsu "${depends_aur[@]}" --noconfirm
    fi

    if [[ "${depends_pip3[*]}" != "" ]]; then
        qecho "Installing ${depends_pip3[*]}..."
        sudo pip3 uninstall "${depends_pip3[@]}"
    fi
}


if [[ "$1" = "-v" ]]; then
    VERBOSE=1
    V_FLAG=()
    S_FLAG=()
    shift
elif [[ "$1" = "-q" ]]; then
    QUIET=1
    V_FLAG=("-q")
    S_FLAG=("-s")
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

