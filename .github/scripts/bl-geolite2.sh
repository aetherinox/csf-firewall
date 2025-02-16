#!/bin/bash

# #
#   @for                https://github.com/Aetherinox/csf-firewall
#   @workflow           blocklist-generate.yml
#   @type               bash script
#   @summary            Aetherx Blocklists > GeoLite2 Country IPsets
#                       generates a set of IPSET files by reading the GeoLite2 csv file and splitting the IPs up into their associated country.
#   
#   @terminal           .github/scripts/bl-geolite2.sh -l <LICENSE_KEY>
#                       .github/scripts/bl-geolite2.sh --local
#                       .github/scripts/bl-geolite2.sh --local --dev
#                       .github/scripts/bl-geolite2.sh --dry
#
#   @command            bl-geolite2.sh -l <LICENSE_KEY> ]
#                       bl-geolite2.sh --local
#                       bl-geolite2.sh --dev
#                       bl-geolite2.sh --dry
# #

# #
#   LICENSE KEY / DOWNLOAD MODE
#       .github/scripts/bl-geolite2.sh -l <LICENSE_KEY>
#       .github/scripts/bl-geolite2.sh --license <LICENSE_KEY>
#
#   If you are not running LOCAL MODE (see below), you will need to download the GeoLite2 database .csv files when the script starts.
#   You must specify a license key from the MaxMind website. Ensure you set up a Github workflow secret if running this script on Github.
#
#   To specify a license key, you can:
#       - Create `aetherx.conf` and add the license key within the file
#           Add LICENSE_KEY=YOUR_LICENSE_KEY
#
#       - Provide the license key as a parameter when running the script
#           bl-geolite2.sh --license ABCDEF123456789
#           bl-geolite2.sh -l ABCDEF123456789
# #

# #
#   LOCAL MODE
#       .github/scripts/bl-geolite2.sh -o
#       .github/scripts/bl-geolite2.sh --local
#
#   PLACE FILES IN
#       `.github/local`
#
#   Local mode allows you to use GeoLite2 database from a local copy on your server, instead of downloading a fresh zip.
#
#   Local files must be placed in the `.github/local` folder. This method supports either the zipped files, OR each CSV.
#
#   If providing the ZIP, you must have the following files:
#       .github/local/GeoLite2-Country-CSV.zip
#       .github/local/GeoLite2-Country-CSV.zip.md5
#
#   OR
#
#   If providing each CSV file, you must have the files:
#       .github/local/GeoLite2-Country-Locations-en.csv
#       .github/local/GeoLite2-Country-Blocks-IPv4.csv
#       .github/local/GeoLite2-Country-Blocks-IPv6.csv
#
#   If you are providing the ZIP files, you can get the zip and the md5 hash files from
#       - CSV URL: https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip
#       - MD5 URL: https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip.md5
#
#   The files MUST be named:
#       - GeoLite2-Country-CSV.zip
#       - GeoLite2-Country-CSV.zip.md5
# #

# #
#   DRY-RUN MODE
#       .github/scripts/bl-geolite2.sh -d
#       .github/scripts/bl-geolite2.sh --dry
#
#   PLACE FILES IN
#       `.github/local`
#   
#   This parameter runs the script as if it were downloading the files from the MaxMind official website, except the CURL calls are skipped.
#   the .ZIP and .ZIP.MD5 files are required to be in the .temp folder.
#
#   The files MUST be named:
#       - GeoLite2-Country-CSV.zip
#       - GeoLite2-Country-CSV.zip.md5
#
#   Download the .zip and .zip.md5 from:
#           - CSV URL: https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip
#           - MD5 URL: https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip.md5
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

RESET=$'\e[0m'
WHITE=$'\e[97m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
UNDERLINE=$'\e[4m'
BLINK=$'\e[5m'
INVERTED=$'\e[7m'
HIDDEN=$'\e[8m'
BLACK=$'\e[38;5;0m'
FUCHSIA1=$'\e[38;5;125m'
FUCHSIA2=$'\e[38;5;198m'
RED1=$'\e[38;5;160m'
RED2=$'\e[38;5;196m'
RED3=$'\e[38;5;166m'
ORANGE1=$'\e[38;5;202m'
ORANGE2=$'\e[38;5;208m'
MAGENTA=$'\e[38;5;5m'
BLUE1=$'\e[38;5;033m'
BLUE2=$'\e[38;5;39m'
CYAN=$'\e[38;5;6m'
GREEN1=$'\e[38;5;2m'
GREEN2=$'\e[38;5;76m'
YELLOW1=$'\e[38;5;184m'
YELLOW2=$'\e[38;5;190m'
YELLOW3=$'\e[38;5;193m'
GREY1=$'\e[38;5;240m'
GREY2=$'\e[38;5;244m'
GREY3=$'\e[38;5;250m'

# #
#   print an error and exit with failure
#   $1: error message
# #

function error()
{
    echo -e "  ⭕ ${GREY2}${APP_THIS_FILE}${RESET}: \n     ${BOLD}${RED1}Error${RESET}: ${RESET}$1"
    echo -e
    exit 0
}

# #
#   Debug Mode
#
#   This script includes debug mode. You can enable it with the settings below:
#       APP_DEBUG=true
#
#   This will enable various prints to show the progress of each step. Make sure to turn this off when
#   in production mode.
# #

SECONDS=0                                                           # set seconds count for beginning of script
APP_NAME="GeoLite2 Database Script"                                 # name of app
APP_VER=("1" "1" "0" "0")                                           # current script version
APP_DEBUG=false                                                     # debug mode
APP_REPO="Aetherinox/blocklists"                                    # repository
APP_REPO_BRANCH="main"                                              # repository branch
APP_CFG_FILE="aetherx.conf"                                         # Optional config file for license key / settings
APP_TARGET_DIR="blocklists/country/geolite"                         # path to save ipsets
APP_TARGET_EXT_TMP="tmp"                                            # temp extension for ipsets before work is done
APP_TARGET_EXT_PROD="ipset"                                         # extension for ipsets
APP_SOURCE_LOCAL_ENABLED=false                                      # True = loads from ./local, False = download from MaxMind
APP_SOURCE_LOCAL="local"                                            # local mode enabled: where to fetch local csv from
APP_SOURCE_TEMP=".temp"                                             # local mode disabled: where csv will be downloaded to
APP_SOURCE_CACHE="cache"                                            # location where countries and continents are stored as array to file
APP_DIR_IPV4="./${APP_TARGET_DIR}/ipv4"                             # folder to store ipv4
APP_DIR_IPV6="./${APP_TARGET_DIR}/ipv6"                             # folder to store ipv6
APP_GEO_LOCS_CSV="GeoLite2-Country-Locations-en.csv"                # Geolite2 Country Locations CSV 
APP_GEO_IPV4_CSV="GeoLite2-Country-Blocks-IPv4.csv"                 # Geolite2 Country CSV IPv4
APP_GEO_IPV6_CSV="GeoLite2-Country-Blocks-IPv6.csv"                 # Geolite2 Country CSV IPv6
APP_GEO_ZIP="GeoLite2-Country-CSV.zip"                              # Geolite2 Country CSV Zip
APP_GEO_ZIP_MD5="${APP_GEO_ZIP}.md5"                                # Geolite2 Country CSV Zip MD5 hash file
COUNT_LINES=0                                                       # number of lines in doc
COUNT_TOTAL_SUBNET=0                                                # number of IPs in all subnets combined
COUNT_TOTAL_IP=0                                                    # number of single IPs (counts each line)
BLOCKS_COUNT_TOTAL_IP=0                                             # number of ips for one particular file
BLOCKS_COUNT_TOTAL_SUBNET=0                                         # number of subnets for one particular file
APP_AGENT="Mozilla/5.0 (Windows NT 10.0; WOW64) "\
"AppleWebKit/537.36 (KHTML, like Gecko) "\
"Chrome/51.0.2704.103 Safari/537.36"                                # user agent used with curl

# #
#   Define > Help Vars
# #

APP_DESC="This script downloads the geographical databases from the MaxMind GeoLite2 servers. \n\n  They are then broken up into their respective continent and country files. Duplicates are removed, IPs\n  are re-sorted, and then all files are pushed to the repository."

APP_USAGE="🗔  Usage: ./${APP_THIS_FILE} ${BLUE2}[-l <LICENSE_KEY>]${RESET}
        ${GREY2}./${APP_THIS_FILE} ${BLUE2}-?${RESET}
        ${GREY2}./${APP_THIS_FILE} ${BLUE2}clr${RESET}
        ${GREY2}./${APP_THIS_FILE} ${BLUE2}chart${RESET}
"

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
    echo -e "RED3 ${GREY1}................. ${RED3}This is test text ███████████████${RESET}"
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
#   func > get version
#
#   returns current version of app
#   converts to human string.
#       e.g.    "1" "2" "4" "0"
#               1.2.4.0
# #

get_version()
{
    ver_join=${APP_VER[*]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

# #
#   Usage
# #

opt_usage()
{
    echo -e
    printf "  ${BLUE1}${APP_NAME}${RESET}\n" 1>&2
    printf "  ${DIM}${APP_DESC}${RESET}\n" 1>&2
    echo -e
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${APP_THIS_FILE} [ ${GREY2} options${RESET} ]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${APP_THIS_FILE} [ ${GREY2}--help${RESET} ] [ ${GREY2}--dry${RESET} ] [ ${GREY2}--local${RESET} ] [ ${GREY2}--license LICENSE_KEY${RESET} ] [ ${GREY2}--version${RESET} ]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-l,  --license" "specifies your MaxMind license key" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-o,  --local" "enables local mode, geo database must be provided locally." 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}does not require MaxMind license key${RESET}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}local geo .csv files OR .zip must be placed in folder ${BLUE2}${APP_THIS_DIR}/${APP_SOURCE_LOCAL}${RESET}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d,  --dry" "runs a dry run of loading csv files from ${BLUE2}${APP_GITHUB_DIR}/${APP_SOURCE_TEMP}${RESET} folder" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}requires you place ${GREEN1}${APP_GEO_ZIP}${RESET} and ${GREEN1}${APP_GEO_ZIP_MD5}${RESET} files in ${BLUE2}${APP_GITHUB_DIR}/${APP_SOURCE_TEMP}${RESET} folder${RESET}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-c,  --color" "displays a demo of the available colors" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}only needed by developer${RESET}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-g,  --graph" "displays a demo bash color graph" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}only needed by developer${RESET}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d,  --dev" "dev mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-p,  --path" "list of paths associated to script" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h,  --help" "show help menu" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}not required when using local mode${RESET}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-u,  --usage" "how to use this script" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v,  --version" "current version of ${APP_THIS_FILE}" 1>&2
    echo
    echo
    exit 1
}

# #
#   Display help text if command not complete
# #

