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
#   Clean container ips added by script once per restart
# #

if [[ $csf_path ]]; then
    echo -e
    echo -e "  ${BOLD}${GREY1}+ WHITELIST     ${WHITE}Cleaning ${CSF_FILE_ALLOW}${END}"
    sed --in-place "/${CSF_COMMENT}/d" ${CSF_FILE_ALLOW}
fi

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
#   check if DOCKER chain exists; flush if true, create if false
# #

if ${path_iptables4} -L DOCKER &> /dev/null; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Flushing existing chain DOCKER${END}"
    ${path_iptables4} -F DOCKER
else
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Creating chain DOCKER${END}"
    ${path_iptables4} -N DOCKER
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
#   Forward > Add
#
#   Allow containers to communicate with themselves & outside world
# #

add_to_forward()
{
    local docker_int=$1

    if [ `${path_iptables4} -nvL FORWARD | grep ${docker_int} | wc -l` -eq 0 ]; then
        # Accept established connections to docker containers
        ${path_iptables4} -A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT
        ${path_iptables4} -A FORWARD -o ${docker_int} -j DOCKER
        ${path_iptables4} -A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT
        ${path_iptables4} -A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT

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
        ${path_iptables4} -t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE
        ${path_iptables4} -t nat -A DOCKER -i ${docker_int} -j RETURN

        echo -e "                  ${GREY1}+ RULE v4:               ${FUCHSIA2}-t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE${END}"
        echo -e "                  ${GREY1}+ RULE v4:               ${FUCHSIA2}-t nat -A DOCKER -i ${docker_int} -j RETURN${END}"

    # ipv6
    elif [ "$subnet" != "${subnet#*:[0-9a-fA-F]}" ]; then
        ${path_iptables6} -t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE
        ${path_iptables6} -A DOCKER -i ${docker_int} -j RETURN

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

    ${path_iptables4} -A DOCKER-ISOLATION-STAGE-1 -i ${docker_int} ! -o ${docker_int} -j DOCKER-ISOLATION-STAGE-2
    ${path_iptables4} -A DOCKER-ISOLATION-STAGE-2 -o ${docker_int} -j DROP

    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-1 -i ${docker_int} ! -o ${docker_int} -j DOCKER-ISOLATION-STAGE-2${END}"
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-2 -o ${docker_int} -j DROP${END}"
}

# #
#   Add Rules
# #

iptables-save | grep -v -- '-j DOCKER' | iptables-restore
chain_exists DOCKER && ${path_iptables4} -X DOCKER
chain_exists DOCKER nat && ${path_iptables4} -t nat -X DOCKER

${path_iptables4} -N DOCKER
${path_iptables4} -N DOCKER-ISOLATION-STAGE-1
${path_iptables4} -N DOCKER-ISOLATION-STAGE-2
${path_iptables4} -N DOCKER-USER

${path_iptables4} -t nat -N DOCKER
${path_iptables4} -A INPUT -i ${DOCKER_INT} -j ACCEPT

${path_iptables4} -A FORWARD -j DOCKER-USER
${path_iptables4} -A FORWARD -j DOCKER-ISOLATION-STAGE-1

add_to_forward ${DOCKER_INT}

${path_iptables4} -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
${path_iptables4} -t nat -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER

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

    ${path_iptables4} -t nat -A POSTROUTING ! -o ${DOCKER_INT} -s ${ip_block} -j MASQUERADE
    ${path_iptables4} -t nat -A POSTROUTING -s ${ip_block} ! -o ${DOCKER_INT} -j MASQUERADE

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

    DOCKER_NET_INT=`docker network inspect -f '{{"'br-$bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $bridge`
    subnet=`docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' $bridge`

	printf '\n%-17s %-35s %-55s' " " "${GREY1}BRIDGE" "${GREEN2}${bridge}${END}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}DOCKER INTERFACE" "${GREEN2}${DOCKER_NET_INT}${END}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}SUBNET" "${GREEN2}${subnet}${END}"
	echo -e

    add_to_nat ${DOCKER_NET_INT} ${subnet}
    add_to_forward ${DOCKER_NET_INT}
    add_to_docker_isolation ${DOCKER_NET_INT}
done

# #
#   Separator
# #

echo -e
echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
echo -e

# #
#   List containers
# #

