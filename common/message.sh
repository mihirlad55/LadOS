#!/usr/bin/bash

[[ -n "$MESSAGE_SH_" ]] && return
MESSAGE_SH_=1


if tput setaf 0 &> /dev/null; then
    CLEAR="$(tput sgr0)"
    BOLD="$(tput bold)"
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
else
    CLEAR="\e[0m"
    BOLD="\e[1m"
    RED="\e[31m"
    GREEN="\e[32m"
    YELLOW="\e[33m"
    BLUE="\e[34m"
fi
readonly CLEAR BOLD READ GREEN YELLOW BLUE


function pause() {
    printf "${BLUE} :: ${CLEAR}${BOLD}Press enter to continue${CLEAR}${BLUE} :: ${CLEAR}"
    read
}

function ask() {
    local mesg="$1"
    local resp
    printf "${BLUE} :: ${CLEAR}${BOLD}${mesg}${CLEAR}:"
    read resp

    echo "$resp"
}

function ask_words() {
    local mesg="$1"
    local resp
    printf "${BLUE} :: ${CLEAR}${BOLD}${mesg}${CLEAR}:"
    read -a resp

    return "${resp[@]}"
}

function prompt() {
    local mesg="$1"
    local resp
    while true; do
	printf "${BLUE} :: ${CLEAR}${BOLD}${mesg}${CLEAR} [Y/n]:"
	read resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

function plain() {
    local mesg="$1"
    shift
    printf "${BOLD}    ${mesg}${CLEAR}\n" "$@"
}

function plain2() {
    local mesg="$1"
    shift
    printf "${BOLD}      ${mesg}${CLEAR}\n" "$@"
}

function plain3() {
    local mesg="$1"
    shift
    printf "${BOLD}        ${mesg}${CLEAR}\n" "$@"
}

function msg() {
    local mesg="$1"
    shift
    printf "${GREEN}==>${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@"
}

function msg2() {
    local mesg="$1"
    shift
    printf "${BLUE} '-->${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@"
}

function warn() {
    local mesg="$1"
    shift
    printf "${YELLOW}==> WARNING:${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@" >&2
}

function error() {
    local mesg="$1"
    shift
    printf "${RED}==> ERROR:${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@" >&2
}