while [ $# -gt 0 ]; do
    case "$1" in
        -u|--usage)
                    echo -e
                    echo -e "  ${WHITE}To use this script, use one of the following methods:\n"
                    echo -e "  ${GREEN1}${BOLD}   License Key / Normal Mode${RESET}"
                    echo -e "  ${GREY3}${BOLD}   This method requires no files to be added. The geographical files will be downloaded from the${RESET}"
                    echo -e "  ${GREY3}${BOLD}   MaxMind website / servers.${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} -l ABCDEF1234567-01234${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} -l ABCDEF1234567-01234${RESET}"
                    echo -e
                    echo -e
                    echo -e "  ${GREEN1}${BOLD}   Local Mode .................................................................................................. ${DIM}[ Option 1 ]${RESET}"
                    echo -e "  ${GREY3}   This mode allows you to use local copies of the GeoLite2 database files to generate an IP list instead of${RESET}"
                    echo -e "  ${GREY3}   downloading a fresh copy of the .CSV / .ZIP files from the MaxMind website. This method requires you to${RESET}"
                    echo -e "  ${GREY3}   place the .ZIP, and .ZIP.MD5 file in the folder ${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_LOCAL}${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Download the following files from the MaxMind website: ${RESET}"
                    echo -e "  ${BLUE2}         https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip${RESET}"
                    echo -e "  ${BLUE2}         https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip.md5${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Place the ${GREEN2}.ZIP${RESET} and ${GREEN2}.ZIP.MD5${RESET} files in: ${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_LOCAL}${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   The filenames MUST be: ${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_LOCAL}/GeoLite2-Country-CSV.zip${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_LOCAL}/GeoLite2-Country-CSV.zip.md5${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Run the following command: ${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} --local${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} -o${RESET}"
                    echo -e
                    echo -e
                    echo -e "  ${GREEN1}${BOLD}   Local Mode .................................................................................................. ${DIM}[ Option 2 ]${RESET}"
                    echo -e "  ${GREY3}   This mode allows you to use local copies of the GeoLite2 database files to generate an IP list instead of${RESET}"
                    echo -e "  ${GREY3}   downloading a fresh copy of the .ZIP files from the MaxMind website. This method requires you to extract${RESET}"
                    echo -e "  ${GREY3}   the .ZIP and place the .CSV files in the folder ${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_LOCAL}${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Download the following file from the MaxMind website: ${RESET}"
                    echo -e "  ${BLUE2}         https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Open the .ZIP and extract the following files to the folder ${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_LOCAL}${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_LOCAL}/GeoLite2-Country-Locations-en.csv${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_LOCAL}/GeoLite2-Country-Blocks-IPv4.csv${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_LOCAL}/GeoLite2-Country-Blocks-IPv6.csv${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Run the following command: ${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} --local${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} -o${RESET}"
                    echo -e
                    echo -e
                    echo -e "  ${GREEN1}${BOLD}   Dry Run .....................................................................................................${RESET}"
                    echo -e "  ${GREY3}   This mode allows you to simulate downloading the .ZIP files from the MaxMind website. However, the CURL${RESET}"
                    echo -e "  ${GREY3}   commands will not actually be ran. Instead, the script will look for the needed database files in the ${RESET}"
                    echo -e "  ${GREY3}   ${APP_SOURCE_TEMP} folder. This method requires you to place either the .ZIP & .ZIP.MD5 files, or extracted CSV files${RESET}"
                    echo -e "  ${GREY3}   in the folder ${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_TEMP}${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Place the .ZIP & .ZIP.MD5 file, OR the .CSV files in the folder ${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_TEMP}${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_TEMP}/GeoLite2-Country-Locations-en.csv${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_TEMP}/GeoLite2-Country-Blocks-IPv4.csv${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_TEMP}/GeoLite2-Country-Blocks-IPv6.csv${RESET}"
                    echo -e
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_TEMP}/GeoLite2-Country-CSV.zip${RESET}"
                    echo -e "  ${BLUE2}         ${APP_THIS_DIR}/${APP_SOURCE_TEMP}/GeoLite2-Country-CSV.zip.md5${RESET}"
                    echo -e
                    echo -e "  ${GREY3}${BOLD}   Run the following command: ${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} --dry${RESET}"
                    echo -e "  ${BLUE2}         ./${APP_THIS_FILE} -d${RESET}"
                    echo -e
                    exit 1
                ;;
        -p|--paths)
                    echo -e
                    echo -e "  ${WHITE}List of paths important to this script:\n"
                    echo -e "  ${GREEN1}${BOLD}${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_LOCAL}${RESET}${RESET}"
                    echo -e "  ${GREY3}Folder used when Local Mode enabled (${GREEN2}--local${RESET})${RESET}"
                    echo -e "  ${GREY2}    Can detect GeoLite2 ${BLUE2}.ZIP${GREY2} and ${BLUE2}.ZIP.MD5${GREY2} files${RESET}"
                    echo -e "  ${GREY2}    Can detect GeoLite2 ${BLUE2}.CSV${GREY2} location and IPv4/IPv6 files${RESET}"
                    echo -e
                    echo -e
                    echo -e "  ${GREEN1}${BOLD}${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_TEMP}${RESET}${RESET}"
                    echo -e "  ${GREY3}Folder used when Dry Run enabled (${GREEN2}--dry${RESET})${RESET}"
                    echo -e "  ${GREY2}    Can detect GeoLite2 ${BLUE2}.ZIP${GREY2} and ${BLUE2}.ZIP.MD5${GREY2} files${RESET}"
                    echo -e "  ${GREY2}    Can detect GeoLite2 ${BLUE2}.CSV${GREY2} location and IPv4/IPv6 files${RESET}"
                    echo -e
                    echo -e
                    echo -e "  ${GREEN1}${BOLD}${ORANGE2}${APP_THIS_DIR}/${APP_SOURCE_CACHE}${RESET}${RESET}"
                    echo -e "  ${GREY3}Folder used to store associative array for continents and countries${RESET}"
                    echo -e
                    echo -e
                    exit 1
                ;;
        -l|--license)
                if [[ "$1" != *=* ]]; then shift; fi
                LICENSE_KEY="${1#*=}"
                if [ -z "${LICENSE_KEY}" ]; then
                    echo -e
                    echo -e "  ${WHITE}Specifies your MaxMind license key.${RESET}"
                    echo -e "  ${GREY1}Required if you are not running the script in local mode.${RESET}"
                    echo -e "  ${WHITE}      Example:    ${GREY2}./${APP_THIS_FILE} -l ABCDEF1234567-01234${RESET}"
                    echo
                    exit 1
                fi
                ;;
        -d|--dev)
                APP_DEBUG=true
                echo -e "  ${FUCHSIA2}${BLINK}Devmode Enabled${RESET}"
                ;;
        -o|--local)
                APP_SOURCE_LOCAL_ENABLED=true
                echo -e "  ${FUCHSIA2}${BLINK}Local Mode Enabled${RESET}"
                ;;
        -d|--dry)
                APP_DRYRUN=true
                echo -e "  ${FUCHSIA2}${BLINK}Dry Run Enabled${RESET}"
                ;;
        -v|--version)
                echo -e
                echo -e "  ${BLUE2}${BOLD}${APP_NAME}${RESET} - v$(get_version)${RESET}"
                echo -e "  ${GREEN1}${BOLD}https://github.com/${APP_REPO}${RESET}"
                echo
                exit 1
                ;;
        -c|--color)
                debug_ColorTest
                exit 1
                ;;
        -g|--graph|--chart)
                debug_ColorChart
                exit 1
                ;;
        -\?|-h|--help)
                opt_usage
                ;;
        *)
                opt_usage
                ;;
    esac
    shift
done

# #
#   Define
# #

readonly CONFIGS_LIST="${APP_GEO_LOCS_CSV} ${APP_GEO_IPV4_CSV} ${APP_GEO_IPV6_CSV}"
declare -A MAP_COUNTRY
declare -A MAP_CONTINENT

# #
#   Arguments
# #

ARG1=$1

if [ "$ARG1" == "clr" ] || [ "$ARG1" == "color" ]; then
    debug_ColorTest
    exit 1
fi

if [ "$ARG1" == "chart" ] || [ "$ARG1" == "graph" ]; then
    debug_ColorChart
    exit 1
fi

# #
#   Country codes
# #

