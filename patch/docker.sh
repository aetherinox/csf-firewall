#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#   ConfigServer Firewall
#
#   @about          this script automatically scans all docker containers that exist within the server and adds
#                   each IP to ConfigServer Firewall.
#
#   @command        sudo /usr/local/include/csf/post.d/install.sh
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# #
#   vars > system
# #

SYS_ARCH=$(dpkg --print-architecture)
SYS_CODE=$(lsb_release -cs)

# #
#   vars > app
# #

APP_TITLE="ConfigServer Firewall Docker Patch"
APP_ABOUT="Configures ConfigServer Firewall to work with Docker and Traefik"
APP_VER=("14" "22" "0")
APP_THIS_FILE=$(basename "$0")                          # current script file
APP_THIS_DIR="${PWD}"                                   # current script directory
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# #
#   vars > app repo
# #

APP_REPO_NAME="csf-firewall"
APP_REPO_AUTHOR="Aetherinox"
APP_REPO_BRANCH="main"
APP_REPO_URL="https://github.com/${APP_REPO_AUTHOR}/${APP_REPO_NAME}"

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
    echo -e "  ⭕ ${GREY2}${APP_THIS_FILE}${RESET}: \n     ${BOLD}${RED}Error${NORMAL}: ${RESET}$1"
    echo -e
    exit 0
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
    ver_join=${APP_VER[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

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
#   Find CSF path on system
# #

csf_path=$(command -v csf)

# #
#   Clean container ips added by script once per restart
# #

if [[ $csf_path ]]; then
    echo -e
    echo -e "  ${BOLD}${GREY1}+ WHITELIST     ${WHITE}Cleaning ${CSF_FILE_ALLOW}${RESET}"
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
#   iptables > find
# #

if ! [ -x "$(command -v iptables)" ]; then
    echo -e "  ${GREY2}Installing package ${MAGENTA}iptables${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install iptables -y -qq >/dev/null 2>&1
fi

# #
#   iptables > assign path to var
# #

PATH_IPTABLES=$(which iptables)
PATH_IPTABLES6=$(which ip6tables)

# #
#   iptables > doesnt exist
# #

if [ -z "${PATH_IPTABLES}" ]; then
    echo -e "  ${BOLD}${ORANGE2}WARNING         ${WHITE}Could not locate the package ${YELLOW2}iptables${RESET}"
    printf '%-17s %-55s %-55s' " " "${GREY1}Must install iptables before continuing${RESET}"
    echo -e

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
    printf "  ${BLUE2}${APP_TITLE}${RESET}\n" 1>&2
    printf "  ${GREY2}${APP_ABOUT}${RESET}\n" 1>&2
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
            echo -e "  ${FUCHSIA2}${BLINK}Devmode Enabled${RESET}"
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -v|--version)
            echo
            echo -e "  ${GREEN2}${BOLD}${APP_TITLE}${RESET} - v$(get_version)${RESET}"
            echo -e "  ${GREY2}${BOLD}${APP_REPO_URL}${RESET}"
            echo -e "  ${GREY2}${BOLD}${OS} | ${OS_VER}${RESET}"
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

if ${PATH_IPTABLES} -L DOCKER &> /dev/null; then
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Flushing existing chain DOCKER${RESET}"
    ${PATH_IPTABLES} -F DOCKER
else
    echo -e "  ${BOLD}${GREY1}+ DOCKER        ${WHITE}Creating chain DOCKER${RESET}"
    ${PATH_IPTABLES} -N DOCKER
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

    ${PATH_IPTABLES} $table -n --list "$chain_name" >/dev/null 2>&1
}

# #
#   Forward > Add
#
#   Allow containers to communicate with themselves & outside world
# #

