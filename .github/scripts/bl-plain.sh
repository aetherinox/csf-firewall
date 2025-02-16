#!/bin/bash

# #
#   @for                https://github.com/Aetherinox/csf-firewall
#   @workflow           blocklist-generate.yml
#   @type               bash script
#   @summary            generate ipset from online plain-text url / page | URLs: VARARG
#                       Uses a URL to fetch a plaintext file from the internet.
#                       Then reads each line, counts how many IP addresses and subnets it contains, and removes 
#                       any comments the original file had, including text that starts with the characters `;` and `#`.
#                       Supports multiple URLs as arguments.
# 
#   @terminal           .github/scripts/bl-plain.sh \
#                           blocklists/03_spam_spamhaus.ipset \
#                           https://www.spamhaus.org/drop/drop.txt
#
#   @workflow           chmod +x ".github/scripts/bl-plain.sh"
#                       run_spamhaus=".github/scripts/bl-plain.sh 03_spam_spamhaus.ipset https://www.spamhaus.org/drop/drop.txt"
#                       eval "./$run_spamhaus"
#
#   @uage               bl-plain.sh
#                           <ARG_SAVEFILE>
#                           <URL_1>
#                           <URL_2>
#                           {...}
#                       bl-plain.sh 03_spam_spamhaus.ipset URL_1 
#                       bl-plain.sh 03_spam_spamhaus.ipset URL_1 URL_2 URL_3
#
#                       📁 .github
#                           📁 scripts
#                               📄 bl-plain.sh
#                           📁 workflows
#                               📄 blocklist-generate.yml
#
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
#   Sort Results
#
#   @usage          line=$(parse_spf_record "${ip}" | sort_results)
# #

sort_results()
{
	declare -a ipv4 ipv6

	while read -r line ; do
		if [[ ${line} =~ : ]] ; then
			ipv6+=("${line}")
		else
			ipv4+=("${line}")
		fi
	done

	[[ -v ipv4[@] ]] && printf '%s\n' "${ipv4[@]}" | sort -g -t. -k1,1 -k 2,2 -k 3,3 -k 4,4 | uniq
	[[ -v ipv6[@] ]] && printf '%s\n' "${ipv6[@]}" | sort -g -t: -k1,1 -k 2,2 -k 3,3 -k 4,4 -k 5,5 -k 6,6 -k 7,7 -k 8,8 | uniq
}

# #
#   Arguments
#
#   This bash script has the following arguments:
#
#       ARG_SAVEFILE        (str)       file to save IP addresses into
#       { ... }             (varg)      list of URLs to download files from
# #

ARG_SAVEFILE=$1

# #
#   Arguments > Validate
# #

if [[ -z "${ARG_SAVEFILE}" ]]; then
    echo -e
    echo -e "  ⭕ ${YELLOW1}[${APP_THIS_FILE}]${RESET}: No target file specified"
    echo -e
    exit 0
fi

if test "$#" -lt 2; then
    echo -e
    echo -e "  ⭕  ${YELLOW1}[${APP_THIS_FILE}]${RESET}: Aborting -- did not provide URL arguments for ${YELLOW1}${ARG_SAVEFILE}${RESET}"
    echo -e
    exit 0
fi

# #
#    Define > General
# #

SECONDS=0                                               # set seconds count for beginning of script
APP_VER=("1" "0" "0" "0")                               # current script version
APP_DEBUG=false                                         # debug mode
APP_REPO="Aetherinox/blocklists"                        # repository
APP_REPO_BRANCH="main"                                  # repository branch
APP_OUT=""                                              # each ip fetched from stdin will be stored in this var
APP_FILE_PERM="${ARG_SAVEFILE}"                         # perm file when building ipset list
COUNT_LINES=0                                           # number of lines in doc
COUNT_TOTAL_SUBNET=0                                    # number of IPs in all subnets combined
COUNT_TOTAL_IP=0                                        # number of single IPs (counts each line)
APP_AGENT="Mozilla/5.0 (Windows NT 10.0; WOW64) "\
"AppleWebKit/537.36 (KHTML, like Gecko) "\
"Chrome/51.0.2704.103 Safari/537.36"                    # user agent used with curl
TEMPL_NOW=`date -u`                                     # get current date in utc format
TEMPL_ID=$(basename -- ${APP_FILE_PERM})                # ipset id, get base filename
TEMPL_ID="${TEMPL_ID//[^[:alnum:]]/_}"                  # ipset id, only allow alphanum and underscore, /description/* and /category/* files must match this value
TEMPL_UUID=$(uuidgen -m -N "${TEMPL_ID}" -n @url)       # uuid associated to each release
TEMPL_DESC=$(curl -sSL -A "${APP_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/descriptions/${TEMPL_ID}.txt")
TEMPL_CAT=$(curl -sSL -A "${APP_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/categories/${TEMPL_ID}.txt")
TEMPL_EXP=$(curl -sSL -A "${APP_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/expires/${TEMPL_ID}.txt")
TEMP_URL_SRC=$(curl -sSL -A "${APP_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/url-source/${TEMPL_ID}.txt")
REGEX_URL='^(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
REGEX_ISNUM='^[0-9]+$'