get_country_name()
{
    local code=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    case "$code" in
        "ad") echo "Andorra" ;;
        "ae") echo "United Arab Emirates" ;;
        "af") echo "Afghanistan" ;;
        "ag") echo "Antigua Barbuda" ;;
        "ai") echo "Anguilla" ;;
        "al") echo "Albania" ;;
        "am") echo "Armenia" ;;
        "an") echo "Netherlands Antilles" ;;
        "ao") echo "Angola" ;;
        "ap") echo "Asia/Pacific Region" ;;
        "aq") echo "Antarctica" ;;
        "ar") echo "Argentina" ;;
        "as") echo "American Samoa" ;;
        "at") echo "Austria" ;;
        "au") echo "Australia" ;;
        "aw") echo "Aruba" ;;
        "ax") echo "Aland Islands" ;;
        "az") echo "Azerbaijan" ;;
        "ba") echo "Bosnia Herzegovina" ;;
        "bb") echo "Barbados" ;;
        "bd") echo "Bangladesh" ;;
        "be") echo "Belgium" ;;
        "bf") echo "Burkina Faso" ;;
        "bg") echo "Bulgaria" ;;
        "bh") echo "Bahrain" ;;
        "bi") echo "Burundi" ;;
        "bj") echo "Benin" ;;
        "bl") echo "Saint Barthelemy" ;;
        "bm") echo "Bermuda" ;;
        "bn") echo "Brunei Darussalam" ;;
        "bo") echo "Bolivia" ;;
        "bq") echo "Bonaire Sint Eustatius Saba" ;;
        "br") echo "Brazil" ;;
        "bs") echo "Bahamas" ;;
        "bt") echo "Bhutan" ;;
        "bv") echo "Bouvet Island" ;;
        "bw") echo "Botswana" ;;
        "by") echo "Belarus" ;;
        "bz") echo "Belize" ;;
        "ca") echo "Canada" ;;
        "cd") echo "Democratic Republic Congo" ;;
        "cf") echo "Central African Republic" ;;
        "cg") echo "Congo" ;;
        "ch") echo "Switzerland" ;;
        "ci") echo "Cote d'Ivoire" ;;
        "ck") echo "Cook Islands" ;;
        "cl") echo "Chile" ;;
        "cm") echo "Cameroon" ;;
        "cn") echo "China" ;;
        "co") echo "Colombia" ;;
        "cr") echo "Costa Rica" ;;
        "cu") echo "Cuba" ;;
        "cv") echo "Cape Verde" ;;
        "cw") echo "Curacao" ;;
        "cx") echo "Christmas Island" ;;
        "cy") echo "Cyprus" ;;
        "cz") echo "Czech Republic" ;;
        "de") echo "Germany" ;;
        "dj") echo "Djibouti" ;;
        "dk") echo "Denmark" ;;
        "dm") echo "Dominica" ;;
        "do") echo "Dominican Republic" ;;
        "dz") echo "Algeria" ;;
        "ec") echo "Ecuador" ;;
        "ee") echo "Estonia" ;;
        "eg") echo "Egypt" ;;
        "eh") echo "Western Sahara" ;;
        "er") echo "Eritrea" ;;
        "es") echo "Spain" ;;
        "et") echo "Ethiopia" ;;
        "eu") echo "Europe" ;;
        "fi") echo "Finland" ;;
        "fj") echo "Fiji" ;;
        "fk") echo "Falkland Islands Malvinas" ;;
        "fm") echo "Micronesia" ;;
        "fo") echo "Faroe Islands" ;;
        "fr") echo "France" ;;
        "ga") echo "Gabon" ;;
        "gb") echo "Great Britain" ;;
        "gd") echo "Grenada" ;;
        "ge") echo "Georgia" ;;
        "gf") echo "French Guiana" ;;
        "gg") echo "Guernsey" ;;
        "gh") echo "Ghana" ;;
        "gi") echo "Gibraltar" ;;
        "gl") echo "Greenland" ;;
        "gm") echo "Gambia" ;;
        "gn") echo "Guinea" ;;
        "gp") echo "Guadeloupe" ;;
        "gq") echo "Equatorial Guinea" ;;
        "gr") echo "Greece" ;;
        "gs") echo "South Georgia and the South Sandwich Islands" ;;
        "gt") echo "Guatemala" ;;
        "gu") echo "Guam" ;;
        "gw") echo "Guinea-Bissau" ;;
        "gy") echo "Guyana" ;;
        "hk") echo "Hong Kong" ;;
        "hn") echo "Honduras" ;;
        "hr") echo "Croatia" ;;
        "ht") echo "Haiti" ;;
        "hu") echo "Hungary" ;;
        "hm") echo "Heard Island and McDonald Islands" ;;
        "id") echo "Indonesia" ;;
        "ie") echo "Ireland" ;;
        "il") echo "Israel" ;;
        "im") echo "Isle of Man" ;;
        "in") echo "India" ;;
        "io") echo "British Indian Ocean Territory" ;;
        "iq") echo "Iraq" ;;
        "ir") echo "Iran" ;;
        "is") echo "Iceland" ;;
        "it") echo "Italy" ;;
        "je") echo "Jersey" ;;
        "jm") echo "Jamaica" ;;
        "jo") echo "Jordan" ;;
        "jp") echo "Japan" ;;
        "ke") echo "Kenya" ;;
        "kg") echo "Kyrgyzstan" ;;
        "kh") echo "Cambodia" ;;
        "ki") echo "Kiribati" ;;
        "km") echo "Comoros" ;;
        "kn") echo "Saint Kitts Nevis" ;;
        "kp") echo "North Korea" ;;
        "kr") echo "South Korea" ;;
        "kw") echo "Kuwait" ;;
        "ky") echo "Cayman Islands" ;;
        "kz") echo "Kazakhstan" ;;
        "la") echo "Laos" ;;
        "lb") echo "Lebanon" ;;
        "lc") echo "Saint Lucia" ;;
        "li") echo "Liechtenstein" ;;
        "lk") echo "Sri Lanka" ;;
        "lr") echo "Liberia" ;;
        "ls") echo "Lesotho" ;;
        "lt") echo "Lithuania" ;;
        "lu") echo "Luxembourg" ;;
        "lv") echo "Latvia" ;;
        "ly") echo "Libya" ;;
        "ma") echo "Morocco" ;;
        "mc") echo "Monaco" ;;
        "md") echo "Republic Moldova" ;;
        "me") echo "Montenegro" ;;
        "mf") echo "Saint Martin (North)" ;;
        "mg") echo "Madagascar" ;;
        "mh") echo "Marshall Islands" ;;
        "mk") echo "Macedonia Republic" ;;
        "ml") echo "Mali" ;;
        "mm") echo "Myanmar" ;;
        "mn") echo "Mongolia" ;;
        "mo") echo "Macao" ;;
        "mp") echo "Northern Mariana Islands" ;;
        "mq") echo "Martinique" ;;
        "mr") echo "Mauritania" ;;
        "ms") echo "Montserrat" ;;
        "mt") echo "Malta" ;;
        "mu") echo "Mauritius" ;;
        "mv") echo "Maldives" ;;
        "mw") echo "Malawi" ;;
        "mx") echo "Mexico" ;;
        "my") echo "Malaysia" ;;
        "mz") echo "Mozambique" ;;
        "na") echo "Namibia" ;;
        "ne") echo "Niger" ;;
        "ng") echo "Nigeria" ;;
        "nl") echo "Netherlands" ;;
        "no") echo "Norway" ;;
        "nc") echo "New Caledonia" ;;
        "ne") echo "Niger" ;;
        "nf") echo "Norfolk Island" ;;
        "ng") echo "Nigeria" ;;
        "ni") echo "Nicaragua" ;;
        "nl") echo "Netherlands" ;;
        "no") echo "Norway" ;;
        "np") echo "Nepal" ;;
        "nr") echo "Nauru" ;;
        "nu") echo "Niue" ;;
        "nz") echo "New Zealand" ;;
        "om") echo "Oman" ;;
        "pa") echo "Panama" ;;
        "pe") echo "Peru" ;;
        "pf") echo "French Polynesia" ;;
        "pg") echo "Papua New Guinea" ;;
        "ph") echo "Philippines" ;;
        "pk") echo "Pakistan" ;;
        "pl") echo "Poland" ;;
        "pm") echo "Saint Pierre Miquelon" ;;
        "pn") echo "Pitcairn" ;;
        "pr") echo "Puerto Rico" ;;
        "ps") echo "Palestine" ;;
        "pt") echo "Portugal" ;;
        "pw") echo "Palau" ;;
        "py") echo "Paraguay" ;;
        "qa") echo "Qatar" ;;
        "re") echo "Reunion" ;;
        "ro") echo "Romania" ;;
        "rs") echo "Serbia" ;;
        "ru") echo "Russia" ;;
        "rw") echo "Rwanda" ;;
        "sa") echo "Saudi Arabia" ;;
        "sb") echo "Solomon Islands" ;;
        "sc") echo "Seychelles" ;;
        "sd") echo "Sudan" ;;
        "se") echo "Sweden" ;;
        "sg") echo "Singapore" ;;
        "sh") echo "Saint Helena" ;;
        "si") echo "Slovenia" ;;
        "sj") echo "Svalbard Jan Mayen" ;;
        "sk") echo "Slovakia" ;;
        "sl") echo "Sierra Leone" ;;
        "sm") echo "San Marino" ;;
        "sn") echo "Senegal" ;;
        "so") echo "Somalia" ;;
        "ss") echo "South Sudan" ;;
        "sr") echo "Suriname" ;;
        "st") echo "Sao Tome Principe" ;;
        "sv") echo "El Salvador" ;;
        "sx") echo "Sint Maarten (South)" ;;
        "sy") echo "Syria" ;;
        "sz") echo "Eswatini" ;;
        "tc") echo "Turks Caicos Islands" ;;
        "td") echo "Chad" ;;
        "tf") echo "French Southern Territories" ;;
        "tg") echo "Togo" ;;
        "th") echo "Thailand" ;;
        "tj") echo "Tajikistan" ;;
        "tk") echo "Tokelau" ;;
        "tl") echo "Timor-Leste" ;;
        "tm") echo "Turkmenistan" ;;
        "tn") echo "Tunisia" ;;
        "to") echo "Tonga" ;;
        "tr") echo "Turkey" ;;
        "tt") echo "Trinidad Tobago" ;;
        "tv") echo "Tuvalu" ;;
        "tw") echo "Taiwan" ;;
        "tz") echo "Tanzania" ;;
        "ua") echo "Ukraine" ;;
        "ug") echo "Uganda" ;;
        "uk") echo "United Kingdom" ;;
        "um") echo "United States Minor Outlying Islands" ;;
        "us") echo "United States" ;;
        "uy") echo "Uruguay" ;;
        "uz") echo "Uzbekistan" ;;
        "va") echo "Vatican City Holy See" ;;
        "vc") echo "Saint Vincent Grenadines" ;;
        "ve") echo "Venezuela" ;;
        "vg") echo "British Virgin Islands" ;;
        "vi") echo "United States Virgin Islands" ;;
        "vn") echo "Vietnam" ;;
        "vu") echo "Vanuatu" ;;
        "wf") echo "Wallis Futuna" ;;
        "ws") echo "Samoa" ;;
        "xk") echo "Kosovo" ;;
        "ye") echo "Yemen" ;;
        "yt") echo "Mayotte" ;;
        "za") echo "South Africa" ;;
        "zm") echo "Zambia" ;;
        "zw") echo "Zimbabwe" ;;
        "zz") echo "Unknown" ;;
        # Add more cases for other country codes and names here
        *) echo "$code" | tr '[:lower:]' '[:upper:]' ;;
    esac
}

# #
#   continents > list
# #

declare -A continents
continents["AF"]="Africa"
continents["AN"]="Antartica"
continents["AS"]="Asia"
continents["EU"]="Europe"
continents["NA"]="North America"
continents["OC"]="Oceania"
continents["SA"]="South America"

# #
#   continent_africa.upset
# #

declare -A af
af["ao"]="AO"               # Angola
af["bf"]="BF"               # Burkina Faso
af["bi"]="BI"               # Burundi
af["bj"]="BJ"               # Benin
af["bw"]="BW"               # Botswana
af["cd"]="CD"               # DR Congo
af["cf"]="CF"               # Central African Republic
af["cg"]="CG"               # Congo Republic
af["ci"]="CI"               # Ivory Coast
af["cm"]="CM"               # Cameroon
af["cv"]="CV"               # Cabo Verde
af["dj"]="DJ"               # Djibouti
af["dz"]="DZ"               # Algeria
af["eg"]="EG"               # Egypt
af["eh"]="EH"               # Western Sahara
af["er"]="ER"               # Eritrea
af["et"]="ET"               # Ethiopia
af["ga"]="GA"               # Gabon
af["gh"]="GH"               # Ghana
af["gm"]="GM"               # Gambia
af["gn"]="GN"               # Guinea
af["gq"]="GQ"               # Equatorial Guinea
af["gw"]="GW"               # Guinea-Bissau
af["ke"]="KE"               # Kenya
af["km"]="KM"               # Comoros
af["lr"]="LR"               # Liberia
af["ls"]="LS"               # Lesotho
af["ly"]="RE"               # Libya
af["ma"]="MA"               # Morocco
af["mg"]="MG"               # Madagascar
af["ml"]="ML"               # Mali
af["mr"]="MR"               # Mauritania
af["mu"]="RU"               # Mauritius
af["mw"]="MW"               # Malawi
af["mz"]="MZ"               # Mozambique
af["na"]="NA"               # Namibia
af["ne"]="NE"               # Niger
af["ng"]="NG"               # Nigeria
af["re"]="RE"               # Réunion
af["rw"]="RW"               # Rwanda
af["sc"]="SC"               # Seychelles
af["sd"]="SD"               # Sudan
af["sh"]="SH"               # Saint Helena
af["sl"]="SL"               # Sierra Leone
af["sn"]="SN"               # Senegal
af["so"]="SO"               # Somalia
af["ss"]="SS"               # South Sudan
af["st"]="ST"               # São Tomé and Príncipe
af["sz"]="SZ"               # Eswatini
af["tg"]="TG"               # Togo
af["tn"]="TN"               # Tunisia
af["tz"]="TZ"               # Tanzania
af["ug"]="UG"               # Uganda
af["yt"]="YT"               # Mayotte
af["za"]="ZA"               # South Africa
af["zm"]="ZM"               # Zambia
af["zw"]="ZW"               # Zimbabwe

