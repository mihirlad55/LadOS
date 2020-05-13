#!/usr/bin/bash

# Get absolute path to directory of script
BASE_DIR="$( readlink -f "$(dirname "$0")" )"
# Get absolute path to root of repo
LAD_OS_DIR="$( echo $BASE_DIR | grep -o ".*/LadOS/" | sed 's/.$//')"

feature_name="vifm"
feature_desc="Install vifm with image previews"

provides=()
new_files=("/usr/local/bin/vifmrun" \
    "$HOME/.vifm/scripts/vifmimg")
modified_files=("/usr/share/applications/vifm.desktop")
temp_files=("/tmp/epub-thumbnailer")

depends_aur=(fontpreview)
depends_pacman=(ffmpeg ffmpegthumbnailer vifm python python-pip poppler)
depends_pip3=()


function check_install() {
    if command -v epub-thumbnailer &> /dev/null &&
        [[ -f "/usr/local/bin/vifmrun" ]] &&
        [[ -f "$HOME/.vifm/scripts/vifmimg" ]] &&
        grep -q -P /usr/share/applications/vifm.desktop -e "Exec=vifmrun\b"; then
        qecho "$feature_name is installed"
        return 0
    else
        echo "$feature_name is not installed" >&2
        return 1
    fi
}

function install() {
    qecho "Cloning epub-thumbnailer..."
    git clone https://github.com/marianosimone/epub-thumbnailer /tmp/epub-thumbnailer

    qecho "Installing epub-thumbnailer..."
    sudo python /tmp/epub-thumbnailer/install.py install

    qecho "Installing vifmimg and vifmrun..."
    sudo install -Dm 755 $BASE_DIR/vifmrun /usr/local/bin/vifmrun
    command install -Dm 755 $BASE_DIR/vifmimg $HOME/.vifm/scripts/vifmimg

    qecho "Updating vifm.desktop..."
    sudo sed -i 's/Exec=vifm\b/Exec=vifmrun/' /usr/share/applications/vifm.desktop
}

function cleanup() {
    qecho "Removing /tmp/epub-thumbnailer..."
    rm -rf /tmp/epub-thumbnailer
}


source "$LAD_OS_DIR/common/feature_common.sh"
