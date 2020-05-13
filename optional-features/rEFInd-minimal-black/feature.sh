#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="rEFInd-minimal-black"
feature_desc="Install and setup rEFInd with minimal-black theme"

provides=()
new_files=("/boot/EFI/refind/themes" \
    "/boot/EFI/refind/refind.conf" \
    "/boot/EFI/refind/refind-manual.conf" \
    "/boot/EFI/refind/refind-options.conf")
modified_files=()
temp_files=("/tmp/refind-options.conf" \
    "/tmp/refind-manual.conf")

depends_aur=()
depends_pacman=(refind)


function check_install() {
    HEAD="$(cat /boot/EFI/refind/themes/rEFInd-minimal-black/.git/HEAD)"
    if grep "include refind-manual.conf" /boot/EFI/refind/refind.conf > /dev/null &&
        [[ -e "/boot/EFI/refind/refind-options.conf" ]] &&
        [[ -e "/boot/EFI/refind/refind-manual.conf" ]] &&
        [[ -d "/boot/EFI/refind/themes/rEFInd-minimal-black" ]]; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function prepare() {
    qecho "Copying configuration files to /tmp..."
    cp $BASE_DIR/refind-options.conf /tmp/refind-options.conf
    cp $BASE_DIR/refind-manual.conf /tmp/refind-manual.conf
}

function install() {
    qecho "Running refind-install..."
    sudo refind-install

    qecho "Copying theme to /boot/EFI/refind/themes..."
    sudo mkdir -p /boot/EFI/refind/themes
    sudo rm -rf /boot/EFI/refind/themes/rEFInd-minimal-black
    sudo git clone https://github.com/andersfischernielsen/rEFInd-minimal-black.git /boot/EFI/refind/themes/rEFInd-minimal-black

    swap_path=$(cat /etc/fstab | grep -P -B 1 \
        -e "UUID=[a-zA-Z0-9\-]*[\t ]+none[\t ]+swap" | head -n1 | sed 's/# *//')
    root_path=$(cat /etc/fstab | grep -P -B 1 \
        -e "UUID=[a-zA-Z0-9\-]*[\t ]+/[\t ]+" | head -n1 | sed 's/# *//')

    partuuid=$(blkid -s PARTUUID -o value $root_path)

    sed -i /tmp/refind-options.conf -e "s/root=PARTUUID=[a-z0-9\-]*/root=PARTUUID=$partuuid/"
    sed -i /tmp/refind-options.conf -e "s;resume=;resume=$swap_path;"

    echo "Opening configuration files for any changes. The root PARTUUID has already been set along with the swap paritition path for resume"
    read -p "Press enter to continue..."

    if [[ "$EDITOR" != "" ]]; then
        $EDITOR /tmp/refind-options.conf
        $EDITOR /tmp/refind-manual.conf
    else
        vim /tmp/refind-options.conf
        vim /tmp/refind-manual.conf
    fi

    qecho "Copying configuration files to /boot/EFI/refind/..."
    sudo install -Dm 755 /tmp/refind-options.conf /boot/EFI/refind/refind-options.conf
    sudo install -Dm 755 /tmp/refind-manual.conf /boot/EFI/refind/refind-manual.conf
    sudo install -Dm 755 /usr/share/refind/refind.conf-sample /boot/EFI/refind/refind.conf

    echo "
    include refind-manual.conf
    include refind-options.conf
    include themes/rEFInd-minimal-black/theme.conf
    " | sudo tee -a /boot/EFI/refind/refind.conf > /dev/null

    qecho "Done"
}

function cleanup() {
    qecho "Removing ${temp_files[@]}..."
    rm -f /tmp/refind-options.conf
    rm -f /tmp/refind-manual.conf
}

source "$LAD_OS_DIR/common/feature_common.sh"
