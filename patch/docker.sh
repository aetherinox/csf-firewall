#!/bin/bash

# #
#   
#   ConfigServer Firewall - Blacklist (IPSETS)
#   
#   @author         Aetherinox
#   @package        ConfigServer Firewall
#   @file           blacklist-ipsets.sh
#   @type           Patch
#   @desc           This CSF script scans all docker containers that exist within the server and adds each
#                   container ip to the ConfigServer Firewall.
#   
#   @usage          chmod +x /usr/local/include/csf/post.d/docker.sh
#                   sudo /usr/local/include/csf/post.d/docker.sh
#
#                   this can also be installed by executing the install.sh script
# #

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# #
#   Configs
#
#   DOCKER_INT                  main docker network interface
#                                   can be created using the command:
#                                       - `sudo docker network create --driver=bridge --subnet=172.18.0.0/16 --gateway=172.18.0.1 traefik``
#   CSF_FILE_ALLOW              the defined allow list file
#   CSF_COMMENT                 comment added to each whitelisted ip within iptables
#   DEBUG_ENABLED               debugging mode; throws prints during various steps
#   IP_CONTAINERS               list of ip address blocks you will be using for your docker setup. these blocks will be whitelisted through ConfigServer Firewall
# #

DOCKER_INT="docker0"
CSF_FILE_ALLOW="/etc/csf/csf.allow"
CSF_COMMENT="Docker container whitelist"
DEBUG_ENABLED="false"

# #
#   list > network ips
#
#   this is the list of IP addresses you will use with docker that must be
#   whitelisted.
# #

IP_CONTAINERS=(
    '172.17.0.0/16'
)

# #
#   define > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   vars > app
# #

app_title="ConfigServer Firewall - Docker Patch"
app_about="Sets up your firewall rules to work with Docker and Traefik"
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
    printf "  ${BLUE2}${app_title}${END}\n" 1>&2
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
#   Clean container ips added by script once per restart
# #

if [[ $csf_path ]]; then
    echo -e
    echo -e "  ${BOLD}${GREY1}+ WHITELIST     ${WHITE}Cleaning ${CSF_FILE_ALLOW}${END}"
    sudo sed --in-place "/${CSF_COMMENT}/d" ${CSF_FILE_ALLOW}
fi

# #
#   List containers
# #

containers=`docker ps -q`

# #
#   Truncate text; add ...
# #

trim() {
    if (( "${#1}" > "$2" )); then
      echo "${1:0:$2}$3"
    else
      echo "$1"
    fi
}

# #
#   Reset Iptables
# #

iptables_reset()
{
    sudo ${path_iptables4} -F
    sudo ${path_iptables4} -X
    sudo ${path_iptables4} -t nat -F
    sudo ${path_iptables4} -t nat -X
    sudo ${path_iptables4} -t mangle -F
    sudo ${path_iptables4} -t mangle -X

    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${WHITE}Successfully reset iptable chains and rules${END}"
}

# #
#   List Containers
# #

