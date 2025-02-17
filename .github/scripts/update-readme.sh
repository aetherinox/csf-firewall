#!/bin/bash

# #
#   @for                https://github.com/Aetherinox/blocklists
#   @workflow           blocklist-generate.yml
#   @type               bash script
#   @summary            updates the repository readme file
#   
#   @terminal           .github/scripts/update-readme.sh
#
#   @workflow           chmod +x ".github/scripts/update-readme.sh"
#                       run_readme=".github/scripts/update-readme.sh"
#                       eval "./$run_readme"
#
#   @command            .github/scripts/update-readme.sh
#                           <ARG1>
#                       .github/scripts/update-readme.sh README.md
#                       .github/scripts/update-readme.sh clr
#
#                       📁 .github
#                           📁 scripts
#                               📄 update-readme.sh
#                           📁 workflows
#                               📄 blocklist-generate.yml
# #

APP_THIS_FILE=$(basename "$0")                          # current script file
APP_THIS_DIR="${PWD}"                                   # current script directory
APP_GITHUB_DIR="${APP_THIS_DIR}/.github"                # .github folder

# #
#   vars > colors
#
#   Use the color table at:
#       - https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
# #

RESET="\e[0m"
WHITE="\e[97m"
BOLD="\e[1m"
DIM="\e[2m"
UNDERLINE="\e[4m"
BLINK="\e[5m"
INVERTED="\e[7m"
HIDDEN="\e[8m"
BLACK="\e[38;5;0m"
FUCHSIA1="\e[38;5;125m"
FUCHSIA2="\e[38;5;198m"
RED1="\e[38;5;160m"
RED2="\e[38;5;196m"
ORANGE1="\e[38;5;202m"
ORANGE2="\e[38;5;208m"
MAGENTA="\e[38;5;5m"
BLUE1="\e[38;5;033m"
BLUE2="\e[38;5;39m"
CYAN="\e[38;5;6m"
GREEN1="\e[38;5;2m"
GREEN2="\e[38;5;76m"
YELLOW1="\e[38;5;184m"
YELLOW2="\e[38;5;190m"
YELLOW3="\e[38;5;193m"
GREY1="\e[38;5;240m"
GREY2="\e[38;5;244m"
GREY3="\e[38;5;250m"

# #
#   print an error and exit with failure
#   $1: error message
# #

function error()
{
    echo -e "  ⭕ ${GREY2}${APP_THIS_FILE}${RESET}: \n     ${BOLD}${RED}Error${NORMAL}: ${RESET}$1"
    echo -e
    exit 0
}

# #
#    Define > General
# #

SECONDS=0                                                       # set seconds count for beginning of script
APP_VER=("1" "0" "0" "0")                                       # current script version
APP_DEBUG=false                                                 # debug mode
APP_REPO="Aetherinox/blocklists"                                # repository
APP_REPO_BRANCH="main"                                          # repository branch
TEMPL_ARG_NOW=`date -u '+%m/%d/%Y %H:%M'`                       # get current date in utc format

# #
#   Color Code Test
#
#   @usage      .github/scripts/bt-transmission.sh clr
# #

