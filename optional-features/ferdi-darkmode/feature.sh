#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly RECIPES_DIR="$HOME/.config/Ferdi/recipes"
readonly BASE_CAL_PATCH="$BASE_DIR/googlecalendar-webview.patch"
readonly TMP_MSGR_DIR="/tmp/DarkNight-FBMessenger"
readonly TMP_CAL_DIR="/tmp/Dark_Google_Calendar"
readonly TMP_WHATSAPP_DIR="/tmp/dark-whatsapp"
readonly TMP_TRELLO_CSS="/tmp/trello-darkmode.css"
readonly NEW_CAL_CSS="$RECIPES_DIR/googlecalendar/darkmode.css"
readonly NEW_CAL_LICENSE="$RECIPES_DIR/googlecalendar/LICENSE"
readonly NEW_MSGR_CSS="$RECIPES_DIR/messenger/darkmode.css"
readonly NEW_MSGR_LICENSE="$RECIPES_DIR/messenger/LICENSE"
readonly NEW_WHATSAPP_CSS="$RECIPES_DIR/whatsapp/darkmode.css"
readonly NEW_WHATSAPP_LICENSE="$RECIPES_DIR/whatsapp/LICENSE"
readonly NEW_TRELLO_CSS="$RECIPES_DIR/trello/darkmode.css"
readonly NEW_TRELLO_LICENSE="$RECIPES_DIR/trello/LICENSE"
readonly MOD_CAL_WEBVIEW="$RECIPES_DIR/googlecalendar/webview.js"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="Ferdi Dark Mode Themes"
readonly FEATURE_DESC="Install Dark Mode Themes for Google Calendar, Facebook \
Messenger, WhatsApp, and Trello"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_CAL_CSS" \
    "$NEW_CAL_LICENSE" \
    "$NEW_MSGR_CSS" \
    "$NEW_MSGR_LICENSE" \
    "$NEW_WHATSAPP_CSS" \
    "$NEW_WHATSAPP_LICENSE" \
    "$NEW_TRELLO_CSS" \
)
readonly MODIFIED_FILES=("$MOD_CAL_WEBVIEW")
readonly TEMP_FILES=( \
    "$TMP_MSGR_DIR" \
    "$TMP_CAL_DIR" \
    "$TMP_WHATSAPP_DIR" \
    "$TMP_TRELLO_CSS" \
)
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()
readonly DEPENDS_PIP3=()

readonly MSGR_GIT_URL="https://github.com/cicerakes/DarkNight-FBMessenger"
readonly CAL_GIT_URL="https://github.com/pyxelr/Dark_Google_Calendar"
readonly WHATSAPP_GIT_URL="https://github.com/vednoc/dark-whatsapp"
readonly TRELLO_CSS_URL="https://userstyles.org/api/v1/styles/css/179512"



function is_patch_applied() {
    local file patch

    file="$1"
    patch="$2"

    if patch -R -p0 -s -f --dry-run "$file" < "$patch" ; then
        vecho "$patch applied to $file"
        return 0
    else
        vecho "$patch not applied to $file"
        return 1
    fi
}

# @-moz-document causes darkmode styles to not be loaded. This replaces those
# at-rules with an @media screen which will always be true.
function replace_moz_document() {
    local file

    file="$1"

    sed -i "$file" -e 's/\@-moz-document.*{/\@media screen {/'
}

function check_install() {
    local f

    for f in "${NEW_FILES[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    if ! is_patch_applied "$MOD_CAL_WEBVIEW" "$BASE_CAL_PATCH"; then
        echo "$BASE_CAL_PATCH did not apply correctly"
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi

    qecho "$FEATURE_NAME is installed"
    return 0
}

function prepare() {
    local new_css

    if [[ ! -d "$TMP_MSGR_DIR" ]]; then
        qecho "Cloning Facebook Messenger theme..."
        git clone "${GIT_FLAGS[@]}" "$MSGR_GIT_URL" "$TMP_MSGR_DIR"
    fi

    if [[ ! -d "$TMP_CAL_DIR" ]]; then
        qecho "Cloning Google Calendar theme..."
        git clone "${GIT_FLAGS[@]}" "$CAL_GIT_URL" "$TMP_CAL_DIR"
    fi

    if [[ ! -d "$TMP_WHATSAPP_DIR" ]]; then
        qecho "Cloning WhatsApp theme..."
        git clone "${GIT_FLAGS[@]}" "$WHATSAPP_GIT_URL" "$TMP_WHATSAPP_DIR"
    fi

    if [[ ! -f "$TMP_TRELLO_CSS" ]]; then
        qecho "Downloading Trello CSS theme..."
        curl "${S_FLAG[@]}" "$TRELLO_CSS_URL" --output "$TMP_TRELLO_CSS"

        qecho "Extracting and unescaping trello css..."
        # Extract css content
        sed -i "$TMP_TRELLO_CSS" -e 's/{"css":"//' -e 's/"}$//'
        # Remove carridge returns
        sed -i "$TMP_TRELLO_CSS" -e 's/\\r//g'
        # Convert \" to "
        sed -i "$TMP_TRELLO_CSS" -e 's/\\"/"/g'
        # Convert \n to new lines and parse unicode sequences
        new_css="$(echo -en "$(cat "$TMP_TRELLO_CSS")")"
        echo "$new_css" > "$TMP_TRELLO_CSS"
    fi

    qecho "Replacing @-moz-document rules with @media screen in css files..."
    replace_moz_document "$TMP_MSGR_DIR/DarkNightFBM.user.css"
    replace_moz_document "$TMP_CAL_DIR/Google-DarkCalendar.user.css"
    replace_moz_document "$TMP_WHATSAPP_DIR/wa.user.css"
    replace_moz_document "$TMP_TRELLO_CSS"
}

function install() {
    qecho "Installing Facebook Messenger theme..."
    command install -Dm 644 "$TMP_MSGR_DIR/DarkNightFBM.user.css" \
        "$NEW_MSGR_CSS"
    command install -Dm 644 "$TMP_MSGR_DIR/LICENSE" "$NEW_MSGR_LICENSE"

    qecho "Installing Google Calendar theme..."
    command install -Dm 644 "$TMP_CAL_DIR/Google-DarkCalendar.user.css" \
        "$NEW_CAL_CSS"
    command install -Dm 644 "$TMP_CAL_DIR/LICENSE" "$NEW_CAL_LICENSE"
    
    if ! is_patch_applied "$MOD_CAL_WEBVIEW" "$BASE_CAL_PATCH"; then
        qecho "Patching $MOD_CAL_WEBVIEW..."
        patch -N -f "${S_FLAG[@]}" "$MOD_CAL_WEBVIEW" "$BASE_CAL_PATCH"
    else
        qecho "$MOD_CAL_WEBVIEW already patched"
    fi

    qecho "Installing WhatsApp theme..."
    command install -Dm 644 "$TMP_WHATSAPP_DIR/wa.user.css" \
        "$NEW_WHATSAPP_CSS"
    command install -Dm 644 "$TMP_WHATSAPP_DIR/license" "$NEW_WHATSAPP_LICENSE"

    qecho "Installing Trello theme..."
    command install -Dm 644 "$TMP_TRELLO_CSS" "$NEW_TRELLO_CSS"
}

function cleanup() {
    qecho "Removing ${TEMP_FILES[@]}..."
    rm -rf "${TEMP_FILES[@]}"
}

function uninstall() {
    qecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"

    qecho "Unpatching $MOD_CAL_WEBVIEW..."
    patch "${S_FLAG[@]}" -R "$MOD_CAL_WEBVIEW" "$BASE_CAL_PATCH"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