# #
#   continent_antarctica.upset
# #

declare -A an
an["aq"]="AQ"               # Antarctica
an["bv"]="BV"               # Bouvet Island
an["gs"]="GS"               # South Georgia and the South Sandwich Islands
an["hm"]="HM"               # Heard Island and McDonald Islands
an["tf"]="TF"               # French Southern Territories

# #
#   continent_asia.upset
# #

declare -A as
as["am"]="AM"               # Armenia
as["iq"]="IQ"               # Iraq
as["ir"]="IR"               # Iran
as["jo"]="JO"               # Hashemite Kingdom of Jordan
as["kw"]="KW"               # Kuwait
as["lb"]="LB"               # Lebanon
as["om"]="OM"               # Oman
as["qa"]="QA"               # Qatar
as["sa"]="SA"               # Saudi Arabia
as["sy"]="SY"               # Syria
as["ye"]="YE"               # Yemen

# #
#   continent_europe.upset
# #

declare -A eu
eu["ad"]="AD"               # Andorra
eu["al"]="AL"               # Albania
eu["at"]="AT"               # Austria
eu["ax"]="AX"               # Aland
eu["ba"]="BA"               # Bosnia and Herzegovina
eu["be"]="BE"               # Belgium
eu["bg"]="BG"               # Bulgaria
eu["by"]="BY"               # Belarus
eu["ch"]="CH"               # Switzerland
eu["cy"]="CY"               # Cyprus
eu["cz"]="CZ"               # Czechia
eu["de"]="DE"               # Germany
eu["dk"]="DK"               # Denmark
eu["ee"]="EE"               # Estonia
eu["es"]="ES"               # Spain
eu["fi"]="FI"               # Finland
eu["fo"]="FO"               # Faroe Islands
eu["fr"]="FR"               # France
eu["gb"]="GB"               # United Kingdom
eu["gg"]="GG"               # Guernsey
eu["gg"]="SM"               # San Marino
eu["gi"]="GI"               # Gibraltar
eu["gr"]="GR"               # Greece
eu["hr"]="HR"               # Croatia
eu["hu"]="HU"               # Hungary
eu["ie"]="IE"               # Ireland
eu["im"]="IM"               # Isle of Man
eu["is"]="IS"               # Iceland
eu["it"]="IT"               # Italy
eu["je"]="JE"               # Jersey
eu["li"]="LI"               # Liechtenstein
eu["lt"]="LT"               # Republic of Lithuania
eu["lu"]="LU"               # Luxembourg
eu["lv"]="LV"               # Latvia
eu["mc"]="MC"               # Monaco
eu["md"]="MD"               # Republic of Moldova
eu["me"]="ME"               # Montenegro
eu["mk"]="MK"               # North Macedonia
eu["mt"]="MT"               # Malta
eu["nl"]="NL"               # Netherlands
eu["no"]="NO"               # Norway
eu["pl"]="PL"               # Poland
eu["pt"]="PT"               # Portugal
eu["ro"]="RO"               # Romania
eu["rs"]="RS"               # Serbia
eu["ru"]="RU"               # Russia
eu["se"]="SE"               # Sweden
eu["si"]="SI"               # Slovenia
eu["sj"]="SJ"               # Svalbard and Jan Mayen
eu["sk"]="SK"               # Slovakia
eu["ua"]="UA"               # Ukraine
eu["va"]="VA"               # Vatican City
eu["xk"]="XK"               # Kosovo

# #
#   continent_north_america.upset
# #

declare -A na
na["ag"]="AG"               # Antigua and Barbuda
na["ai"]="AI"               # Anguilla
na["aw"]="AW"               # Aruba
na["bb"]="BB"               # Barbados
na["bl"]="BL"               # Saint Barthélemy
na["bm"]="BM"               # Bermuda
na["bq"]="BQ"               # Bonaire Sint Eustatius and Saba
na["bs"]="BS"               # Bahamas
na["bz"]="BZ"               # Belize
na["ca"]="CA"               # Canada
na["cr"]="CR"               # Costa Rica
na["cu"]="CU"               # Cuba
na["cw"]="CW"               # Curaçao
na["dm"]="DM"               # Dominica
na["do"]="DO"               # Dominican Republic
na["gd"]="GD"               # Grenada
na["gl"]="GL"               # Greenland
na["gp"]="GP"               # Guadeloupe
na["gt"]="GT"               # Guatemala
na["hn"]="HN"               # Honduras
na["ht"]="HT"               # Haiti
na["jm"]="JM"               # Jamaica
na["kn"]="KN"               # St Kitts and Nevis
na["ky"]="KY"               # Cayman Islands
na["lc"]="LC"               # Saint Lucia
na["mf"]="MF"               # Saint Martin
na["mq"]="MQ"               # Martinique
na["ms"]="MS"               # Montserrat
na["mx"]="MX"               # Mexico
na["ni"]="NI"               # Nicaragua
na["pa"]="PA"               # Panama
na["pm"]="PM"               # Saint Pierre and Miquelon
na["pr"]="PR"               # Puerto Rico
na["sv"]="SV"               # El Salvador
na["sx"]="SX"               # Sint Maarten
na["tc"]="TC"               # Turks and Caicos Islands
na["tt"]="TT"               # Trinidad and Tobago
na["us"]="US"               # United States
na["vc"]="VC"               # Saint Vincent and the Grenadines
na["vg"]="VG"               # British Virgin Islands
na["vi"]="VI"               # U.S. Virgin Islands

# #
#   continent_oceania.upset
# #

declare -A oc
oc["as"]="AS"               # American Samoa
oc["au"]="AU"               # Australia
oc["ck"]="CK"               # Cook Islands
oc["cx"]="CX"               # Christmas Island
oc["fj"]="FJ"               # Fiji
oc["fm"]="FM"               # Federated States of Micronesia
oc["ki"]="KI"               # Kiribati
oc["mh"]="MH"               # Marshall Islands
oc["mp"]="MP"               # Northern Mariana Islands
oc["nc"]="NC"               # New Caledonia
oc["nf"]="NF"               # Norfolk Island
oc["nr"]="NR"               # Nauru
oc["nu"]="NU"               # Niue
oc["nz"]="NZ"               # New Zealand
oc["pf"]="PF"               # French Polynesia
oc["pg"]="PG"               # Papua New Guinea
oc["pn"]="PN"               # Pitcairn Islands
oc["pw"]="PW"               # Palau
oc["sb"]="SB"               # Solomon Islands
oc["tk"]="TK"               # Tokelau
oc["tl"]="TL"               # East Timor
oc["to"]="TO"               # Tonga
oc["tv"]="TV"               # Tuvalu
oc["um"]="UM"               # U.S. Minor Outlying Islands
oc["vu"]="VU"               # Vanuatu
oc["wf"]="WF"               # Wallis and Futuna
oc["ws"]="GU"               # Guam
oc["ws"]="WS"               # Samoa

# #
#   continent_south_america.upset
# #

declare -A sa
sa["ar"]="AR"               # Argentina
sa["bo"]="BO"               # Bolivia
sa["br"]="BR"               # Brazil
sa["cl"]="CL"               # Chile
sa["co"]="CO"               # Colombia
sa["ec"]="EC"               # Ecuador
sa["fk"]="FK"               # Falkland Islands
sa["gf"]="GF"               # French Guiana
sa["gy"]="GY"               # Guyana
sa["pe"]="PE"               # Peru
sa["py"]="PY"               # Paraguay
sa["sr"]="SR"               # Suriname
sa["uy"]="UY"               # Uruguay
sa["ve"]="VE"               # Venezuela

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
#   ensure the programs needed to execute are available
# #

function CHECK_PACKAGES()
{
    local PKG="awk cat curl sed md5sum mktemp unzip"
    which ${PKG} > /dev/null 2>&1 || error "Required dependencies not found in PATH: ${PKG}"
}

# #
#   get latest MaxMind GeoLite2 IP country database and md5 checksum
#       CSV URL: https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip
#       MD5 URL: https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=LICENSE_KEY&suffix=zip.md5
#
#   if using --dry, you must manually download the .zip and .zip.md5 files and place them in the local folder assigned to the value
#       $APP_SOURCE_LOCAL
# #

