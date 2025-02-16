#!/bin/bash

# #
#   @for                https://github.com/Aetherinox/csf-firewall
#   @workflow           blocklist-generate.yml
#   @type               bash script
#   @summary            compiles a blocklist which can be used in the BitTorrent client Transmission.
#   
#   @terminal           .github/scripts/bt-transmission.sh
#
#   @workflow           chmod +x ".github/scripts/bt-transmission.sh""
#                       run_bt=".github/scripts/bt-transmission.sh"
#                       eval "./$run_bt"
#
#   @command            bt-transmission.sh
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

SECONDS=0                                                                                       # set seconds count for beginning of script
APP_VER=("1" "0" "0" "0")                                                                       # current script version
APP_DEBUG=false                                                                                 # debug mode
APP_REPO="Aetherinox/blocklists"                                                                # repository
APP_REPO_BRANCH="main"                                                                          # repository branch
APP_FILE_TEMP="bt_temp"                                                                         # name of temp file to use throughout process
APP_FILE_PERM_DIR="blocklists/transmission"                                                     # folder where perm files will be stored
APP_FILE_PERM="${APP_FILE_PERM_DIR}/blocklist"                                                  # name of file to save at the end of the process
APP_FILE_PERM_EXT="ipset"                                                                       # name of final file extension
APP_ZIP_FILE="wael.list.p2p.zip"                                                                # zip to download from waelisa/Best-blocklist
APP_ZIP_READ_FILE="wael.list.p2p"                                                               # file to target and read inside the zip
APP_ZIP_URL="https://raw.githubusercontent.com/waelisa/Best-blocklist/main/${APP_ZIP_FILE}"     # location to download bt blocklist zip
APP_URL_CBUCKET="https://mirror.codebucket.de/transmission/blocklist.p2p"
APP_URL_IBL="https://www.iblocklist.com/lists.php"
APP_AGENT="Mozilla/5.0 (Windows NT 10.0; WOW64) "\
"AppleWebKit/537.36 (KHTML, like Gecko) "\
"Chrome/51.0.2704.103 Safari/537.36"                                                            # user agent used with curl

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
#   List of websites to download transmission rules from
# #

domain_list=(
    "https://reputation.alienvault.com/reputation.generic"
    "https://www.binarydefense.com/banlist.txt"
    "https://lists.blocklist.de/lists/all.txt"
    "https://iplists.firehol.org/files/bruteforceblocker.ipset"
    "https://cinsscore.com/list/ci-badguys.txt"
    "https://iplists.firehol.org/files/cruzit_web_attacks.ipset"
    "https://www.darklist.de/raw.php"
    "https://rules.emergingthreats.net/blockrules/compromised-ips.txt"
    "https://feodotracker.abuse.ch/downloads/ipblocklist.txt"
    "https://iplists.firehol.org/files/nixspam.ipset"
    "https://sslbl.abuse.ch/blacklist/sslipblacklist.txt"
    "https://pgl.yoyo.org/adservers/iplist.php?ipformat=plain&showintro=0&mimetype=plaintext"
)

# #
#   Start
# #

echo -e
echo -e "  ⭐ Starting script ${GREEN1}${APP_THIS_FILE}${RESET}"

# #
#	Loop each website above and download the rules
# #

echo -e "  🌎  ${WHITE}Downloading files from domain list${RESET}"
for i in ${domain_list[@]}; do
    echo -e "      📄  ${GREY1}Downloading ${GREEN1}${i}${RESET}"
	wget -q "${i}" -O - | sed "/^#.*/d" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort --unique >> "${APP_FILE_TEMP}_1.txt"
done

# #
#	combined_1 > Generate BT combined file
# #

echo -e "  📄  ${WHITE}Migrating ${BLUE2}${APP_FILE_TEMP}_1.txt${RESET} => ${BLUE2}${APP_FILE_TEMP}_2.txt${RESET}"
while read line; do 
	echo "blocklist:$line-$line"; 
done < "${APP_FILE_TEMP}_1.txt" > "${APP_FILE_TEMP}_2.txt"

# #
#   combined_1 > Download iblocklist.com rules, filter out nonsense and add to file
# #

