#!/bin/bash

# #
#   CSF OpenVPN Script
#
#   this script adds iptable / csf firewall rules so that you can still host an OpenVPN server
#   and also use ConfigServer Firewall.
#
#   run using one of the following commands:
#       - ./install.sh
#       - sh install.sh
#
#   Please scroll down to see available config options.
# #

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# #
#   Configs
#
#   ETH_ADAPTER                 : primary ethernet adapter. these are usually eth* or enp.
#                                 to manually specify your network adapter, replace the code with the name.
#                                 ETH_ADAPTER="eth0"
#
#   TUN_ADAPTER                 : primary openvpn tun adapter. this is usually tun*
#                                 to manually specify your tunnel adapter name, replace the code with the name.
#                                 TUN_ADAPTER="tun0"
#
#   IP_PUBLIC                   : by default, the script attempts to automatically find your public IP address.
#                                 if you wish to manually define the IP address, replace the code with your IP
#                                 IP_PUBLIC="xx.xx.xx.xx"
#
#   DEBUG_ENABLED               : debugging mode; throws prints during various steps
#   
# #

ETH_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
TUN_ADAPTER=$(ip -br l | awk '$1 ~ "^tun[0-9]" { print $1}')
IP_PUBLIC=$(curl -s ipinfo.io/ip)
DEBUG_ENABLED="false"

# #
#   list > vpn ips
#
#   this is the IP pool assigned to a user who connects to your vpn server
# #

IP_POOL=(
    '10.8.0.0/24'
)

# #
#   vars > colors
#
#   tput setab  [1-7]       : Set a background color using ANSI escape
#   tput setb   [1-7]       : Set a background color
#   tput setaf  [1-7]       : Set a foreground color using ANSI escape
#   tput setf   [1-7]       : Set a foreground color
# #

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
ORANGE=$(tput setaf 208)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 156)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GREYL=$(tput setaf 242)
DEV=$(tput setaf 157)
DEVGREY=$(tput setaf 243)
FUCHSIA=$(tput setaf 198)
PINK=$(tput setaf 200)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)
STRIKE="\e[9m"
END="\e[0m"

# #
#   vars > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   vars > app
# #

app_title="ConfigServer Firewall OpenVPN Patch"
app_about="Configures ConfigServer Firewall to allow traffic through an OpenVPN server"
app_ver=("14" "22" "0")
app_file_this=$(basename "$0")
app_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# #
#   vars > app repo
# #

app_repo_name="csf-firewall"
app_repo_author="Aetherinox"
app_repo_branch="main"
app_repo_url="https://github.com/${app_repo_author}/${app_repo_name}"

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
            OS=$NAME
            OS_VER=$VERSION_ID

    # #
    #   linuxbase.org
    # #

        elif type lsb_release >/dev/null 2>&1; then
            OS=$(lsb_release -si)
            OS_VER=$(lsb_release -sr)

    # #
    #   versions of Debian/Ubuntu without lsb_release cmd
    # #

        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS=$DISTRIB_ID
            OS_VER=$DISTRIB_RELEASE

    # #
    #   older Debian/Ubuntu/etc distros
    # #

        elif [ -f /etc/debian_version ]; then
            OS=Debian
            OS_VER=$(cat /etc/debian_version)

    # #
    #   fallback: uname, e.g. "Linux <version>", also works for BSD
    # #

        else
            OS=$(uname -s)
            OS_VER=$(uname -r)
        fi

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
#   Display Usage Help
#
#   activate using ./install.sh --help or -h
# #

opt_usage()
{
    echo -e 
    printf "  ${BLUE}${app_title}${NORMAL}\n" 1>&2
    printf "  ${GREYL}${app_about}${NORMAL}\n" 1>&2
    echo -e 
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREYL}-h${NORMAL}] [${GREYL}-v${NORMAL}] [${GREYL}-d${NORMAL}]" 1>&2
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
            echo -e "  ${FUCHSIA}${BLINK}Devmode Enabled${NORMAL}"
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -v|--version)
            echo
            echo -e "  ${GREEN}${BOLD}${app_title}${NORMAL} - v$(get_version)${NORMAL}"
            echo -e "  ${GREYL}${BOLD}${app_repo_url}${NORMAL}"
            echo -e "  ${GREYL}${BOLD}${OS} | ${OS_VER}${NORMAL}"
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
#   iptables > find
# #

if ! [ -x "$(command -v iptables)" ]; then
    echo -e "  ${GREYL}Installing package ${MAGENTA}iptables${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install iptables -y -qq >/dev/null 2>&1
fi

# #
#   iptables > assign path to var
# #

PATH_IPTABLES=$(which iptables)

# #
#   iptables > doesnt exist
# #

if [ -z "${PATH_IPTABLES}" ]; then
    echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}Could not locate the package ${YELLOW}iptables${NORMAL}"
    printf '%-17s %-55s %-55s' " " "${DEVGREY}Must install iptables before continuing${NORMAL}"
    echo -e

    exit 0
fi

# #
#   whitelist ip addresses associated with OpenVPN
#
#   filter network adapters
#       ip -br l | awk '$1 !~ "lo|vir|wl|docker|veth|br" { print $1}'
#       ls /sys/class/net | grep ^e
#       ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//"
#
#   only print adapters starting with eth or 
#       ip -br l | awk '$1 ~ "^enp|^eth[0-9]" { print $1}'
#
#   find tun*
#       ip -br l | awk '$1 ~ "^tun[0-9]" { print $1}'
# #

