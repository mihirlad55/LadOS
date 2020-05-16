#!/usr/bin/bash

set -o errtrace
set -o pipefail
trap error_trap ERR


CONF_DIR="$LAD_OS_DIR/conf/install"
REQUIRED_FEATURES_DIR="$LAD_OS_DIR/required-features"
OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"
LOCAL_REPO_PATH="$LAD_OS_DIR/localrepo"
PKG_CACHE_DIR="$LOCAL_REPO_PATH/pkg"

VERBOSITY=
VERBOSITY_FLAG="-q"


source "$LAD_OS_DIR/common/message.sh"
if [[ -f "$CONF_DIR/conf.sh" ]]; then source "$CONF_DIR/conf.sh";
else source "$CONF_DIR/conf.sh.sample"; fi

if [[ "$1" = "-v" ]] || [[ "$CONF_VERBOSITY" -eq 1 ]]; then
    VERBOSITY=1
    VERBOSITY_FLAG=""
elif [[ "$1" = "-vv" ]] || [[ "$CONF_VERBOSITY" -eq 2 ]]; then
    VERBOSITY=2
    VERBOSITY_FLAG="-v"
fi


function error_trap() {
    error_code="$?"
    last_command="$BASH_COMMAND"
    command_caller="$(caller)"
    
    echo "$command_caller: \"$last_command\" returned error code $error_code" >&2

    exit $error_code
}

function vecho() {
    if [[ -n "$VERBOSE" ]]; then echo "$@"; fi
}