function DB_DOWNLOAD()
{
    local URL_CSV="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=${LICENSE_KEY}&suffix=zip"
    local URL_MD5="${URL_CSV}.md5" # take URL_CSV value and add .md5 to end for hash file

    # #
    #   download files
    # #

    if [[ "${APP_DRYRUN}" != "true" ]] && [[ $APP_SOURCE_LOCAL_ENABLED != "true" ]]; then
        local URL_HIDDEN_CSV=$(echo $URL_CSV | sed -e "s/$LICENSE_KEY/HIDDEN/g")
        local URL_HIDDEN_MD5=$(echo $URL_MD5 | sed -e "s/$LICENSE_KEY/HIDDEN/g")

        echo -e "  🌎 Downloading file ${GREEN2}${APP_GEO_ZIP}${RESET} from ${URL_HIDDEN_CSV}"
        curl --silent --location --output $APP_GEO_ZIP "$URL_CSV" || error "Failed to curl file: ${URL_CSV}"

        echo -e "  🌎 Downloading file ${GREEN2}${APP_GEO_ZIP_MD5}${RESET} from ${URL_HIDDEN_MD5}"
        curl --silent --location --output $APP_GEO_ZIP_MD5 "$URL_MD5" || error "Failed to curl file: ${URL_MD5}"
    fi

    # #
    #   Both the .ZIP and the .CSV are missing, warn user to provide one or the other
    # #

    if [[ ! -f ${APP_GEO_ZIP} ]] && [[ ! -f ${APP_GEO_LOCS_CSV} ]]; then
        error "You must supply either the [ ZIP ${RED2}${APP_GEO_ZIP}${RESET} + MD5 hash file ${RED2}${APP_GEO_ZIP_MD5}${RESET} ] or the extracted CSV files ${RED2}${APP_GEO_LOCS_CSV}${RESET} -- Cannot locate either${RESET}"
    fi

    # #
    #   Provided the .ZIP, but not the ZIP hash file
    # #

    if [[ -f ${APP_GEO_ZIP} ]] && [[ ! -f "${APP_GEO_ZIP_MD5}" ]]; then
        error "You provided the ZIP ${RED2}${APP_GEO_ZIP}${RESET}, but did not provide the hash file ${RED2}${APP_GEO_ZIP_MD5}${RESET} -- Cannot continue${RESET}"
    fi

    # #
    #   Provided the LOCATIONS csv file, but may be missing the others
    # #

    if [[ -f ${APP_GEO_LOCS_CSV} ]]; then
        if [[ ! -f ${APP_GEO_IPV4_CSV} ]]; then
            error "You provided the LOCATION CSV ${RED2}${APP_GEO_LOCS_CSV}${RESET}, but did not provide the other needed CSV file ${RED2}$APP_GEO_IPV4_CSV${RESET} -- Cannot continue${RESET}"
        fi

        if [[ ! -f ${APP_GEO_IPV6_CSV} ]]; then
            error "You provided the LOCATION CSV ${RED2}${APP_GEO_LOCS_CSV}${RESET}, but did not provide the other needed CSV file ${RED2}$APP_GEO_IPV6_CSV${RESET} -- Cannot continue${RESET}"
        fi
    fi

    # #
    #   Provided the IPv4 csv file, but may be missing the others
    # #

    if [[ -f ${APP_GEO_IPV4_CSV} ]]; then
        if [[ ! -f ${APP_GEO_LOCS_CSV} ]]; then
            error "You provided the IPV4 CSV ${RED2}${APP_GEO_IPV4_CSV}${RESET}, the locations file ${RED2}$APP_GEO_LOCS_CSV${RESET} -- Cannot continue${RESET}"
        fi

        if [[ ! -f ${APP_GEO_IPV6_CSV} ]]; then
            error "You provided the IPV4 CSV ${RED2}${APP_GEO_LOCS_CSV}${RESET}, but did not provide the other IPv6 CSV file ${RED2}$APP_GEO_IPV6_CSV${RESET} -- Cannot continue${RESET}"
        fi
    fi

    # #
    #   Provided the IPv6 csv file, but may be missing the others
    # #

    if [[ -f ${APP_GEO_IPV6_CSV} ]]; then
        if [[ ! -f ${APP_GEO_LOCS_CSV} ]]; then
            error "You provided the IPV6 CSV ${RED2}${APP_GEO_IPV4_CSV}${RESET}, the locations file ${RED2}$APP_GEO_LOCS_CSV${RESET} -- Cannot continue${RESET}"
        fi

        if [[ ! -f ${APP_GEO_IPV4_CSV} ]]; then
            error "You provided the IPV6 CSV ${RED2}${APP_GEO_LOCS_CSV}${RESET}, but did not provide the other IPv4 CSV file ${RED2}$APP_GEO_IPV6_CSV${RESET} -- Cannot continue${RESET}"
        fi
    fi

    # #
    #   Zip files provided, check MD5
    # #

    if [[ -f ${APP_GEO_ZIP} ]] && [[ -f ${APP_GEO_ZIP_MD5} ]]; then

        echo -e "  📄 Found ZIP set ${BLUE2}${APP_GEO_ZIP}${RESET} and ${BLUE2}${APP_GEO_ZIP_MD5}${RESET}"

        local md5Response="$(cat ${APP_GEO_ZIP_MD5})"
        if [[ $md5Response == *"download limit reached"* ]]; then
            error "MaxMind: Daily download limit reached"
        fi

        # #
        #   validate checksum
        #   .md5 file is not in expected format; which means method 'md5sum --check $APP_GEO_ZIP_MD5' wont work
        # #

        [[ "$md5Response" == "$(md5sum ${TEMPDIR}/${APP_GEO_ZIP} | awk '{print $1}')" ]] || error "GeoLite2 md5 downloaded checksum does not match local md5 checksum"

        # #
        #   unzip into current working directory
        # #

        if [ -f ${APP_GEO_ZIP} ]; then
            echo -e "      📦 Unzip ${BLUE2}${APP_GEO_ZIP}${RESET}"
            unzip -o -j -q -d . ${APP_GEO_ZIP}
        else
            error "Cannot find ${RED2}${APP_GEO_ZIP}${RESET}"
        fi

    elif [[ -f ${APP_GEO_LOCS_CSV} ]] && [[ -f ${APP_GEO_IPV4_CSV} ]] && [[ -f ${APP_GEO_IPV6_CSV} ]]; then
        echo -e "  📄 Found Uncompressed set ${BLUE2}${APP_GEO_LOCS_CSV}${RESET}, ${BLUE2}${APP_GEO_IPV4_CSV}${RESET} and ${BLUE2}${APP_GEO_IPV6_CSV}${RESET}"
    else
        error "Could not find either ${ORANGE1}ZIP + MD5${RESET}, or the ${ORANGE1}uncompressed CSV files${RESET}. Aborting.${RESET}"
    fi
}

# #
#   ensure the configuration files needed to execute are available
# #

function CONFIG_LOAD()
{
    echo -e "  📄 Loading geo database files"

    local configs=(${CONFIGS_LIST})
    for f in ${configs[@]}; do
        echo -e "      📄 Mounting geo file ${BLUE2}${TEMPDIR}/${f}${RESET}"
        [[ -f $f  ]] || error "Missing geo file: $f"
    done
}

# #
#   Loads the GeoLite2 Geolite2-Country-Locations-en.csv file and grabs a list of all locations, line by line.
#
#   Two lists will be populated:
#       - CONTINENT_CODE
#       - COUNTRY_CODE
#
#   build map of geoname_id to ISO country code
#   ${MAP_COUNTRY[$geoname_id]}='country_iso_code'
#   example row: 6251999,en,NA,"North America",CA,Canada,0
#
#   CSV Structure [ Geolite2-Country-Locations-en.csv ]
#
#   Line 0          Line 1          Line 2              Line 3              Line 4                  Line 5                          Line 6
#   -------------------------------------------------------------------------------------------------------------------------------------------------------
#   geoname_id      locale_code     continent_code      continent_name      country_iso_code        country_name                    is_in_european_union
#   -------------------------------------------------------------------------------------------------------------------------------------------------------
#   49518           en              AF                  Africa              RW                      Rwanda                          0
#   69543           en              AS                  Asia                YE                      Yemen                           0
#   146669          en              EU                  Europe              CY                      Cyprus                          1
#   1546748         en              AN                  Antarctica          TF                      French Southern Territories     0
#   1559582         en              OC                  Oceania             PW                      Palau                           0
#   6252001         en              NA                  North America       US                      United States                   0
# #

function MAP_BUILD()
{
    echo -e "  🗺️  Build map"

    OIFS=$IFS
    IFS=','
    while read -ra LINE; do

        if [[ $APP_DEBUG == "true" ]]; then
            echo -e "ID ............... ${LINE[0]}"
            echo -e "Lang ............. ${LINE[1]}"
            echo -e "Continent Code ... ${LINE[2]}"
            echo -e "Continent ........ ${LINE[3]}"
            echo -e "Country Code. .... ${LINE[4]}"
            echo -e "Country .......... ${LINE[5]}"
            echo -e "In EU Union ...... ${LINE[6]}"
            echo -e
        fi

        # echo "geoname_id: ${LINE[0]} country code: ${LINE[4]}"
        CONTINENT_CODE="${LINE[2]}"
        COUNTRY_CODE="${LINE[4]}"
    
        # skip geoname_id which are not country specific (ex: Europe)
        if [[ ! -z $COUNTRY_CODE ]]; then
            MAP_COUNTRY[${LINE[0]}]=${COUNTRY_CODE}
        fi

        if [[ ! -z $CONTINENT_CODE ]]; then
            MAP_CONTINENT[${LINE[0]}]=${CONTINENT_CODE}
        fi

    done < <(sed -e 1d ${APP_GEO_LOCS_CSV})
    IFS=$OIFS
}

# #
#   Generate > IPv4
#
#   Loads the list of countries and pulls out the IPv4 addresses. Each country will have a country .tmp file created and the list of
#   ip addresses will be thrown in that file.
#
#   Continents will be placed in:
#       blocklists/country/geolite/ipv4/AN.tmp
#       blocklists/country/geolite/ipv4/AF.tmp
#       blocklists/country/geolite/ipv4/EU.tmp
#       blocklists/country/geolite/ipv4/AS.tmp
#       blocklists/country/geolite/ipv4/SA.tmp
#       blocklists/country/geolite/ipv4/NA.tmp
#       blocklists/country/geolite/ipv4/OC.tmp
#
#   Countries will be placed in:
#       blocklists/country/geolite/ipv4/AD.tmp
#       blocklists/country/geolite/ipv4/AE.tmp
#       blocklists/country/geolite/ipv4/AF.tmp
#       [ ... ]
#
#   CSV Structure [ GeoLite2-Blocks-IPv4.csv ]
#
#   Line 0          Line 1          Line 2                              Line 3                              Line 4                  Line 5                          Line 6
#   -------------------------------------------------------------------------------------------------------------------------------------------------------
#   network         geoname_id      registered_country_geoname_id       represented_country_geoname_id      is_anonymous_proxy      is_satellite_provider
#   -------------------------------------------------------------------------------------------------------------------------------------------------------
#   1.0.0.0/24                      2077456                                                                 0                       0
#   1.0.1.0/24      1814991         1814991                                                                 0                       0
#   1.0.164.0/28    1605651         1605651                                                                 0                       0
# #

function GENERATE_IPv4
{

    echo -e "  📟 Generate IPv4"
    echo -e "      📂 Remove ${RED2}${APP_DIR_IPV4}${RESET}"

    rm -rf $APP_DIR_IPV4
    echo -e "      📂 Create ${GREEN1}${APP_DIR_IPV4}${RESET}"
    mkdir --parent $APP_DIR_IPV4

    OIFS=$IFS
    IFS=','

    echo -e "      ➕ Importing IPs from database${RESET}"
    while read -ra LINE; do

        # #
        #   prefer location over registered country 
        # #

        ID="${LINE[1]}"
        if [ -z "${ID}" ]; then
            ID="${LINE[2]}"
        fi

        # #
        #   skip entry if both location and registered country are empty
        # #

        if [ -z "${ID}" ]; then
            continue
        fi

        # #
        #   If country code
        # #

        COUNTRY_CODE="${MAP_COUNTRY[${ID}]}"
        CONTINENT_CODE="${MAP_CONTINENT[${ID}]}"
        SUBNET="${LINE[0]}"
        SET_NAME="${COUNTRY_CODE}.${APP_TARGET_EXT_TMP}"

        # #
        #   iptables/ipsets
        # #

        IPSET_FILE="${APP_DIR_IPV4}/${SET_NAME}"

        # #
        #   add ip to ipset file
        # #

        if [ -z "${COUNTRY_CODE}" ] || [ "${COUNTRY_CODE}" == "" ] || [ "${COUNTRY_CODE}" == "_" ]; then
            SET_NAME="${CONTINENT_CODE}.${APP_TARGET_EXT_TMP}"
            IPSET_FILE="${APP_DIR_IPV4}/${SET_NAME}"

            if [[ $APP_DEBUG == "true" ]]; then
                echo -e "      🌎 Added continent ${CONTINENT_CODE} to ${IPSET_FILE}"
                echo -e "+ Item missing country, assigning as Continent | ID ${ID} - ${LINE[2]} | Subnet ${SUBNET} | Continent ${CONTINENT_CODE} Country ${COUNTRY_CODE} | File ${IPSET_FILE} | NAME ${SET_NAME}" >> "${APP_THIS_FILE}-ipv4-missing.log"
            fi
        fi

        # #
        #   add ip to ipset file
        # #

        if [[ $APP_DEBUG == "true" ]]; then
            echo -e "      📄 Add ${SUBNET} to ${IPSET_FILE}"
        fi

        echo "${SUBNET}" >> $IPSET_FILE

    done < <(sed -e 1d "${TEMPDIR}/${APP_GEO_IPV4_CSV}")
    IFS=$OIFS
}

