#!/usr/bin/bash

function print_usage() {
    echo "usage: feature.sh [ full | name | desc | check_defaults | load_defaults | check_install | prepare | install | post_install | cleanup | install_dependencies ]"
}

function install_dependencies() {
    echo "Installing ${depends_pacman[@]}..."
    sudo pacman -S ${depends_pacman[@]} --noconfirm --needed

    echo "Installing ${depends_aur[@]}..."
    yay -S ${depends_aur[@]} --noconfirm --needed

    echo "Done installing dependencies for $feature_name"
}


case "$1" in
    full)
        if type -p install_dependencies; then
            install_dependencies
        fi

        if type -p prepare; then
            echo "Beginning prepare..."
            prepare
        fi

        if type -p check_defaults && type -p load_defaults; then
            echo "Checking and loading defaults..."
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

        ;;
    name)
        echo "$feature_name"
        ;;
    desc)
        echo "$feature_desc"
        ;;
    check_defaults | load_defaults | check_install | prepare | install | \
        post_install | cleanup | install_dependencies)
        if type -p "$1"; then
            $1
        else
            echo "$1 is not defined for this feature"
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
