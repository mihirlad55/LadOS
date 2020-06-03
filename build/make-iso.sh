#!/usr/bin/bash
 
# Catch errors
set -o errtrace
set -o pipefail
trap error_trap ERR

# Keep at top so any errors after this can be caught
function error_trap() {
    error_code="$?"
    error "$(caller): \"$BASH_COMMAND\" returned error code $error_code"
    exit $error_code
}


# Get absolute path to directory of script
readonly BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
readonly LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

readonly ISO_NAME="LadOS"
readonly ISO_PUBLISHER="Mihir Lad <https://mihirlad.com>"
readonly ISO_APPLICATION="LadOS Linux Live CD"
readonly ISO_OUT_DIR="$BASE_DIR"

# These flags are marked as readonly after being finalized at the bottom
VERBOSE=
GIT_FLAGS=("--depth" "1")
V_FLAG=()
Q_FLAG=("-q")

# Contains screen printing functions
source "$LAD_OS_DIR/common/message.sh"



function print_usage() {
    echo "usage: ${0} <mode> [options]"
    echo
    echo "  Modes:"
    echo "   interactive                 Start interactive mode. This mode uses"
    echo "                               no options."
    echo
    echo "   build                       Build LadOS iso from scratch. This"
    echo "                               mode accepts the options"
    echo "                               --create-localrepo, --ms-ttf-win10,"
    echo "                               --dev, --sb-key-path, --sb-crt-path."
    echo
    echo "   remaster                    Remaster archiso and add LadOS. This"
    echo "                               mode accepts the options"
    echo "                               --create-localrepo, --ms-ttf-win10,"
    echo "                               --dev, --archiso-path,"
    echo "                               --auto-download-iso, --sb-key-path,"
    echo "                               --sb-crt-path."
    echo
    echo "   image <dev>                 Image device with existing image. This"
    echo "                               mode requires the device as an"
    echo "                               argument."
    echo
    echo "   make_recovery               Build recovery mode and copy it to"
    echo "                               conf/recovery-mode/recovery."
    echo
    echo "   help                        Display this message and exit"
    echo
    echo "  Options:"
    echo "   -a  --auto-download-iso     Automatically download latest archiso"
    echo "   -c, --sb-crt-path           Path to certificate file for secure"
    echo "                               boot"
    echo "   -d, --dev <dev>             Image <dev> with archiso image at end"
    echo "   -i, --archiso-path          Path to existing archiso to remaster"
    echo "   -k, --sb-key-path           Path to private key file to sign EFIs"
    echo "                               with for secure boot"
    echo "   -l, --create-localrepo      Include offline package repo in iso"
    echo "   -m, --ms-ttf-win10          Build and and include ms-ttf-win10"
    echo "                               package"
    echo "   -v                          Verbose level 1"
    echo "   -vv                         Verbose level 2"
    echo "   -vvv                        Verbose level 3"
    
}

# Only prompt if interactive mode
function iprompt() {
    if [[ "$CMD" = "interactive" ]]; then
        if prompt "$@"; then
            return 0
        fi
    fi

    return 1
}

function vecho() {
    if [[ -n "$VERBOSE" ]]; then echo "$@"; fi
}

