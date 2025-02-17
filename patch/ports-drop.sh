#!/bin/bash

# #
#   
#   ConfigServer Firewall - Drop & Block Ports
#   
#   @author         Aetherinox
#   @package        ConfigServer Firewall
#   @file           ports-drop
#   @type           Patch
#   @desc           This CSF script ensures that certain ports cannot be accessed at all.
#                   Add each port you wish to block to the table `BLACKLIST_PORTS`.
#                   This method adds the port into iptables, it does NOT make use of ipsets.
#   
#   @usage          chmod +x /usr/local/include/csf/post.d/ports-drop.sh
#                   sudo /usr/local/include/csf/post.d/ports-drop.sh
#   
# #

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# #
#   Settings > Ports
# #

BLACKLIST_PORTS=$(cat <<EOF
[
    {"port":"111", "comment":"used by rpcbind, has vulnerabilities"}
]
EOF
)

# #
#   define > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   define > app
# #

app_title="ConfigServer Firewall - Drop Ports"
app_about="Ensures that certain ports cannot be accessed at all by the outside world"
app_ver=("14" "22" "0")
app_dir_this_a="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
app_dir_this_b="${PWD}"                                 # current script directory
app_file_this=$(basename "$0")                          # ports-block.sh (with ext)
app_file_bin="${app_file_this%.*}"                      # ports-block (without ext)
app_pid=$BASHPID

# #
#   define > configs
# #

cfg_dev_enabled=false
cfg_verbose_enabled=false

# #
#   define > app repo
# #

repo_name="csf-firewall"
repo_author="Aetherinox"
repo_branch="main"
repo_url="https://github.com/${repo_author}/${repo_name}"

# #
#   define > colors
#
#   Use the color table at:
#       - https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
# #

END=$'\e[0m'
WHITE=$'\e[97m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
UNDERLINE=$'\e[4m'
STRIKE=$'\e[9m'
BLINK=$'\e[5m'
INVERTED=$'\e[7m'
HIDDEN=$'\e[8m'
BLACK=$'\e[38;5;0m'
FUCHSIA1=$'\e[38;5;205m'
FUCHSIA2=$'\e[38;5;198m'
RED=$'\e[38;5;160m'
RED2=$'\e[38;5;196m'
ORANGE=$'\e[38;5;202m'
ORANGE2=$'\e[38;5;208m'
MAGENTA=$'\e[38;5;5m'
BLUE=$'\e[38;5;033m'
BLUE2=$'\e[38;5;39m'
BLUE3=$'\e[38;5;68m'
CYAN=$'\e[38;5;51m'
GREEN=$'\e[38;5;2m'
GREEN2=$'\e[38;5;76m'
YELLOW=$'\e[38;5;184m'
YELLOW2=$'\e[38;5;190m'
YELLOW3=$'\e[38;5;193m'
GREY1=$'\e[38;5;240m'
GREY2=$'\e[38;5;244m'
GREY3=$'\e[38;5;250m'
NAVY=$'\e[38;5;62m'
OLIVE=$'\e[38;5;144m'
PEACH=$'\e[38;5;210m'

# #
#   print an error and exit with failure
#   $1: error message
# #

function error()
{
    echo -e "  ⭕ ${GREY2}${app_file_this}${END}: \n     ${BOLD}${RED}Error${END}: ${END}$1"
    echo -e
    exit 0
}

# #
#   Check Sudo
#
#	this script requires permissions to copy, etc.
# 	require the user to run as sudo
# #

