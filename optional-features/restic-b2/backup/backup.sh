#!/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"

source "$BASE_DIR/constants.sh"
source "$BASE_DIR/utils.sh"



function check_ready() {
    local time

    # Check if another restic process is running
    if pgrep restic; then
        # If b2-clean is running, skip this backup
        if systemctl is-active --quiet b2-clean.service; then
            time="$(systemctl status b2-backup.timer \
                | grep Trigger: \
                | cut -d';' -f2 \
                | sed -e 's/ //' -e 's/ left//')"

            notify "Cannot begin backup. Cleaning in progress. Retrying in $time seconds"
            # TEMPFAIL exit code considered successful exit by systemd
            # This will restart the backup at its next normally scheduled time
            # instead of after RestartSec
            exit 75
        else
            notify "Cannot begin backup. There is another restic process active."
            exit 1
        fi
    elif is_locked; then
        notify "Cannot begin backup. There are stale locks. Please run restic unlock to continue."
        exit 1
    fi
}

function backup() {
    # Will return 1 if already exists
    restic init || true

    notify "Beginning B2 backup using restic"

    restic backup "$O_OPTIONS" \
        --exclude-file="$BASE_DIR/excludes.txt" \
        --files-from "$BASE_DIR/includes.txt"
}

function display_last_backup_stats() {
    local snapshot_ids last_id second_last_id last_diff files_stat size_stat
    local total_size_stat body

    mapfile -t snapshot_ids < <(restic snapshots -c "$O_OPTIONS" \
        | head -n-2 \
        | tail -n+3 \
        | cut -d' ' -f1)

    last_id="${snapshot_ids[-1]}"
    second_last_id="${snapshot_ids[-2]}"
    last_diff="$(restic diff "$last_id" "$second_last_id")"

    files_stat="$(echo "$last_diff" | grep '^Files:' | tr -s ' ')"
    size_stat="$(echo "$last_diff" \
        | grep -e 'Added: ' -e 'Removed: ' \
        | tr -s ' ' \
        | sed 's/ *//')"
    total_size_stat=$(restic stats "$last_id" "$O_OPTIONS" \
        | grep 'Total Size:' \
        | tr -s ' ' \
        | sed 's/ *//')

    body="Backup complete!"
    body="$body\n$files_stat\n$size_stat\n$total_size_stat"

    notify "$body"
}


# Send file descriptor to stdout
exec 5>&1

check_ready

backup

display_last_backup_stats

# Close file descriptor
exec 5>&-


source "$BASE_DIR/unset-constants.sh"
