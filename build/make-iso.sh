#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

ISO_NAME="LadOS"
ISO_PUBLISHER="Mihir Lad <https://mihirlad.com"
ISO_APPLICATION="LadOS Linux Live CD"
ISO_OUT_DIR="$BASE_DIR"

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

function prompt() {
    while true; do
        read -p "$1 [Y/n] " resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

function is_arch_user() {
    pacman -V > /dev/null
}

function image_usb() {
    local ISO_PATH="$1"

    if prompt "Would you like to write this image to a USB? Note this will wipe your USB."; then
        read -p "Please insert your usb and press enter to continue"
        ls /dev

        read -p "Please enter the path to your usb (i.e. /dev/sdX): " path
        
        sudo dd bs=4M if="$ISO_PATH" of=$path status=progress oflag=sync
    fi
}

function build_win10_fonts() {
    local PKG_PATH="$1"

    if ! find "$PKG_PATH" -name "*ttf-ms-win10*" | grep -q '.'; then
        mkdir -p /var/tmp/win10-fonts
        $BASE_DIR/misc/build-ttf-ms-win10.sh "/var/tmp/win10-fonts"

        sudo mv /var/tmp/win10-fonts/* "$PKG_PATH"

        rm -r /var/tmp/win10-fonts
    else
        echo "ttf-ms-win10 package already found in $PKG_PATH"
        echo "Not going to rebuild tff-ms-win10"
    fi
}

function build_aur_packages() {
    local AUR_URL="https://aur.archlinux.org"
    local PKG_PATH="$1"

    IFS=$'\n'
    aur_packages=($(cat "$LAD_OS_DIR/packages.csv" | grep "^.*,.*,aur,"))
    for pkg in "${aur_packages[@]}"; do
        pkg_name="$( echo "$pkg" | cut -d',' -f1 )"
        git clone --depth 1 "$AUR_URL/$pkg_name.git" "/var/tmp/$pkg_name"
        (
            source /var/tmp/$pkg_name/PKGBUILD
            if type pkgver &> /dev/null; then
                # pkgver is function
                ver=$(pkgver)
            else
                # pkgver is variable
                ver=$pkgver
            fi

            if [[ "$epoch" = "" ]]; then
                pkg_path=$PKG_PATH/${pkgname}-${ver}*.pkg.tar.xz
            else
                pkg_path=$PKG_PATH/${pkgname}-${epoch}:${ver}*.pkg.tar.xz
            fi

            echo $pkg_path
            if ! test -f $pkg_path; then
                cd "/var/tmp/$pkg_name"
                makepkg -s --noconfirm
                sudo cp *.pkg.tar.xz "$PKG_PATH"
            else
                echo "$pkgname already exists at $PKG_PATH"
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

    pacman_packages=($(cat "$LAD_OS_DIR/packages.csv" | \
        grep "^.*,.*,system," | \
        cut -d ',' -f1))

    if [[ -f "$ARCH_ISO_PATH/packages.x86_64" ]]; then
        arch_iso_packages=("$(cat "$ARCH_ISO_PATH/packages.x86_64")")

        # Add packages from archiso
        pacman_packages=($pacman_packages $arch_iso_packages)
    fi

    for pkg in ${pacman_packages[@]}; do
        target="$(pacman -Spdd $pkg | \
            grep -v -e "^https" | \
            sed -e "s;file://;;" | \
            sed -e 's;^.*/;;')"

        if [[ "$target" != "" ]] && [[ ! -f "$PKG_PATH/$target" ]]; then
            echo "Found package $pkg at $target"
            echo "Copying $pkg to $PKG_PATH..."
            sudo cp -f "$target" "$PKG_PATH"
        fi
    done


    sudo pacman -Sy --noconfirm --dbpath "$TEMP_DB_PATH"

    sudo pacman -S ${pacman_packages[@]} \
        -w --cachedir "$PKG_PATH" \
        --dbpath "$TEMP_DB_PATH" \
        --noconfirm --needed

    echo "Removing older packages..."
    paccache -rk1 -c "$PKG_PATH"

	if ! grep -q "$PACMAN_CONF_PATH" -e "LadOS"; then
	    sudo sed -i "$PACMAN_CONF_PATH" -e '1 i\Include = /LadOS/install/localrepo.conf'
    fi
}

function increase_tty_scrollback() {
    local ENTRIES_DIR="$1"
    local OPTION="fbcon=scrollback:1024k"

    if ! grep -q -F "$OPTION" $ENTRIES_DIR/*; then
        sudo sed -i $ENTRIES_DIR/* -e "s/^options.*$/& $OPTION/"
    fi
}

function create_localrepo() {
    AIROOTFS_DIR="$1"
    PACMAN_CONF_PATH="$2"
    LOCAL_REPO_PATH="$AIROOTFS_DIR/LadOS/localrepo"
    PKG_PATH="$LOCAL_REPO_PATH/pkg"

    sudo mkdir -p "$PKG_PATH"

    build_aur_packages "$PKG_PATH"

    if prompt "Build ttf-ms-win10?"; then
        build_win10_fonts "$PKG_PATH"
    fi

    copy_pacman_packages "$PKG_PATH" "$ARCH_ISO_DIR" "$PACMAN_CONF_PATH"

    (cd "$LOCAL_REPO_PATH" && sudo repo-add localrepo.db.tar.gz pkg/*)
}

function build_from_scratch() {
    local ARCH_ISO_DIR="/var/tmp/archiso"
    local AIRROOTFS_DIR="$ARCH_ISO_DIR/airootfs"
    local BOOT_ENTRIES_DIR="$ARCH_ISO_DIR/efiboot/loader/entries/"
    local sb_key_path sb_crt_path

    echo "Removing old ISOs..."
    rm -f $BASE_DIR/*.iso
    
    echo "Cleaning up work directory..."
    sudo rm -rf "$ARCH_ISO_DIR/work"

    sudo pacman -R archiso --noconfirm
    sudo pacman -S arch-install-scripts btrfs-progs dosfstools libisoburn lynx squashfs-tools git --needed --noconfirm

    sudo cp -afT "$BASE_DIR/archiso" "$ARCH_ISO_DIR"

    sudo cp -rft "$AIRROOTFS_DIR" "$LAD_OS_DIR"

    if prompt "Pre-compile and download packages?"; then
        create_localrepo "$AIRROOTFS_DIR" "$ARCH_ISO_DIR/pacman.conf"
    fi

    if prompt "Would you like to sign the archiso bootloader and binaries with custom secure boot keys?"; then
        read -p "Enter path to the private key: " sb_key_path
        read -p "Enter path to the crt: " sb_crt_path
    fi

    # Avoid permission errors
    sudo chown -R root:root "$ARCH_ISO_DIR"

    increase_tty_scrollback "$BOOT_ENTRIES_DIR"

    (
        cd $ARCH_ISO_DIR
        sudo ./build.sh \
            -N "$ISO_NAME" \
            -P "$ISO_PUBLISHER" \
            -A "$ISO_APPLICATION" \
            -o "$BASE_DIR" \
            -k "$sb_key_path" \
            -c "$sb_crt_path"
    )
    res="$?"

    if [[ "$res" -eq 0 ]]; then
        out="$BASE_DIR/$(date +$ISO_NAME-%Y.%m.%d-x86_64.iso)"
        echo "ISO has been created at $out"
        image_usb "$out"

        exit 0
    else
        exit 1
    fi
}


function download_iso() {
    archiso_path="/tmp/archiso.iso"
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

    echo "Downloading archiso..."
    curl $url_iso --output "$archiso_path"
}

function use_existing_iso() {
    read -p "Enter path to iso: " archiso_path
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
        sudo pacman -R archiso-git --noconfirm
        sudo pacman -S archiso cdrtools --needed --noconfirm
    fi

    echo "Removing ISOs from LadOS..."
    rm -rf "$BASE_DIR"/*.iso
    
    sudo mkdir -p "$MOUNT_PATH"

    echo "Mounting archiso to $MOUNT_PATH..."
    sudo mount -t iso9660 -o loop "$archiso_path" "$MOUNT_PATH"

    echo  "Copying archiso to $CUSTOM_ISO_PATH..."
    sudo mkdir -p "$CUSTOM_ISO_PATH"
    sudo cp -a $MOUNT_PATH/* "$CUSTOM_ISO_PATH"

    echo "Unsquashing airootfs.sfs..."
    sudo unsquashfs -f -d "$SQUASHFS_ROOT_PATH" "$AIROOTFS_PATH" 
    echo "Copying over LadOS to the squashfs-root..."
    sudo cp -rf "$LAD_OS_DIR" "$SQUASHFS_ROOT_PATH"

    if prompt "Pre-compile and download packages?"; then
        create_localrepo "$SQUASHFS_ROOT_PATH" "$SQUASHFS_ROOT_PATH/etc/pacman.conf"
    fi

    # Avoid permission errors
    sudo chown -R root:root "$CUSTOM_ISO_PATH"

    increase_tty_scrollback "$BOOT_ENTRIES_DIR"

    echo "Removing the old airootfs.sfs..."
    sudo rm "$AIROOTFS_PATH"

    echo "Resquashing into airootfs.sfs..."
    sudo mksquashfs "$SQUASHFS_ROOT_PATH" "$AIROOTFS_PATH" -comp xz 

    echo "Removing squashfs-root"
    sudo rm -rf "$SQUASHFS_ROOT_PATH"

    echo "Updating SHA512 checksum..."
    sudo sha512sum "$AIROOTFS_PATH" | sudo tee "$SHA512_AIROOTFS_PATH"

    if prompt "Would you like to sign the archiso bootloader and binaries with custom secure boot keys?"; then
        read -p "Enter path to the private key: " sb_key_path
        read -p "Enter path to the crt: " sb_crt_path

        echo "Signing EFI and vmlinuz binaries in $CUSTOM_ISO_PATH..."
        sudo find "$CUSTOM_ISO_PATH" \( -iname '*.efi' -o -iname 'vmlinuz*' \) \
            -exec sbsign --key "$sb_key_path" --cert "$sb_crt_path" --output {} {} \;

        echo "Mounting efiboot.img on $EFI_BOOT_MOUNT_PATH..."
        sudo mkdir -p "$EFI_BOOT_MOUNT_PATH"
        sudo mount -t vfat -o loop "$CUSTOM_ISO_PATH/EFI/archiso/efiboot.img" "$EFI_BOOT_MOUNT_PATH"

        echo "Signing EFI and vmlinuz binaries in $EFI_BOOT_MOUNT_PATH..."
        sudo find "$EFI_BOOT_MOUNT_PATH" \( -iname '*.efi' -o -iname 'vmlinuz*' \) \
            -exec sbsign --key "$sb_key_path" --cert "$sb_crt_path" --output {} {} \;
        
        echo "Unmounting efiboot.img..."
        sudo umount "$EFI_BOOT_MOUNT_PATH"
    fi

    echo "Creating new iso..."
    local LABEL="$(cat /mnt/archiso/loader/entries/archiso-x86_64.conf | \
        tail -n1 | \
        grep -o "archisolabel=.*$" | \
        cut -d'=' -f2)"

    local out="$ISO_OUT_DIR/$ISO_NAME.iso"
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

    image_usb "$out"

    echo "Done!"
    exit 0
}


function remaster_iso() {
    show_menu "Build from scratch" \
        "Download ISO"      "download_iso; remaster" \
        "Use existing ISO"  "use_existing_iso; remaster" \
        "Go Back"           "return 0"
}

function existing_image_to_usb() {
    read -p "Please enter the path to the iso: " iso_path

    image_usb "$iso_path"
}


if is_arch_user; then
    show_menu "Make ISO" \
        "Build from scratch"    "build_from_scratch" \
        "Remaster ISO"          "remaster_iso" \
        "Image USB"             "existing_image_to_usb" \
        "Exit"                  "exit 0"
else
    echo "Since you are not using Arch Linux, the only way to create an ISO is to remaster an existing archiso. Please download an Arch Linux ISO from https://www.archlinux.org/download/"
    echo "Please also install squashfs-tools libisoburn dosfstools lynx syslinux"

    if prompt "Would you like to continue to remaster the ISO?"; then
        use_existing_iso
    fi
fi
