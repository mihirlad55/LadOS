#!/usr/bin/bash

case "$1" in
    full | full_no_check)
        if ! check_conflicts; then
            exit 1
        fi

        if type -p check_conf && type -p load_conf; then
            qecho "Checking and loading configuration..."
            check_conf && load_conf
        fi

        if type -p install_dependencies; then
            install_dependencies
        fi

        if type -p prepare; then
            qecho "Beginning prepare..."
            prepare
        fi

        qecho "Installing feature..."
        install

        if type -p post_install; then
            qecho "Starting post_install..."
            post_install
        fi

        if type -p cleanup; then
            qecho "Starting cleanup..."
            cleanup
        fi

        if [[ "$1" = "full" ]] && type -p check_install; then
            qecho "Checking if feature was installed correctly..."
            check_install
        fi
        ;;

    name)
        echo "$feature_name"
        ;;

    desc)
        echo "$feature_desc"
        ;;

    conflicts)
        echo "${conflicts[*]}"
        ;;

    check_conf | load_conf | check_install | prepare | install |  post_install \
        | cleanup | check_conflicts)
        if type -p "$1"; then
            qecho "Starting $1..."
            res=0
            $1 || res=$?
            qecho "Done $1"
            exit "$res"
        else
            qecho "$1 is not defined for this feature"
            exit 1
        fi
        ;;

    uninstall)
        if ! check_install &> /dev/null; then
            echo "$feature_name is not installed"
            exit 1
        fi

        if prompt "Are you sure you want to uninstall $feature_name?"; then
            echo "Uninstalling $feature_name..."

            if has_dependencies; then
                echo -n "$feature_name depends on ${depends_pacman[*]} "
                echo "${depends_aur[*]} ${depends_pip3[*]}"
                if prompt "Would you like to uninstall these dependencies?"; then
                    uninstall_dependencies
                fi
            fi

            if type -p uninstall; then
                uninstall
            fi

            echo "Finished uninstalling $feature_name"
        fi
        ;;

    install_dependencies)
        if has_dependencies; then
            install_dependencies
        else
            qecho "No dependencies to install"
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