echo -e "  🌎  ${WHITE}Downloading ${GREEN1}${APP_URL_IBL}${RESET}${GREYL} => ${BLUE2}${APP_FILE_TEMP}_2.txt${RESET}"
curl -sSL -A "${APP_AGENT}" "${APP_URL_IBL}" \
        | sed -n "s/.*value='\(http:.*\)'.*/\1/p" \
        | sed "s/\&amp;/\&/g" \
        | sed "s/http/\"http/g" \
        | sed "s/gz/gz\"/g" \
        | xargs curl -s -L \
        | gunzip \
        | egrep -v '^#' \
        | sed "/^$/d" >> "${APP_FILE_TEMP}_2.txt"
        
# #
#	combined_1 > Codebucket > Blocklist
#
#	Includes:
#		- spamhaus
#		- alienvault_reputation
#		- blocklist_de
#		- bruteforceblocker
#		- ciarmy
#		- cruzit_web_attacks
#		- nixspam
#		- yoyo_adservers
#		- dm_tor
#		- dshield
# #

echo -e "  🌎  ${RESET}Downloading ${GREEN1}${APP_URL_CBUCKET}${RESET} => ${BLUE2}${APP_FILE_TEMP}_2.txt${RESET}"
curl -sSL -A "${APP_AGENT}" "${APP_URL_CBUCKET}" >> "${APP_FILE_TEMP}_2.txt"

# #
#	Download zip and extract rules
# #

echo -e "  🗄️   ${RESET}Downloading zip ${GREEN1}${APP_ZIP_URL}${RESET}"
curl -sSLO -A "${APP_AGENT}" "${APP_ZIP_URL}"

# #
#	Read target file in zip and filter out the rules, add to temp file
# #

echo -e "  🗜️   ${RESET}Unzipping ${ORANGE2}${APP_ZIP_FILE}${RESET} and reading ${ORANGE2}${APP_ZIP_READ_FILE}${RESET} => ${BLUE2}${APP_FILE_TEMP}_2.txt${RESET}"
P2P=$(unzip -p "${APP_ZIP_FILE}" "${APP_ZIP_READ_FILE}" | sed "/^#.*/d" | grep -Ev "^[0-9][0-9][0-9]\.[0-9][0-9][0-9].*" >> "${APP_FILE_TEMP}_2.txt")

# #
#   Creating Perm Folder
# #

echo -e "  📁  ${WHITE}Create folder ${BLUE2}${APP_FILE_PERM_DIR}${RESET}"
mkdir -p ${APP_FILE_PERM_DIR}

# #
#	Read temp file, sort data, output to final version
# #

echo -e "  〽️  ${WHITE}Sorting ${BLUE2}${APP_FILE_TEMP}_2.txt${RESET} => ${YELLOW1}${APP_FILE_PERM}.${APP_FILE_PERM_EXT}${RESET}"
sort --unique "${APP_FILE_TEMP}_2.txt" > "${APP_FILE_PERM}.${APP_FILE_PERM_EXT}"

# #
#   gzip final version
# #

echo -e "  📦  ${WHITE}Creating ${YELLOW1}${APP_FILE_PERM}.gz${RESET}"
gzip -c "${APP_FILE_PERM}.${APP_FILE_PERM_EXT}" > "${APP_FILE_PERM}.gz"

# #
#   Confirm gz file created
# #

if [ -f "${APP_FILE_PERM}.gz" ]; then
    echo -e "  ✔️   ${GREEN1}Successfully created package ${YELLOW1}${APP_FILE_PERM}.gz${RESET}"
else
    echo -e "  ⭕   ${RED1}Could not create ${YELLOW1}${APP_FILE_PERM}.gz -- aborting${RESET}"
    exit 1
fi

# #
#   Cleanup
# #

if [ -f "${APP_FILE_TEMP}_1.txt" ]; then
    echo -e "  🗑️   ${GREY2}Cleanup ${APP_FILE_TEMP}_1.txt${RESET}"
    rm "${APP_FILE_TEMP}_1.txt"
fi

if [ -f "${APP_FILE_TEMP}_2.txt" ]; then
    echo -e "  🗑️   ${GREY2}Cleanup ${APP_FILE_TEMP}_2.txt${RESET}"
    rm "${APP_FILE_TEMP}_2.txt"
fi

if [ -f "${APP_ZIP_FILE}" ]; then
    echo -e "  🗑️   ${GREY2}Cleanup ${APP_ZIP_FILE}${RESET}"
    rm "${APP_ZIP_FILE}"
fi

if [ -f "${APP_ZIP_READ_FILE}" ]; then
    echo -e "  🗑️   ${GREY2}Cleanup ${APP_ZIP_READ_FILE}${RESET}"
    rm "${APP_ZIP_READ_FILE}"
fi

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