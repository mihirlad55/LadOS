#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"
readonly OPTIONAL_FEATURES_DIR="$LAD_OS_DIR/optional-features"
readonly FEATURE_DIR="$OPTIONAL_FEATURES_DIR/win10-fonts"
readonly PKG_BUILD_DIR="$HOME/.cache/yay/ttf-ms-win10"
readonly BUILD_SH="$FEATURE_DIR/feature-build.sh"

readonly PKG_DIR="$1"


# Try to load fonts
"$BUILD_SH" check_conf && "$BUILD_SH" load_conf

"$BUILD_SH" prepare

# Copy compiled package to PKG_DIR
echo "Copying $PKG_BUILD_DIR*.pkg.tar.xz to $PKG_DIR..."
find "$PKG_BUILD_DIR" -name '*.pkg.tar.xz' -exec cp -f {} "$PKG_DIR" \;

"$BUILD_SH" cleanup
