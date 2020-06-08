#!/usr/bin/bash

# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo "$BASE_DIR" | grep -o ".*/LadOS/" | sed 's/.$//' )"
readonly INSTALL_DIR="$HOME/.local/share/systemd/user"
readonly TARGET_DIR="$HOME/.config/systemd/user/default.target.wants"
readonly BASE_SERVICE_DIR="$BASE_DIR/services"
readonly BASE_BATTERY_CHECK_SVC="$BASE_SERVICE_DIR/battery-check-notify.service"
readonly BASE_COMPTON_SVC="$BASE_SERVICE_DIR/compton.service"
readonly BASE_DUNST_SVC="$BASE_SERVICE_DIR/dunst.service"
readonly BASE_NITROGEN_DELAYED_SVC="$BASE_SERVICE_DIR/nitrogen-delayed.service"
readonly BASE_NITROGEN_SVC="$BASE_SERVICE_DIR/nitrogen.service"
readonly BASE_POLYBAR_SVC="$BASE_SERVICE_DIR/polybar.service"
readonly BASE_REDSHIFT_SVC="$BASE_SERVICE_DIR/redshift.service"
readonly BASE_UPDATE_NOTIFY_SVC="$BASE_SERVICE_DIR/update-notify.service"
readonly BASE_NOTIFY_TMR="$BASE_SERVICE_DIR/update-notify.timer"
readonly BASE_XAUTOLOCK_SVC="$BASE_SERVICE_DIR/xautolock.service"
readonly BASE_XBINDKEYS_SVC="$BASE_SERVICE_DIR/xbindkeys.service"
readonly BASE_STARTUP_SVC="$BASE_SERVICE_DIR/startup.service"
readonly BASE_SUCKLESS_NOTIFY_SVC="$BASE_SERVICE_DIR/suckless-notify.service"
readonly BASE_SUCKLESS_NOTIFY_TMR="$BASE_SERVICE_DIR/suckless-notify.timer"
readonly NEW_BATTERY_CHECK_SVC="$INSTALL_DIR/battery-check-notify.service"
readonly NEW_COMPTON_SVC="$INSTALL_DIR/compton.service"
readonly NEW_DUNST_SVC="$INSTALL_DIR/dunst.service"
readonly NEW_NITROGEN_DELAYED_SVC="$INSTALL_DIR/nitrogen-delayed.service"
readonly NEW_NITROGEN_SVC="$INSTALL_DIR/nitrogen.service"
readonly NEW_POLYBAR_SVC="$INSTALL_DIR/polybar.service"
readonly NEW_REDSHIFT_SVC="$INSTALL_DIR/redshift.service"
readonly NEW_UPDATE_NOTIFY_SVC="$INSTALL_DIR/update-notify.service"
readonly NEW_NOTIFY_TMR="$INSTALL_DIR/update-notify.timer"
readonly NEW_XAUTOLOCK_SVC="$INSTALL_DIR/xautolock.service"
readonly NEW_XBINDKEYS_SVC="$INSTALL_DIR/xbindkeys.service"
readonly NEW_STARTUP_SVC="$INSTALL_DIR/startup.service"
readonly NEW_SUCKLESS_NOTIFY_SVC="$INSTALL_DIR/suckless-notify.service"
readonly NEW_SUCKLESS_NOTIFY_TMR="$INSTALL_DIR/suckless-notify.timer"
readonly SYM_BATTERY_CHECK_SVC="$TARGET_DIR/battery-check-notify.service"
readonly SYM_COMPTON_SVC="$TARGET_DIR/compton.service"
readonly SYM_DUNST_SVC="$TARGET_DIR/dunst.service"
readonly SYM_NITROGEN_DELAYED_SVC="$TARGET_DIR/nitrogen-delayed.service"
readonly SYM_NITROGEN_SVC="$TARGET_DIR/nitrogen.service"
readonly SYM_POLYBAR_SVC="$TARGET_DIR/polybar.service"
readonly SYM_REDSHIFT_SVC="$TARGET_DIR/redshift.service"
readonly SYM_UPDATE_NOTIFY_SVC="$TARGET_DIR/update-notify.service"
readonly SYM_NOTIFY_TMR="$TARGET_DIR/update-notify.timer"
readonly SYM_XAUTOLOCK_SVC="$TARGET_DIR/xautolock.service"
readonly SYM_XBINDKEYS_SVC="$TARGET_DIR/xbindkeys.service"
readonly SYM_STARTUP_SVC="$TARGET_DIR/startup.service"
readonly SYM_SUCKLESS_NOTIFY_TMR="$TARGET_DIR/suckless-notify.timer"
readonly MOD_LOGIND_CONF="/etc/systemd/logind.conf"

source "$LAD_OS_DIR/common/feature_header.sh"

