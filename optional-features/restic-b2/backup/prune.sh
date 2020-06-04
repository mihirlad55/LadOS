#!/usr/bin/bash

BASE_PATH=$(dirname "$SCRIPT")

source "$BASE_PATH/constants.sh"

notify "Beginning prune of $B2_BUCKET"

restic prune

notify "Finished pruning $B2_BUCKET"

source "$BASE_PATH/unset-constants.sh"
