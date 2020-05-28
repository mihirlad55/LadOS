#!/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"

source "$BASE_DIR/constants.sh"
source "$BASE_DIR/utils.sh"

# Send /dev/fd/5 to stdout
exec 5>&1


function backup() {
    restic init

    notify "Beginning B2 backup using restic"

    restic backup "$O_OPTIONS" \
        --exclude-file="$BASE_DIR/excludes.txt" \
        --files-from "$BASE_DIR/includes.txt"
}

function display_last_backup_stats() {
    last_snapshot_id=$(restic snapshots "$O_OPTIONS" --json |
        grep -o -P '"short_id":"[A-Za-z0-9]*"' |
        tail -n 1 |
        cut -d':' -f2 |
        sed 's/"//g' |
        tee /dev/fd/5)

    backup_size=$(restic stats "$last_snapshot_id" "$O_OPTIONS" |
        grep -o "Total Size:.*$" |
        grep -o -P "[0-9]*\.[0-9]* [A-Za-z]{3}" |
        tee /dev/fd/5)

    notify "Backup complete! $backup_size of data was backed up. Now beginning backup check"
}

function backup_check() {
    check="$(restic check --check-unused --read-data --with-cache "$O_OPTIONS" |
        tee /dev/fd/5)"
    unused_blobs=$(echo "$check" |
        grep -c "unused blob")
    unreferenced_indexes=$(echo "$check" |
        grep -P -l "pack [0-9A-Za-z]{8}: not referenced in any index")
    res=$(echo "$check" | tail -n 1)

    notify "Backup check complete! $unused_blobs unused blobs. $unreferenced_indexes packs not referenced in any index $res"
}

function forget() {
    notify "Removing old snapshots. Forgetting snapshots and keeping only:
    - 24 hourly snapshots
    - 7 daily snapshots
    - 4 weekly snapshots
    - 12 monthly snapshots
    - 80 yearly snapshots"

    restic forget "$O_OPTIONS" \
        --keep-hourly 24 \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 12 \
        --keep-yearly 80

    notify "Finished removing old snapshots from B2"
}


backup

display_last_backup_stats

backup_check

forget


source "$BASE_DIR/unset-constants.sh"
