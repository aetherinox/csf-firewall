#!/bin/bash

# #
#   
#   ConfigServer Firewall - Whitelist IPs & Ports
#   
#   @author         Aetherinox
#   @package        ConfigServer Firewall
#   @file           ports-whitelist
#   @type           Patch
#   @desc           This CSF script will whitelist the specified IP addresses for certain ports and then
#                   drop all other attempted connections.
#   
#   @usage          chmod +x /usr/local/include/csf/post.d/ports-whitelist.sh
#                   sudo /usr/local/include/csf/post.d/ports-whitelist.sh
# #

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# #
#   Settings > Whitelisted IPs & Ports
#
#   LIST_PORTS                  List of ports to block off from outside access
#                               Port 9001 is used in the example, which is the Portainer Agent
#   LIST_IPS                    List of ip address blocks you will be using for your docker setup. these blocks will be whitelisted through ConfigServer Firewall
# #

LIST_PORTS=(
    '9001'
)

LIST_IPS=(
    'XX.XX.XX.XX'
)

# #
#   vars > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   vars > app
# #

app_title="ConfigServer Firewall - Drop Ports"
app_about="Whitelist certain IP addresses for specific ports; DROP all other connections"
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
#   vars > app repo
# #

repo_name="csf-firewall"
repo_author="Aetherinox"
repo_branch="main"
repo_url="https://github.com/${repo_author}/${repo_name}"

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
NAVY=$'\e[38;5;99m'
OLIVE=$'\e[38;5;144m'
PEACH=$'\e[38;5;210m'

# #
#   print an error and exit with failure
#   $1: error message
# #

function error()
{
    echo -e "  ⭕ ${GREY2}${app_file_this}${RESET}: \n     ${BOLD}${RED}Error${NORMAL}: ${RESET}$1"
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
#   Find CSF path on system
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
#   iptables > assign path to var
# #

path_iptables4=$(which iptables)
path_iptables6=$(which ip6tables)

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
#   Display Usage Help
#
#   activate using ./install.sh --help or -h
# #

opt_usage()
{
    echo -e 
    printf "  ${BLUE2}${app_title}${RESET}\n" 1>&2
    printf "  ${GREY2}${app_about}${RESET}\n" 1>&2
    echo -e 
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREY2}options${RESET}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREY2}-h${RESET}] [${GREY2}-v${RESET}] [${GREY2}-d${RESET}]" 1>&2
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
    -d|--dev)
            OPT_DEV_ENABLE=true
            echo -e "  ${MAGENTA}${BLINK}Devmode Enabled${RESET}"
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -v|--version)
            echo
            echo -e "  ${GREEN2}${BOLD}${app_title}${RESET} - v$(get_version)${RESET}"
            echo -e "  ${GREY2}${BOLD}${repo_url}${RESET}"
            echo -e "  ${GREY2}${BOLD}${sys_os} | ${sys_os}${RESET}"
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
#   check if DOCKER-USER chain exists; flush if true, create if false
# #

if ${path_iptables4} -L DOCKER &> /dev/null; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER-USER   ${WHITE}Flushing existing chain DOCKER-USER${RESET}"
    ${path_iptables4} -F DOCKER-USER
else
    echo -e "  ${BOLD}${GREY1}+ DOCKER-USER   ${WHITE}Creating chain DOCKER-USER${RESET}"
    ${path_iptables4} -N DOCKER-USER
fi

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
#   whitelist ip addresses associated with docker
# #

echo -e
echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
echo -e

echo -e "  ${BOLD}${GREY1}+ DOCKER-USER   ${WHITE}Add whitelisted IPs for Portainer${RESET}"

for j in "${!LIST_IPS[@]}"; do

    # #
    #   get ip addresses
    # #

    ip_whitelist=${LIST_IPS[$j]}
    echo -e "  ${BOLD}${WHITE}                + ${YELLOW2}${ip_whitelist}${RESET}"

    # #
    #   Masquerade outbound connections from containers
    # #

    for p in "${!LIST_PORTS[@]}"; do

        PORT=${LIST_PORTS[$p]}

        # #
        #   Old Rule
        # #
    
        # ${path_iptables4} -I DOCKER-USER 1 -s ${ip_whitelist} -p tcp -m conntrack --ctorigdstport ${PORT} -j ACCEPT
        # echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-I DOCKER-USER -s ${ip_whitelist} -p tcp -m conntrack --ctorigdstport ${PORT} -j ACCEPT${RESET}"

        ${path_iptables4} -I DOCKER-USER 1 -p tcp --dport ${PORT} -s ${ip_whitelist} -j ACCEPT
        ${path_iptables4} -I DOCKER-USER 1 -p tcp --dport ${PORT} -d ${ip_whitelist} -j ACCEPT

        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-I DOCKER-USER 1 -p tcp --dport ${PORT} -s ${ip_whitelist} -j ACCEPT${RESET}"
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-I DOCKER-USER 1 -p tcp --dport ${PORT} -d ${ip_whitelist} -j ACCEPT${RESET}"

    done

    echo -e
done

# #
#   Block access to port
# #

for j in "${!LIST_PORTS[@]}"; do
    PORT=${LIST_PORTS[$j]}

    ${path_iptables4} -A DOCKER-USER -p tcp --dport ${PORT} -j DROP
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-I DOCKER-USER 1 -p tcp --dport ${PORT} -j DROP${RESET}"
done

# #
#   Separator
# #

echo -e
echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
echo -e

echo -e
echo -e