# #
#   Generate > IPv6
#
#   Loads the list of countries and pulls out the IPv6 addresses. Each country will have a country .tmp file created and the list of
#   ip addresses will be thrown in that file.
#
#   Continents will be placed in:
#       blocklists/country/geolite/ipv6/AN.tmp
#       blocklists/country/geolite/ipv6/AF.tmp
#       blocklists/country/geolite/ipv6/EU.tmp
#       blocklists/country/geolite/ipv6/AS.tmp
#       blocklists/country/geolite/ipv6/SA.tmp
#       blocklists/country/geolite/ipv6/NA.tmp
#       blocklists/country/geolite/ipv6/OC.tmp
#
#   Countries will be placed in:
#       blocklists/country/geolite/ipv6/AD.tmp
#       blocklists/country/geolite/ipv6/AE.tmp
#       blocklists/country/geolite/ipv6/AF.tmp
#       [ ... ]
# #

function GENERATE_IPv6
{

    echo -e "  📟 Generate IPv6"
    echo -e "      📂 Remove ${RED2}${APP_DIR_IPV6}${RESET}"

    rm -rf $APP_DIR_IPV6
    echo -e "      📂 Create ${GREEN1}${APP_DIR_IPV6}${RESET}"
    mkdir --parent $APP_DIR_IPV6

    OIFS=$IFS
    IFS=','

    echo -e "      ➕ Importing IPs from database${RESET}"
    while read -ra LINE; do

        # #
        #   prefer location over registered country
        # #

        ID="${LINE[1]}"
        if [ -z "${ID}" ]; then
            ID="${LINE[2]}"
        fi

        # #
        #   skip entry if both location and registered country are empty
        # #

        if [ -z "${ID}" ]; then
            continue
        fi

        # #
        #   If country code
        # #

        COUNTRY_CODE="${MAP_COUNTRY[${ID}]}"
        CONTINENT_CODE="${MAP_CONTINENT[${ID}]}"
        SUBNET="${LINE[0]}"
        SET_NAME="${COUNTRY_CODE}.${APP_TARGET_EXT_TMP}"

        # #
        #   iptables/ipsets
        # #
  
        IPSET_FILE="${APP_DIR_IPV6}/${SET_NAME}"

        # #
        #   add ip to ipset file
        # #

        if [ -z "${COUNTRY_CODE}" ] || [ "${COUNTRY_CODE}" == "" ] || [ "${COUNTRY_CODE}" == "_" ]; then
            SET_NAME="${CONTINENT_CODE}.${APP_TARGET_EXT_TMP}"
            IPSET_FILE="${APP_DIR_IPV4}/${SET_NAME}"

            if [[ $APP_DEBUG == "true" ]]; then
                echo -e "      🌎 Added continent ${CONTINENT_CODE} to ${IPSET_FILE}"
                echo -e "+ Item missing country, assigning as Continent | ID ${ID} - ${LINE[2]} | Subnet ${SUBNET} | Continent ${CONTINENT_CODE} Country ${COUNTRY_CODE} | File ${IPSET_FILE} | NAME ${SET_NAME}" >> "${APP_THIS_FILE}-ipv4-missing.log"
            fi
        fi

        # #
        #   add ip to ipset file
        # #

        if [[ $APP_DEBUG == "true" ]]; then
            echo -e "      📄 Add ${SUBNET} to ${IPSET_FILE}"
        fi

        echo "${SUBNET}" >> $IPSET_FILE

    done < <(sed -e 1d "${TEMPDIR}/${APP_GEO_IPV6_CSV}")
    IFS=$OIFS

}

# #
#   Merge IPv4 and IPv6 Files
#
#   Takes all of the ipv6 addresses and merges them with the ipv4 file.
#       blocklists/country/geolite/ipv6/AD.tmp  =>  blocklists/country/geolite/ipv4/AD.tmp
#       [ DELETED ]                             =>                         [ MERGED WITH ]
#
#   Removes the ipv6 file after the merge is done.
# #