################################################################################
# Display menu to user with title and options
#   Globals:
#     None
#   Arguments:
#     title, Title of menu
#     <option name> <option_function>... Unlimited pairs of option names and
#     functions to call when corresponding option is selected. Each option name
#     and function are separate arguments, but must be provided in pairs.
#   Outputs:
#     Prompts user with list of options
#   Returns:
#     0 if successful
################################################################################
function show_menu() {
    local option num_of_options i name name_idx func_idx

    # Print title and shift title out of arguments list
    title="-----$1-----"
    shift

    option=0
    # Option names and thier functions come in pairs
    num_of_options=$(( $# / 2 ))

    while true; do
        i=1

        echo "$title"

        # Print every option
        while (( i <= num_of_options )); do
            # Name of option is the first argument of every pair
            name_idx="$(( i * 2 - 1 ))"
            name="${!name_idx}"

            echo "$i. $name"

            i=$(( i + 1 ))
        done

        read -rp "Option: " option

        # If input is invalid re-print menu
        if echo "$option" | grep -q -P "^[0-9]+$"; then
            if (( option > num_of_options )); then
                continue
            fi
        else
            continue
        fi

        # Call function associated with option (2nd argument in pair)
        func_idx=$(( option * 2 ))
        "${!func_idx}"
    done
}

function is_arch_user() {
    pacman -V > /dev/null
}

# Make recovery for recovery-mode feature
# Used for make recovery menu function
function _make_recovery() {
    make_recovery "$LAD_OS_DIR/conf/recovery-mode"
    exit 0
}

################################################################################
# Make boot directory with squashed recovery mode
#   Globals:
#     BASE_DIR
#   Arguments:
#     install_dir, Directory to copy recovery directory into
#   Outputs:
#     Prints info about progress to user
#   Returns:
#     0 if successful
################################################################################
function make_recovery() {
    local RECOVERY_DIR AIROOTFS_DIR
    local install_dir

    RECOVERY_DIR="/var/tmp/recovery"
    AIROOTFS_DIR="$RECOVERY_DIR/airootfs"
    install_dir="$1"

    readonly RECOVERY_DIR AIROOTFS_DIR

    msg "Making recovery..."

    if [[ -d "$RECOVERY_DIR" ]]; then
        msg2 "Cleaning up old mounts from $RECOVERY_DIR..."
        sudo find "$RECOVERY_DIR" -type d -exec mountpoint -q {} \; \
            -exec umount {} \;
    fi

    msg2 "Copying recovery config to $RECOVERY_DIR..."
    sudo cp -afT "$BASE_DIR/recovery" "$RECOVERY_DIR"

    # Avoid permission errors
    msg2 "Setting root as owner of $RECOVERY_DIR..."
    sudo chown -R root:root "$RECOVERY_DIR"

    msg2 "Building recovery..."
    ( cd "$RECOVERY_DIR" && sudo ./build.sh )

    msg2 "Copying recovery to $install_dir..."
    sudo cp -rft "$install_dir" "$RECOVERY_DIR/work/iso/recovery"
}

################################################################################
# Image device with ISO
#   Globals:
#     None
#   Arguments:
#     iso_path, path to ISO file
#     dev, path to device (i.e. /dev/sdX)
#   Outputs:
#     Prints dd progress
#   Returns:
#     0 if successful, error code of dd otherwise
################################################################################
function image_dev() {
    local iso_path dev

    iso_path="$1"
    dev="$2"

    sudo dd bs=4M if="$iso_path" of="$dev" status=progress oflag=sync
}

################################################################################
# Build ttf-ms-win10 AUR package to be included in localrepo. This can be used
# as an alternative method of installing the win10-fonts feature, so that the
# package does not have to be compiled during the install. This package requires
# windows 10 fonts to be present in win10-fonts conf folder.
#   Globals:
#     None
#   Arguments:
#     PKG_DIR, path to directory to save compiled ttf-ms-win10 package
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful
################################################################################
function build_win10_fonts() {
    local TMP_DIR FONTS_DIR BUILD_SH PKG_DIR

    TMP_DIR="/var/tmp"
    FONTS_DIR="$TMP_DIR/win10-fonts"
    BUILD_SH="$BASE_DIR/misc/build-ttf-ms-win10.sh"
    PKG_DIR="$1"

    readonly TMP_DIR FONTS_DIR BUILD_SH PKG_DIR

    if ! find "$PKG_DIR" -name "*ttf-ms-win10*" | grep -q '.'; then
        msg3 "ttf-ms-win10 not found in $PKG_DIR"

        msg3 "Building ttf-ms-win10..."
        mkdir -p "$FONTS_DIR"
        "$BUILD_SH" "${Q_FLAG[@]}" "${V_FLAG[@]}" "$FONTS_DIR"

        msg3 "Moving files to $PKG_DIR..."
        sudo mv -f "$FONTS_DIR"/* "$PKG_DIR"

        msg3 "Removing temp files..."
        rm -rf "$FONTS_DIR"
    else
        msg3 "ttf-ms-win10 package already found in $PKG_DIR"
        msg3 "Not going to rebuild tff-ms-win10"
    fi
}

################################################################################
# Build AUR packages from packages.csv to be included in ISO, so these packages
# don't have to be compiled during the install.
#   Globals:
#     LAD_OS_DIR
#     GIT_FLAGS
#   Arguments:
#     PKG_DIR, path to directory to save compiled AUR packages
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful
################################################################################
function build_aur_packages() {
    local AUR_URL PKG_DIR TMP_DIR
    local aur_packages pkg_name pkg_dir pkg_url

    AUR_URL="https://aur.archlinux.org"
    TMP_DIR="/var/tmp"
    PKG_DIR="$1"

    readonly AUR_URL PKG_DIR TMP_DIR

    # Get list of AUR packages from packages.csv
    mapfile -t aur_packages < <(grep "^.*,.*,aur," "$LAD_OS_DIR/packages.csv")

    for pkg in "${aur_packages[@]}"; do
        pkg_name="$( echo "$pkg" | cut -d',' -f1 )"
        pkg_dir="$TMP_DIR/$pkg_name"
        pkg_url="$AUR_URL/$pkg_name.git"

        msg3 "$pkg_name"

        # Clone if not already done
        if [[ ! -d "$pkg_dir" ]]; then
            git clone "${GIT_FLAGS[@]}" "$pkg_url" "$pkg_dir"
        fi

        # Source PKGBUILD to build beginning of package file name
        (
            source "/var/tmp/$pkg_name/PKGBUILD"
            
            if [[ "$epoch" != "" ]]; then
                tar_name_prefix="$pkg_name-$epoch:"
            else
                tar_name_prefix="$pkg_name-"
            fi

            if ! type pkgver &> /dev/null; then
                # pkgver is variable
                tar_name_prefix="${tar_name_prefix}${pkgver}"
            fi

            # Look for packages with this prefix
            tar_path="$(find "$PKG_DIR" -iname "$tar_name_prefix*.pkg.tar.xz")"

            # Build package if not found already in localrepo
            if [[ "$tar_path" == "" ]]; then
                msg4 "Building $pkg_name..."

                cd "$pkg_dir"
                makepkg -s --noconfirm --nocolor
                sudo cp -f ./*.pkg.tar.xz "$PKG_DIR"
            else
                msg4 "$pkg_name already exists"
            fi
        )

        rm -rf "$pkg_dir"
    done
}

################################################################################
# Copy pacman packages from packages.csv to $PKG_DIR. Copy any packages found in
# host pacman cache to $PKG_DIR. Download any packages not found in cache and
# copy them to $PKG_DIR. Also include any packages.x86_64 from archiso root
# directory if found. Add localrepo include directive to specified pacman.conf
#   Globals:
#     LAD_OS_DIR
#   Arguments:
#     PKG_DIR, path to directory to save compiled AUR packages
#     ARCH_ISO_DIR, path to archiso root directory
#     PACMAN_CONF, path to pacman conf to add localrepo include directive
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful
################################################################################
function copy_pacman_packages() {
    local PKG_DIR ARCH_ISO_DIR PACMAN_CONF TMP_DB_DIR pacman_packages
    local ARCH_ISO_PACKAGE_LIST
    local pkg target_paths target_path target

    PKG_DIR="$1"
    ARCH_ISO_DIR="$2"
    PACMAN_CONF="$3"
    TMP_DB_DIR="/tmp"
    ARCH_ISO_PACKAGE_LIST="$ARCH_ISO_DIR/packages.x86_64"
    
    # Get names of pacman packages from packages.csv
    mapfile -t pacman_packages < <(cat "$LAD_OS_DIR/packages.csv" | \
        grep "^.*,.*,system," | \
        cut -d ',' -f1)

    readonly PKG_DIR ARCH_ISO_DIR PACMAN_CONF TMP_DB_DIR ARCH_ISO_PACKAGE_LIST

    # Sync pacman and upgrade system
    sudo pacman -Syu --noconfirm

    # Include packages.x86_64 if found
    if [[ -f "$ARCH_ISO_PACKAGE_LIST" ]]; then
        msg3 "Found package list at $ARCH_ISO_PACKAGE_LIST..."
        mapfile -t arch_iso_packages < "$ARCH_ISO_PACKAGE_LIST"

        # Add packages from archiso
        pacman_packages=("${pacman_packages[@]}" "${arch_iso_packages[@]}")
    fi

    for pkg in ${pacman_packages[@]}; do
        msg3 "$pkg"

        # Get list of targets to package
        mapfile -t target_paths < <(pacman -Spdd $pkg)

        # If $pkg is a group i.e. base-devel, there will be multiple paths
        for target_path in "${target_paths[@]}"; do 
            # If target begins with file://, package can be found in cache
            if [[ "$target_path" =~ file://** ]]; then
                target="${target_path##file://**/}"
                target_path="${target_path#file://}"

                # If package is not found in localrepo, copy package from cache
                if [[ ! -f "$PKG_DIR/$target" ]]; then
                    msg4 "Copying $target from cache to the archiso"
                    vecho "Copying from $target_path to $PKG_DIR..."
                    sudo cp -f "$target_path" "$PKG_DIR"
                else
                    msg4 "$target is already in localrepo"
                fi
            else
                # Package is not in cache
                target="${target_path##https://**/}"
                msg4 "$target not found in host pacman cache"
            fi
        done
    done

    # Create a temporary pacman database
    sudo pacman -Sy --noconfirm --dbpath "$TMP_DB_DIR"

    # Use temporary pacman database to download missing packages in $PKG_DIR
    msg3 "Downloading missing packages..."
    sudo pacman -S ${pacman_packages[@]} \
        -w --cachedir "$PKG_DIR" \
        --dbpath "$TMP_DB_DIR" \
        --noconfirm --needed

    # Add localrepo include directive in pacman.conf, so archiso build can use
    # the localrepo package cache
	if ! grep -q "$PACMAN_CONF" -e "LadOS"; then
        msg3 "Adding localrepo to pacman.conf"
	    sudo sed -i "$PACMAN_CONF" \
            -e '1 i\Include = /LadOS/install/localrepo.conf'
    fi
}

################################################################################
# Add kernel commandline parameter to all systemd-boot entries to increase
# scrollback buffer.
#   Globals:
#     None
#   Arguments:
#     ENTRIES_DIR, path to systemd-boot boot entries directory
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful
################################################################################
function increase_tty_scrollback() {
    local ENTRIES_DIR OPTION

    ENTRIES_DIR="$1"
    OPTION="fbcon=scrollback:1024k"

    readonly ENTRIES_DIR OPTION

    if ! grep -q -F "$OPTION" $ENTRIES_DIR/*; then
        msg2 "Adding $OPTION kernel parameter"
        sudo sed -i $ENTRIES_DIR/* -e "s/^options.*$/& $OPTION/"
    fi
}

################################################################################
# Create a local pacman repo with a package cache which can be used during the
# LadOS install, so packages don't have to be compiled or downloaded during the
# install
#   Globals:
#     Q_FLAG
#   Arguments:
#     AIROOTFS_DIR, path to airootfs directory in archiso
#     PACMAN_CONF, path to pacman conf in archiso
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful
################################################################################
function create_localrepo() {
    local AIROOTFS_DIR PACMAN_CONF LOCAL_REPO_DIR PKG_DIR

    AIROOTFS_DIR="$1"
    PACMAN_CONF="$2"
    LOCAL_REPO_DIR="$AIROOTFS_DIR/LadOS/localrepo"
    PKG_DIR="$LOCAL_REPO_DIR/pkg"

    readonly AIROOTFS_DIR PACMAN_CONF LOCAL_REPO_DIR PKG_DIR

    # Install pacman-contrib to use paccache
    sudo pacman -S pacman-contrib --needed --noconfirm

    sudo mkdir -p "$PKG_DIR"

    msg2 "Building AUR packages..."
    build_aur_packages "$PKG_DIR"

    if [[ -n "$BUILD_TTF_MS_WIN_10" ]] || iprompt "Build ttf-ms-win10?"; then
        msg2 "Building windows 10 fonts..."
        build_win10_fonts "$PKG_DIR"
    fi

    msg2 "Copying pacman packages..."
    copy_pacman_packages "$PKG_DIR" "$ARCH_ISO_DIR" "$PACMAN_CONF"

    msg2 "Removing older packages..."
    sudo paccache --nocolor -rk1 -c "$PKG_DIR"

    msg2 "Adding all packages to localrepo database..."
    # If all packages are already present, repo-add returns 1
    (cd "$LOCAL_REPO_DIR" && sudo repo-add "${Q_FLAG[@]}" -n -R -p --nocolor \
        localrepo.db.tar.gz pkg/*) || true
}

################################################################################
# The main function for the build from scratch method of building the archiso.
#   Globals:
#     BASE_DIR
#     LAD_OS_DIR
#     SB_KEY_PATH
#     SB_CRT_PATH
#     ISO_NAME
#     ISO_PUBLISHER
#     ISO_APPLICATION
#     Q_FLAG
#     DEV
#   Arguments:
#     None
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful, 1 otherwise
################################################################################
function build_from_scratch() {
    local ARCH_ISO_DIR AIROOTFS_DIR RECOVERY_DIR BOOT_ENTRIES_DIR PACMAN_CONF
    local sb_key_path sb_crt_path res out dev

    ARCH_ISO_DIR="/var/tmp/archiso"
    AIROOTFS_DIR="$ARCH_ISO_DIR/airootfs"
    RECOVERY_DIR="$AIROOTFS_DIR/LadOS/conf/recovery-mode/"
    BOOT_ENTRIES_DIR="$ARCH_ISO_DIR/efiboot/loader/entries/"
    PACMAN_CONF="$ARCH_ISO_DIR/pacman.conf"

    readonly ARCH_ISO_DIR AIROOTFS_DIR RECOVERY_DIR BOOT_ENTRIES_DIR PACMAN_CONF

    msg "Removing old ISOs..."
    rm -f $BASE_DIR/*.iso
    
    if [[ -d "$ARCH_ISO_DIR" ]]; then
        msg "Cleaning up old mounts from $ARCH_ISO_DIR..."
        sudo find "$ARCH_ISO_DIR" -type d -exec mountpoint -q {} \; \
            -exec umount {} \;
        
        msg "Cleaning up work directory..."
        sudo rm -rf "$ARCH_ISO_DIR/work"
    fi

    if ! pacman -Q archiso-git &> /dev/null; then
        msg "Installing archiso-git..."
        sudo pacman -R archiso --noconfirm
        yay -S archiso-git --noconfirm --needed --mflags -m
    fi

    msg "Copying archiso config to $ARCH_ISO_DIR..."
    sudo cp -afT "$BASE_DIR/archiso" "$ARCH_ISO_DIR"

    msg "Copying LadOS to $AIROOTFS_DIR..."
    sudo cp -rft "$AIROOTFS_DIR" "$LAD_OS_DIR"

    if [[ -n "$CREATE_LOCAL_REPO" ]] || iprompt "Create local package repo?"; then
        msg "Creating localrepo..."
        create_localrepo "$AIROOTFS_DIR" "$PACMAN_CONF"
    fi

    if iprompt "Sign the EFI binaries with keys for secure boot?"; then
        sb_key_path="$(ask "Enter path to the private key")"
        sb_crt_path="$(ask "Enter path to the crt")"
    elif [[ -n "$SB_KEY_PATH" ]] && [[ -n "$SB_CRT_PATH" ]]; then
        sb_key_path="$SB_KEY_PATH"
        sb_crt_path="$SB_CRT_PATH"
    fi

    msg "Making recovery files..."
    make_recovery "$RECOVERY_DIR"

    # Avoid permission errors
    msg "Setting root as owner of $ARCH_ISO_DIR..."
    sudo chown -R root:root "$ARCH_ISO_DIR"

    msg "Increasing TTY scrollback..."
    increase_tty_scrollback "$BOOT_ENTRIES_DIR"

    msg "Building archiso..."
    (
        cd $ARCH_ISO_DIR
        sudo ./build.sh \
            -N "$ISO_NAME" \
            -P "$ISO_PUBLISHER" \
            -A "$ISO_APPLICATION" \
            -o "$BASE_DIR" \
            -k "$sb_key_path" \
            -c "$sb_crt_path" \
            "${V_FLAG[@]}"
    )
    res="$?"

    if [[ "$res" -eq 0 ]]; then
        out="$BASE_DIR/$(date +$ISO_NAME-%Y.%m.%d-x86_64.iso)"
        msg "ISO has been created at $out"

        if [[ -n "$DEV" ]]; then
            image_dev "$out" "$DEV"
        elif iprompt "Would you like to write this image to a device?"; then
            ls /dev
            dev="$(ask "Please enter the path to your device (i.e. /dev/sdX)")"

            image_dev "$out" "$dev"
        fi

        exit 0
    else
        exit 1
    fi
}

################################################################################
# Download the latest archiso
#   Globals:
#     None
#   Arguments:
#     ARCH_ISO, path to download archiso to
#   Outputs:
#     Progress info
#   Returns:
#     0 if successful, error code of curl otherwise
################################################################################
function download_iso() {
    local ARCH_ISO
    local top_mirror url_root iso_name url_iso

    ARCH_ISO="$1"
    readonly ARCH_ISO

    # Get first uncommented mirror from /etc/pacman.d/mirrorlist
    top_mirror="$(cat /etc/pacman.d/mirrorlist \
        | grep "^Server = " \
        | head -n1 \
        | cut -d'=' -f2 \
        | awk '{$1=$1; print}')"

    # Get beginning of url
    url_root="$(echo "$top_mirror" \
        | sed -e "s;\$repo/os/\$arch;iso/latest;")"

    # Get name of iso file by grepping html
    iso_name="$(curl -Ls "$url_root" \
        | grep -o -P -e "archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64\.iso" \
        | head -n1)"

    # Construct full URL to iso
    url_iso="$url_root/$iso_name"

    msg "Downloading archiso..."
    curl "$url_iso" --output "$ARCH_ISO"
}

################################################################################
# Download latest archiso and remaster downloaded ISO
#   Globals:
#     None
#   Arguments:
#     None
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful, 1 otherwise
################################################################################
function download_and_remaster() {
    local ARCH_ISO
    ARCH_ISO="/tmp/archiso.iso"
    readonly ARCH_ISO

    download_iso "$ARCH_ISO"

    remaster "$ARCH_ISO"
}

################################################################################
# Prompt user for path to existing archiso to remaster and begin remastering
# specified ISO
#   Globals:
#     None
#   Arguments:
#     None
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful, 1 otherwise
################################################################################
function use_existing_and_remaster() {
    local arch_iso

    arch_iso="$(ask "Enter path to iso")"

    remaster "$arch_iso"
}

################################################################################
# Prompt user for device path to image with built LadOS ISO
#   Globals:
#     BASE_DIR
#     DEV
#   Arguments:
#     None
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful, 1 otherwise
################################################################################
function existing_image_to_usb() {
    iso_path="$(find "$BASE_DIR" -type f -name 'LadOS*.iso' -print -quit)"

    if [[ -z "$DEV" ]]; then
        ls /dev
        dev="$(ask "Please enter the path to your device (i.e. /dev/sdX)")"

        image_dev "$iso_path" "$dev"
    else
        image_dev "$iso_path" "$DEV"
    fi
}

################################################################################
# The main function for the remaster method of building the archiso.
#   Globals:
#     BASE_DIR
#     LAD_OS_DIR
#     SB_KEY_PATH
#     SB_CRT_PATH
#     ISO_NAME
#     ISO_PUBLISHER
#     ISO_APPLICATION
#     Q_FLAG
#     DEV
#   Arguments:
#     ARCH_ISO, path to archiso file
#   Outputs:
#     Prints progress
#   Returns:
#     0 if successful, 1 otherwise
################################################################################
function remaster() {
    local ARCH_ISO ARCH_ISO_DIR EFI_BOOT_DIR CUSTOM_ISO_DIR AIROOTFS_SFS
    local SHA512_AIROOTFS_SFS SQUASHFS_ROOT_DIR BOOT_ENTRIES_DIR RECOVERY_DIR
    local PACMAN_CONF EFI_BOOT_IMG ARCH_ISO_BOOT_CONF
    local sb_key_path sb_crt_path label out dev

    ARCH_ISO="$1"
    ARCH_ISO_DIR="/mnt/archiso"
    EFI_BOOT_DIR="/mnt/efiboot"
    CUSTOM_ISO_DIR="/var/tmp/customiso"
    AIROOTFS_SFS="$CUSTOM_ISO_DIR/arch/x86_64/airootfs.sfs"
    SHA512_AIROOTFS_SFS="$CUSTOM_ISO_DIR/arch/x86_64/airootfs.sha512"
    SQUASHFS_ROOT_DIR="$CUSTOM_ISO_DIR/arch/x86_64/squashfs-root"
    BOOT_ENTRIES_DIR="$CUSTOM_ISO_DIR/loader/entries"
    RECOVERY_DIR="$AIROOTFS_DIR/LadOS/conf/recovery-mode/"
    PACMAN_CONF="$SQUASHFS_ROOT_DIR/etc/pacman.conf"
    EFI_BOOT_IMG="$CUSTOM_ISO_DIR/EFI/archiso/efiboot.img"
    ARCH_ISO_BOOT_CONF="$ARCH_ISO_DIR/loader/entries/archiso-x86_64.conf"

    readonly ARCH_ISO ARCH_ISO_DIR EFI_BOOT_DIR CUSTOM_ISO_DIR AIROOTFS_SFS
    readonly SHA512_AIROOTFS_SFS SQUASHFS_ROOT_DIR BOOT_ENTRIES_DIR RECOVERY_DIR
    readonly PACMAN_CONF EFI_BOOT_IMG ARCH_ISO_BOOT_CONF

    if is_arch_user; then
        msg "Installing archiso cdrtools..."
        if pacman -Q archiso-git &> /dev/null; then
            sudo pacman -R archiso-git --noconfirm
        fi
        sudo pacman -S archiso cdrtools --needed --noconfirm
    fi

    msg "Removing ISOs from LadOS..."
    rm -rf "$BASE_DIR"/*.iso

    if [[ -d "$CUSTOM_ISO_DIR" ]]; then
        msg "Cleaning up old mounts from $CUSTOM_ISO_DIR..."
        sudo find "$CUSTOM_ISO_DIR" -type d -exec mountpoint -q {} \; \
            -exec umount {} \;
    fi

    if findmnt --target "$ARCH_ISO_DIR" &> /dev/null; then
        msg "Cleaning up old mount $ARCH_ISO_DIR..."
        sudo umount "$ARCH_ISO_DIR"
    fi
    
    # Mount archiso
    msg "Mounting archiso to $ARCH_ISO_DIR..."
    sudo mkdir -p "$ARCH_ISO_DIR"
    sudo mount -t iso9660 -o loop "$ARCH_ISO" "$ARCH_ISO_DIR"

    # Copy contents of archiso to tmp directory
    msg  "Copying archiso to $CUSTOM_ISO_DIR..."
    sudo mkdir -p "$CUSTOM_ISO_DIR"
    sudo cp -a $ARCH_ISO_DIR/* "$CUSTOM_ISO_DIR"

    msg "Unsquashing airootfs.sfs..."
    sudo unsquashfs -f -d "$SQUASHFS_ROOT_DIR" "$AIROOTFS_SFS" 

    msg "Copying over LadOS to the squashfs-root..."
    sudo cp -rf "$LAD_OS_DIR" "$SQUASHFS_ROOT_DIR"

    if [[ -n "$CREATE_LOCAL_REPO" ]] || iprompt "Pre-compile and download packages?"; then
        msg "Creating localrepo..."
        create_localrepo "$SQUASHFS_ROOT_DIR" "$PACMAN_CONF"
    fi
    
    msg "Making recovery files..."
    make_recovery "$RECOVERY_DIR"

    # Avoid permission errors
    msg "Setting root as owner of $CUSTOM_ISO_DIR..."
    sudo chown -R root:root "$CUSTOM_ISO_DIR"

    msg "Increasing TTY scrollback..."
    increase_tty_scrollback "$BOOT_ENTRIES_DIR"

    msg "Removing the old airootfs.sfs..."
    sudo rm "$AIROOTFS_SFS"

    msg "Resquashing into airootfs.sfs..."
    sudo mksquashfs "$SQUASHFS_ROOT_DIR" "$AIROOTFS_SFS" -comp xz 

    msg "Removing squashfs-root"
    sudo rm -rf "$SQUASHFS_ROOT_DIR"

    msg "Updating SHA512 checksum..."
    sudo sha512sum "$AIROOTFS_SFS" | sudo tee "$SHA512_AIROOTFS_SFS"

    if iprompt "Sign the EFI binaries with keys for secure boot?"; then
        msg "Signing EFIs..."
        sb_key_path="$(ask "Enter path to the private key")"
        sb_crt_path="$(ask "Enter path to the crt")"
    elif [[ -n "$SB_KEY_PATH" ]] && [[ -n "$SB_CRT_PATH" ]]; then
        sb_key_path="$SB_KEY_PATH"
        sb_crt_path="$SB_CRT_PATH"
    fi

    # Use sbsign to sign EFI boot binaries for secure boot
    if [[ -n "$sb_key_path" ]] && [[ -n "$sb_crt_path" ]]; then
        msg2 "Signing EFI and vmlinuz binaries in $CUSTOM_ISO_DIR..."
        sudo find "$CUSTOM_ISO_DIR" \( -iname '*.efi' -o -iname 'vmlinuz*' \) \
            -exec sbsign --key "$sb_key_path" --cert "$sb_crt_path" \
            --output {} {} \;

        msg2 "Mounting efiboot.img on $EFI_BOOT_DIR..."
        sudo mkdir -p "$EFI_BOOT_DIR"
        sudo mount -t vfat -o loop "$EFI_BOOT_IMG" "$EFI_BOOT_DIR"

        msg2 "Signing EFI and vmlinuz binaries in $EFI_BOOT_DIR..."
        sudo find "$EFI_BOOT_DIR" \( -iname '*.efi' -o -iname 'vmlinuz*' \) \
            -exec sbsign --key "$sb_key_path" --cert "$sb_crt_path" \
            --output {} {} \;
        
        msg2 "Unmounting efiboot.img..."
        sudo umount "$EFI_BOOT_DIR"
    fi

    # Get label from systemd-boot entry
    msg "Creating new iso..."
    label="$(cat "$ARCH_ISO_BOOT_CONF" \
        | tail -n1 \
        | grep -o "archisolabel=.*$" \
        | cut -d'=' -f2)"

    # Name of remastered ISO
    out="$ISO_OUT_DIR/$(date +$ISO_NAME-%Y.%m.%d-x86_64.iso)"

    sudo rm -f "$out"

    # Create remastered ISO
    sudo xorriso -as mkisofs \
        -full-iso9660-filenames \
        -volid "$label" \
        -eltorito-boot isolinux/isolinux.bin \
        -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -isohybrid-mbr "$CUSTOM_ISO_DIR"/isolinux/isohdpfx.bin \
        -eltorito-alt-boot \
        -e EFI/archiso/efiboot.img \
        -no-emul-boot -isohybrid-gpt-basdat \
        -output "$out" \
        "$CUSTOM_ISO_DIR"

    # Image device with remastered ISO
    if [[ -n "$DEV" ]]; then
        image_dev "$out" "$DEV"
    elif iprompt "Would you like to write this image to a device? "; then
        ls /dev
        dev="$(ask "Please enter the path to your device (i.e. /dev/sdX)")"

        image_dev "$out" "$dev"
    fi

    exit 0
}

################################################################################
# Display remaster menu
#   Globals:
#     None
#   Arguments:
#     None
#   Outputs:
#     Prints menu
#   Returns:
#     0 if successful, 1 otherwise
################################################################################
function remaster_iso() {
    show_menu "Remaster ISO" \
        "Download ISO"      "download_and_remaster" \
        "Use existing ISO"  "use_existing_and_remaster" \
        "Go Back"           "return 0"
}

################################################################################
# Display main menu
#   Globals:
#     None
#   Arguments:
#     None
#   Outputs:
#     Prints menu
#   Returns:
#     0 if successful, 1 otherwise
################################################################################
function interactive() {
    if is_arch_user; then
        show_menu "Make ISO" \
            "Build from scratch"    "build_from_scratch" \
            "Remaster ISO"          "remaster_iso" \
            "Image USB"             "existing_image_to_usb" \
            "Make Recovery"         "_make_recovery" \
            "Exit"                  "exit 0"
    else
        echo "Since you are not using Arch Linux, the only way to create an ISO"
        echo "is to remaster an existing archiso. Please download an Arch Linux"
        echo "ISO from https://www.archlinux.org/download/"
        echo "Please also install squashfs-tools libisoburn dosfstools lynx"
        echo "syslinux"

        show_menu "Make ISO" \
            "Remaster ISO"          "remaster_iso" \
            "Image USB"             "existing_image_to_usb" \
            "Exit"                  "exit 0"
    fi
}



# Parse script arguments and set main mode
case "$1" in
    interactive | build | remaster | make_recovery)
        CMD="$1"
        shift
        ;;
    image)
        CMD="$1"
        shift
        DEV="$1"
        shift
        ;;
    help)
        print_usage
        exit 0
        ;;
    *)
        if [[ "$1" != "" ]]; then
            echo "Unrecognized option '$1'"
        fi
        echo "usage: ${0} <mode> [options]"
        echo "Try '${0} help' for more information"
        exit 1
esac

# Parse commandline options and set global flags using given arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -a | --auto-download-iso)
            AUTO_DOWNLOAD_ISO=1
            shift
            ;;
        -c | --sb-crt-path)
            shift
            SB_CRT_PATH="$1"
            shift
            ;;
        -d | --dev)
            shift
            DEV="$1"
            shift
            ;;
        -i | --archiso-path)
            shift
            ARCH_ISO_PATH="$1"
            shift
            ;;
        -k | --sb-key-path)
            shift
            SB_KEY_PATH="$1"
            shift
            ;;
        -l | --create-localrepo)
            CREATE_LOCAL_REPO=1
            shift
            ;;
        -m | --ms-ttf-win10)
            BUILD_TTF_MS_WIN_10=1
            shift
            ;;
        -v)
            VERBOSITY=1
            V_FLAG=("")
            Q_FLAG=("-q")
            shift
            ;;
        -vv)
            VERBOSITY=2
            V_FLAG=("")
            Q_FLAG=("")
            shift
            ;;
        -vvv)
            VERBOSITY=3
            V_FLAG=("-v")
            Q_FLAG=("")
            shift
            ;;
        *)
            if [[ "$1" != "" ]]; then
                echo "Unrecognized option '$1'"
            fi
            echo "usage: ${0} <mode> [options]"
            echo "Try '${0} help' for more information"
            exit 1
            ;;
    esac
done

GIT_FLAGS=("${GIT_FLAGS[@]}" "${V_FLAG[@]}" "${Q_FLAG[@]}")

readonly CMD AUTO_DOWNLOAD_ISO SB_CRT_PATH DEV SB_KEY_PATH CREATE_LOCAL_REPO 
readonly BUILD_TTF_MS_WIN_10 VERBOSITY Q_FLAG V_FLAG GIT_FLAGS


# Start mode
case "$CMD" in
    interactive)
        interactive
        ;;
    build)
        if is_arch_user; then
            build_from_scratch
        else
            error "You must be running arch linux to do this."
        fi
        ;;
    remaster)
        if [[ -n "$AUTO_DOWNLOAD_ISO" ]]; then
            download_iso
            remaster
        elif [[ -n "$ARCH_ISO_PATH" ]]; then
            remaster
        fi
        ;;
    image)
        existing_image_to_usb
        ;;
    make_recovery)
        _make_recovery
        ;;
esac
