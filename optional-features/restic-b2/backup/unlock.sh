#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"

source "$BASE_DIR/constants.sh"

restic unlock

source "$BASE_DIR/unset-constants.sh"