function MERGE_IPSETS()
{

    echo -e
    echo -e "  🚛 Start Merge"

    for fullpath_ipv6 in ${APP_DIR_IPV6}/*.${APP_TARGET_EXT_TMP}; do
        file_ipv6=$(basename ${fullpath_ipv6})

        if [[ $APP_DEBUG == "true" ]]; then
            # /blocklists/country/geolite/ipv6/AE.tmp to ./blocklists/country/geolite/ipv4/AE.tmp
            echo -e "  📄 Move ${fullpath_ipv6} to ${APP_DIR_IPV4}/${file_ipv6}"
        fi

        cat $fullpath_ipv6 >> ${APP_DIR_IPV4}/${file_ipv6}
        rm -rf $fullpath_ipv6
    done
}

# #
#   Cleanup Garbage
#
#   Removes old ipv4 and ipv5 folders
# #

function GARBAGE()
{
    if [ -d $APP_DIR_IPV4 ]; then
        echo -e "  🗑️  Cleanup ${APP_DIR_IPV4}"
        rm -rf ${APP_DIR_IPV4}
    fi

    if [ -d $APP_DIR_IPV6 ]; then
        echo -e "  🗑️  Cleanup ${APP_DIR_IPV6}"
       rm -rf ${APP_DIR_IPV6}
    fi

    # remove temp
    rm -rf "${APP_GITHUB_DIR}/${APP_SOURCE_TEMP}"
}

# #
#   Generate Continents
#
#   Loops through array continents to get the 7 main continents.
#   Within each loop, the other country arrays will be checked to see if that parent continent has any countries within it to list under that continent name.
#
#   CONTINENT files will be created in:
#       blocklists/country/geolite/ipv4/AN.tmp
#       blocklists/country/geolite/ipv4/AF.tmp
#       blocklists/country/geolite/ipv4/EU.tmp
#       blocklists/country/geolite/ipv4/AS.tmp
#       blocklists/country/geolite/ipv4/SA.tmp
#       blocklists/country/geolite/ipv4/NA.tmp
#       blocklists/country/geolite/ipv4/OC.tmp
#
#   COUNTRY files will be created in:
#       blocklists/country/geolite/ipv4/AD.tmp
#       blocklists/country/geolite/ipv4/AE.tmp
#       blocklists/country/geolite/ipv4/AF.tmp
#       [ ... ]
#
#   If a country exists within a continent, a new file will be created:
#       blocklists/country/geolite/ipv4/AD.tmp
#
#   If there are IP addresses with NO country specified, and are continent only, those IPs will be moved to
#   a base (parent) continent file:
#       blocklists/country/geolite/ipv4/EU.tmp
#
#   After all IPs are added for a continent, the .tmp file will be moved to its final spot:
#       blocklists/country/geolite/ipv4/EU.tmp => blocklists/country/geolite/EU.ipset
# #

function GENERATE_CONTINENTS()
{

    echo -e
    echo -e "  🏷️  Generate Continents"

    # #
    #   continents array
    #       key     value
    #       -------------------
    #       AN      Antartica
    #       AS      Asia
    #
    #       CONTINENT_NAME          = South America
    #       CONTINENT_ID            = south_america
    #       FILE_CONTINENT_TEMP     = blocklists/country/geolite/ipv4/continent_europe.tmp
    #       FILE_CONTINENT_PERM     = blocklists/country/geolite/ipv4/continent_europe.ipset
    # #

    # loop continents, antartica, europe, north america
    local TEMPL_COUNTRIES_LIST=""
    local count=0
    for key in "${!continents[@]}"; do
    
        CONTINENT_NAME=${continents[$key]}
        CONTINENT_ID=$( echo "$CONTINENT_NAME" | sed 's/ /_/g' | tr -d "[.,/\\-\=\+\{\[\]\}\!\@\#\$\%\^\*\'\\\(\)]" | tr '[:upper:]' '[:lower:]')

        FILE_CONTINENT_TEMP="$APP_DIR_IPV4/continent_$CONTINENT_ID.$APP_TARGET_EXT_TMP"             # blocklists/country/geolite/ipv4/continent_europe.tmp
        FILE_CONTINENT_PERM="$APP_TARGET_DIR/continent_$CONTINENT_ID.$APP_TARGET_EXT_PROD"          # blocklists/country/geolite/ipv4/continent_europe.ipset

        echo -e "      🌎 Generate Continent ${BLUE2}${CONTINENT_NAME}${RESET} ${GREY3}(${CONTINENT_ID})${RESET}"

        # #
        #   Return each country's ips to be included in continent file
        #       GR
        #       BG
        # #

        COUNTRY_ABBREV=$(echo "$key" | tr '[:upper:]' '[:lower:]')
        TEMPL_COUNTRIES_LIST=""
        local count=1   # start at one, since the last step is base continent file
        for country in $(eval echo \${$COUNTRY_ABBREV${i}[@]}); do
            CONTINENT_COUNTRY_NAME=$(get_country_name "$country")

            # count number of items in country array for this particular continent
            i_array=$(eval echo \${#$COUNTRY_ABBREV${i}[@]})
            i_array=$(( $i_array - 1 ))

            echo -e "          🌎 + Country ${DIM}${BLUE2}${CONTINENT_NAME}${RESET} › ${BLUE2}${CONTINENT_COUNTRY_NAME}${RESET} ${GREY2}(${country})${RESET}"

            # blocklists/country/geolite/ipv4/JE.tmp
            FILE_TARGET="$APP_DIR_IPV4/$country.$APP_TARGET_EXT_TMP"

            # check if a specific country file exists, if so, open and grab all the IPs in the list. They need to be copied to $FILE_CONTINENT_TEMP
            if [ -f "$FILE_TARGET" ]; then
                # ./blocklists/country/geolite/ipv4/VU.tmp to ./blocklists/country/geolite/ipv4/continent_oceania.tmp
                if [[ $APP_DEBUG == "true" ]]; then
                    echo -e "          📒 Add country to continent file ${ORANGE2}${FILE_TARGET}${RESET} to ${BLUE2}${FILE_CONTINENT_TEMP}${RESET}"
                fi
                APP_OUTPUT=$(cat "$FILE_TARGET" | sort_results | awk '{if (++dup[$0] == 1) print $0;}' >> ${FILE_CONTINENT_TEMP})
            else
                echo -e "          ⭕ Could not find target file $FILE_TARGET"
            fi

            # #
            #   Count and determine how countries are printed in header of file.
            #   depending on the position, the comma will be excluded on the last entry in the list
            # #

            if [ "${i_array}" == "${count}" ]; then
                if [ $((ASN_I_STEP%3)) -eq 0 ]; then
                    TEMPL_ASN_LIST+=$'\n'"#                   ${CONTINENT_COUNTRY_NAME} (${country})"
                else
                    TEMPL_ASN_LIST+="${CONTINENT_COUNTRY_NAME} (${country})"
                fi
            else
                if [ $((count%3)) -eq 0 ]; then
                    TEMPL_COUNTRIES_LIST+=$'\n'"#                   ${CONTINENT_COUNTRY_NAME} (${country}), "
                else
                    TEMPL_COUNTRIES_LIST+="${CONTINENT_COUNTRY_NAME} (${country}), "
                fi
            fi

            count=$(( count + 1 ))
        done

        # #
        #   Import the continent file
        #
        #   Looks for the continent file that contains all non-country assigned IPs. Not all continents will have one.
        #
        #   CONTINENT_BASE_TARGET
        #       blocklists/country/geolite/ipv4/AN.tmp
        #       blocklists/country/geolite/ipv4/AF.tmp
        #       blocklists/country/geolite/ipv4/EU.tmp
        #       blocklists/country/geolite/ipv4/AS.tmp
        #       blocklists/country/geolite/ipv4/SA.tmp
        #       blocklists/country/geolite/ipv4/NA.tmp
        #       blocklists/country/geolite/ipv4/OC.tmp
        # #

        CONTINENT_BASE_TARGET="$APP_DIR_IPV4/$key.$APP_TARGET_EXT_TMP"
        if [ -f "$CONTINENT_BASE_TARGET" ]; then
            echo -e "          📒 Merge base continent file ${ORANGE2}${CONTINENT_BASE_TARGET}${RESET} to ${BLUE2}${FILE_CONTINENT_TEMP}${RESET}"

            APP_OUTPUT=$(cat "$CONTINENT_BASE_TARGET" | sort_results | awk '{if (++dup[$0] == 1) print $0;}' >> ${FILE_CONTINENT_TEMP})
            echo -e
        else
            echo -e "          ⭕ Continent ${BLUE2}${CONTINENT_NAME}${RESET} doesn't have a base file to import from ${BLUE2}${CONTINENT_BASE_TARGET}${RESET} ... skipping"
        fi

        # #
        #   Confirm country temp file exists
        # #

        if [ ! -f "$FILE_TARGET" ]; then
            echo -e "          ⭕ Could not find temp country file ${ORANGE2}${FILE_CONTINENT_TEMP}${RESET}. Something failed."
            break
        fi

        # #
        #   Count statistics
        # #

        BLOCKS_COUNT_LINES=0
        BLOCKS_COUNT_TOTAL_IP=0
        BLOCKS_COUNT_TOTAL_SUBNET=0

        # blocklists/country/geolite/ipv4/continent_europe.tmp
        for line in $(cat ${FILE_CONTINENT_TEMP}); do

            # is ipv6
            if [ "$line" != "${line#*:[0-9a-fA-F]}" ]; then
                if [[ $line =~ /[0-9]{1,3}$ ]]; then
                    COUNT_TOTAL_SUBNET=$(( $COUNT_TOTAL_SUBNET + 1 ))                       # GLOBAL count subnet
                    BLOCKS_COUNT_TOTAL_SUBNET=$(( $BLOCKS_COUNT_TOTAL_SUBNET + 1 ))         # LOCAL count subnet
                else
                    COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + 1 ))                               # GLOBAL count ip
                    BLOCKS_COUNT_TOTAL_IP=$(( $BLOCKS_COUNT_TOTAL_IP + 1 ))                 # LOCAL count ip
                fi

            # is subnet
            elif [[ $line =~ /[0-9]{1,2}$ ]]; then
                ips=$(( 1 << (32 - ${line#*/}) ))

                if [[ $ips =~ $REGEX_ISNUM ]]; then
                    BLOCKS_COUNT_TOTAL_IP=$(( $BLOCKS_COUNT_TOTAL_IP + $ips ))              # LOCAL count IPs in subnet
                    BLOCKS_COUNT_TOTAL_SUBNET=$(( $BLOCKS_COUNT_TOTAL_SUBNET + 1 ))         # LOCAL count subnet

                    COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + $ips ))                            # GLOBAL count IPs in subnet
                    COUNT_TOTAL_SUBNET=$(( $COUNT_TOTAL_SUBNET + 1 ))                       # GLOBAL count subnet
                fi

            # is normal IP
            elif [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                BLOCKS_COUNT_TOTAL_IP=$(( $BLOCKS_COUNT_TOTAL_IP + 1 ))
                COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + 1 ))
            fi
        done

        # #
        #   Continents > Format block count
        # #

        BLOCKS_COUNT_LINES=$(wc -l < ${FILE_CONTINENT_TEMP})                                # LOCAL count ip lines
        COUNT_LINES=$(wc -l < ${FILE_CONTINENT_TEMP})                                       # GLOBAL count ip lines

        BLOCKS_COUNT_TOTAL_IP=$(printf "%'d" "$BLOCKS_COUNT_TOTAL_IP")                      # LOCAL add commas to thousands
        BLOCKS_COUNT_TOTAL_SUBNET=$(printf "%'d" "$BLOCKS_COUNT_TOTAL_SUBNET")              # LOCAL add commas to thousands
        BLOCKS_COUNT_LINES=$(printf "%'d" "$BLOCKS_COUNT_LINES")                            # LOCAL add commas to thousands

        echo -e "  🚛 Move ${ORANGE2}${FILE_CONTINENT_TEMP}${RESET} to ${BLUE2}${FILE_CONTINENT_PERM}${RESET}"
        mv -- "$FILE_CONTINENT_TEMP" "${FILE_CONTINENT_PERM}"
        # cp "$FILE_CONTINENT_TEMP" "${FILE_CONTINENT_PERM}"

        echo -e "  ➕ Added ${FUCHSIA2}${BLOCKS_COUNT_TOTAL_IP} IPs${RESET} and ${FUCHSIA2}${BLOCKS_COUNT_TOTAL_SUBNET} Subnets${RESET} to ${BLUE2}${FILE_CONTINENT_PERM}${RESET}"
        echo -e

        TEMPL_NAME=$(basename -- ${FILE_CONTINENT_PERM})        # file name
        TEMPL_NOW=`date -u`                                     # get current date in utc format
        TEMPL_ID=$(basename -- ${FILE_CONTINENT_PERM})          # ipset id, get base filename
        TEMPL_ID="${TEMPL_ID//[^[:alnum:]]/_}"                  # ipset id, only allow alphanum and underscore, /description/* and /category/* files must match this value
        TEMPL_UUID=$(uuidgen -m -N "${TEMPL_ID}" -n @url)       # uuid associated to each release
        TEMPL_DESC=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/descriptions/countries/geolite2_ipset.txt")
        TEMPL_CAT=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/categories/countries/geolite2_ipset.txt")
        TEMPL_EXP=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/expires/countries/geolite2_ipset.txt")
        TEMP_URL_SRC=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/url-source/countries/geolite2_ipset.txt")

        # #
        #   Continents > Default Values
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
        #   ed
        #       0a  top of file
        # #

ed -s ${FILE_CONTINENT_PERM} <<END_ED
0a
# #
#   🧱 Firewall Blocklist - ${TEMPL_NAME}
#
#   @url            https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/${FILE_CONTINENT_PERM}
#   @source         ${TEMP_URL_SRC}
#   @id             ${TEMPL_ID}
#   @uuid           ${TEMPL_UUID}
#   @updated        ${TEMPL_NOW}
#   @entries        ${BLOCKS_COUNT_TOTAL_IP} ips
#                   ${BLOCKS_COUNT_TOTAL_SUBNET} subnets
#                   ${BLOCKS_COUNT_LINES} lines
#   @continent      ${CONTINENT_NAME} (${key})
#   @countries      ${TEMPL_COUNTRIES_LIST}
#   @expires        ${TEMPL_EXP}
#   @category       ${TEMPL_CAT}
#
${TEMPL_DESC}
# #

.
w
q
END_ED

    done

    # #
    #   Continents > Count lines and subnets
    # #

    COUNT_TOTAL_IP=$(printf "%'d" "$COUNT_TOTAL_IP")                                    # GLOBAL add commas to thousands
    COUNT_TOTAL_SUBNET=$(printf "%'d" "$COUNT_TOTAL_SUBNET")                            # GLOBAL add commas to thousands

    # #
    #   Continents > Finished
    # #

    T=$SECONDS
    D=$((T/86400))
    H=$((T/3600%24))
    M=$((T/60%60))
    S=$((T%60))

    echo -e "  🎌 ${GREY2}Finished! ${YELLOW2}${D} days ${H} hrs ${M} mins ${S} secs${RESET}"

    # #
    #   Continents > Output
    # #

    echo -e
    echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"
    echo -e "  #️⃣ ${BLUE2}${FILE_CONTINENT_PERM}${RESET} | Added ${FUCHSIA2}${COUNT_TOTAL_IP} IPs${RESET} and ${FUCHSIA2}${COUNT_TOTAL_SUBNET} Subnets${RESET}"
    echo -e " ──────────────────────────────────────────────────────────────────────────────────────────────"
    echo -e
    echo -e
    echo -e

}

# #
#   Generate Countries
#
#   Loops through each file in blocklists/country/geolite/ipv4/*
#   Counts the statistics:
#       - Number of lines in file
#       - Number of normal IPs
#       - Number of subnets
#
#   Header will be added to the top of the file which statistics and other info.
#
#   File will be re-named / moved:
#       blocklists/country/geolite/ipv4/AE.tmp => blocklists/country/geolite/AE.ipset
# #