# #
#   Default Values
# #

if [[ "$TEMPL_DESC" == *"404: Not Found"* ]]; then
    TEMPL_DESC="#   No description provided"
fi

if [[ "$TEMPL_CAT" == *"404: Not Found"* ]]; then
    TEMPL_CAT="Uncategorized"
fi

if [[ "$TEMPL_EXP" == *"404: Not Found"* ]]; then
    TEMPL_EXP="6 hours"
fi

if [[ "$TEMP_URL_SRC" == *"404: Not Found"* ]]; then
    TEMP_URL_SRC="None"
fi

# #
#   Output > Header
# #

echo -e
echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"
echo -e "  ${YELLOW1}${APP_FILE_PERM}${RESET}"
echo -e
echo -e "  ${GREY2}ID:          ${TEMPL_ID}${RESET}"
echo -e "  ${GREY2}UUID:        ${TEMPL_UUID}${RESET}"
echo -e "  ${GREY2}CATEGORY:    ${TEMPL_CAT}${RESET}"
echo -e "  ${GREY2}ACTION:      ${APP_THIS_FILE}${RESET}"
echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"

# #
#   output
# #

echo -e
echo -e "  ⭐ Starting script ${GREEN1}${APP_THIS_FILE}${RESET}"

# #
#   Create or Clean file
# #

if [ -f $APP_FILE_PERM ]; then
    echo -e "  📄 Clean ${BLUE2}${APP_FILE_PERM}${RESET}"
    echo -e
   > ${APP_FILE_PERM}       # clean file
else
    echo -e "  📁 Create ${BLUE2}${APP_FILE_PERM}${RESET}"
    echo -e
    mkdir -p $(dirname "${APP_FILE_PERM}")
    touch ${APP_FILE_PERM}
fi

# #
#   Func > Download List
# #

download_list()
{

    local fnUrl=$1
    local fnFile=$2
    local fnFileTemp="${2}.tmp"
    local DL_COUNT_TOTAL_IP=0
    local DL_COUNT_TOTAL_SUBNET=0

    echo -e "  🌎 Downloading IP blacklist to ${ORANGE2}${fnFileTemp}${RESET}"

    curl -sSL -A "${CURL_AGENT}" ${fnUrl} -o ${fnFileTemp} >/dev/null 2>&1      # download file
    sed -i 's/\-.*//' ${fnFileTemp}                                             # remove hyphens for ip ranges
    sed -i '/[#;]/{s/#.*//;s/;.*//;/^$/d}' ${fnFileTemp}                        # remove # and ; comments
    sed -i 's/[[:blank:]]*$//' ${fnFileTemp}                                    # remove space / tab from EOL
    sed -i '/^\s*$/d' ${fnFileTemp}                                             # remove empty lines

    # #
    #   calculate how many IPs are in a subnet
    #   if you want to calculate the USABLE IP addresses, subtract -2 from any subnet not ending with 31 or 32.
    #   
    #   for our purpose, we want to block them all in the event that the network has reconfigured their network / broadcast IPs,
    #   so we will count every IP in the block.
    # #

    echo -e "  📊 Fetching statistics for clean file ${ORANGE2}${fnFileTemp}${RESET}"
    for line in $(cat ${fnFileTemp}); do
        # is ipv6
        if [ "$line" != "${line#*:[0-9a-fA-F]}" ]; then
            COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + 1 ))                           # GLOBAL count subnet
            DL_COUNT_TOTAL_IP=$(( $DL_COUNT_TOTAL_IP + 1 ))                     # LOCAL count subnet

        # is subnet
        elif [[ $line =~ /[0-9]{1,2}$ ]]; then
            ips=$(( 1 << (32 - ${line#*/}) ))

            if [[ $ips =~ $REGEX_ISNUM ]]; then
                # CIDR=$(echo $line | sed 's:.*/::')

                # uncomment if you want to count ONLY usable IP addresses
                # subtract - 2 from any cidr not ending with 31 or 32
                # if [[ $CIDR != "31" ]] && [[ $CIDR != "32" ]]; then
                    # COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP - 2 ))
                    # DL_COUNT_TOTAL_IP=$(( $DL_COUNT_TOTAL_IP - 2 ))
                # fi

                COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + $ips ))                    # GLOBAL count IPs in subnet
                COUNT_TOTAL_SUBNET=$(( $COUNT_TOTAL_SUBNET + 1 ))               # GLOBAL count subnet

                DL_COUNT_TOTAL_IP=$(( $DL_COUNT_TOTAL_IP + $ips ))              # LOCAL count IPs in subnet
                DL_COUNT_TOTAL_SUBNET=$(( $DL_COUNT_TOTAL_SUBNET + 1 ))         # LOCAL count subnet
            fi

        # is normal IP
        elif [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + 1 ))
            DL_COUNT_TOTAL_IP=$(( $DL_COUNT_TOTAL_IP + 1 ))
        fi
    done

    # #
    #   Count lines and subnets
    # #

    DL_COUNT_TOTAL_IP=$(printf "%'d" "$DL_COUNT_TOTAL_IP")                      # LOCAL add commas to thousands
    DL_COUNT_TOTAL_SUBNET=$(printf "%'d" "$DL_COUNT_TOTAL_SUBNET")              # LOCAL add commas to thousands

    # #
    #   Move temp file to final
    # #

    echo -e "  🚛 Move ${ORANGE2}${fnFileTemp}${RESET} to ${BLUE2}${fnFile}${RESET}"
    cat ${fnFileTemp} >> ${fnFile}                                              # copy .tmp contents to real file
    rm ${fnFileTemp}                                                            # delete temp file

    echo -e "  ➕ Added ${FUCHSIA2}${DL_COUNT_TOTAL_IP} IPs${RESET} and ${FUCHSIA2}${DL_COUNT_TOTAL_SUBNET} subnets${RESET} to ${BLUE2}${fnFile}${RESET}"
}