check_sudo()
{
	if [ "$EUID" -ne 0 ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Must run script with ${YELLOW2}sudo${END}"
        echo -e "                    ${GREY2}sudo ./${app_file_this}${END}"

        exit 1
	fi
}

# #
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
# #

get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
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
    ver_join=${app_ver[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

# #
#   define > CSF path on system
# #

csf_path=$(command -v csf)

# #
#   distro
#
#   returns distro information.
# #

    # #
    #   freedesktop.org and systemd
    # #

        if [ -f /etc/os-release ]; then
            . /etc/os-release
            sys_os=$NAME
            sys_os_ver=$VERSION_ID

    # #
    #   linuxbase.org
    # #

        elif type lsb_release >/dev/null 2>&1; then
            sys_os=$(lsb_release -si)
            sys_os_ver=$(lsb_release -sr)

    # #
    #   versions of Debian/Ubuntu without lsb_release cmd
    # #

        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            sys_os=$DISTRIB_ID
            sys_os_ver=$DISTRIB_RELEASE

    # #
    #   older Debian/Ubuntu/etc distros
    # #

        elif [ -f /etc/debian_version ]; then
            sys_os=Debian
            sys_os_ver=$(cat /etc/debian_version)

    # #
    #   fallback: uname, e.g. "Linux <version>", also works for BSD
    # #

        else
            sys_os=$(uname -s)
            sys_os_ver=$(uname -r)
        fi

# #
#   Ensure we're in the correct directory
# #

cd "${app_dir_this_a}"

# #
#   find > iptables
# #

if ! [ -x "$(command -v iptables)" ]; then
    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}iptables${END}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install iptables -y -qq >/dev/null 2>&1
fi

# #
#   find > ipset
# #

if ! [ -x "$(command -v ipset)" ]; then
    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}ipset${END}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install ipset -y -qq >/dev/null 2>&1
fi

# #
#   iptables > assign path to var
# #

path_iptables4=$(which iptables)
path_iptables6=$(which ip6tables)
path_ipset=$(which ipset)

# #
#   empty var > iptables4
# #

if [ -z "${path_iptables4}" ]; then
    echo
    echo -e "  ${ORANGE}WARNING      ${WHITE}Could not locate the package ${YELLOW2}iptables${END}"
    echo -e "               This package is required before you can utilize this script with ConfigServer Firewall.${END}"
    echo
    echo -e "  ${BOLD}${WHITE}Try installing the package with:${END}"
    echo -e "  ${BOLD}${WHITE}     sudo apt-get update${END}"
    echo -e "  ${BOLD}${WHITE}     sudo apt-get install iptables${END}"

    exit 0
fi

# #
#   empty var > ipset
# #

if [ -z "${path_ipset}" ]; then
    echo
    echo -e "  ${ORANGE}WARNING      ${WHITE}Could not locate the package ${YELLOW2}ipset${END}"
    echo -e "               This package is required before you can utilize this script with ConfigServer Firewall.${END}"
    echo
    echo -e "  ${BOLD}${WHITE}Try installing the package with:${END}"
    echo -e "  ${BOLD}${WHITE}     sudo apt-get update${END}"
    echo -e "  ${BOLD}${WHITE}     sudo apt-get install ipset${END}"

    exit 0
fi

# #
#   Display Usage Help
#
#   activate using ./ports-block.sh --help or -h
# #

opt_usage()
{
    echo -e 
    printf "  ${BLUE}${app_title}${END}\n" 1>&2
    printf "  ${GREY2}${app_about}${END}\n" 1>&2
    echo -e 
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREY2}options${END}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREY2}-h${END}] [${GREY2}-v${END}] [${GREY2}-d${END}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "developer mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "displays advanced logs" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of csf script" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    echo -e 
    echo -e 
    exit 1
}

# #
#   command-line options
#
#   reminder that any functions which need executed must be defined BEFORE
#   this point. Bash sucks like that.
#
#   --dev           show advanced printing
#   --help          show help and usage information
#   --version       display version information
# #

