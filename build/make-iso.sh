#!/usr/bin/bash
 
set -o errtrace
set -o pipefail
trap error_trap ERR

function error_trap() {
    error_code="$?"
    error "$(caller): \"$BASH_COMMAND\" returned error code $error_code"
    exit $error_code
}


# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

ISO_NAME="LadOS"
ISO_PUBLISHER="Mihir Lad <https://mihirlad.com"
ISO_APPLICATION="LadOS Linux Live CD"
ISO_OUT_DIR="$BASE_DIR"

VERBOSE=
V_FLAG=
Q_FLAG="-q"

source "$LAD_OS_DIR/common/message.sh"



function print_usage() {
    echo "usage: ${0} <mode> [options]"
    echo
    echo "  Modes:"
    echo "   interactive                 Start interactive mode. This mode uses"
    echo "                               no options."
    echo
    echo "   build                       Build LadOS iso from scratch. This mode"
    echo "                               accepts the options --create-localrepo,"
    echo "                               --ms-ttf-win10, --dev, --sb-key-path,"
    echo "                               --sb-crt-path."
    echo
    echo "   remaster                    Remaster archiso and add LadOS. This mode"
    echo "                               accepts the options --create-localrepo,"
    echo "                               --ms-ttf-win10, --dev, --archiso-path,"
    echo "                               --auto-download-iso, --sb-key-path,"
    echo "                               --sb-crt-path."
    echo
    echo "   image <dev>                 Image device with existing image. This"
    echo "                               mode requires the device as an argument."
    echo
    echo "   help                        Display this message and exit"
    echo
    echo "  Options:"
    echo "   -a  --auto-download-iso     Automatically download latest archiso"
    echo "   -c, --sb-crt-path           Path to certificate file for secure boot"
    echo "   -d, --dev <dev>             Image <dev> with archiso image at end"
    echo "   -i, --archiso-path          Path to existing archiso to remaster"
    echo "   -k, --sb-key-path           Path to private key file to sign EFIs"
    echo "                               with for secure boot"
    echo "   -l, --create-localrepo      Include offline repo of packages in iso"
    echo "   -m, --ms-ttf-win10          Build and and include ms-ttf-win10 package"
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

function show_menu() {
    local option=0

    title="-----$1-----"
    shift

    local num_of_options=$(($#/2))

    while true; do
        local i=1
        echo $title
        while [[ "$i" -le $num_of_options ]]; do
            local name=$(($i*2-1))
            echo "$i. ${!name}"
            i=$(($i+1))
        done
        echo -n "Option: "
        read option

        func_num=$(($option*2))
        eval ${!func_num}
    done
}

function is_arch_user() {
    pacman -V > /dev/null
}

function make_recovery() {
    local RECOVERY_DIR="/var/tmp/recovery"
    local AIROOTFS_DIR="$RECOVERY_DIR/airootfs"
    local install_dir

    install_dir="$1"
    msg "Making recovery..."

    if [[ -d "$RECOVERY_DIR" ]]; then
        msg2 "Cleaning up old mounts from $RECOVERY_DIR..."
        sudo find "$RECOVERY_DIR" -type d -exec mountpoint -q {} \; -exec umount {} \;
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

function image_dev() {
    local iso_path="$1"
    local dev="$2"

    sudo dd bs=4M if="$iso_path" of="$dev" status=progress oflag=sync
}

function build_win10_fonts() {
    local PKG_PATH="$1"

    if ! find "$PKG_PATH" -name "*ttf-ms-win10*" | grep -q '.'; then
        msg3 "ttf-ms-win10 not found in $PKG_PATH"

        msg3 "Building ttf-ms-win10..."
        mkdir -p /var/tmp/win10-fonts
        $BASE_DIR/misc/build-ttf-ms-win10.sh $Q_FLAG $V_FLAG "/var/tmp/win10-fonts"

        msg3 "Moving files to $PKG_PATH..."
        sudo mv -f /var/tmp/win10-fonts/* "$PKG_PATH"

        msg3 "Removing temp files..."
        rm -rf /var/tmp/win10-fonts
    else
        msg3 "ttf-ms-win10 package already found in $PKG_PATH"
        msg3 "Not going to rebuild tff-ms-win10"
    fi
}

function build_aur_packages() {
    local AUR_URL="https://aur.archlinux.org"
    local PKG_PATH="$1"

    IFS=$'\n'
    aur_packages=($(cat "$LAD_OS_DIR/packages.csv" | grep "^.*,.*,aur,"))
    for pkg in "${aur_packages[@]}"; do
        pkg_name="$( echo "$pkg" | cut -d',' -f1 )"

        msg3 "$pkg_name"
        if [[ ! -d "/var/tmp/$pkg_name" ]]; then
            git clone $Q_FLAG --depth 1 "$AUR_URL/$pkg_name.git" "/var/tmp/$pkg_name"
        fi
        (
            source /var/tmp/$pkg_name/PKGBUILD
            if ! type pkgver &> /dev/null; then
                # pkgver is variable
                ver=$pkgver
            fi

            if [[ "$epoch" = "" ]]; then
                tar_path_prefix="$PKG_PATH/${pkgname}-${ver}"
            else
                tar_path_prefix="$PKG_PATH/${pkgname}-${epoch}:${ver}"
            fi

            if ! test -f "$tar_path_prefix"*.pkg.tar.xz; then
                msg4 "Building $pkg_name..."
                cd "/var/tmp/$pkg_name"
                makepkg -s --noconfirm --nocolor
                sudo cp -f *.pkg.tar.xz "$PKG_PATH"
            else
                msg4 "$pkgname already exists"
            fi
        )

        rm -rf "/var/tmp/$pkg_name"
    done
}

function copy_pacman_packages() {
    local PKG_PATH="$1"
    local ARCH_ISO_PATH="$2"
    local PACMAN_CONF_PATH="$3"
    local TEMP_DB_PATH="/tmp"


    sudo pacman -Syu --noconfirm
    sudo pacman -S pacman-contrib --needed --noconfirm

    mapfile -t pacman_packages < <(cat "$LAD_OS_DIR/packages.csv" | \
        grep "^.*,.*,system," | \
        cut -d ',' -f1)

    if [[ -f "$ARCH_ISO_PATH/packages.x86_64" ]]; then
        msg3 "Found package list at $ARCH_ISO_PATH/packages.x86_64..."
        arch_iso_packages=("$(cat "$ARCH_ISO_PATH/packages.x86_64")")

        # Add packages from archiso
        pacman_packages=("${pacman_packages[@]}" "${arch_iso_packages[@]}")
    fi

    for pkg in ${pacman_packages[@]}; do
        msg3 "$pkg"
        mapfile -t target_paths < <(pacman -Spdd $pkg)

        for target_path in "${target_paths[@]}"; do 
            if [[ "$target_path" =~ file://** ]]; then
                target="${target_path##file://**/}"
                target_path="${target_path#file://}"
                if [[ ! -f "$PKG_PATH/$target" ]]; then
                    msg4 "Copying $target from cache to the archiso"
                    vecho "Copying from $target_path to $PKG_PATH..."
                    sudo cp -f "$target_path" "$PKG_PATH"
                else
                    msg4 "$target is already in localrepo"
                fi
            else
                target="${target_path##https://**/}"
                msg4 "$target not found in host pacman cache"
            fi
        done
    done


    sudo pacman -Sy --noconfirm --dbpath "$TEMP_DB_PATH"

    msg3 "Downloading missing packages..."
    sudo pacman -S ${pacman_packages[@]} \
        -w --cachedir "$PKG_PATH" \
        --dbpath "$TEMP_DB_PATH" \
        --noconfirm --needed

	if ! grep -q "$PACMAN_CONF_PATH" -e "LadOS"; then
        msg3 "Adding localrepo to pacman.conf"
	    sudo sed -i "$PACMAN_CONF_PATH" -e '1 i\Include = /LadOS/install/localrepo.conf'
    fi
}

function increase_tty_scrollback() {
    local ENTRIES_DIR="$1"
    local OPTION="fbcon=scrollback:1024k"

    if ! grep -q -F "$OPTION" $ENTRIES_DIR/*; then
        msg2 "Adding $OPTION kernel parameter"
        sudo sed -i $ENTRIES_DIR/* -e "s/^options.*$/& $OPTION/"
    fi
}

function create_localrepo() {
    AIROOTFS_DIR="$1"
    PACMAN_CONF_PATH="$2"
    LOCAL_REPO_PATH="$AIROOTFS_DIR/LadOS/localrepo"
    PKG_PATH="$LOCAL_REPO_PATH/pkg"

    sudo mkdir -p "$PKG_PATH"

    msg2 "Building AUR packages..."
    build_aur_packages "$PKG_PATH"

    if [[ -n "$BUILD_TTF_MS_WIN_10" ]] || iprompt "Build ttf-ms-win10?"; then
        msg2 "Building windows 10 fonts..."
        build_win10_fonts "$PKG_PATH"
    fi

    msg2 "Copying pacman packages..."
    copy_pacman_packages "$PKG_PATH" "$ARCH_ISO_DIR" "$PACMAN_CONF_PATH"

    msg2 "Removing older packages..."
    sudo paccache --nocolor -rk1 -c "$PKG_PATH"

    msg2 "Adding all packages to localrepo database..."
    # If all packages are already present, repo-add returns 1
    (cd "$LOCAL_REPO_PATH" && sudo repo-add $Q_FLAG -n -R -p --nocolor localrepo.db.tar.gz pkg/*) || true
}

function build_from_scratch() {
    local ARCH_ISO_DIR="/var/tmp/archiso"
    local AIRROOTFS_DIR="$ARCH_ISO_DIR/airootfs"
    local BOOT_ENTRIES_DIR="$ARCH_ISO_DIR/efiboot/loader/entries/"
    local sb_key_path sb_crt_path

    msg "Removing old ISOs..."
    rm -f $BASE_DIR/*.iso
    
    if [[ -d "$ARCH_ISO_DIR" ]]; then
        msg "Cleaning up old mounts from $ARCH_ISO_DIR..."
        sudo find "$ARCH_ISO_DIR" -type d -exec mountpoint -q {} \; -exec umount {} \;
        
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

    msg "Copying LadOS to $AIRROOTFS_DIR..."
    sudo cp -rft "$AIRROOTFS_DIR" "$LAD_OS_DIR"

    if [[ -n "$CREATE_LOCAL_REPO" ]] || iprompt "Pre-compile and download packages?"; then
        msg "Creating localrepo..."
        create_localrepo "$AIRROOTFS_DIR" "$ARCH_ISO_DIR/pacman.conf"
    fi

    if iprompt "Would you like to sign the archiso bootloader and binaries with custom secure boot keys?"; then
        ask "Enter path to the private key"
        read -r SB_KEY_PATH
        ask "Enter path to the crt"
        read -r SB_CRT_PATH
    fi

    msg "Making recovery files..."
    make_recovery "$AIRROOTFS_DIR/LadOS/conf/recovery-mode/"

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
            -k "$SB_KEY_PATH" \
            -c "$SB_CRT_PATH" \
            $V_FLAG
    )
    res="$?"

    if [[ "$res" -eq 0 ]]; then
        out="$BASE_DIR/$(date +$ISO_NAME-%Y.%m.%d-x86_64.iso)"
        msg "ISO has been created at $out"

        if [[ -n "$DEV" ]]; then
            image_dev "$out" "$DEV"
        elif iprompt "Would you like to write this image to a device? Note this will wipe your device."; then
            ls /dev
            ask "Please enter the path to your device (i.e. /dev/sdX)"
            read -r dev

            image_dev "$out" "$dev"
        fi

        exit 0
    else
        exit 1
    fi
}


function download_iso() {
    ARCH_ISO_PATH="/tmp/archiso.iso"
    local top_mirror="$(cat /etc/pacman.d/mirrorlist | \
        grep "^Server = " | \
        head -n1 | \
        cut -d'=' -f2 | \
        awk '{$1=$1; print}')"

    local url_root="$(echo "$top_mirror" | \
        sed -e "s;\$repo/os/\$arch;iso/latest;")"

    local iso_name="$(curl -Ls $url_root | \
        grep -o -P -e "archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64\.iso" | \
        head -n1)"

    local url_iso="$url_root/$iso_name"

    msg "Downloading archiso..."
    curl $url_iso --output "$ARCH_ISO_PATH"
}

function use_existing_iso() {
    ask "Enter path to iso"
    read -r ARCH_ISO_PATH
}

function remaster() {
    MOUNT_PATH="/mnt/archiso"
    EFI_BOOT_MOUNT_PATH="/mnt/efiboot"
    CUSTOM_ISO_PATH="/var/tmp/customiso"
    AIROOTFS_PATH="$CUSTOM_ISO_PATH/arch/x86_64/airootfs.sfs"
    SHA512_AIROOTFS_PATH="$CUSTOM_ISO_PATH/arch/x86_64/airootfs.sha512"
    SQUASHFS_ROOT_PATH="$CUSTOM_ISO_PATH/arch/x86_64/squashfs-root"
    BOOT_ENTRIES_DIR="$CUSTOM_ISO_PATH/loader/entries"

    if is_arch_user; then
        msg "Installing archiso cdrtools..."
        if pacman -Q archiso-git &> /dev/null; then
            sudo pacman -R archiso-git --noconfirm
        fi
        sudo pacman -S archiso cdrtools --needed --noconfirm
    fi

    msg "Removing ISOs from LadOS..."
    rm -rf "$BASE_DIR"/*.iso

    if [[ -d "$CUSTOM_ISO_PATH" ]]; then
        msg "Cleaning up old mounts from $CUSTOM_ISO_PATH..."
        sudo find "$CUSTOM_ISO_PATH" -type d -exec mountpoint -q {} \; -exec umount {} \;
    fi

    if findmnt --target "$MOUNT_PATH" &> /dev/null; then
        msg "Cleaning up old mount $MOUNT_PATH..."
        sudo umount "$MOUNT_PATH"
    fi
    
    msg "Mounting archiso to $MOUNT_PATH..."
    sudo mkdir -p "$MOUNT_PATH"
    sudo mount -t iso9660 -o loop "$ARCH_ISO_PATH" "$MOUNT_PATH"

    msg  "Copying archiso to $CUSTOM_ISO_PATH..."
    sudo mkdir -p "$CUSTOM_ISO_PATH"
    sudo cp -a $MOUNT_PATH/* "$CUSTOM_ISO_PATH"

    msg "Unsquashing airootfs.sfs..."
    sudo unsquashfs -f -d "$SQUASHFS_ROOT_PATH" "$AIROOTFS_PATH" 

    msg "Copying over LadOS to the squashfs-root..."
    sudo cp -rf "$LAD_OS_DIR" "$SQUASHFS_ROOT_PATH"

    if [[ -n "$CREATE_LOCAL_REPO" ]] || prompt "Pre-compile and download packages?"; then
        msg "Creating localrepo..."
        create_localrepo "$SQUASHFS_ROOT_PATH" "$SQUASHFS_ROOT_PATH/etc/pacman.conf"
    fi
    
    msg "Making recovery files..."
    make_recovery "$AIRROOTFS_DIR/LadOS/conf/recovery-mode/"

    # Avoid permission errors
    msg "Setting root as owner of $CUSTOM_ISO_PATH..."
    sudo chown -R root:root "$CUSTOM_ISO_PATH"

    msg "Increasing TTY scrollback..."
    increase_tty_scrollback "$BOOT_ENTRIES_DIR"

    msg "Removing the old airootfs.sfs..."
    sudo rm "$AIROOTFS_PATH"

    msg "Resquashing into airootfs.sfs..."
    sudo mksquashfs "$SQUASHFS_ROOT_PATH" "$AIROOTFS_PATH" -comp xz 

    msg "Removing squashfs-root"
    sudo rm -rf "$SQUASHFS_ROOT_PATH"

    msg "Updating SHA512 checksum..."
    sudo sha512sum "$AIROOTFS_PATH" | sudo tee "$SHA512_AIROOTFS_PATH"

    if iprompt "Would you like to sign the archiso bootloader and binaries with custom secure boot keys?"; then
        msg "Signing EFIs..."
        ask "Enter path to the private key"
        read -r SB_KEY_PATH
        ask "Enter path to the crt"
        read -r SB_CRT_PATH
    fi

    if [[ -n "$SB_KEY_PATH" ]] && [[ -n "$SB_CRT_PATH" ]]; then
        msg2 "Signing EFI and vmlinuz binaries in $CUSTOM_ISO_PATH..."
        sudo find "$CUSTOM_ISO_PATH" \( -iname '*.efi' -o -iname 'vmlinuz*' \) \
            -exec sbsign --key "$SB_KEY_PATH" --cert "$SB_CRT_PATH" --output {} {} \;

        msg2 "Mounting efiboot.img on $EFI_BOOT_MOUNT_PATH..."
        sudo mkdir -p "$EFI_BOOT_MOUNT_PATH"
        sudo mount -t vfat -o loop "$CUSTOM_ISO_PATH/EFI/archiso/efiboot.img" "$EFI_BOOT_MOUNT_PATH"

        msg2 "Signing EFI and vmlinuz binaries in $EFI_BOOT_MOUNT_PATH..."
        sudo find "$EFI_BOOT_MOUNT_PATH" \( -iname '*.efi' -o -iname 'vmlinuz*' \) \
            -exec sbsign --key "$SB_KEY_PATH" --cert "$SB_CRT_PATH" --output {} {} \;
        
        msg2 "Unmounting efiboot.img..."
        sudo umount "$EFI_BOOT_MOUNT_PATH"
    fi

    msg "Creating new iso..."
    local LABEL="$(cat /mnt/archiso/loader/entries/archiso-x86_64.conf | \
        tail -n1 | \
        grep -o "archisolabel=.*$" | \
        cut -d'=' -f2)"

    local out="$ISO_OUT_DIR/$(date +$ISO_NAME-%Y.%m.%d-x86_64.iso)"

    sudo rm -f "$out"

    sudo xorriso -as mkisofs \
        -full-iso9660-filenames \
        -volid "$LABEL" \
        -eltorito-boot isolinux/isolinux.bin \
        -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -isohybrid-mbr "$CUSTOM_ISO_PATH"/isolinux/isohdpfx.bin \
        -eltorito-alt-boot \
        -e EFI/archiso/efiboot.img \
        -no-emul-boot -isohybrid-gpt-basdat \
        -output "$out" \
        "$CUSTOM_ISO_PATH"

    if [[ -n "$DEV" ]]; then
        image_dev "$out" "$DEV"
    elif iprompt "Would you like to write this image to a device? Note this will wipe your device."; then
        ls /dev
        ask "Please enter the path to your device (i.e. /dev/sdX)"
        read -r dev

        image_dev "$out" "$dev"
    fi

    exit 0
}


function remaster_iso() {
    show_menu "Remaster ISO" \
        "Download ISO"      "download_iso; remaster" \
        "Use existing ISO"  "use_existing_iso; remaster" \
        "Go Back"           "return 0"
}

function existing_image_to_usb() {
    iso_path="$(find "$BASE_DIR" -type f -name 'LadOS*.iso' -print -quit)"

    if [[ -z "$DEV" ]]; then
        ls /dev
        ask "Please enter the path to your device (i.e. /dev/sdX)"
        read -r dev

        image_dev "$iso_path" "$dev"
    else
        image_dev "$iso_path" "$DEV"
    fi
}

function interactive() {
    if is_arch_user; then
        show_menu "Make ISO" \
            "Build from scratch"    "build_from_scratch" \
            "Remaster ISO"          "remaster_iso" \
            "Image USB"             "existing_image_to_usb" \
            "Exit"                  "exit 0"
    else
        echo "Since you are not using Arch Linux, the only way to create an ISO is to remaster an existing archiso. Please download an Arch Linux ISO from https://www.archlinux.org/download/"
        echo "Please also install squashfs-tools libisoburn dosfstools lynx syslinux"

        show_menu "Make ISO" \
            "Remaster ISO"          "remaster_iso" \
            "Image USB"             "existing_image_to_usb" \
            "Exit"                  "exit 0"
    fi
}



case "$1" in
    interactive | build | remaster)
        cmd="$1"
        shift
        ;;
    image)
        cmd="$1"
        shift
        DEV="$1"
        shift
        ;;
    help)
        print_usage
        exit 0
        ;;
    *)
        echo "Invalid command $1"
        print_usage
        exit 1
esac

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
            V_FLAG=""
            Q_FLAG="-q"
            shift
            ;;
        -vv)
            VERBOSITY=2
            V_FLAG=""
            Q_FLAG=""
            shift
            ;;
        -vvv)
            VERBOSITY=3
            V_FLAG="-v"
            Q_FLAG=""
            shift
            ;;
        *)
            echo "Invalid command $1"
            print_usage
            exit 1
            ;;
    esac
done

case "$cmd" in
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
esac
