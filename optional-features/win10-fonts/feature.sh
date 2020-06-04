#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"



if pacman -Si ttf-ms-win10 &> /dev/null; then
    # Use localrepo/cache
    source "$BASE_DIR/feature-pkg.sh"
else
    source "$BASE_DIR/feature-build.sh"
fi
