#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"

source "$BASE_DIR/constants.sh"
source "$BASE_DIR/utils.sh"


function display_last_backup_diff() {
    local snapshot_ids last_id second_last_id last_diff files_stat size_stat
    local total_size_stat body

    mapfile -t snapshot_ids < <(restic snapshots -c "$O_OPTIONS" \
        | head -n-2 \
        | tail -n+3 \
        | cut -d' ' -f1)

    last_id="${snapshot_ids[-1]}"
    second_last_id="${snapshot_ids[-2]}"
    restic diff "$second_last_id" "$last_id" | less
}


display_last_backup_diff


source "$BASE_DIR/unset-constants.sh"