add_to_forward()
{
    local docker_int=$1

    if [ `${PATH_IPTABLES} -nvL FORWARD | grep ${docker_int} | wc -l` -eq 0 ]; then
        # Accept established connections to docker containers
        ${PATH_IPTABLES} -A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT
        ${PATH_IPTABLES} -A FORWARD -o ${docker_int} -j DOCKER
        ${PATH_IPTABLES} -A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT
        ${PATH_IPTABLES} -A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT

        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT${RESET}"
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -o ${docker_int} -j DOCKER${RESET}"
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT${RESET}"
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT${RESET}"
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
        ${PATH_IPTABLES} -t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE
        ${PATH_IPTABLES} -t nat -A DOCKER -i ${docker_int} -j RETURN

        echo -e "                  ${GREY1}+ RULE v4:               ${FUCHSIA2}-t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE${RESET}"
        echo -e "                  ${GREY1}+ RULE v4:               ${FUCHSIA2}-t nat -A DOCKER -i ${docker_int} -j RETURN${RESET}"

    # ipv6
    elif [ "$subnet" != "${subnet#*:[0-9a-fA-F]}" ]; then
        ${PATH_IPTABLES6} -t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE
        ${PATH_IPTABLES6} -A DOCKER -i ${docker_int} -j RETURN

        echo -e "                  ${GREY1}+ RULE v6:               ${FUCHSIA2}-t nat -A POSTROUTING -s ${subnet} ! -o ${docker_int} -j MASQUERADE${RESET}"
        echo -e "                  ${GREY1}+ RULE v6:               ${FUCHSIA2}-A DOCKER -i ${docker_int} -j RETURN${RESET}"
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

    ${PATH_IPTABLES} -A DOCKER-ISOLATION-STAGE-1 -i ${docker_int} ! -o ${docker_int} -j DOCKER-ISOLATION-STAGE-2
    ${PATH_IPTABLES} -A DOCKER-ISOLATION-STAGE-2 -o ${docker_int} -j DROP

    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-1 -i ${docker_int} ! -o ${docker_int} -j DOCKER-ISOLATION-STAGE-2${RESET}"
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-2 -o ${docker_int} -j DROP${RESET}"
}

# #
#   Add Rules
# #

iptables-save | grep -v -- '-j DOCKER' | iptables-restore
chain_exists DOCKER && ${PATH_IPTABLES} -X DOCKER
chain_exists DOCKER nat && ${PATH_IPTABLES} -t nat -X DOCKER

${PATH_IPTABLES} -N DOCKER
${PATH_IPTABLES} -N DOCKER-ISOLATION-STAGE-1
${PATH_IPTABLES} -N DOCKER-ISOLATION-STAGE-2
${PATH_IPTABLES} -N DOCKER-USER

${PATH_IPTABLES} -t nat -N DOCKER
${PATH_IPTABLES} -A INPUT -i ${DOCKER_INT} -j ACCEPT

${PATH_IPTABLES} -A FORWARD -j DOCKER-USER
${PATH_IPTABLES} -A FORWARD -j DOCKER-ISOLATION-STAGE-1

add_to_forward ${DOCKER_INT}

${PATH_IPTABLES} -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
${PATH_IPTABLES} -t nat -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER

# #
#   whitelist ip addresses associated with docker
# #

echo -e
echo -e " ${BLUE2}---------------------------------------------------------------------------------------------------${RESET}"
echo -e

echo -e "  ${BOLD}${GREY1}+ POSTROUTING   ${WHITE}Adding IPs from primary IP list${RESET}"

for j in "${!IP_CONTAINERS[@]}"; do

    # #
    #   get ip addresses
    # #

    ip_block=${IP_CONTAINERS[$j]}
    echo -e "  ${BOLD}${WHITE}                + ${YELLOW2}${ip_block}${RESET}"

    # #
    #   Masquerade outbound connections from containers
    # #

    ${PATH_IPTABLES} -t nat -A POSTROUTING ! -o ${DOCKER_INT} -s ${ip_block} -j MASQUERADE
    ${PATH_IPTABLES} -t nat -A POSTROUTING -s ${ip_block} ! -o ${DOCKER_INT} -j MASQUERADE

    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -A POSTROUTING ! -o ${DOCKER_INT} -s ${ip_block} -j MASQUERADE${RESET}"
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -A POSTROUTING -s ${ip_block} ! -o ${DOCKER_INT} -j MASQUERADE${RESET}"
done

