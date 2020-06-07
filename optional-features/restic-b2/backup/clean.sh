#!/usr/bin/bash

readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"

source "$BASE_DIR/constants.sh"
source "$BASE_DIR/utils.sh"


function check_ready() {
    local time sub_state

    # Check if another restic process is currently running
    if pgrep restic; then
        # If backup is in progress, fail the service and wait RestartSec if
        # restarting, otherwise fail until next timer activation
        if systemctl is-active --quiet b2-clean.service; then
            time="$(systemctl show b2-clean.service \
                --property RestartUSec --value)"
            sub_state="$(systemctl show b2-clean.service \
                --property SubState --value)"

            if [[ "$sub_state" == "auto-restart" ]]; then
                notify "Cannot begin cleaning. Backup in progress. Retrying in $time."
            else
                notify "Cannot begin cleaning. Backup in progress. Will not retry."
            fi
            exit 1
        else
            notify "Cannot begin backup. There is another restic process active."
            exit 1
        fi
    elif is_locked; then
        notify "Cannot begin backup. There are stale locks. Please run restic unlock to continue."
        exit 1
    fi
}

function backup_check() {
    local check unused_blobs unreferenced_indices res body
    local CHECK_ARGS
    CHECK_ARGS=("--check-unused" "--read-data" "--with-cache" "$O_OPTIONS")
    readonly CHECK_ARGS

    notify "Beginning backup check"

    # Unused blobs and unreferenced indices will cause restic check to return 1
    # This must be an in if statement to avoid triggering the error trap
    if check="$(restic check "${CHECK_ARGS[@]}" | tee >(cat - >&5))"; then
        notify "Backup check complete!\nNo errors found"        
    else
        unused_blobs=$(echo "$check" | grep -c "unused blob")
        unreferenced_indices=$(echo "$check" \
            | grep -P -c "pack [0-9A-Za-z]{8}: not referenced in any index")

        body="Backup check complete!\n"
        body="$body $unused_blobs unused blobs.\n"
        body="$body $unreferenced_indices packs not referenced in any index"

        notify "$body"
    fi
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

function prune() {
    notify "Beginning prune of $B2_BUCKET"

    restic prune

    notify "Finished pruning $B2_BUCKET. Finished cleaning backup."
}


# Send file descriptor to stdout
exec 5>&1

check_ready

backup_check

forget

prune

# Close file descriptor
exec 5>&-


source "$BASE_DIR/unset-constants.sh"
