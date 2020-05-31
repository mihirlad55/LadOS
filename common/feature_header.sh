#!/usr/bin/bash

function error_trap() {
    error_code="$?"
    echo "$(caller): \"$BASH_COMMAND\" returned error code $error_code" >&2
    exit $error_code
}

set -o errtrace
set -o pipefail
trap error_trap ERR


# Absolute path to directory of script defined in file that sources this
readonly BASE_DIR
# Absolute path to root of repo defined in file that sources this
readonly LAD_OS_DIR
readonly REQUIRED_FEATURES_DIR="$LAD_OS_DIR/required-features"
readonly OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"

# The following flags are set to readonly below
VERBOSE=
QUIET=
V_FLAG=()     # Verbosity flag and also use arrays to avoid SC2086
S_FLAG=()     # Silent flag
SYSTEMD_FLAGS=("-f")
GIT_FLAGS=("--depth 1")

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
    GIT_FLAGS=("${GIT_FLAGS[@]}" "${V_FLAG[@]}")
    shift
fi

if [[ "$1" = "--no-service-start" ]]; then
    shift
else
    SYSTEMD_FLAGS=("${SYSTEMD_FLAGS[@]}" "--now")
fi

readonly VERBOSE QUIET V_FLAG S_FLAG SYSTEMD_FLAGS GIT_FLAGS


## Set in file that sources this file ##
#FEATURE_NAME=
#FEATURE_DESC=
#CONFLICTS=()
#PROVIDES=()
#NEW_FILES=()
#MODIFIED_FILES=()
#TEMP_FILES=()
#DEPENDS_AUR=()
#DEPENDS_PACMAN=()
#DEPENDS_PIP3=()
########################################



# If user is root or sudo does not exist, don't use sudo
# This is for installing features as part of the main installation in case
# sudo has not yet been installed
shopt -s expand_aliases
if [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null; then
    vecho "Aliasing sudo to command"
    alias sudo='command'
fi


# Only print this if quiet flag is not set 
function qecho() {
    if [[ -z "$QUIET" ]]; then echo "$@"; fi
}

# Only print this if verbose flag is set
function vecho() {
    if [[ -n "$VERBOSE" ]]; then echo "$@"; fi
}

################################################################################
# Prompt user with specified yes/no question and return response
#   Globals:
#     None
#   Arguments:
#     mesg, Question to ask user
#   Outputs:
#     Prompts user with question
#   Returns:
#     0, if user responds with "Y" or "y"
#     1, if user responds with "N" or "n"
################################################################################
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

################################################################################
# Check if any conflicting features are installed
#   Globals:
#     REQUIRED_FEATURES_DIR
#     OPTIONAL_FEATURES_DIR
#     FEATURES_NAME
#   Arguments:
#     None
#   Outputs:
#     Name of conflicting feature in a message, if it is installed and if script
#     is not in quiet mode
#   Returns:
#     0, if no conflicting features are installed
#     1, if a conflicting feature is installed
################################################################################
function check_conflicts() {
    for c in "${CONFLICTS[@]}"; do
        if [[ -d "$REQUIRED_FEATURES_DIR/$c" ]] &&
            "$REQUIRED_FEATURES_DIR"/"$c"/feature.sh -q check_install &> /dev/null ||
            [[ -d "$OPTIONAL_FEATURES_DIR/$c" ]] &&
            "$OPTIONAL_FEATURES_DIR"/"$c"/feature.sh -q check_install &> /dev/null; then
            qecho "Cannot install $FEATURE_NAME. It conflicts with $c"
            return 1
        fi
    done

    return 0
}


################################################################################
# Check if feature has any dependencies
#   Globals:
#     DEPENDS_PACMAN
#     DEPENDS_AUR
#     DEPENDS_PIP3
#   Arguments:
#     None
#   Outputs:
#     None
#   Returns:
#     0, if there are dependencies for this feature
#     1, if there are no dependencies for this feature
################################################################################
function has_dependencies() {
    if [[ "${DEPENDS_PACMAN[*]}${DEPENDS_AUR[*]}${DEPENDS_PIP3[*]}" = "" ]]; then
        return 1
    else
        return 0
    fi
}

################################################################################
# Install dependencies for feature
#   Globals:
#     DEPENDS_PACMAN
#     DEPENDS_AUR
#     DEPENDS_PIP3
#   Arguments:
#     None
#   Outputs:
#     Info about progress (if quiet flag is not set)
#   Returns:
#     0, if successful
################################################################################
function install_dependencies() {
    if [[ "${DEPENDS_PACMAN[*]}" != "" ]]; then
        qecho "Installing ${DEPENDS_PACMAN[*]}..."
        # Reinstall warnings go to stderr
        sudo pacman -S "${DEPENDS_PACMAN[@]}" --noconfirm --needed
    fi

    if [[ "${DEPENDS_AUR[*]}" != "" ]]; then
        qecho "Installing ${DEPENDS_AUR[*]}..."
        yay -S "${DEPENDS_AUR[@]}" --noconfirm --needed
    fi

    if [[ "${DEPENDS_PIP3[*]}" != "" ]]; then
        if ! command -v pip3 > /dev/null; then
            sudo pacman -S python-pip --noconfirm --needed
        fi

        qecho "Installing ${DEPENDS_PIP3[*]}..."
        sudo pip3 install "${DEPENDS_PIP3[@]}"
    fi
}

################################################################################
# Uninstall dependencies for feature
#   Globals:
#     DEPENDS_PACMAN
#     DEPENDS_AUR
#     DEPENDS_PIP3
#   Arguments:
#     None
#   Outputs:
#     Info about progress (if quiet flag is not set)
#   Returns:
#     0, if successful
################################################################################
function uninstall_dependencies() {
    if [[ "${DEPENDS_PACMAN[*]}" != "" ]]; then
        qecho "Uninstalling ${DEPENDS_PACMAN[*]}..."
        sudo pacman -Rsu "${DEPENDS_PACMAN[@]}" --noconfirm
    fi

    if [[ "${DEPENDS_AUR[*]}" != "" ]]; then
        qecho "Uninstalling ${DEPENDS_AUR[*]}..."
        # Some normal output goes to stderr
        yay -Rsu "${DEPENDS_AUR[@]}" --noconfirm
    fi

    if [[ "${DEPENDS_PIP3[*]}" != "" ]]; then
        qecho "Uninstalling ${DEPENDS_PIP3[*]}..."
        sudo pip3 uninstall "${DEPENDS_PIP3[@]}"
    fi
}


if [[ "$#" -ne 1 ]]; then
    print_usage
    exit 1
fi