readonly FEATURE_NAME="user-services"
readonly FEATURE_DESC="Install custom user-services for applications"
readonly PROVIDES=()
readonly NEW_FILES=( \
    "$NEW_BATTERY_CHECK_SVC" \
    "$NEW_COMPTON_SVC" \
    "$NEW_DUNST_SVC" \
    "$NEW_NITROGEN_DELAYED_SVC" \
    "$NEW_NITROGEN_SVC" \
    "$NEW_POLYBAR_SVC" \
    "$NEW_REDSHIFT_SVC" \
    "$NEW_UPDATE_NOTIFY_SVC" \
    "$NEW_NOTIFY_TMR" \
    "$NEW_XAUTOLOCK_SVC" \
    "$NEW_XBINDKEYS_SVC" \
    "$NEW_STARTUP_SVC" \
    "$NEW_SUCKLESS_NOTIFY_SVC" \
    "$NEW_SUCKLESS_NOTIFY_TMR" \
    "$SYM_BATTERY_CHECK_SVC" \
    "$SYM_COMPTON_SVC" \
    "$SYM_DUNST_SVC" \
    "$SYM_NITROGEN_DELAYED_SVC" \
    "$SYM_NITROGEN_SVC" \
    "$SYM_POLYBAR_SVC" \
    "$SYM_REDSHIFT_SVC" \
    "$SYM_UPDATE_NOTIFY_SVC" \
    "$SYM_NOTIFY_TMR" \
    "$SYM_XAUTOLOCK_SVC" \
    "$SYM_XBINDKEYS_SVC" \
    "$SYM_STARTUP_SVC" \
    "$SYM_SUCKLESS_NOTIFY_TMR" \
)
readonly MODIFIED_FILES=("$MOD_LOGIND_CONF")
readonly TEMP_FILES=()
readonly DEPENDS_AUR=()
readonly DEPENDS_PACMAN=()



function check_install() {
    local f

    for f in "${NEW_FILES[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "$f is missing" >&2
            echo "$FEATURE_NAME is not installed" >&2
            return 1
        fi
    done

    if ! grep -q "$MOD_LOGIND_CONF" -e "^KillUserProcesses=yes$"; then
        echo "KillUserProcesses=yes not in $MOD_LOGIND_CONF" >&2
        echo "$FEATURE_NAME is not installed" >&2
        return 1
    fi

    qecho "$FEATURE_NAME is installed"
    return 0
}

function install() {
    mkdir -p "$INSTALL_DIR"

    qecho "Copying service files..."
    command install -m 644 \
        "$BASE_SERVICE_DIR/battery-check-notify.service" \
        "$BASE_SERVICE_DIR/compton.service" \
        "$BASE_SERVICE_DIR/dunst.service" \
        "$BASE_SERVICE_DIR/nitrogen-delayed.service" \
        "$BASE_SERVICE_DIR/nitrogen.service" \
        "$BASE_SERVICE_DIR/polybar.service" \
        "$BASE_SERVICE_DIR/redshift.service" \
        "$BASE_SERVICE_DIR/update-notify.service" \
        "$BASE_SERVICE_DIR/update-notify.timer" \
        "$BASE_SERVICE_DIR/xautolock.service" \
        "$BASE_SERVICE_DIR/xbindkeys.service" \
        "$BASE_SERVICE_DIR/startup.service" \
        "$BASE_SERVICE_DIR/suckless-notify.service" \
        "$BASE_SERVICE_DIR/suckless-notify.timer" \
        "$INSTALL_DIR"

    qecho "Editing logind.conf to kill user processes on logout..."
    sudo sed -i "$MOD_LOGIND_CONF" \
        -e "s/[# ]*KillUserProcesses=.*$/KillUserProcesses=yes/"
}

function post_install() {
    qecho "Enabling services..."
    mkdir -p "$TARGET_DIR"

    ln -sft "$TARGET_DIR" \
        "$INSTALL_DIR/compton.service" \
        "$INSTALL_DIR/dunst.service" \
        "$INSTALL_DIR/nitrogen-delayed.service" \
        "$INSTALL_DIR/nitrogen.service" \
        "$INSTALL_DIR/polybar.service" \
        "$INSTALL_DIR/redshift.service" \
        "$INSTALL_DIR/battery-check-notify.service" \
        "$INSTALL_DIR/update-notify.service" \
        "$INSTALL_DIR/update-notify.timer" \
        "$INSTALL_DIR/xautolock.service" \
        "$INSTALL_DIR/xbindkeys.service" \
        "$INSTALL_DIR/startup.service" \
        "$INSTALL_DIR/suckless-notify.timer" \
        "/usr/lib/systemd/user/insync.service" \
        "/usr/lib/systemd/user/spotify-listener.service"
    
    qecho "Done"
}

function uninstall() {
    qecho "Disabling and removing services..."
    vecho "Removing ${NEW_FILES[*]}..."
    rm -f "${NEW_FILES[@]}"
}


source "$LAD_OS_DIR/common/feature_footer.sh"