containers_list()
{

    if [ `echo ${containers} | wc -c` -gt "1" ]; then

        echo " ${GREY1}                 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${END}"
        
        printf '%-17s %-30s %-38s %-26s %-33s %-33s %-30s %-40s %-50s' \
            " " \
            "${GREY2}   Container${END}" \
            "${GREY2}   Name" \
            "${GREY2}   Shell${END}" \
            "${GREY2}   IP${END}" \
            "${GREY2}   IfLink ID${END}" \
            "${GREY2}   Veth Adapter${END}" \
            "${GREY2}   Network Mode${END}" \
            "${GREY2}   Network List${END}"

        for container in ${containers}; do

            # #
            #   Output:
            #       CONTAINER ............... : 5b251b810e7d
            #       NETMODE ................. : 63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
            #
            #   Example:
            #       Running `docker inspect -f "{{.HostConfig.NetworkMode}}" 5b251b810e7d` outputs:
            #       63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
            # #

            netmode=`docker inspect -f "{{.HostConfig.NetworkMode}}" ${container}`
            network=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' ${container}`
            network_list=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s " $net}}{{end}}' ${container}`
            network_simple=`docker inspect -f "{{json .NetworkSettings.Networks}}" ${container}`
            name=`docker inspect -f "{{.Name}}" ${container}`
            name=${name#/}                          # remove forward slash
            name=$(echo $name | sed "s/ //g")       # remove spaces
            iflink=`docker exec -i "$container" bash -c 'cat /sys/class/net/eth0/iflink' 2> /dev/null`
            container_shell_type="Bash"

            err_bash_notfound=`echo "$iflink" 2> /dev/null | grep -c "exec failed"`
        
            # #
            #   Bash Not Found
            # #

            if [[ "$err_bash_notfound" == "1" ]]; then
                iflink=`docker exec -it "$container" sh -c 'cat /sys/class/net/eth0/iflink' 2>/dev/null`
                err_sh_notfound=`echo "$iflink" 2> /dev/null | grep -c "exec failed"`

                # #
                #   Sh Not Found
                # #

                if [[ "$err_sh_notfound" == "1" ]]; then
                    container_shell_type="Unknown"
                    iflink="Unknown"
                else
                    iflink=`echo $iflink | sed 's/[^0-9]*//g'`
                    container_shell_type="SH"
                fi
            else
                iflink=`echo $iflink | sed 's/[^0-9]*//g'`
            fi

            # #
            #   Container > Running
            # #

            container_status=$(docker ps --format '{{.Names}}' | grep -c "^${name}$")
            if [ "$( docker container inspect -f '{{.State.Running}}' $name )" != "true" ]; then
                iflink="Not running"
            fi

            if [ -z "${iflink}" ]; then
                iflink="Unresponsive"
            fi

            # #
            #   Get veth network interface
            # #

            if [ -n "${iflink}" ]; then
                veth=$(sudo grep -l -s $iflink /sys/class/net/veth*/ifindex)
                veth=`echo $veth|sed -e 's;^.*net/\(.*\)/ifindex$;\1;'`

                if [ -z "${veth}" ]; then
                    veth="Unknown"
                fi

            fi

            # #
            #   Chart Truncation
            # #

            name_chart=$(trim "$name" 20 "...")
            network_list_chart=$(trim "$network_list" 50 "...")
            network_mode_chart=$(trim "$netmode" 18 "...")
            network_ip_chart="Not Found"
            network_list="$network"
            declare -a network_arr=( $network )

            # #
            #   Netmode > Default
            # #

            if [ $netmode == "default" ]; then
                bridge_name=${DOCKER_INT}
                ipaddr=`docker inspect -f "{{.NetworkSettings.IPAddress}}" ${container}`
                network_ip_chart="$ipaddr"

            # #
            #   Netmode > Other
            # #

            else
                # Loop Networks
                while IFS= read -r network_list; do
                    # bridge_name=`docker inspect -f "{{with index .NetworkSettings.Networks \"bridge\"}}{{.NetworkID}}{{end}}" cb9a6ae9c19e | cut -c -12`
                    bridge=$(docker inspect -f "{{with index .NetworkSettings.Networks \"${network_list}\"}}{{.NetworkID}}{{end}}" ${container} | cut -c -12)

                    # docker network inspect -f {{"br-e95004d90f8d" | or (index .Options "com.docker.network.bridge.name")}} e95004d90f8d
                    bridge_name=`docker network inspect -f '{{"'br-$bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $bridge`
                    ipaddr=`docker inspect -f "{{with index .NetworkSettings.Networks \"${network_list}\"}}{{.IPAddress}}{{end}}" ${container}`
                    ipaddr_orig=${ipaddr}
                    network_ip_chart="$ipaddr"

                    if [ -z "${bridge}" ]; then bridge="${RED2}Not found${END}"; fi
                    if [ -z "${bridge_name}" ]; then bridge_name="${RED2}Not found${END}"; fi
                    if [ -z "${ipaddr}" ]; then 
                        ipaddr="${RED2}Not found${END}";
                        network_ip_chart="Not Found";
                    fi
                done <<< "$network_list"
            fi

            # #
            #   List each container
            # #

            printf '\n%-17s %-30s %-38s %-26s %-33s %-33s %-30s %-40s %-50s' \
                " " \
                "${GREY2}   ${container}${END}" \
                "${GREY2}   ${name_chart}" \
                "${GREY2}   ${container_shell_type}${END}" \
                "${GREY2}   ${network_ip_chart}${END}" \
                "${GREY2}   ${iflink}${END}" \
                "${GREY2}   ${veth}${END}" \
                "${GREY2}   ${network_mode_chart}${END}" \
                "${GREY2}   [${#network_arr[@]}] ${network_list_chart}${END}"
        done

        echo -e
        echo " ${GREY1}                 └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${END}"
        echo -e
        echo -e
    fi
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
            cfg_dev_enabled=true
            echo -e "  ${MAGENTA}MODE         ${END}Developer Enabled${END}"
            ;;

        -h*|--help*)
            opt_usage
            ;;

        -l|--list)
            containers_list
            exit 1
            ;;

        -r|--reset)
            iptables_reset
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
#   {bridge} 	= docker0
#   {subnet} 	= 172.17.0.0/16
#
#   + MASQUERADE rule: 172.17.0.0/16 on docker0
#   + FORWARD rule: accept established connections for docker0
#   + FORWARD rule: allow communication for docker0
#   + MASQUERADE rule: 172.18.0.0/16 on br-2e0fde4b0664
#   + FORWARD rule: accept established connections for br-2e0fde4b0664
#   + FORWARD rule: allow communication for br-2e0fde4b0664
# #