while [ $# -gt 0 ]; do
    case "$1" in
        -h*|--help*)
            opt_usage
            ;;

        -d|--dev)
            cfg_dev_enabled=true
            echo -e "  ${MAGENTA}MODE         ${END}Developer Enabled${END}"
            ;;

        -V|--verbose)
            cfg_verbose_enabled=true
            echo -e "  ${MAGENTA}MODE         ${END}Verbose Enabled${END}"
            ;;

        -c|--clean)

            # #
            #   this argument removes all iptable and blacklist rules from your server.
            #   any ips that were previously restricted, will now be able to access your server again.
            # #

            echo

            for row in $(echo "${BLACKLIST_PORTS}" | jq -r '.[] | @base64'); do

                _jq()
                {
                    echo ${row} | base64 --decode | jq -r ${1}
                }

                ENTRY_PORT=$(_jq '.port')
                ENTRY_COMMENT=$(_jq '.comment')
                
                echo -e "  ${BOLD}${GREY1}+ BLACKLIST     ${WHITE}Checking port ${BLUE2}${ENTRY_PORT}${END}${END}"

                # #
                #   See if ports already exist in iptables
                # #

                DELETE_INPUT_UDP=0
                DELETE_INPUT_TCP=0
                sudo ${path_iptables4} -C INPUT -p udp --dport ${ENTRY_PORT} -j DROP >/dev/null 2>&1 || DELETE_INPUT_UDP=1
                sudo ${path_iptables4} -C INPUT -p tcp --dport ${ENTRY_PORT} -j DROP >/dev/null 2>&1 || DELETE_INPUT_TCP=1

                # #
                #   UDP
                # #

                if [ "$DELETE_INPUT_UDP" == "0" ]; then
                    sudo ${path_iptables4} -D INPUT -p udp  --dport ${ENTRY_PORT} -j DROP
                    echo -e "  ${BOLD}${WHITE}                 ✓ ${GREY1}Opened UDP port on chain INPUT chain${END}"
                else
                    echo -e "  ${BOLD}${WHITE}                 ✓ ${GREY1}Skip DELETE for chain INPUT; port not blocked${END}"
                fi

                # #
                #   TCP
                # #

                if [ "$DELETE_INPUT_TCP" == "0" ]; then
                    sudo ${path_iptables4} -D INPUT -p tcp  --dport ${ENTRY_PORT} -j DROP
                    echo -e "  ${BOLD}${WHITE}                 ✓ ${GREY1}Opened TCP port on chain INPUT chain${END}"
                else
                    echo -e "  ${BOLD}${WHITE}                 ✓ ${GREY1}Skip DELETE for chain INPUT; port not blocked${END}"
                fi

            done

            echo
            echo -e "  ${ORANGE}WARNING         ${END}Ports have been unblocked${END}"
            echo -e "                  The ports listed above have been unblocked from iptables, which means that they may now${END}"
            echo -e "                  be utilized to access your server.${END}"
            echo

            exit 1
            ;;

        -v|--version)
            echo
            echo -e "  ${GREEN2}${BOLD}${app_title}${END} - v$(get_version)${END}"
            echo -e "  ${GREY2}${BOLD}${repo_url}${END}"
            echo -e "  ${GREY2}${BOLD}${sys_os} | ${sys_os_ver}${END}"
            echo
            exit 1
            ;;
        *)
            opt_usage
            ;;
    esac
    shift
done

# #
#   Chain Exists
# #

chain_exists()
{
    [ $# -lt 1 -o $# -gt 2 ] && {
        echo "Usage: chain_exists <chain_name> [table]" >&2
        return 1
    }

    local chain_name="$1" ; shift
    [ $# -eq 1 ] && local table="--table $1"

    ${path_iptables4} $table -n --list "$chain_name" >/dev/null 2>&1
}

# #
#   Loop blacklists, create if missing
# #

echo -e
echo -e "  ${BOLD}${GREY1}+ RESTRICT      ${WHITE}Banning Ports${END}"

for row in $(echo "${BLACKLIST_PORTS}" | jq -r '.[] | @base64'); do
    _jq()
    {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    ENTRY_PORT=$(_jq '.port')
    ENTRY_COMMENT=$(_jq '.comment')
    
    # #
    #   See if ports already exist in iptables
    # #

    DELETE_INPUT_UDP=0
    DELETE_INPUT_TCP=0
    sudo ${path_iptables4} -C INPUT -p udp --dport ${ENTRY_PORT} -j DROP >/dev/null 2>&1 || DELETE_INPUT_UDP=1
    sudo ${path_iptables4} -C INPUT -p tcp --dport ${ENTRY_PORT} -j DROP >/dev/null 2>&1 || DELETE_INPUT_TCP=1

    # #
    #   Drop Port > UDP
    # #

    if [ "$DELETE_INPUT_UDP" == "0" ]; then
        echo -e "  ${BOLD}${WHITE}                 ✓ ${GREY1}Port already blocked${END}"
    else
        sudo ${path_iptables4} -I INPUT -p udp --dport ${ENTRY_PORT} -j DROP
        printf '%-17s %-50s %-55s\n' " " "${GREY1} ├─ Ban ${GREEN}$ENTRY_PORT (UDP)" "${GREY1}${ENTRY_COMMENT}${END}"
    fi

    # #
    #   Drop Port > TCP
    # #

    if [ "$DELETE_INPUT_TCP" == "0" ]; then
        echo -e "  ${BOLD}${WHITE}                 ✓ ${GREY1}Port already blocked${END}"
    else
        sudo ${path_iptables4} -I INPUT -p tcp --dport ${ENTRY_PORT} -j DROP
        printf '%-17s %-50s %-55s\n' " " "${GREY1} ├─ Ban ${GREEN}$ENTRY_PORT (TCP)" "${GREY1}${ENTRY_COMMENT}${END}"
    fi

done

echo -e
echo -e
