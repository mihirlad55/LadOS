#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"
FEATURE_DIR="$OPTIONAL_FEATURES_DIR/win10-fonts"
PKG_BUILD_DIR="$HOME/.cache/yay/ttf-ms-win10"

PKG_DIR="$1"

$FEATURE_DIR/feature-build.sh check_conf &&
    $FEATURE_DIR/feature-build.sh load_conf

$FEATURE_DIR/feature-build.sh prepare

echo "Copying $PKG_BUILD_DIR*.pkg.tar.xz to $PKG_DIR..."
find $PKG_BUILD_DIR -name '*.pkg.tar.xz' -exec cp -f {} "$PKG_DIR" \;

$FEATURE_DIR/feature-build.sh cleanup

echo "Done"