# #
#   Chain Exists
# #

chainExists()
{

    [ $# -lt 1 -o $# -gt 2 ] && {
        echo "Usage: chainExists <chain_name> [table]" >&2
        return 1
    }

    local chain_name="$1" ; shift
    [ $# -eq 1 ] && local table="-t $1"


    if [ `sudo ${path_iptables4} -n --list "$chain_name" $table | grep "$chain_name" | wc -l` -eq 0 ]; then
        echo 0;
    else
        echo 1;
    fi
}

# #
#   Rule Exists
# #

ruleExists()
{

    [ $# -lt 1 ] && {
        echo "Usage: ruleExists <rule>" >&2
        return 1
    }

    local chain_rule="$1"


    if [ `iptables -C "$chain_rule" > /dev/null 2>&1` ]; then
        echo 1;
    else
        echo 0;
    fi
}

# #
#   Forward > Add
#
#   Allow containers to communicate with themselves & outside world
# #

add_to_forward()
{
    local docker_int=$1

    if [ `sudo ${path_iptables4} -nvL FORWARD | grep ${docker_int} | wc -l` -eq 0 ]; then
        # Accept established connections to docker containers
        sudo ${path_iptables4} -A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT
        sudo ${path_iptables4} -A FORWARD -o ${docker_int} -j DOCKER
        sudo ${path_iptables4} -A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT
        sudo ${path_iptables4} -A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT

        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT${END}"
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -o ${docker_int} -j DOCKER${END}"
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT${END}"
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT${END}"
    fi
}

# #
#   NAT > Add
# #

add_to_nat()
{
    local docker_int=$1
    local subnet=$2

    # ipv4
    if [ "$subnet" != "${subnet#*[0-9].[0-9]}" ]; then
        sudo ${path_iptables4} -t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE
        sudo ${path_iptables4} -t nat -A DOCKER -i ${docker_int} -j RETURN

        echo -e "                  ${GREY1}+ RULE v4:               ${FUCHSIA2}-t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE${END}"
        echo -e "                  ${GREY1}+ RULE v4:               ${FUCHSIA2}-t nat -A DOCKER -i ${docker_int} -j RETURN${END}"

    # ipv6
    elif [ "$subnet" != "${subnet#*:[0-9a-fA-F]}" ]; then
        sudo ${path_iptables6} -t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE
        sudo ${path_iptables6} -A DOCKER -i ${docker_int} -j RETURN

        echo -e "                  ${GREY1}+ RULE v6:               ${FUCHSIA2}-t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE${END}"
        echo -e "                  ${GREY1}+ RULE v6:               ${FUCHSIA2}-A DOCKER -i ${docker_int} -j RETURN${END}"
    else
        echo "Unrecognized subnet format '$subnet'"
    fi

}

# #
#   Docker Isolation > Add
# #

add_to_docker_isolation()
{
    local docker_int=$1

    sudo ${path_iptables4} -A DOCKER-ISOLATION-STAGE-1 -i ${docker_int} ! -o ${docker_int} -j DOCKER-ISOLATION-STAGE-2
    sudo ${path_iptables4} -A DOCKER-ISOLATION-STAGE-2 -o ${docker_int} -j DROP

    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-1 -i ${docker_int} ! -o ${docker_int} -j DOCKER-ISOLATION-STAGE-2${END}"
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-2 -o ${docker_int} -j DROP${END}"
}

# #
#   iptables-save & restore
# #

sudo iptables-save | grep -v -- '-j DOCKER' | sudo iptables-restore

# #
#   Delete chain DOCKER if exists
#   
#   -X <chain>          Delete a user defined-chain
# #

if [ $(chainExists DOCKER) -eq 1 ] ; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Delete existing chain DOCKER${END}"
    sudo ${path_iptables4} -X DOCKER
fi

# #
#   Delete chain DOCKER table NAT if exists
#  
#   -X <chain>          Delete a user defined-chain
#   -t <table>          Table to delete
# #

if [ $(chainExists DOCKER nat) -eq 1 ] ; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Delete existing chain DOCKER; table NAT${END}"
    sudo ${path_iptables4} -t nat -X DOCKER
fi

# #
#   Create new chains
#       - DOCKER
#       - DOCKER-STAGE-1
#       - DOCKER-STAGE-2
#       - DOCKER-USER
#
#   -N <chain>      Chain to create
# #

if [ $(chainExists DOCKER) -eq 0 ] ; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Create new chain DOCKER${END}"
    sudo ${path_iptables4} -N DOCKER
fi

if [ $(chainExists DOCKER-ISOLATION-STAGE-1) -eq 0 ] ; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Create new chain DOCKER-ISOLATION-STAGE-1${END}"
    sudo ${path_iptables4} -N DOCKER-ISOLATION-STAGE-1
fi

if [ $(chainExists DOCKER-ISOLATION-STAGE-2) -eq 0 ] ; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Create new chain DOCKER-ISOLATION-STAGE-2${END}"
    sudo ${path_iptables4} -N DOCKER-ISOLATION-STAGE-2
fi

if [ $(chainExists DOCKER-USER) -eq 0 ] ; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Create new chain DOCKER-USER${END}"
    sudo ${path_iptables4} -N DOCKER-USER
fi

# #
#   Create new chain DOCKER; table nat
#   
#   -N <chain>          Chain to create
#   -t <table>          Table to create
# #

if [ $(chainExists DOCKER nat) -eq 0 ] ; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Create new chain DOCKER; table NAT${END}"
    sudo ${path_iptables4} -t nat -N DOCKER
fi

# #
#   Add Rules:
#       - INPUT     add docker0 ACCEPT
#       - FORWARD   add DOCKER-USER
#       - FORWARD   add DOCKER-ISO-1
#   
#   -A <chain>          Append rule to chain
#   -i <input-eth>      Incoming network interface
#   -j <rule>           Target for rule; ACCEPT, DROP, REJECT
# #

if ! sudo ${path_iptables4} -C INPUT -i docker0 -j ACCEPT &>/dev/null; then
    sudo ${path_iptables4} -A INPUT -i ${DOCKER_INT} -j ACCEPT
fi

if ! sudo ${path_iptables4} -C FORWARD -j DOCKER-USER &>/dev/null; then
    sudo ${path_iptables4} -A FORWARD -j DOCKER-USER
fi

if ! sudo ${path_iptables4} -C FORWARD -j DOCKER-ISOLATION-STAGE-1 &>/dev/null; then
    sudo ${path_iptables4} -A FORWARD -j DOCKER-ISOLATION-STAGE-1
fi

# #
#   add docker0 to forward
#   
#   -A                  Append rule
#   -m <match>          Extended match (may load extension)
#   -N <chain>          Chain to create
#   -t <table>          Table to create
#   -d <address>        destination
# #

add_to_forward ${DOCKER_INT}

sudo ${path_iptables4} -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
sudo ${path_iptables4} -t nat -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER

# #
#   whitelist ip addresses associated with docker
# #

echo -e
echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
echo -e

echo -e "  ${BOLD}${GREY1}+ POSTROUTING   ${WHITE}Adding IPs from primary IP list${END}"

for j in "${!IP_CONTAINERS[@]}"; do

    # #
    #   get ip addresses
    # #

    ip_block=${IP_CONTAINERS[$j]}
    echo -e "  ${BOLD}${WHITE}                + ${YELLOW2}${ip_block}${END}"

    # #
    #   Masquerade outbound connections from containers
    # #

    sudo ${path_iptables4} -t nat -A POSTROUTING ! -o ${DOCKER_INT} -s ${ip_block} -j MASQUERADE
    sudo ${path_iptables4} -t nat -A POSTROUTING -s ${ip_block} ! -o ${DOCKER_INT} -j MASQUERADE

    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -A POSTROUTING ! -o ${DOCKER_INT} -s ${ip_block} -j MASQUERADE${END}"
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -A POSTROUTING -s ${ip_block} ! -o ${DOCKER_INT} -j MASQUERADE${END}"
done

# #
#   Separator
# #

echo -e
echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
echo -e

# #
#   Get bridges
#
#   Output:
#       7018d23c9bb4
#       2e0fde4b0664
# #

echo -e "  ${BOLD}${GREY1}+ BRIDGES       ${WHITE}Configuring network bridges${END}"

bridges=`docker network ls -q --filter='Driver=bridge'`
bridge_ids=`docker network ls -q --filter driver=bridge --format "{{.ID}}"`

for bridge in $bridges; do

    # #
    #   Output:
    #       BRIDGE ............... : 242441c7d76c
    #       DOCKER_NET_INT_1 ..... : docker0
    #       SUBNET ............... : 172.17.0.0/16
    # #

    bridge_name=`docker network inspect -f '{{"'br-$bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $bridge`
    subnet=`docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' $bridge`

	printf '\n%-17s %-35s %-55s' " " "${GREY1}BRIDGE" "${GREEN2}${bridge}${END}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}DOCKER INTERFACE" "${GREEN2}${bridge_name}${END}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}SUBNET" "${GREEN2}${subnet}${END}"
	echo -e

    add_to_nat ${bridge_name} ${subnet}
    add_to_forward ${bridge_name}
    add_to_docker_isolation ${bridge_name}
done

# #
#   Separator
# #

echo -e
echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
echo -e

# #
#   Loop containers
# #

echo -e "  ${BOLD}${GREY1}+ CONTAINERS    ${WHITE}Configure containers${END}"

# #
#   Table Chart
# #

printf '\n%-17s %-31s %-35s %-24s %-28s %-30s %-40s %-50s' \
  " " \
  "${GREY2}Container${END}" \
  " ${GREY2}Name" \
  " ${GREY2}Shell${END}" \
  " ${GREY2}IfLink ID${END}" \
  " ${GREY2}Veth Adapter${END}" \
  " ${GREY2}Network Mode${END}" \
  " ${GREY2}Network List${END}"

# #
#   Loop containers
# #

echo -e "  ${BOLD}${GREY1}+ CONTAINERS    ${WHITE}Configure containers${END}"

if [ `echo ${containers} | wc -c` -gt "1" ]; then
    for container in ${containers}; do

        # #
        #   Output:
        #       CONTAINER ............... : 5b251b810e7d
        #       NETMODE ................. : 63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
        #
        #   Example:
        #       Running `docker inspect -f "{{.HostConfig.NetworkMode}}" 5b251b810e7d` outputs:
        #       63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
        # #

        netmode=`docker inspect -f "{{.HostConfig.NetworkMode}}" ${container}`
        network=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' ${container}`
        network_list=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s " $net}}{{end}}' ${container}`
        network_simple=`docker inspect -f "{{json .NetworkSettings.Networks}}" ${container}`
        name=`docker inspect -f "{{.Name}}" ${container}`
        name=${name#/}                          # remove forward slash
        name=$(echo $name | sed "s/ //g")       # remove spaces
        iflink=`docker exec -i "$container" bash -c 'cat /sys/class/net/eth0/iflink' 2> /dev/null`
        container_shell_type="Bash"

        err_bash_notfound=`echo "$iflink" 2> /dev/null | grep -c "exec failed"`
    
        # #
        #   Bash Not Found
        # #

        if [[ "$err_bash_notfound" == "1" ]]; then
            iflink=`docker exec -it "$container" sh -c 'cat /sys/class/net/eth0/iflink' 2>/dev/null`
            err_sh_notfound=`echo "$iflink" 2> /dev/null | grep -c "exec failed"`

            # #
            #   Sh Not Found
            # #

            if [[ "$err_sh_notfound" == "1" ]]; then
                container_shell_type="Unknown"
                iflink="Unknown"
            else
                iflink=`echo $iflink | sed 's/[^0-9]*//g'`
                container_shell_type="SH"
            fi
        else
            iflink=`echo $iflink | sed 's/[^0-9]*//g'`
        fi

        # #
        #   Container > Running
        # #

        container_status=$(docker ps --format '{{.Names}}' | grep -c "^${name}$")
        if [ "$( docker container inspect -f '{{.State.Running}}' $name )" != "true" ]; then
            iflink="Not running"
        fi

        if [ -z "${iflink}" ]; then
            iflink="Unresponsive"
        fi

        # #
        #   Get veth network interface
        # #

        if [ -n "${iflink}" ]; then
            veth=$(sudo grep -l -s $iflink /sys/class/net/veth*/ifindex)
            veth=`echo $veth|sed -e 's;^.*net/\(.*\)/ifindex$;\1;'`

            if [ -z "${veth}" ]; then
                veth="Unknown"
            fi

        fi

        # #
        #   Chart Truncation
        # #

        name_chart=$(trim "$name" 20 "...")
        network_list_chart=$(trim "$network_list" 50 "...")
        network_mode_chart=$(trim "$netmode" 18 "...")
        network_ip_chart="Not Found"
        network_list="$network"
        declare -a network_arr=( $network )

        # #
        #   Netmode > Default
        # #

        if [ $netmode == "default" ]; then
            bridge_name=${DOCKER_INT}
            ipaddr=`docker inspect -f "{{.NetworkSettings.IPAddress}}" ${container}`
            network_ip_chart="$ipaddr"

        # #
        #   Netmode > Other
        # #

        else
            # Loop Networks
            while IFS= read -r network_list; do
                # bridge_name=`docker inspect -f "{{with index .NetworkSettings.Networks \"bridge\"}}{{.NetworkID}}{{end}}" cb9a6ae9c19e | cut -c -12`
                bridge=$(docker inspect -f "{{with index .NetworkSettings.Networks \"${network_list}\"}}{{.NetworkID}}{{end}}" ${container} | cut -c -12)

                # docker network inspect -f {{"br-e95004d90f8d" | or (index .Options "com.docker.network.bridge.name")}} e95004d90f8d
                bridge_name=`docker network inspect -f '{{"'br-$bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $bridge`
                ipaddr=`docker inspect -f "{{with index .NetworkSettings.Networks \"${network_list}\"}}{{.IPAddress}}{{end}}" ${container}`
                ipaddr_orig=${ipaddr}
                network_ip_chart="$ipaddr"

                if [ -z "${bridge}" ]; then bridge="${RED2}Not found${END}"; fi
                if [ -z "${bridge_name}" ]; then bridge_name="${RED2}Not found${END}"; fi
                if [ -z "${ipaddr}" ]; then 
                    ipaddr="${RED2}Not found${END}";
                    network_ip_chart="Not Found";
                fi
            done <<< "$network_list"
        fi

        # #
        #   List each container
        # #

        echo -e
        echo " ${GREY1}                 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${END}"
        echo " ${GREY1}                 │                                                                                                                                                                │"

        printf '%-17s %-30s %-38s %-26s %-33s %-33s %-30s %-40s %-50s' \
            " " \
            "${GREY2}   Container${END}" \
            "${GREY2}   Name" \
            "${GREY2}   Shell${END}" \
            "${GREY2}   IP${END}" \
            "${GREY2}   IfLink ID${END}" \
            "${GREY2}   Veth Adapter${END}" \
            "${GREY2}   Network Mode${END}" \
            "${GREY2}   Network List${END}"

        printf '\n%-17s %-30s %-38s %-26s %-33s %-33s %-30s %-40s %-50s' \
            " " \
            "${GREY2}   ${container}${END}" \
            "${GREY2}   ${name_chart}" \
            "${GREY2}   ${container_shell_type}${END}" \
            "${GREY2}   ${network_ip_chart}${END}" \
            "${GREY2}   ${iflink}${END}" \
            "${GREY2}   ${veth}${END}" \
            "${GREY2}   ${network_mode_chart}${END}" \
            "${GREY2}   [${#network_arr[@]}] ${network_list_chart}${END}"

        echo -e
        echo " ${GREY1}                 │                                                                                                                                                                │"
        echo " ${GREY1}                 └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${END}"

        # #
        #   Netmode > Default
        # #

        if [ $netmode == "default" ]; then
            bridge_name=${DOCKER_INT}

            #   This will return empty if IP manually assigned from docker-compose.yml for container
            #   docker inspect -f "{{.NetworkSettings.IPAddress}}" 5b251b810e7d

            ipaddr=`docker inspect -f "{{.NetworkSettings.IPAddress}}" ${container}`

        # #
        #   Netmode > Other
        # #

        else

            # #
            #   return all container info
            #       sudo docker inspect -f '' badaaca1d5da
            # #

            # #
            #   network_adapter=$(docker container inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' ${container})
            #
            #   RETURNS:
            #       'traefik'
            # #

            # #
            #   should return:
            #       2e0fde4b0664
            # #

            # Loop Network
            while IFS= read -r network; do

                printf '\n%-17s %-46s' " " "${GREY1}│ ${END}"

                bridge=$(docker inspect -f "{{with index .NetworkSettings.Networks \"${network}\"}}{{.NetworkID}}{{end}}" ${container} | cut -c -12)

                # #
                #   should return:
                #       br-2e0fde4b0664
                # #

                bridge_name=`docker network inspect -f '{{"'br-$bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $bridge`

                # here somewhere

                # #
                #   should return:
                #       172.18.0.7 (or any other IP)
                # #

                ipaddr=`docker inspect -f "{{with index .NetworkSettings.Networks \"${network}\"}}{{.IPAddress}}{{end}}" ${container}`
                ipaddr_orig=${ipaddr}

                if [ -z "${bridge}" ]; then bridge="${RED2}Not found${END}"; fi
                if [ -z "${bridge_name}" ]; then bridge_name="${RED2}Not found${END}"; fi
                if [ -z "${ipaddr}" ]; then ipaddr="${RED2}Not found${END}"; fi

                printf '\n%-17s %-46s %-55s' " " "${GREY1}├── ${GREY1}BRIDGE" "${GREEN2}${bridge_name}${END}"
             #  printf '\n%-17s %-46s %-55s' " " "${GREY1}├── ${GREY1}DOCKER_NET" "${GREEN2}${bridge_name}${END}"
                printf '\n%-17s %-46s %-55s' " " "${GREY1}├── ${GREY1}IP" "${GREEN2}${ipaddr}${END}"

                if [ "${cfg_dev_enabled}" == "true" ] || [ "${DEBUG_ENABLED}" == "true" ]; then
                    echo -e "                                           ${GREY1}docker inspect -f \"{{with index .NetworkSettings.Networks \"${network}\"}}{{.NetworkID}}{{end}}\" ${container} | cut -c -12${END}"
                    echo -e "                                           ${GREY1}docker network inspect -f '{{\"'br-$bridge'\" | or (index .Options \"com.docker.network.bridge.name\")}}' ${bridge}${END}"
                    echo -e "                                           ${GREY1}docker inspect -f '{{with index .NetworkSettings.Networks \"${network}\"}}{{.IPAddress}}{{end}}' ${container}${END}"
                fi

            done <<< "$network"
        fi

        # #
        #   CHeck if containers IP is currently in CSF allow list /etc/csf/csf.allow
        # #

        if [[ -n "${ipaddr}" ]] && [[ "$ipaddr" != "${RED2}Not found${END}" ]]; then

            if sudo grep -q "\b${ipaddr}\b" ${CSF_FILE_ALLOW}; then
                printf '\n%-17s %-46s %-55s' " " "${GREY1}└── ${GREY1}WHITELIST" "${YELLOW2}Already whitelisted in: ${END}${CSF_FILE_ALLOW}${END}"
            else

                # #
                #   Found CSF binary, add container IP to allow list /etc/csf/csf.allow
                # #

                if [[ $csf_path ]]; then
                    printf '\n%-17s %-46s %-55s' " " "${GREY1}└── ${GREY1}WHITELIST" "${GREEN2}Adding ${ipaddr} to allow list ${CSF_FILE_ALLOW}${END}"
                 #   $csf_path -a ${ipaddr} ${CSF_COMMENT} >/dev/null 2>&1
                fi
            fi
        else
            printf '\n%-17s %-46s %-55s' " " "${GREY1}└── ${GREY1}WHITELIST" "${RED2}Found blank IP, cannot be added to ${CSF_FILE_ALLOW}${END}"
        fi

        # #
        #   22/tcp->0.0.0.0:22
        #   22/tcp->[::]:22
        #   80/tcp->0.0.0.0:80
        #   80/tcp->[::]:80
        #   443/tcp->0.0.0.0:443
        #   443/tcp->[::]:443
        #   2222/tcp->0.0.0.0:2222
        #   2222/tcp->[::]:2222
        # #

        rules=`docker port ${container} | sed 's/ //g'`

        # #
        #   manage ip:port rules
        # #

        if [ `echo ${rules} | wc -c` -gt "1" ]; then

            for rule in ${rules}; do

                # #
                #   pull ip:port from each rule and format it appropriately
                # #

                src=`echo ${rule} | awk -F'->' '{ print $2 }'`
                dst=`echo ${rule} | awk -F'->' '{ print $1 }'`

                src_ip=`echo ${src} | sed 's|^\(.*\):.*$|\1|'`
                src_port=`echo ${src} | awk -F':' '{ print $2 }'`

                dst_port=`echo ${dst} | awk -F'/' '{ print $1 }'`
                dst_proto=`echo ${dst} | awk -F'/' '{ print $2 }'`

                # #
                #   SOURCE          0.0.0.0:22                            
                #   DESTINATION     22/tcp                                
                #   PORT            22                                    
                #   PROTOTYPE       tcp    
                # #
                
                printf '\n%-17s %-46s' " " "${GREY1}│ ${END}"
                printf '\n%-17s %-46s %-55s' " " "${GREY1}├── ${GREY1}SOURCE" "${FUCHSIA2}${src}${END}"
                printf '\n%-17s %-46s %-55s' " " "${GREY1}└── ${GREY1}DESTINATION" "${FUCHSIA2}${dst}${END}"
                # printf '\n%-17s %-35s %-55s' " " "${GREY1}PORT" "${FUCHSIA2}${dst_port}${END}"
                # printf '\n%-17s %-35s %-55s' " " "${GREY1}PROTOTYPE" "${FUCHSIA2}${dst_proto}${END}"
                echo -e

                # #
                #   IPTABLE RULE > Add container ip:port for each entry
                # #

                sudo ${path_iptables4} -A DOCKER -d ${ipaddr}/32 ! -i ${bridge_name} -o ${bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT
                sudo ${path_iptables4} -t nat -A POSTROUTING -s ${ipaddr}/32 -d ${ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE

                echo -e "                  ${GREY1}    ├── + RULE:    ${GREY1}-A DOCKER -d ${ipaddr}/32 ! -i ${bridge_name} -o ${bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT${END}"
                echo -e "                  ${GREY1}    ├── + RULE:    ${GREY1}-t nat -A POSTROUTING -s ${ipaddr}/32 -d ${ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE${END}"

                # #
                #   Support for IPv4
                # #

                iptables_opt_src=""
                if [ ${src_ip} != "0.0.0.0" ]; then
                    iptables_opt_src="-d ${src_ip}/32 "
                fi

                if [[ ${src_ip} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    sudo ${path_iptables4} -t nat -A DOCKER ${iptables_opt_src}! -i ${bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${ipaddr}:${dst_port}
                    echo -e "                  ${GREY1}    └── + RULE:    ${GREY1}-t nat -A DOCKER ${iptables_opt_src}! -i ${bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${ipaddr}:${dst_port}${END}"
                fi
            done
        fi

        echo -e
        echo -e

    done
fi

echo -e
echo -e

# #
#   DOCKER-ISOLATION-STAGE
# #

echo " ${GREY1}                 ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐${END}"
echo -e "  ${BOLD}${GREY1}+ RULES         │  ${WHITE}Add DOCKER-ISOLATION-STAGE & DOCKER-USER rules${GREY1}                                                                                                                │"
echo " ${GREY1}                 └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${END}"

chain_docker_iso_stage_1_exiss=`sudo ${path_iptables4} -nvL DOCKER-ISOLATION-STAGE-1 2> /dev/null | grep "RETURN" | grep -c "0.0.0.0/0"`
chain_docker_iso_stage_2_exiss=`sudo ${path_iptables4} -nvL DOCKER-ISOLATION-STAGE-2 2> /dev/null | grep "RETURN" | grep -c "0.0.0.0/0"`
chain_docker_user_exiss=`sudo ${path_iptables4} -nvL DOCKER-USER 2> /dev/null | grep "RETURN" | grep -c "0.0.0.0/0"`

if [[ "$chain_docker_iso_stage_1_exiss" == "0" ]]; then
    printf '\n%-17s %-29s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-1 -j RETURN${END}"
    sudo ${path_iptables4} -A DOCKER-ISOLATION-STAGE-1 -j RETURN
else
    printf '\n%-17s %-29s %-55s' " " "${GREY1}! RULE" "${END}Already exists: ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-1 -j RETURN${END} already exists ${END}"
fi

if [[ "$chain_docker_iso_stage_2_exiss" == "0" ]]; then
    printf '\n%-17s %-29s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-2 -j RETURN${END}"
    sudo ${path_iptables4} -A DOCKER-ISOLATION-STAGE-2 -j RETURN
else
    printf '\n%-17s %-29s %-55s' " " "${GREY1}! RULE" "${END}Already exists: ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-2 -j RETURN${END} already exists ${END}"
fi

if [[ "$chain_docker_user_exiss" == "0" ]]; then
    printf '\n%-17s %-29s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-USER -j RETURN${END}"
    sudo ${path_iptables4} -A DOCKER-USER -j RETURN
else
    printf '\n%-17s %-29s %-55s' " " "${GREY1}! RULE" "${END}Already exists: ${FUCHSIA2}-A DOCKER-USER -j RETURN${END}"
fi

# #
#   Check if docker0 inside DOCKER chain
# #

printf '\n%-17s %-29s %-55s' " " "${GREY1}+ TASK" "${FUCHSIA2}Checking ${END}${DOCKER_INT}${FUCHSIA2} status${END}"
if [ `sudo ${path_iptables4} -t nat -nvL DOCKER | grep ${DOCKER_INT} | wc -l` -eq 0 ]; then
    sudo ${path_iptables4} -t nat -I DOCKER -i ${DOCKER_INT} -j RETURN
    printf '\n%-17s %-29s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-t nat -I DOCKER -i ${DOCKER_INT} -j RETURN${END}"
else
    printf '\n%-17s %-29s %-55s' " " "${GREY1}! RULE" "${END}Already exists: ${FUCHSIA2}-t nat -I DOCKER -i ${DOCKER_INT} -j RETURN${END}"
fi

echo -e
echo -e