echo -e
echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
echo -e

# #
#   Check OpenVPN
# #

if ! [ -x "$(command -v openvpn)" ]; then
    echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}Could not locate ${GREEN}OpenVPN${WHITE}.${NORMAL}"
    printf '%-17s %-55s %-55s' " " "${DEVGREY}Skipping OpenVPN patch ...${NORMAL}"
    echo -e

    exit
fi

echo -e "  ${BOLD}${DEVGREY}+ OPENVPN       ${WHITE}Adding OpenVPN Rules${NORMAL}"

# #
#   Check > Must have valid OpenVPN tunnel
# #

if [ -z "${TUN_ADAPTER}" ]; then
    echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}Could not locate a valid ${GREEN}tun${WHITE} adapter. Check your OpenVPN install.${NORMAL}"
    printf '%-17s %-55s %-55s' " " "${DEVGREY}Skipping OpenVPN patch ...${NORMAL}"
    echo -e

    exit 1
fi

# #
#   Add rules > Tunnel > INPUT
#
#   Allow TUN interface connections to OpenVPN server
# #

${PATH_IPTABLES} -A INPUT -i tun+ -j ACCEPT
printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-A INPUT -i tun+ -j ACCEPT${NORMAL}"

# #
#   Add rules > Tunnel > FORWARD
#
#   Allow TUN interface connections to be forwarded through other interfaces.
# #

${PATH_IPTABLES} -A FORWARD -i tun+ -j ACCEPT
printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-A FORWARD -i tun+ -j ACCEPT${NORMAL}"

# #
#   Tunnel Adapter
# #

if [ ! -z "${TUN_ADAPTER}" ]; then
    ${PATH_IPTABLES} -A FORWARD -o ${TUN_ADAPTER} -j ACCEPT
    printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-A FORWARD -o ${TUN_ADAPTER} -j ACCEPT${NORMAL}"
else
    printf '\n%-17s %-35s %-55s' " " "${RED}X${DEVGREY} RULE" "     ${RED}couldn't find tun adapter${NORMAL}"
fi

# #
#   Ethernet / Network Adapter
# #

if [ ! -z "${ETH_ADAPTER}" ]; then
    ${PATH_IPTABLES} -t nat -A POSTROUTING -o ${ETH_ADAPTER} -j MASQUERADE
    printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-t nat -A POSTROUTING -o ${ETH_ADAPTER} -j MASQUERADE${NORMAL}"

    # #
    #   get vpn ip pool and add firewall rule for each ip in the pool
    # #

    for j in "${!IP_POOL[@]}"; do

        # #
        #   get vpn pool
        # #

        vpn_ip_pool=${IP_POOL[$j]}

        ${PATH_IPTABLES} -t nat -A POSTROUTING -s ${vpn_ip_pool} -o ${ETH_ADAPTER} -j MASQUERADE
        printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-t nat -A POSTROUTING -s ${vpn_ip_pool} -o ${ETH_ADAPTER} -j MASQUERADE${NORMAL}"

    done

    ${PATH_IPTABLES} -A INPUT -i ${ETH_ADAPTER} -m state --state NEW -p udp --dport 1194 -j ACCEPT
    ${PATH_IPTABLES} -A FORWARD -i tun+ -o ${ETH_ADAPTER} -m state --state RELATED,ESTABLISHED -j ACCEPT
    ${PATH_IPTABLES} -A FORWARD -i ${ETH_ADAPTER} -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT

    printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-A INPUT -i ${ETH_ADAPTER} -m state --state NEW -p udp --dport 1194 -j ACCEPT${NORMAL}"
    printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-A FORWARD -i tun+ -o ${ETH_ADAPTER} -m state --state RELATED,ESTABLISHED -j ACCEPT${NORMAL}"
    printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-A FORWARD -i ${ETH_ADAPTER} -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT${NORMAL}"
else
    printf '\n%-17s %-35s %-55s' " " "${RED}X${DEVGREY} RULE" "     ${RED}couldn't find ethernet adapter${NORMAL}"
fi

# #
#   Public IP Address
#
#   LIST
#       sudo csf -l
#   DROP RULE
#       sudo iptables -t nat -D POSTROUTING <NUMBER>
# #

if [ ! -z "${IP_PUBLIC}" ]; then
    # ${PATH_IPTABLES} -t nat -A POSTROUTING -j SNAT --to-source ${IP_PUBLIC}
    printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-t nat -A POSTROUTING -j SNAT --to-source ${IP_PUBLIC}${NORMAL}"
else
    printf '\n%-17s %-35s %-55s' " " "${RED}X${DEVGREY} RULE" "     ${RED}couldn't find public ip${NORMAL}"
fi

# #
#   Required if OUTPUT value is not ACCEPT:
# #

${PATH_IPTABLES} -A OUTPUT -o tun+ -j ACCEPT
printf '\n%-17s %-35s %-55s' " " "${DEVGREY}+ RULE" "${FUCHSIA}-A OUTPUT -o tun+ -j ACCEPT${NORMAL}"

echo -e
echo -e
