#!/usr/bin/bash

# Exit on error to avoid complications
set -o errtrace
set -o pipefail
trap error_trap ERR

function error_trap() {
    error_code="$?"
    last_command="$BASH_COMMAND"
    command_caller="$(caller)"
    
    echo "$command_caller: \"$last_command\" returned error code $error_code" >&2

    exit $error_code
}

readonly CONF_DIR="$LAD_OS_DIR/conf/install"
readonly REQUIRED_FEATURES_DIR="$LAD_OS_DIR/required-features"
readonly OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"
readonly LOCAL_REPO_PATH="$LAD_OS_DIR/localrepo"
readonly PKG_CACHE_DIR="$LOCAL_REPO_PATH/pkg"

# Set as readonly below
F_FLAGS=("--no-service-start")
VERBOSITY=
V_FLAG=("-q")


source "$LAD_OS_DIR/common/message.sh"

if [[ -f "$CONF_DIR/conf.sh" ]]; then source "$CONF_DIR/conf.sh";
else source "$CONF_DIR/conf.sh.sample"; fi
readonly CONF_NOCONFIRM CONF_VERBOSITY CONF_USE_WIFI CONF_WIFI_ADAPTER
readonly CONF_COUNTRY_CODE CONF_TIMEZONE_PATH CONF_LOCALE CONF_HOSTNAME
readonly CONF_EDIT_HOSTS CONF_ROOT_PASSWORD CONF_USERNAME CONF_PASSWORD
readonly CONF_INSTALL_OPTIONAL CONF_EXCLUDE_FEATURES

if [[ "$1" = "-v" ]] || [[ "$CONF_VERBOSITY" -eq 1 ]]; then
    VERBOSITY=1
    V_FLAG=()
elif [[ "$1" = "-vv" ]] || [[ "$CONF_VERBOSITY" -eq 2 ]]; then
    VERBOSITY=2
    V_FLAG=("-v")
fi

F_FLAGS=("${V_FLAG[@]}" "${F_FLAGS[@]}")
readonly VERBOSITY V_FLAG F_FLAGS



function vecho() {
    if [[ -n "$VERBOSE" ]]; then echo "$@"; fi
}