containers=`docker ps -q`

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

        printf '\n%-22s %-35s %-55s' "    ${GREEN2}           " "${GREY1}NAME" "${YELLOW2}${name}${END}"
        printf '\n%-17s %-35s %-55s' " " "${GREY1}CONTAINER" "${GREEN2}${container}${END}"
        printf '\n%-17s %-35s %-55s' " " "${GREY1}NETMODE" "${GREEN2}${netmode}${END}"
        printf '\n%-17s %-35s %-55s' " " "${GREY1}NETWORK" "${GREEN2}${network_list}${END}"

        # #
        #   Netmode > Default
        # #

        if [ $netmode == "default" ]; then
            DOCKER_NET_INT=${DOCKER_INT}

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

                printf '\n%-17s %-52s' " " "${GREY1}  │ ${END}"

                bridge=$(docker inspect -f "{{with index .NetworkSettings.Networks \"${network}\"}}{{.NetworkID}}{{end}}" ${container} | cut -c -12)

                # #
                #   should return:
                #       br-2e0fde4b0664
                # #

                DOCKER_NET_INT=`docker network inspect -f '{{"'br-$bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $bridge`

                # here somewhere

                # #
                #   should return:
                #       172.18.0.7 (or any other IP)
                # #

                ipaddr=`docker inspect -f "{{with index .NetworkSettings.Networks \"${network}\"}}{{.IPAddress}}{{end}}" ${container}`
                ipaddr_orig=${ipaddr}

                if [ -z "${bridge}" ]; then bridge="${RED2}Not found${END}"; fi
                if [ -z "${DOCKER_NET_INT}" ]; then DOCKER_NET_INT="${RED2}Not found${END}"; fi
                if [ -z "${ipaddr}" ]; then ipaddr="${RED2}Not found${END}"; fi

                printf '\n%-17s %-52s %-55s' " " "${GREY1}  ├── ${GREY1}BRIDGE" "${GREEN2}${bridge}${END}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}  ├── ${GREY1}DOCKER_NET" "${GREEN2}${DOCKER_NET_INT}${END}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}  ├── ${GREY1}IP" "${GREEN2}${ipaddr}${END}"

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

            if grep -q "\b${ipaddr}\b" ${CSF_FILE_ALLOW}; then
                printf '\n%-17s %-52s %-55s' " " "${GREY1}  └── ${GREY1}WHITELIST" "${YELLOW2}${ipaddr} already white-listed in ${CSF_FILE_ALLOW}${END}"
            else

                # #
                #   Found CSF binary, add container IP to allow list /etc/csf/csf.allow
                # #

                if [[ $csf_path ]]; then
                    printf '\n%-17s %-52s %-55s' " " "${GREY1}  └── ${GREY1}WHITELIST" "${GREEN2}Adding ${ipaddr} to allow list ${CSF_FILE_ALLOW}${END}"
                    $csf_path -a ${ipaddr} ${CSF_COMMENT} >/dev/null 2>&1
                fi
            fi
        else
            printf '\n%-17s %-52s %-55s' " " "${GREY1}  └── ${GREY1}WHITELIST" "${RED2}Found blank IP, cannot be added to ${CSF_FILE_ALLOW}${END}"
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
                
                printf '\n%-17s %-52s' " " "${GREY1}      │ ${END}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}      ├── ${GREY1}SOURCE" "${FUCHSIA2}${src}${END}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}      └── ${GREY1}DESTINATION" "${FUCHSIA2}${dst}${END}"
                # printf '\n%-17s %-35s %-55s' " " "${GREY1}PORT" "${FUCHSIA2}${dst_port}${END}"
                # printf '\n%-17s %-35s %-55s' " " "${GREY1}PROTOTYPE" "${FUCHSIA2}${dst_proto}${END}"
                echo -e

                # #
                #   IPTABLE RULE > Add container ip:port for each entry
                # #

                ${path_iptables4} -A DOCKER -d ${ipaddr}/32 ! -i ${DOCKER_NET_INT} -o ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT
                ${path_iptables4} -t nat -A POSTROUTING -s ${ipaddr}/32 -d ${ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE

                echo -e "                  ${GREY1}          ├── + RULE:    ${GREY1}-A DOCKER -d ${ipaddr}/32 ! -i ${DOCKER_NET_INT} -o ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT${END}"
                echo -e "                  ${GREY1}          ├── + RULE:    ${GREY1}-t nat -A POSTROUTING -s ${ipaddr}/32 -d ${ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE${END}"

                # #
                #   Support for IPv4
                # #

                iptables_opt_src=""
                if [ ${src_ip} != "0.0.0.0" ]; then
                    iptables_opt_src="-d ${src_ip}/32 "
                fi

                if [[ ${src_ip} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    ${path_iptables4} -t nat -A DOCKER ${iptables_opt_src}! -i ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${ipaddr}:${dst_port}
                    echo -e "                  ${GREY1}          └── + RULE:    ${GREY1}-t nat -A DOCKER ${iptables_opt_src}! -i ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${ipaddr}:${dst_port}${END}"
                fi
            done
        fi

        echo -e
        echo -e

    done
fi

# #
#   Loop containers
# #

echo -e "  ${BOLD}${GREY1}+ RULES         ${WHITE}Add DOCKER-ISOLATION-STAGE rules${END}"

${path_iptables4} -A DOCKER-ISOLATION-STAGE-1 -j RETURN
${path_iptables4} -A DOCKER-ISOLATION-STAGE-2 -j RETURN
${path_iptables4} -A DOCKER-USER -j RETURN

printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-1 -j RETURN${END}"
printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-2 -j RETURN${END}"
printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-USER -j RETURN${END}"

if [ `${path_iptables4} -t nat -nvL DOCKER | grep ${DOCKER_INT} | wc -l` -eq 0 ]; then
    ${path_iptables4} -t nat -I DOCKER -i ${DOCKER_INT} -j RETURN
    printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-t nat -I DOCKER -i ${DOCKER_INT} -j RETURN${END}"
fi

echo -e
echo -e
