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
        ${!func_num}
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

function image_usb() {
    local ISO_PATH="$1"

    if prompt "Would you like to write this image to a USB? Note this will wipe your USB."; then
        read -p "Please insert your usb and press enter to continue"
        ls /dev

        read -p "Please enter the path to your usb (i.e. /dev/sdX): " path
        
        sudo dd bs=4M if="$ISO_PATH" of=$path status=progress oflag=sync
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
            if [[ "$epoch" = "" ]]; then
                pkg_path=$PKG_PATH/${pkgname}-${pkgver}*.pkg.tar.xz
            else
                pkg_path=$PKG_PATH/${pkgname}-${epoch}:${pkgver}*.pkg.tar.xz
            fi

            echo $pkg_path
            if ! test -f $pkg_path; then
                cd "/var/tmp/$pkg_name"
                makepkg -s
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
    local TEMP_DB_PATH="/tmp"

    sudo pacman -Syu --noconfirm
    sudo pacman -S pacman-contrib --needed --noconfirm

    pacman_packages=($(cat "$LAD_OS_DIR/packages.csv" | \
        grep "^.*,.*,system," | \
        cut -d ',' -f1))

    for pkg in ${pacman_packages[@]}; do
        target="$(pacman -Spd $pkg | \
            grep -v -e "^https" | \
            sed -e "s;file://;;" | \
            sed -e 's;^.*/;;')"

        if [[ "$target" != "" ]] && [[ ! -f "$PKG_PATH/$target" ]]; then
            echo "Found package $pkg at $target"
            echo "Copying $pkg to $PKG_PATH..."
            sudo cp -f "$target" "$PKG_PATH"
        fi
    done

    echo "Removing older packages..."
    paccache -rk1 -c "$PKG_PATH"

    sudo pacman -Sy --noconfirm --dbpath "$TEMP_DB_PATH"

    sudo pacman -S ${pacman_packages[@]} \
        -w --cachedir "$PKG_PATH" \
        --dbpath "$TEMP_DB_PATH" \
        --noconfirm --needed
}


function build_from_scratch() {
    ARCH_ISO_DIR="/var/tmp/archiso"
    AIRROOTFS_DIR="$ARCH_ISO_DIR/airootfs"
    LOCAL_REPO_PATH="$AIRROOTFS_DIR/LadOS/localrepo"
    PKG_PATH="$LOCAL_REPO_PATH/pkg"

    echo "Removing old ISOs..."
    rm -f $BASE_DIR/*.iso
    
    echo "Cleaning up work directory..."
    sudo rm -rf "$ARCH_ISO_DIR/work"

    yay -S archiso-git --needed --noconfirm

    sudo cp -af /usr/share/archiso/configs/releng "$ARCH_ISO_DIR"

    sudo cp -rf -t "$AIRROOTFS_DIR" "$LAD_OS_DIR"

    if prompt "Pre-compile and download packages?"; then
        sudo mkdir -p "$PKG_PATH"

        build_aur_packages "$PKG_PATH"

        copy_pacman_packages "$PKG_PATH"

        (cd "$LOCAL_REPO_PATH" && sudo repo-add localrepo.db.tar.gz pkg/*)
    fi

    # Avoid permission errors
    sudo chown -R root:root "$ARCH_ISO_DIR"


    (
        cd $ARCH_ISO_DIR
        sudo ./build.sh \
            -N "$ISO_NAME" \
            -P "$ISO_PUBLISHER" \
            -A "$ISO_APPLICATION" \
            -o "$BASE_DIR"
    )

    out="$BASE_DIR/$(date +$ISO_NAME-%Y.%m.%d-x86_64.iso)"
    echo "ISO has been created at $out"
    image_usb "$out"

    echo "Done"
    exit 0
}


function download_iso() {
    archiso_path="/tmp/archiso.iso"
    local top_mirror="$(cat /etc/pacman.d/mirrorlist | \
        grep "^Server = " | \
        head -n1 | \
        cut -d'=' -f2 | \
        awk '{$1=$1; print}')"

    local url_root="$(echo "$top_mirror" | \
        sed -e "s;\$repo/os/\$arch;iso/$arch_date;")"

    local iso_name="$(curl -Ls $url_root/iso/latest | \
        grep -o -P -e "archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64\.iso" | \
        head -n1)"

    local url_iso="$url_root/$iso_name"

    echo "Downloading archiso..."
    curl $url_iso --output "$archiso_path"
}

function use_existing_iso() {
    read -p "Enter path to iso: " archiso_path

    remaster
}

function remaster() {
    MOUNT_PATH="/mnt/archiso"
    CUSTOM_ISO_PATH="/tmp/customiso"
    AIROOTFS_PATH="$CUSTOMISO_PATH/arch/x86_64/airootfs.sfs"
    SHA512_AIROOTFS_PATH="$CUSTOMISO_PATH/arch/x86_64/airootfs.sha512"
    SQUASHFS_ROOT_PATH="$CUSTOMISO_PATH/arch/x86_64/squashfs-root"

    sudo pacman -S archiso cdrtools --needed --noconfirm
    
    sudo mkdir -p "$MOUNT_PATH"

    echo "Mounting archiso to $MOUNT_PATH..."
    sudo mount -t iso9660 -o loop "$archiso_path" "$MOUNT_PATH"

    echo  "Copying archiso to $CUSTOM_ISO_PATH..."
    sudo mkdir -p "$CUSTOM_ISO_PATH"
    sudo cp -a $MOUNT_PATH/* "$CUSTOM_ISO_PATH"

    echo "Unsquashing airootfs.sfs..."
    sudo unsquashfs "$AIROOTFS_PATH" -d "$SQUASHFS_ROOT_PATH"

    echo "Copying over LadOS to the squashfs-root..."
    sudo cp -rf "$BASE_DIR" "$SQUASHFS_ROOT_PATH"

    echo "Removing the old airootfs.sfs..."
    sudo rm "$AIROOTFS_PATH"

    echo "Resquashing into airootfs.sfs..."
    sudo mksquashfs "$SQUASHFS_ROOT_PATH" "$AIROOTFS_PATH" -comp xz 

    echo "Removing squashfs-root"
    sudo rm -rf "$SQUASHFS_ROOT_PATH"

    echo "Updating SHA512 checksum..."
    sudo sha512sum "$AIROOTFS_PATH" | sudo tee "$SHA512_AIROOTFS_PATH"

    echo "Creating new iso..."
    local LABEL="$(cat /mnt/archiso/loader/entries/archiso-x86_64.conf | \
        tail -n1 | \
        grep -o "archisolabel=.*$" | \
        cut -d'=' -f2)"

    local out="$ISO_OUT_DIR/$ISO_NAME.iso"
    sudo rm -f "$out"

    sudo genisoimage -l -r -J \
        -V "$LABEL" \
        -b isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -c isolinux/boot.cat \
        -o "$out" \
        $CUSTOM_ISO_PATH

    image_usb "$out"

    echo "Done!"
    exit 0
}


function remaster_iso() {
    show_menu "Build from scratch" \
        "Download ISO"      "download_iso" \
        "Use existing ISO"  "use_existing_iso"
}


show_menu "Make ISO" \
    "Build from scratch"    "build_from_scratch" \
    "Remaster ISO"          "remaster_iso" \
    "Exit"                  "exit 0"
