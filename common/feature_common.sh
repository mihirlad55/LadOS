#!/usr/bin/bash

# If user is root or sudo does not exist, don't use sudo
shopt -s expand_aliases
( [[ "$USER" = "root" ]] || ! command -v sudo &> /dev/null ) && alias sudo=

function print_usage() {
    echo "usage: feature.sh [ full | name | desc | check_conf | load_conf | check_install | prepare | install | post_install | cleanup | install_dependencies | help ]"
}

function install_dependencies() {
    if [[ "${depends_pacman[@]}" != "" ]]; then
        echo "Installing ${depends_pacman[@]}..."
        sudo pacman -S ${depends_pacman[@]} --noconfirm --needed
        echo "Done installing pacman packages for $feature_name"
    fi

    if [[ "${depends_aur[@]}" != "" ]]; then
        echo "Installing ${depends_aur[@]}..."
        yay -S ${depends_aur[@]} --noconfirm --needed
        echo "Done installing aur packages for $feature_name"
    fi

    if [[ "${depends_pip3[@]}" != "" ]]; then
        if ! command -v pip3 > /dev/null; then
            sudo pacman -S python-pip --noconfirm --needed
        fi

        echo "Installing ${depends_pip3[@]}..."
        sudo pip3 install ${depends_pip3[@]}
        echo "Done installing pip3 packages for $feature_name"
    fi
}


case "$1" in
    full)
        if type -p check_conf && type -p load_conf; then
            echo "Checking and loading configuration..."
            check_conf && load_conf
        fi

        if type -p install_dependencies; then
            install_dependencies
        fi

        if type -p prepare; then
            echo "Beginning prepare..."
            prepare
        fi

        echo "Installing feature..."
        install

        if type -p post_install; then
            echo "Executing post_install..."
            post_install
        fi

        if type -p cleanup; then
            echo "Starting cleanup..."
            cleanup
        fi

        if type -p check_install; then
            echo "Checking if feature was installed correctly..."
            check_install
        fi

        ;;
    name)
        echo "$feature_name"
        ;;
    desc)
        echo "$feature_desc"
        ;;
    check_conf | load_conf | check_install | prepare | install |  post_install \
        | cleanup)
        if type -p "$1"; then
            echo "Beginning $1..."
            $1
            echo "Finished $1"
        else
            echo "$1 is not defined for this feature"
            exit 1
        fi
        ;;

    install_dependencies)
        if [[ "${depends_pacman[@]}" != "" ]] || [[ "${depends_aur[@]}" != "" ]]; then
            install_dependencies
        else
            echo "No dependencies to install"
            exit 1
        fi
        ;;

    help)
        print_usage
        ;;
    *)
        print_usage
        exit 1
esac