# #
#   Separator
# #

echo -e
echo -e " ${BLUE2}---------------------------------------------------------------------------------------------------${RESET}"
echo -e

# #
#   Get bridges
#
#   Output:
#       7018d23c9bb4
#       2e0fde4b0664
# #

echo -e "  ${BOLD}${GREY1}+ BRIDGES       ${WHITE}Configuring network bridges${RESET}"

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

	printf '\n%-17s %-35s %-55s' " " "${GREY1}BRIDGE" "${GREEN2}${bridge}${RESET}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}DOCKER INTERFACE" "${GREEN2}${DOCKER_NET_INT}${RESET}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}SUBNET" "${GREEN2}${subnet}${RESET}"
	echo -e

    add_to_nat ${DOCKER_NET_INT} ${subnet}
    add_to_forward ${DOCKER_NET_INT}
    add_to_docker_isolation ${DOCKER_NET_INT}
done

# #
#   Separator
# #

echo -e
echo -e " ${BLUE2}---------------------------------------------------------------------------------------------------${RESET}"
echo -e

# #
#   List containers
# #

containers=`docker ps -q`

# #
#   Loop containers
# #

echo -e "  ${BOLD}${GREY1}+ CONTAINERS    ${WHITE}Configure containers${RESET}"

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

        printf '\n%-22s %-35s %-55s' "    ${GREEN2}           " "${GREY1}NAME" "${YELLOW2}${name}${RESET}"
        printf '\n%-17s %-35s %-55s' " " "${GREY1}CONTAINER" "${GREEN2}${container}${RESET}"
        printf '\n%-17s %-35s %-55s' " " "${GREY1}NETMODE" "${GREEN2}${netmode}${RESET}"
        printf '\n%-17s %-35s %-55s' " " "${GREY1}NETWORK" "${GREEN2}${network_list}${RESET}"

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

                printf '\n%-17s %-52s' " " "${GREY1}  │ ${RESET}"

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

                if [ -z "${bridge}" ]; then bridge="${RED2}Not found${RESET}"; fi
                if [ -z "${DOCKER_NET_INT}" ]; then DOCKER_NET_INT="${RED2}Not found${RESET}"; fi
                if [ -z "${ipaddr}" ]; then ipaddr="${RED2}Not found${RESET}"; fi

                printf '\n%-17s %-52s %-55s' " " "${GREY1}  ├── ${GREY1}BRIDGE" "${GREEN2}${bridge}${RESET}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}  ├── ${GREY1}DOCKER_NET" "${GREEN2}${DOCKER_NET_INT}${RESET}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}  ├── ${GREY1}IP" "${GREEN2}${ipaddr}${RESET}"

                if [ "${OPT_DEV_ENABLE}" == "true" ] || [ "${DEBUG_ENABLED}" == "true" ]; then
                    echo -e "                                           ${GREY1}docker inspect -f \"{{with index .NetworkSettings.Networks \"${network}\"}}{{.NetworkID}}{{end}}\" ${container} | cut -c -12${RESET}"
                    echo -e "                                           ${GREY1}docker network inspect -f '{{\"'br-$bridge'\" | or (index .Options \"com.docker.network.bridge.name\")}}' ${bridge}${RESET}"
                    echo -e "                                           ${GREY1}docker inspect -f '{{with index .NetworkSettings.Networks \"${network}\"}}{{.IPAddress}}{{end}}' ${container}${RESET}"
                fi

            done <<< "$network"
        fi

        # #
        #   CHeck if containers IP is currently in CSF allow list /etc/csf/csf.allow
        # #

        if [[ -n "${ipaddr}" ]] && [[ "$ipaddr" != "${RED2}Not found${RESET}" ]]; then

            if grep -q "\b${ipaddr}\b" ${CSF_FILE_ALLOW}; then
                printf '\n%-17s %-52s %-55s' " " "${GREY1}  └── ${GREY1}WHITELIST" "${YELLOW2}${ipaddr} already white-listed in ${CSF_FILE_ALLOW}${RESET}"
            else

                # #
                #   Found CSF binary, add container IP to allow list /etc/csf/csf.allow
                # #

                if [[ $csf_path ]]; then
                    printf '\n%-17s %-52s %-55s' " " "${GREY1}  └── ${GREY1}WHITELIST" "${GREEN2}Adding ${ipaddr} to allow list ${CSF_FILE_ALLOW}${RESET}"
                    $csf_path -a ${ipaddr} ${CSF_COMMENT} >/dev/null 2>&1
                fi
            fi
        else
            printf '\n%-17s %-52s %-55s' " " "${GREY1}  └── ${GREY1}WHITELIST" "${RED2}Found blank IP, cannot be added to ${CSF_FILE_ALLOW}${RESET}"
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
                
                printf '\n%-17s %-52s' " " "${GREY1}      │ ${RESET}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}      ├── ${GREY1}SOURCE" "${FUCHSIA2}${src}${RESET}"
                printf '\n%-17s %-52s %-55s' " " "${GREY1}      └── ${GREY1}DESTINATION" "${FUCHSIA2}${dst}${RESET}"
                # printf '\n%-17s %-35s %-55s' " " "${GREY1}PORT" "${FUCHSIA2}${dst_port}${RESET}"
                # printf '\n%-17s %-35s %-55s' " " "${GREY1}PROTOTYPE" "${FUCHSIA2}${dst_proto}${RESET}"
                echo -e

                # #
                #   IPTABLE RULE > Add container ip:port for each entry
                # #

                ${PATH_IPTABLES} -A DOCKER -d ${ipaddr}/32 ! -i ${DOCKER_NET_INT} -o ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT
                ${PATH_IPTABLES} -t nat -A POSTROUTING -s ${ipaddr}/32 -d ${ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE

                echo -e "                  ${GREY1}          ├── + RULE:    ${GREY1}-A DOCKER -d ${ipaddr}/32 ! -i ${DOCKER_NET_INT} -o ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT${RESET}"
                echo -e "                  ${GREY1}          ├── + RULE:    ${GREY1}-t nat -A POSTROUTING -s ${ipaddr}/32 -d ${ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE${RESET}"

                # #
                #   Support for IPv4
                # #

                iptables_opt_src=""
                if [ ${src_ip} != "0.0.0.0" ]; then
                    iptables_opt_src="-d ${src_ip}/32 "
                fi

                if [[ ${src_ip} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    ${PATH_IPTABLES} -t nat -A DOCKER ${iptables_opt_src}! -i ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${ipaddr}:${dst_port}
                    echo -e "                  ${GREY1}          └── + RULE:    ${GREY1}-t nat -A DOCKER ${iptables_opt_src}! -i ${DOCKER_NET_INT} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${ipaddr}:${dst_port}${RESET}"
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

echo -e "  ${BOLD}${GREY1}+ RULES         ${WHITE}Add DOCKER-ISOLATION-STAGE rules${RESET}"

${PATH_IPTABLES} -A DOCKER-ISOLATION-STAGE-1 -j RETURN
${PATH_IPTABLES} -A DOCKER-ISOLATION-STAGE-2 -j RETURN
${PATH_IPTABLES} -A DOCKER-USER -j RETURN

printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-1 -j RETURN${RESET}"
printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-ISOLATION-STAGE-2 -j RETURN${RESET}"
printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-A DOCKER-USER -j RETURN${RESET}"

if [ `${PATH_IPTABLES} -t nat -nvL DOCKER | grep ${DOCKER_INT} | wc -l` -eq 0 ]; then
    ${PATH_IPTABLES} -t nat -I DOCKER -i ${DOCKER_INT} -j RETURN
    printf '\n%-17s %-35s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-t nat -I DOCKER -i ${DOCKER_INT} -j RETURN${RESET}"
fi

echo -e
echo -e