function GENERATE_COUNTRIES()
{

    echo -e
    echo -e "  🔖  Generate Countries"

    # #
    #   Loop each temp file
    #       CA.TMP
    #       US.TMP
    # #

    COUNT_TOTAL_IP=0
    COUNT_TOTAL_SUBNET=0

    for APP_FILE_TEMP in ./${APP_DIR_IPV4}/*.${APP_TARGET_EXT_TMP}; do

        file_temp_base=$(basename -- ${APP_FILE_TEMP})                                      # get two letter country code
        COUNTRY_CODE="${file_temp_base%.*}"                                                 # base file without extension
        COUNTRY=$(get_country_name "$COUNTRY_CODE")                                         # get full country name from abbreviation

        echo -e "  📒 + Country ${GREY2}${COUNTRY}${RESET} to ${ORANGE2}${APP_FILE_TEMP}${RESET}"
        COUNTRY_ID=$(echo "$COUNTRY" | sed 's/ /_/g' | tr -d "[.,/\\-\=\+\{\[\]\}\!\@\#\$\%\^\*\'\\\(\)]" | tr '[:upper:]' '[:lower:]') # country long name with spaces, special chars removed

        APP_FILE_TEMP=${APP_FILE_TEMP#././}                                                 # remove ./ from front which means us with just the temp path
        APP_FILE_PERM="${APP_TARGET_DIR}/country_${COUNTRY_ID}.${APP_TARGET_EXT_PROD}"      # final location where ipset files should be

        # #
        #   calculate how many IPs are in a subnet
        #   if you want to calculate the USABLE IP addresses, subtract -2 from any subnet not ending with 31 or 32.
        #   
        #   for our purpose, we want to block them all in the event that the network has reconfigured their network / broadcast IPs,
        #   so we will count every IP in the block.
        # #

        BLOCKS_COUNT_LINES=0
        BLOCKS_COUNT_TOTAL_IP=0
        BLOCKS_COUNT_TOTAL_SUBNET=0

        echo -e "  📊 Fetching statistics for clean file ${ORANGE2}${APP_FILE_TEMP}${RESET}"
        for line in $(cat ${APP_FILE_TEMP}); do

            # is ipv6
            if [ "$line" != "${line#*:[0-9a-fA-F]}" ]; then
                if [[ $line =~ /[0-9]{1,3}$ ]]; then
                    COUNT_TOTAL_SUBNET=$(( $COUNT_TOTAL_SUBNET + 1 ))                       # GLOBAL count subnet
                    BLOCKS_COUNT_TOTAL_SUBNET=$(( $BLOCKS_COUNT_TOTAL_SUBNET + 1 ))         # LOCAL count subnet
                else
                    COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + 1 ))                               # GLOBAL count ip
                    BLOCKS_COUNT_TOTAL_IP=$(( $BLOCKS_COUNT_TOTAL_IP + 1 ))                 # LOCAL count ip
                fi

            # is subnet
            elif [[ $line =~ /[0-9]{1,2}$ ]]; then
                ips=$(( 1 << (32 - ${line#*/}) ))

                if [[ $ips =~ $REGEX_ISNUM ]]; then
                    BLOCKS_COUNT_TOTAL_IP=$(( $BLOCKS_COUNT_TOTAL_IP + $ips ))              # LOCAL count IPs in subnet
                    BLOCKS_COUNT_TOTAL_SUBNET=$(( $BLOCKS_COUNT_TOTAL_SUBNET + 1 ))         # LOCAL count subnet

                    COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + $ips ))                            # GLOBAL count IPs in subnet
                    COUNT_TOTAL_SUBNET=$(( $COUNT_TOTAL_SUBNET + 1 ))                       # GLOBAL count subnet
                fi

            # is normal IP
            elif [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                BLOCKS_COUNT_TOTAL_IP=$(( $BLOCKS_COUNT_TOTAL_IP + 1 ))
                COUNT_TOTAL_IP=$(( $COUNT_TOTAL_IP + 1 ))
            fi
        done

        # #
        #   Format block count
        # #

        BLOCKS_COUNT_LINES=$(wc -l < ${APP_FILE_TEMP})
        COUNT_LINES=$(wc -l < ${APP_FILE_TEMP})                                             # GLOBAL count ip lines

        BLOCKS_COUNT_TOTAL_IP=$(printf "%'d" "$BLOCKS_COUNT_TOTAL_IP")                      # LOCAL add commas to thousands
        BLOCKS_COUNT_TOTAL_SUBNET=$(printf "%'d" "$BLOCKS_COUNT_TOTAL_SUBNET")              # LOCAL add commas to thousands
        BLOCKS_COUNT_LINES=$(printf "%'d" "$BLOCKS_COUNT_LINES")                            # LOCAL add commas to thousands

        echo -e "  🚛 Move ${ORANGE2}${APP_FILE_TEMP}${RESET} to ${BLUE2}${APP_FILE_PERM}${RESET}"
        mv -- "$APP_FILE_TEMP" "${APP_FILE_PERM}"
        # cp "$APP_FILE_TEMP" "${APP_FILE_PERM}"

        echo -e "  ➕ Added ${FUCHSIA2}${BLOCKS_COUNT_TOTAL_IP} IPs${RESET} and ${FUCHSIA2}${BLOCKS_COUNT_TOTAL_SUBNET} subnets${RESET} to ${BLUE2}${APP_FILE_PERM}${RESET}"
        echo -e

        TEMPL_NAME=$(basename -- ${APP_FILE_PERM})              # file name
        TEMPL_NOW=`date -u`                                     # get current date in utc format
        TEMPL_ID=$(basename -- ${APP_FILE_PERM})                # ipset id, get base filename
        TEMPL_ID="${TEMPL_ID//[^[:alnum:]]/_}"                  # ipset id, only allow alphanum and underscore, /description/* and /category/* files must match this value
        TEMPL_UUID=$(uuidgen -m -N "${TEMPL_ID}" -n @url)       # uuid associated to each release
        TEMPL_DESC=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/descriptions/countries/geolite2_ipset.txt")
        TEMPL_CAT=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/categories/countries/geolite2_ipset.txt")
        TEMPL_EXP=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/expires/countries/geolite2_ipset.txt")
        TEMP_URL_SRC=$(curl -sSL -A "${APP_CURL_AGENT}" "https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/.github/url-source/countries/geolite2_ipset.txt")

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
        #   ed
        #       0a  top of file
        # #

ed -s ${APP_FILE_PERM} <<END_ED
0a
# #
#   🧱 Firewall Blocklist - ${TEMPL_NAME}
#
#   @url            https://raw.githubusercontent.com/${APP_REPO}/${APP_REPO_BRANCH}/${APP_FILE_PERM}
#   @source         ${TEMP_URL_SRC}
#   @id             ${TEMPL_ID}
#   @uuid           ${TEMPL_UUID}
#   @updated        ${TEMPL_NOW}
#   @entries        ${BLOCKS_COUNT_TOTAL_IP} ips
#                   ${BLOCKS_COUNT_TOTAL_SUBNET} subnets
#                   ${BLOCKS_COUNT_LINES} lines
#   @country        ${COUNTRY} (${COUNTRY_CODE})
#   @expires        ${TEMPL_EXP}
#   @category       ${TEMPL_CAT}
#
${TEMPL_DESC}
# #

.
w
q
END_ED

    done

    # #
    #   Count lines and subnets
    # #

    COUNT_TOTAL_IP=$(printf "%'d" "$COUNT_TOTAL_IP")                                    # GLOBAL add commas to thousands
    COUNT_TOTAL_SUBNET=$(printf "%'d" "$COUNT_TOTAL_SUBNET")                            # GLOBAL add commas to thousands

    # #
    #   Run garbge cleanup
    # #

    GARBAGE

    # #
    #   Countries > Finished
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

}

# #
#   Main Function
#
#   Accepts -p (parameters)
#     ./script -p LICENSE_KEY
# #

function main()
{

    # #
    #   get license key
    # #

    if [ -f "${APP_THIS_DIR}/${APP_CFG_FILE}" ]; then
        echo -e "Loading config ${APP_THIS_DIR}/${APP_CFG_FILE}"
        source "${APP_THIS_DIR}/${APP_CFG_FILE}" > /dev/null 2>&1
    fi

    if [[ -z "${APP_SOURCE_LOCAL_ENABLED}" ]] && [[ -z "${LICENSE_KEY}" ]]; then
        error "Must supply a valid MaxMind license key -- aborting"
    fi

    # #
    #   Start
    # #

    echo -e
    echo -e "  ⭐ Starting script ${GREEN1}${APP_THIS_FILE}${RESET}"

    # #
    #   Check Packages
    #
    #   ensure all the packages we need are installed on the system.
    # #

    CHECK_PACKAGES

    # #
    #   Temp Path
    #
    #   Local Mode          .github/local
    #   Network Mode        .github/.temp
    # #

    if [[ $APP_SOURCE_LOCAL_ENABLED == "false" ]]; then
       # export TEMPDIR=$(mktemp --directory "${APP_GITHUB_DIR}/${APP_SOURCE_TEMP}")
        mkdir -p "${APP_GITHUB_DIR}/${APP_SOURCE_TEMP}"
        export TEMPDIR="${APP_GITHUB_DIR}/${APP_SOURCE_TEMP}"
    else
        mkdir -p "${APP_GITHUB_DIR}/${APP_SOURCE_LOCAL}"
        export TEMPDIR="${APP_GITHUB_DIR}/${APP_SOURCE_LOCAL}"
    fi

    # #
    #   place geolite data in temporary directory
    # #

    echo -e "  ⚙️  Setting temp folder ${YELLOW2}${TEMPDIR}${RESET}"
    pushd ${TEMPDIR} > /dev/null 2>&1
  
    # #
    #   Download / Unzip .zip
    # #

    DB_DOWNLOAD


    CONFIG_LOAD
    MAP_BUILD

    # #
    #   @TODO       add caching for associative array
    # #

    mkdir -p "${APP_GITHUB_DIR}/${APP_SOURCE_CACHE}"

    declare -p MAP_CONTINENT > ${APP_GITHUB_DIR}/${APP_SOURCE_CACHE}/MAP_CONTINENT.cache
    declare -p MAP_COUNTRY > ${APP_GITHUB_DIR}/${APP_SOURCE_CACHE}/MAP_COUNTRY.cache

    if [[ $APP_DEBUG == "true" ]]; then
        for KEY in "${!MAP_CONTINENT[@]}"; do
            printf "%s --> %s\n" "$KEY" "${MAP_CONTINENT[$KEY]}"
        done | tee "${APP_GITHUB_DIR}/.logs/MAP_CONTINENT.log"

        for KEY in "${!MAP_COUNTRY[@]}"; do
            printf "%s --> %s\n" "$KEY" "${MAP_COUNTRY[$KEY]}"
        done | tee "${APP_GITHUB_DIR}/.logs/MAP_COUNTRY.log"
    fi

    # #
    #   place set output in current working directory
    # #

    popd > /dev/null 2>&1

    # #
    #   Cleanup old files
    # #

    rm -rf $APP_TARGET_DIR/*

    rm -rf $APP_DIR_IPV4
    mkdir --parent $APP_DIR_IPV4

    rm -rf $APP_DIR_IPV6
    mkdir --parent $APP_DIR_IPV6

    # #
    #   Run actions
    # #

    GENERATE_IPv4
    GENERATE_IPv6
    MERGE_IPSETS
    GENERATE_CONTINENTS
    GENERATE_COUNTRIES
    GARBAGE
}

main "$@"
