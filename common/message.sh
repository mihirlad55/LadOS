#!/usr/bin/bash

# Include guard
[[ -n "$MESSAGE_SH_" ]] && return
MESSAGE_SH_=1


# Get escape codes, for formatting, but prefer tput
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


################################################################################
# Wait for user to press enter to continue
#   Globals:
#     BLUE
#     CLEAR
#     BOLD
#   Arguments:
#     None
#   Outputs:
#     stderr: Press enter to continue (colorized)
################################################################################
function pause() {
    # Output to stderr, so actual response can be captured and so if a script
    # is blocking stdout, the prompt is not hidden
    printf "${BLUE} :: ${CLEAR}${BOLD}Press enter to continue${CLEAR}${BLUE} :: ${CLEAR}" >&2
    read
}

################################################################################
# Prompt user for input and return response of user
#   Globals:
#     BLUE
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to prompt user
#   Outputs:
#     stderr: <mesg> (colorized)
#     stdout: response of user
################################################################################
function ask() {
    local mesg="$1"

    # Output to stderr, so actual response can be captured and so if a script
    # is blocking stdout, the prompt is not hidden
    printf "${BLUE} :: ${CLEAR}${BOLD}${mesg}${CLEAR}: " >&2

    read -r resp
    echo "$resp"
}

################################################################################
# Prompt user for input and return response of user as array of words
#   Globals:
#     BLUE
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to prompt user
#   Outputs:
#     stderr: <mesg> (colorized)
#     stdout: response of user as array of words
################################################################################
function ask_words() {
    local mesg="$1"

    # Output to stderr, so actual response can be captured and so if a script
    # is blocking stdout, the prompt is not hidden
    printf "${BLUE} :: ${CLEAR}${BOLD}${mesg}${CLEAR}: " >&2

    read -ar resp
    echo "${resp[@]}"
}

################################################################################
# Prompt user a yes/no question
#   Globals:
#     BLUE
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to prompt user
#   Outputs:
#     stderr: <mesg> [Y/n] (colorized)
#   Returns
#     0, if user responds with "y" or "Y"
#     1, if user responds with "n" or "N"
################################################################################
function prompt() {
    local mesg="$1"
    local resp

    while true; do
        printf "${BLUE} :: ${CLEAR}${BOLD}${mesg}${CLEAR} ${BLUE}[Y/n]:${CLEAR} " >&2
        read resp

        if [[ "$resp" = "y" ]] || [[ "$resp" = "Y" ]]; then
            return 0
        elif [[ "$resp" = "n" ]] || [[ "$resp" = "N" ]]; then
            return 1
        fi
    done
}

################################################################################
# Print message in bold without any symbols (same indent as msg)
#   Globals:
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     <mesg> (colorized)
################################################################################
function plain() {
    local mesg="$1"
    shift
    printf "${BOLD}    ${mesg}${CLEAR}\n" "$@"
}

################################################################################
# Print message in bold without any symbols (same indent as msg2)
#   Globals:
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     <mesg> (colorized)
################################################################################
function plain2() {
    local mesg="$1"
    shift
    printf "${BOLD}      ${mesg}${CLEAR}\n" "$@"
}

################################################################################
# Print message in bold without any symbols (same indent as msg3)
#   Globals:
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     <mesg> (colorized)
################################################################################
function plain3() {
    local mesg="$1"
    shift
    printf "${BOLD}        ${mesg}${CLEAR}\n" "$@"
}

################################################################################
# Print level one message
#   Globals:
#     GREEN
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     <mesg> (colorized)
################################################################################
function msg() {
    local mesg="$1"
    shift
    printf "${GREEN}══>${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@"
}

################################################################################
# Print level two message
#   Globals:
#     BLUE
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     <mesg> (colorized)
################################################################################
function msg2() {
    local mesg="$1"
    shift
    printf "${BLUE} ╚══>${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@"
}

################################################################################
# Print level three message
#   Globals:
#     BLUE
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     <mesg> (colorized)
################################################################################
function msg3() {
    local mesg="$1"
    shift
    printf "${BLUE}   ───>${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@"
}

################################################################################
# Print level four message
#   Globals:
#     BLUE
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     <mesg> (colorized)
################################################################################
function msg4() {
    local mesg="$1"
    shift
    printf "${BLUE}     └-─>${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@"
}

################################################################################
# Print warning
#   Globals:
#     YELLOW
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     stderr: WARNING: <mesg> (colorized)
################################################################################
function warn() {
    local mesg="$1"
    shift
    printf "${YELLOW}══> WARNING:${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@" >&2
}

################################################################################
# Print error
#   Globals:
#     RED
#     CLEAR
#     BOLD
#   Arguments:
#     mesg, string to print with newline
#     ..., strings to print (without newline)
#   Outputs:
#     stderr: ERROR: <mesg> (colorized)
################################################################################
function error() {
    local mesg="$1"
    shift
    printf "${RED}══> ERROR:${CLEAR}${BOLD} ${mesg}${CLEAR}\n" "$@" >&2
}