function debug_ColorTest()
{
    echo -e
    echo -e "RESET ${GREY1}................ ${RESET}This is test text ███████████████${RESET}"
    echo -e "WHITE ${GREY1}................ ${WHITE}This is test text ███████████████${RESET}"
    echo -e "BOLD ${GREY1}................. ${BOLD}This is test text ███████████████${RESET}"
    echo -e "DIM ${GREY1}.................. ${DIM}This is test text ███████████████${RESET}"
    echo -e "UNDERLINE ${GREY1}............ ${UNDERLINE}This is test text ███████████████${RESET}"
    echo -e "BLINK ${GREY1}................ ${BLINK}This is test text ███████████████${RESET}"
    echo -e "INVERTED ${GREY1}............. ${INVERTED}This is test text ███████████████${RESET}"
    echo -e "HIDDEN ${GREY1}............... ${HIDDEN}This is test text ███████████████${RESET}"
    echo -e "BLACK ${GREY1}................ ${BLACK}This is test text ███████████████${RESET}"
    echo -e "FUCHSIA1 ${GREY1}............. ${FUCHSIA1}This is test text ███████████████${RESET}"
    echo -e "FUCHSIA2 ${GREY1}............. ${FUCHSIA2}This is test text ███████████████${RESET}"
    echo -e "RED1 ${GREY1}................. ${RED1}This is test text ███████████████${RESET}"
    echo -e "RED2 ${GREY1}................. ${RED2}This is test text ███████████████${RESET}"
    echo -e "ORANGE1 ${GREY1}.............. ${ORANGE1}This is test text ███████████████${RESET}"
    echo -e "ORANGE2 ${GREY1}.............. ${ORANGE2}This is test text ███████████████${RESET}"
    echo -e "MAGENTA ${GREY1}.............. ${MAGENTA}This is test text ███████████████${RESET}"
    echo -e "BLUE1 ${GREY1}................ ${BLUE1}This is test text ███████████████${RESET}"
    echo -e "BLUE2 ${GREY1}................ ${BLUE2}This is test text ███████████████${RESET}"
    echo -e "CYAN ${GREY1}................. ${CYAN}This is test text ███████████████${RESET}"
    echo -e "GREEN1 ${GREY1}............... ${GREEN1}This is test text ███████████████${RESET}"
    echo -e "GREEN2 ${GREY1}............... ${GREEN2}This is test text ███████████████${RESET}"
    echo -e "YELLOW1 ${GREY1}.............. ${YELLOW1}This is test text ███████████████${RESET}"
    echo -e "YELLOW2 ${GREY1}.............. ${YELLOW2}This is test text ███████████████${RESET}"
    echo -e "YELLOW3 ${GREY1}.............. ${YELLOW3}This is test text ███████████████${RESET}"
    echo -e "GREY1 ${GREY1}................ ${GREY1}This is test text ███████████████${RESET}"
    echo -e "GREY2 ${GREY1}................ ${GREY2}This is test text ███████████████${RESET}"
    echo -e "GREY3 ${GREY1}................ ${GREY3}This is test text ███████████████${RESET}"
    echo -e

    exit 1
}

# #
#   Helper > Show Color Chart
#   Shows a complete color charge which can be used with the color declarations in this script.
#
#   @usage      .github/scripts/bt-transmission.sh chart
# #

function debug_ColorChart()
{
    # foreground / background
    for fgbg in 38 48 ; do
        # colors
        for clr in {0..255} ; do
            # show color
            printf "\e[${fgbg};5;%sm  %3s  \e[0m" $clr $clr
            # show 6 colors per lines
            if [ $((($clr + 1) % 6)) == 4 ] ; then
                echo -e
            fi
        done

        echo -e
    done
    
    exit 1
}

# #
#   Arguments
# #

ARG1=$1

if [ "$ARG1" == "clr" ]; then
    debug_ColorTest
    exit 1
fi

if [ "$ARG1" == "chart" ]; then
    debug_ColorChart
    exit 1
fi

# #
#   Arguments > Validate
# #

if [[ -z "${ARG1}" ]]; then
    echo -e
    echo -e "  ⭕ No target file specified for script ${YELLOW1}${APP_THIS_FILE}${RESET}"
    echo -e
    exit 1
fi

# #
#   Start
# #

echo -e
echo -e "  ⭐ Starting script ${GREEN1}${APP_THIS_FILE}${RESET}"

# #
#   README > Set Sync Time
# #

sed -r -i 's@[[TEMPLATE_UPDATE]]@Last Sync: $now@g' README.md
sed -r -i "s@Last Sync: [0-9]{2}\/[0-9]{2}\/[0-9]{4} [0-9]{2}\:[0-9]{2} UTC@Last Sync: ${TEMPL_ARG_NOW} UTC@g" README.md

# #
#   Finished
# #

T=$SECONDS
D=$((T/86400))
H=$((T/3600%24))
M=$((T/60%60))
S=$((T%60))

echo -e
echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"
echo -e "  🎌  ${GREY2}Finished! ${YELLOW2}${D} days ${H} hrs ${M} mins ${S} secs${RESET}"
echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"
echo -e