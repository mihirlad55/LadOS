#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

REFIND_CONF_ADD="$BASE_DIR/refind.conf.add"
REFIND_THEME_URL="https://github.com/andersfischernielsen/rEFInd-minimal-black.git"
REFIND_PATH="/boot/EFI/refind"
REFIND_CONF="$REFIND_PATH/refind.conf"
REFIND_THEME_PATH="$REFIND_PATH/themes/rEFInd-minimal-black"


feature_name="rEFInd-minimal-black"
feature_desc="Install and setup rEFInd with minimal-black theme"

provides=()
new_files=("/boot/EFI/refind/themes" \
    "/boot/EFI/refind/refind.conf" \
    "/boot/EFI/refind/refind-manual.conf" \
    "/boot/EFI/refind/refind-options.conf")
modified_files=()
temp_files=("/tmp/refind-options.conf" \
    "/tmp/refind-manual.conf" \
    "/tmp/rEFInd-minimal-black")

depends_aur=()
depends_pacman=(refind)


function check_refind_conf() {
    refind_conf_add_first_line="$(head -n1 "$REFIND_CONF_ADD")"
    num_of_lines="$(wc -l "$REFIND_CONF_ADD" | cut -d' ' -f1)"
    after_context=$(( num_of_lines - 1 ))
    refind_includes="$(grep -F "$refind_conf_add_first_line" -A $after_context "$REFIND_CONF")"
    echo "$refind_includes" | diff "$REFIND_CONF_ADD" - > /dev/null
}

function check_install() {
    HEAD="$(cat /boot/EFI/refind/themes/rEFInd-minimal-black/.git/HEAD)"
    if check_refind_conf &&
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
    cp -f $BASE_DIR/refind-options.conf /tmp/refind-options.conf
    cp -f $BASE_DIR/refind-manual.conf /tmp/refind-manual.conf
}

function install() {
    qecho "Running refind-install..."
    sudo refind-install

    qecho "Copying theme to $REFIND_PATH/themes..."
    sudo mkdir -p "$REFIND_PATH"/themes
    sudo rm -rf "$REFIND_THEME_PATH"

    if [[ ! -d "/tmp/rEFInd-minimal-black" ]]; then
        git clone --depth 1 $VERBOSITY_FLAG "$REFIND_THEME_PATH" /tmp/rEFInd-minimal-black
    fi

    (shopt -s dotglob; sudo cp -rf /tmp/rEFInd-minimal-black/* "$REFIND_THEME_PATH")

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

    qecho "Copying configuration files to $REFIND_PATH..."
    sudo install -Dm 755 /tmp/refind-options.conf $REFIND_PATH/refind-options.conf
    sudo install -Dm 755 /tmp/refind-manual.conf $REFIND_PATH/refind-manual.conf
    sudo install -Dm 755 /usr/share/refind/refind.conf-sample $REFIND_PATH/refind.conf

    echo | sudo tee -a "$REFIND_CONF" > /dev/null
    cat "$REFIND_CONF_ADD" | sudo tee -a "$REFIND_CONF" > /dev/null

    qecho "Done"
}

function cleanup() {
    qecho "Removing ${temp_files[@]}..."
    rm -rf "${temp_files[@]}"
}

function uninstall() {
    qecho "Removing ${new_files[@]}..."
    sudo rm -rf "${new_files[@]}"

}


source "$LAD_OS_DIR/common/feature_common.sh"