# #
#   Download lists
# #

for arg in "${@:2}"; do
    if [[ $arg =~ $REGEX_URL ]]; then
        download_list ${arg} ${APP_FILE_PERM}
        echo -e
    fi
done

# #
#   Sort
#       - sort lines numerically and create .sort file
#       - move re-sorted text from .sort over to real file
#       - remove .sort temp file
# #

sorting=$(cat ${APP_FILE_PERM} | grep -vi "^#|^;|^$" | sort -n | awk '{if (++dup[$0] == 1) print $0;}' > ${APP_FILE_PERM}.sort)
> ${APP_FILE_PERM}
cat ${APP_FILE_PERM}.sort >> ${APP_FILE_PERM}
rm ${APP_FILE_PERM}.sort

# #
#   Format Counts
# #

COUNT_LINES=$(wc -l < ${APP_FILE_PERM})                                     # count ip lines
COUNT_LINES=$(printf "%'d" "$COUNT_LINES")                                  # GLOBAL add commas to thousands

# #
#   Format count totals since we no longer need to add
# #

COUNT_TOTAL_IP=$(printf "%'d" "$COUNT_TOTAL_IP")                            # GLOBAL add commas to thousands
COUNT_TOTAL_SUBNET=$(printf "%'d" "$COUNT_TOTAL_SUBNET")                    # GLOBAL add commas to thousands

# #
#   ed
#       0a  top of file
# #

ed -s ${APP_FILE_PERM} <<END_ED
0a
# #
#   🧱 Firewall Blocklist - ${APP_FILE_PERM}
#
#   @url            https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/${APP_FILE_PERM}
#   @source         ${TEMP_URL_SRC}
#   @id             ${TEMPL_ID}
#   @uuid           ${TEMPL_UUID}
#   @updated        ${TEMPL_NOW}
#   @entries        ${COUNT_TOTAL_IP} ips
#                   ${COUNT_TOTAL_SUBNET} subnets
#                   ${COUNT_LINES} lines
#   @expires        ${TEMPL_EXP}
#   @category       ${TEMPL_CAT}
#
${TEMPL_DESC}
# #

.
w
q
END_ED

# #
#   Finished
# #

T=$SECONDS
D=$((T/86400))
H=$((T/3600%24))
M=$((T/60%60))
S=$((T%60))

echo -e "  🎌 ${GREY2}Finished! ${YELLOW2}${D} days ${H} hrs ${M} mins ${S} secs${RESET}"

# #
#   Output
# #

echo -e
echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"
echo -e "  #️⃣ ${BLUE2}${APP_FILE_PERM}${RESET} | Added ${FUCHSIA2}${COUNT_TOTAL_IP} IPs${RESET} and ${FUCHSIA2}${COUNT_TOTAL_SUBNET} Subnets${RESET}"
echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"
echo -e