#!/bin/bash

# #
#   
#   ConfigServer Firewall - Docker Patch
#   
#   @author         Aetherinox
#   @package        ConfigServer Firewall
#   @file           docker.sh
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
#   define > configs
#
#   docker0_eth                 main docker network interface
#                                   can be created using the command:
#                                       - `sudo docker network create --driver=bridge --subnet=172.18.0.0/16 --gateway=172.18.0.1 traefik``
#   file_csf_allow              the defined allow list file
#   csf_comment                 comment added to each whitelisted ip within iptables
#   containers_ip_cidr               list of ip address blocks you will be using for your docker setup. these blocks will be whitelisted through ConfigServer Firewall
# #

docker0_eth="docker0"
csf_comment="Docker container whitelist"
file_csf_allow="/etc/csf/csf.allow"

# #
#   define > network ips
#
#   this is the list of IP addresses you will use with docker that must be
#   whitelisted.
# #

containers_ip_cidr=(
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

app_dir_this_a="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"     # current script full path
app_dir_this_b="${PWD}"                                                             # current script full path (alternative)
app_file_this=$(basename "$0")                                                      # docker.sh (with ext)
app_file_bin="${app_file_this%.*}"                                                  # docker (without ext)
app_pid=$BASHPID                                                                    # app pid
app_title="ConfigServer Firewall - Docker Patch"                                    # app title; displayed with --version
app_about="Sets up your firewall rules to work with Docker and Traefik. \n"\
"     This script requires that you have iptables installed on your system. \n"\
"     The required packages will be installed if you do not have them."             # app about; displayed with --version
app_ver=("14" "24" "0")                                                             # current script version

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
#   func > check sudo
#
#	this script requires permissions to copy, etc.
# 	require the user to run as sudo
# #

check_sudo()
{
	if [ "$EUID" -ne 0 ]; then
        echo -e 
        echo -e "  ${ORANGE}WARNING      ${WHITE}This script requires ${YELLOW2}sudo$${END}"
        echo -e "               Without this elevated permission; iptables will not add the proper rules."
        echo -e "               before this script can be ran.${END}"
        echo -e
        echo -e "               You may trigger sudo by running the following command:${END}"
        echo -e "                    ${GREY2}sudo ./${app_file_this}${END}"
        echo -e

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
#   func > service exists
# #

service_exists()
{
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

# #
#   Find CSF path on system; throw error if not found
# #

csf_path=$(command -v csf)

if [ -z "$csf_path" ]; then
    echo -e 
    echo -e "  ${ORANGE}WARNING      ${WHITE}This Script Requires ConfigServer Firewall${END}"
    echo -e "               You must install the application ${RED}ConfigServer Firewall${END} on your server"
    echo -e "               before this script can be ran.${END}"
    echo -e
    echo -e "               You can download ConfigServer Firewall from the following links:${END}"
    echo -e "                    ${GREY2}https://github.com/Aetherinox/csf-firewall/releases${END}"
    echo -e "                    ${GREY2}https://download.configserver.com/csf.tgz${END}"
    echo -e

    exit 0
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
#   clear screen before starting step 1
# #

clear

# #
#   Check sudo
# #

check_sudo

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
    echo -e 
    echo -e "  ${ORANGE}WARNING      ${WHITE}This Script Requires Iptables${END}"
    echo -e "               This package is required before you can utilize this script with ConfigServer Firewall."
    echo -e
    echo -e "               Try installing the package with:${END}"
    echo -e "                    ${GREY2}sudo apt-get update${END}"
    echo -e "                    ${GREY2}sudo apt-get install iptables${END}"
    echo -e

    exit 0
fi

# #
#   Truncate text; add ...
#   
#   @usage          $(trim "$name" 20 "...")
# #

trim()
{
    if (( "${#1}" > "$2" )); then
        echo "${1:0:$2}$3"
    else
        echo "$1"
    fi
}

# #
#   func > cmd > help
#
#   activate using ./install.sh --help or -h
# #

cmd_help()
{
    echo -e
    echo "${GREY1}  ┌────────────────────────────────────────────────────────────────────────────────────────┐${END}"
    echo
    printf "     ${BLUE2}${app_title} (v$(get_version))${END}\n\n" 1>&2
    printf "     ${GREY2}${app_about}${END}\n" 1>&2
    echo -e

    printf '  %-5s %-40s\n' "   ${GREEN}Usage:${END}" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${app_file_this} ${GREY1}[${GREY2}options${END}${GREY1}]${END}" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${app_file_this} ${GREY1}[${GREY2}-h | --help${END}${GREY1}] [${GREY2}-v | --version${END}${GREY1}] [${GREY2}-d | --dev${END}${GREY1}] [${GREY2}-l | --list${END}${GREY1}] [${GREY2}-r | --reset${END}${GREY1}]" 1>&2
    printf '  %-5s %-40s\n' "   ${GREEN}Options:${END}" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "developer mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}includes verbose logging${END}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-l, --list" "shows all current docker containers with information" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-c, --clear" "clears entire iptables rule list" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}firewall will be completely open after this finishes${END}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-r, --restart" "restarts config server firewall and lfd" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${GREY2}firewall will be completely open after this finishes${END}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of ${app_file_this} script" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    echo
    echo "${GREY1}  └────────────────────────────────────────────────────────────────────────────────────────┘${END}"
    echo -e
}

# #
#   func > cmd > version info & about
#   
#   @usage          docker.sh --version
#                   docker.sh -v
# #

cmd_version()
{

    echo -e
    echo "${GREY1}  ┌────────────────────────────────────────────────────────────────────────────────────────┐${END}"
    echo
    printf "     ${BLUE2}${app_title} (v$(get_version))${END}\n\n" 1>&2
    printf "     ${GREY2}${app_about}${END}\n" 1>&2
    echo -e
    printf "     ${GREY2}@repo        ${BLUE2}${repo_url}\n" 1>&2
    printf "     ${GREY2}@system      ${BLUE2}${sys_os} | ${sys_os_ver}\n" 1>&2
    printf "     ${GREY2}@notice      ${YELLOW}Before running this script, open ${FUCHSIA1}${app_dir_this_a}/${app_file_this}\n" 1>&2
    printf "     ${GREY2}             ${YELLOW}and edit the settings at the top of the file.\n" 1>&2
    echo
    echo "${GREY1}  └────────────────────────────────────────────────────────────────────────────────────────┘${END}"
    echo -e
}

# #
#   func > cmd > clear iptables
#   
#   clears the entire iptables list
#   
#   @usage          docker.sh --clear
#                   docker.sh -c
# #

cmd_iptables_clear()
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
#   func > cmd > csf > restart
#   
#   restarts csf and lfd
#   
#   @usage          docker.sh --restart
#                   docker.sh -r
# #

cmd_csf_restart()
{

    echo -e

    if service_exists lfd; then
        echo -e "  ${BOLD}${GREY1}+ lfd.service   ${END}${GREEN}Restarting${END}"
        sudo systemctl restart lfd.service
    else
        echo -e 
        echo -e "  ${ORANGE}WARNING      ${WHITE}Could not find service ${YELLOW2}lfd.service${END}"
        echo -e "               It is either not installed or the service is disabled. Enable the service first."
        echo -e
        echo -e "               Once CSF is installed, you can enable the service by running:${END}"
        echo -e "                    ${GREY2}sudo csf -e${END}"
        echo -e

        sudo systemctl status lfd
    fi

    if service_exists csf; then
        echo -e "  ${BOLD}${GREY1}+ csf.service   ${END}${GREEN}Restarting${END}"
        sudo systemctl restart csf.service
    else
        echo -e 
        echo -e "  ${ORANGE}WARNING      ${WHITE}Could not find service ${YELLOW2}csf.service${END}"
        echo -e "               It is either not installed or the service is disabled. Enable the service first."
        echo -e
        echo -e "               Once CSF is installed, you can enable the service by running:${END}"
        echo -e "                    ${GREY2}sudo csf -e${END}"
        echo -e

        sudo systemctl status csf
    fi

    echo -e
}

# #
#   func > cmd > list containers
#   
#   lists all of the docker containers, with information such as veth adapter, ip, container id, name, etc.
#   
#   @usage          docker.sh --list
#                   docker.sh -l
# #

cmd_containers_list()
{

    # #
    #   get all containers from docker
    # #

    containers=`docker ps -q`

    # #
    #   count docker containers; must be greater than 1
    # #

    if [ `echo ${containers} | wc -c` -gt "1" ]; then

        echo -e
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

        # #
        #   Loop containers
        # #

        for cont_id in ${containers}; do

            # #
            #   Output:
            #       CONTAINER ............... : 5b251b810e7d
            #       NETMODE ................. : 63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
            #
            #   Example:
            #       Running `docker inspect -f "{{.HostConfig.NetworkMode}}" 5b251b810e7d` outputs:
            #       63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
            # #

            cont_netmode=`docker inspect -f "{{.HostConfig.NetworkMode}}" ${cont_id}`                                                       # mail_default
            cont_network=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' ${cont_id}`       # mail_default \n traefik       (multiple lines)
            cont_network_list=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s " $net}}{{end}}' ${cont_id}`   # mail_default traefik          (unformatted list)
            cont_network_json=`docker inspect -f "{{json .NetworkSettings.Networks}}" ${cont_id}`                                           # {"mail_default":{"IPAMConfig":null,"Links":null,"Aliases":["mail-antispam","antispam"],"MacAddress":"01:22:00:0a:00:01"
            cont_name=`docker inspect -f "{{.Name}}" ${cont_id}`                                                                            # /mail-smtp
            cont_name=${cont_name#/}                                                                                                        #  mail-smtp                    (remove forward slash)
            cont_name=$(echo "$cont_name" | sed "s/ //g")                                                                                   # mail-smtp                     (remove spaces)
            cont_iflink=`docker exec -i "$cont_id" bash -c 'cat /sys/class/net/eth0/iflink' 2> /dev/null`                                   # 3605
            cont_shell="Bash"                                                                                                               # bash                          (default shell)

            err_bash_notfound=`echo "$cont_iflink" 2> /dev/null | grep -c "exec failed"`
        
            # #
            #   Bash Not Found
            # #

            if [[ "$err_bash_notfound" == "1" ]]; then
                cont_iflink=`docker exec -it "$cont_id" sh -c 'cat /sys/class/net/eth0/iflink' 2>/dev/null`
                err_sh_notfound=`echo "$cont_iflink" 2> /dev/null | grep -c "exec failed"`

                # #
                #   Sh Not Found
                # #

                if [[ "$err_sh_notfound" == "1" ]]; then
                    cont_shell="Unknown"
                    cont_iflink="Unknown"
                else
                    cont_iflink=`echo "$cont_iflink" | sed 's/[^0-9]*//g'`
                    cont_shell="SH"
                fi
            else
                cont_iflink=`echo "$cont_iflink" | sed 's/[^0-9]*//g'`
            fi

            # #
            #   container > running || unresponsive || offline
            # #

            cont_status=$(docker ps --format '{{.Names}}' | grep -c "^${cont_name}$")
            if [ "$( docker container inspect -f '{{.State.Running}}' $cont_name )" != "true" ]; then
                cont_iflink="Offline"
            fi

            if [ -z "${cont_iflink}" ]; then
                cont_iflink="Unresponsive"
            fi

            # #
            #   Get veth network interface
            # #

            if [ -n "${cont_iflink}" ]; then
                cont_veth=$(sudo grep -l -s "$cont_iflink" /sys/class/net/veth*/ifindex)
                cont_veth=`echo "$cont_veth" | sed -e 's;^.*net/\(.*\)/ifindex$;\1;'`

                if [ -z "${cont_veth}" ]; then
                    cont_veth="Unknown"
                fi

            fi

            # #
            #   Chart Truncation
            # #

            cont_name_chart=$(trim "$cont_name" 20 "...")
            cont_network_list_chart=$(trim "$cont_network_list" 50 "...")
            cont_network_mode_chart=$(trim "$cont_netmode" 18 "...")
            cont_network_ip_chart="Not Found"
            cont_network_list="$cont_network"
            declare -a cont_network_arr=( $cont_network )

            # #
            #   Netmode > Default
            # #

            if [ "$cont_netmode" == "default" ]; then
                cont_bridge_name="${docker0_eth}"
                cont_ipaddr=`docker inspect -f "{{.NetworkSettings.IPAddress}}" ${cont_id}`
                cont_network_ip_chart="$cont_ipaddr"

            # #
            #   Netmode > Other
            # #

            else
                # Loop Networks
                while IFS= read -r cont_network_list; do
                    # cont_bridge_name=`docker inspect -f "{{with index .NetworkSettings.Networks \"bridge\"}}{{.NetworkID}}{{end}}" cb9a6ae9c19e | cut -c -12`
                    cont_bridge=$(docker inspect -f "{{with index .NetworkSettings.Networks \"${cont_network_list}\"}}{{.NetworkID}}{{end}}" ${cont_id} | cut -c -12)

                    # docker network inspect -f {{"br-e95004d90f8d" | or (index .Options "com.docker.network.bridge.name")}} e95004d90f8d
                    cont_bridge_name=`docker network inspect -f '{{"'br-$cont_bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $cont_bridge`
                    cont_ipaddr=`docker inspect -f "{{with index .NetworkSettings.Networks \"${cont_network_list}\"}}{{.IPAddress}}{{end}}" ${cont_id}`
                    cont_ipaddr_orig=${cont_ipaddr}
                    cont_network_ip_chart="$cont_ipaddr"

                    if [ -z "${cont_bridge}" ]; then cont_bridge="${RED2}Not found${END}"; fi
                    if [ -z "${cont_bridge_name}" ]; then cont_bridge_name="${RED2}Not found${END}"; fi
                    if [ -z "${cont_ipaddr}" ]; then 
                        cont_ipaddr="${RED2}Not found${END}";
                        cont_network_ip_chart="Not Found";
                    fi
                done <<< "$cont_network_list"
            fi

            # #
            #   List each container
            # #

            printf '\n%-17s %-30s %-38s %-26s %-33s %-33s %-30s %-40s %-50s' \
                " " \
                "${GREY2}   ${cont_id}${END}" \
                "${GREY2}   ${cont_name_chart}" \
                "${GREY2}   ${cont_shell}${END}" \
                "${GREY2}   ${cont_network_ip_chart}${END}" \
                "${GREY2}   ${cont_iflink}${END}" \
                "${GREY2}   ${cont_veth}${END}" \
                "${GREY2}   ${cont_network_mode_chart}${END}" \
                "${GREY2}   [${#cont_network_arr[@]}] ${cont_network_list_chart}${END}"
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
            cmd_help
            exit 1
            ;;

        -l|--list)
            cmd_containers_list
            exit 1
            ;;

        -r|--restart)
            cmd_csf_restart
            exit 1
            ;;

        -c|--clear)
            cmd_iptables_clear
            exit 1
            ;;

        -v|--version)
            cmd_version
            exit 1
            ;;
        *)
            cmd_help
            exit 1
            ;;
    esac
    shift
done

# #
#   Clean container ips added by script once per restart
# #

if [[ $csf_path ]]; then
    echo -e
    echo -e "  ${BOLD}${GREY1}+ CSF           ${WHITE}Cleaning ${file_csf_allow}${END}"
    sudo sed --in-place "/${csf_comment}/d" ${file_csf_allow}
fi

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


    if [ `sudo ${path_iptables4} -n --list "$chain_name" $table 2> /dev/null | grep "$chain_name" | wc -l` -eq 0 ]; then
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

    if ! sudo ${path_iptables4} -C FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT &>/dev/null; then
        sudo ${path_iptables4} -A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT${END}"
    else
        echo -e "                  ${GREY1}! RULE:                  ${YELLOW}SKIP:${FUCHSIA2} -A FORWARD -o ${docker_int} -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT${END}"
    fi

    if ! sudo ${path_iptables4} -C FORWARD -o ${docker_int} -j DOCKER &>/dev/null; then
        sudo ${path_iptables4} -A FORWARD -o ${docker_int} -j DOCKER
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -o ${docker_int} -j DOCKER${END}"
    else
        echo -e "                  ${GREY1}! RULE:                  ${YELLOW}SKIP:${FUCHSIA2} -A FORWARD -o ${docker_int} -j DOCKER${END}"
    fi

    if ! sudo ${path_iptables4} -C FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT &>/dev/null; then
        sudo ${path_iptables4} -A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT${END}"
    else
        echo -e "                  ${GREY1}! RULE:                  ${YELLOW}SKIP:${FUCHSIA2} -A FORWARD -i ${docker_int} ! -o ${docker_int} -j ACCEPT${END}"
    fi

    if ! sudo ${path_iptables4} -C FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT &>/dev/null; then
        sudo ${path_iptables4} -A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT${END}"
    else
        echo -e "                  ${GREY1}! RULE:                  ${YELLOW}SKIP:${FUCHSIA2} -A FORWARD -i ${docker_int} -o ${docker_int} -j ACCEPT${END}"
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
#   sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
# #

# #
#   iptables-save & restore
# #

sudo iptables-save | grep -v -- '-j DOCKER' | sudo iptables-restore

# #
#   Chain DOCKER - Flush or Create
#   
#   -N <chain>                  Creates new chain
#   -X <chain>                  Delete a user defined-chain
#   -F <chain>                  Flush rules in chain
# #

if [ $(chainExists DOCKER) -eq 1 ] ; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Flush existing chain DOCKER${END}"
    sudo ${path_iptables4} -F DOCKER
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-F DOCKER${END}"
else
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Create new chain DOCKER${END}"
    sudo ${path_iptables4} -N DOCKER
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-N DOCKER${END}"
fi

# #
#   Chain DOCKER-ISOLATION-STAGE-1 - Flush or Create
#   
#   -N <chain>                  Creates new chain
#   -X <chain>                  Delete a user defined-chain
#   -F <chain>                  Flush rules in chain
# #

if [ $(chainExists DOCKER-ISOLATION-STAGE-1) -eq 1 ] ; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Flush existing chain DOCKER-ISOLATION-STAGE-1${END}"
    sudo ${path_iptables4} -F DOCKER-ISOLATION-STAGE-1
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-F DOCKER-ISOLATION-STAGE-1${END}"
else
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Create new chain DOCKER-ISOLATION-STAGE-1${END}"
    sudo ${path_iptables4} -N DOCKER-ISOLATION-STAGE-1
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-N DOCKER-ISOLATION-STAGE-1${END}"
fi

# #
#   Chain DOCKER-ISOLATION-STAGE-2 - Flush or Create
#   
#   -N <chain>                  Creates new chain
#   -X <chain>                  Delete a user defined-chain
#   -F <chain>                  Flush rules in chain
# #

if [ $(chainExists DOCKER-ISOLATION-STAGE-2) -eq 1 ] ; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Flush existing chain DOCKER-ISOLATION-STAGE-2${END}"
    sudo ${path_iptables4} -F DOCKER-ISOLATION-STAGE-2
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-F DOCKER-ISOLATION-STAGE-2${END}"
else
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Create new chain DOCKER-ISOLATION-STAGE-2${END}"
    sudo ${path_iptables4} -N DOCKER-ISOLATION-STAGE-2
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-N DOCKER-ISOLATION-STAGE-2${END}"
fi

# #
#   Chain DOCKER-USER - Flush or Create
#   
#   -N <chain>                  Creates new chain
#   -X <chain>                  Delete a user defined-chain
#   -F <chain>                  Flush rules in chain
# #

if [ $(chainExists DOCKER-USER) -eq 1 ] ; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Flush existing chain DOCKER-USER${END}"
    sudo ${path_iptables4} -F DOCKER-USER
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-F DOCKER-USER${END}"
else
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Create new chain DOCKER-USER${END}"
    sudo ${path_iptables4} -N DOCKER-USER
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-N DOCKER-USER${END}"
fi

# #
#   Chain DOCKER-USER (table nat) - Flush or Create
#   
#   -N <chain>                  Creates new chain
#   -X <chain>                  Delete a user defined-chain
#   -F <chain>                  Flush rules in chain
#   -t <table>                  Table to manipulate
# #

if [ $(chainExists DOCKER nat) -eq 1 ] ; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Flush existing chain DOCKER; table NAT${END}"
    sudo ${path_iptables4} -t nat -F DOCKER
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -F DOCKER${END}"
else
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Create new chain DOCKER; table NAT${END}"
    sudo ${path_iptables4} -t nat -N DOCKER
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -N DOCKER${END}"
fi

# #
#   Add Rules:
#       - INPUT                 add docker0 ACCEPT
#       - FORWARD               add DOCKER-USER
#       - FORWARD               add DOCKER-ISO-1
#   
#   -A <chain> <rule>           Append rule
#   -i <input-eth>              Incoming network interface
#   -j <rule>                   Target for rule; ACCEPT, DROP, REJECT
# #

if ! sudo ${path_iptables4} -C INPUT -i docker0 -j ACCEPT &>/dev/null; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Add ACCEPT policy for chain INPUT on DOCKER0 integrate${END}"
    sudo ${path_iptables4} -A INPUT -i ${docker0_eth} -j ACCEPT
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A INPUT -i ${docker0_eth} -j ACCEPT${END}"
fi

# #
#   Chain FORWARD (policy DROP)
#   
#   target                      prot opt source             destination         
#   DOCKER-USER                 all  --  anywhere           anywhere            
# #

if ! sudo ${path_iptables4} -C FORWARD -j DOCKER-USER &>/dev/null; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Add JUMP rule in chain FORWARD to chain DOCKER-USER${END}"
    sudo ${path_iptables4} -A FORWARD -j DOCKER-USER
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -j DOCKER-USER${END}"
fi

# #
#   Chain FORWARD (policy DROP)
#   
#   target                      prot opt source             destination         
#   DOCKER-ISOLATION-STAGE-1    all  --  anywhere           anywhere 
# #

if ! sudo ${path_iptables4} -C FORWARD -j DOCKER-ISOLATION-STAGE-1 &>/dev/null; then
    echo -e "  ${BOLD}${GREY1}+ IPTABLES      ${END}Add JUMP rule in chain FORWARD to chain DOCKER-ISOLATION-STAGE-1${END}"
    sudo ${path_iptables4} -A FORWARD -j DOCKER-ISOLATION-STAGE-1
    echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-A FORWARD -j DOCKER-ISOLATION-STAGE-1${END}"
fi

# #
#   add docker0 to forward
# #

add_to_forward ${docker0_eth}

# #
#   To view PREROUTING and POSTROUTING rules; add `-t nat` with:
#       sudo iptables -t nat -L --line-numbers -n
#   
#   Check if rule exists with:
#       sudo iptables -C PREROUTING -t nat -m addrtype --dst-type LOCAL -j DOCKER
#   
#   target                      prot opt source             destination         
#   DOCKER                      0    --  0.0.0.0/0          !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
# #

sudo ${path_iptables4} -t nat -A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
sudo ${path_iptables4} -t nat -A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER

# #
#   whitelist ip addresses associated with docker
# #

echo -e
echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
echo -e

echo -e "  ${BOLD}${GREY1}+ POSTROUTING   ${WHITE}Adding IPs from primary IP list${END}"

for j in "${!containers_ip_cidr[@]}"; do

    # #
    #   get ip addresses
    # #

    ip_block=${containers_ip_cidr[$j]}
    echo -e "  ${BOLD}${WHITE}                + ${YELLOW2}${ip_block}${END}"

    # #
    #   Masquerade outbound connections from containers
    #   
    #   check rules with:
    #       sudo iptables -C POSTROUTING -t nat ! -o docker0 -s 172.17.0.0/16 -j MASQUERADE
    #       sudo iptables -C POSTROUTING -t nat -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
    # #

    if ! `sudo ${path_iptables4} -C POSTROUTING -t nat ! -o ${docker0_eth} -s ${ip_block} -j MASQUERADE &>/dev/null`; then
        sudo ${path_iptables4} -t nat -A POSTROUTING ! -o ${docker0_eth} -s ${ip_block} -j MASQUERADE
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -A POSTROUTING ! -o ${docker0_eth} -s ${ip_block} -j MASQUERADE${END}"
    else
        echo -e "                  ${GREY1}! RULE:                  ${YELLOW}SKIP:${FUCHSIA2} -t nat -A POSTROUTING ! -o ${docker0_eth} -s ${ip_block} -j MASQUERADE${END}"
    fi

    if ! `sudo ${path_iptables4} -C POSTROUTING -t nat -s ${ip_block} ! -o ${docker0_eth} -j MASQUERADE &>/dev/null`; then
        sudo ${path_iptables4} -t nat -A POSTROUTING -s ${ip_block} ! -o ${docker0_eth} -j MASQUERADE
        echo -e "                  ${GREY1}+ RULE:                  ${FUCHSIA2}-t nat -A POSTROUTING -s ${ip_block} ! -o ${docker0_eth} -j MASQUERADE${END}"
    else
        echo -e "                  ${GREY1}! RULE:                  ${YELLOW}SKIP:${FUCHSIA2} -t nat -A POSTROUTING -s ${ip_block} ! -o ${docker0_eth} -j MASQUERADE${END}"
    fi
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

for cont_bridge in $bridges; do

    # #
    #   Output:
    #       BRIDGE ............... : 242441c7d76c
    #       DOCKER_NET_INT_1 ..... : docker0
    #       SUBNET ............... : 172.17.0.0/16
    # #

    cont_bridge_name=`docker network inspect -f '{{"'br-$cont_bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $cont_bridge`
    subnet=`docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' $cont_bridge`

	printf '\n%-17s %-35s %-55s' " " "${GREY1}BRIDGE" "${BLUE2}${cont_bridge}${END}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}DOCKER INTERFACE" "${BLUE2}${cont_bridge_name}${END}"
	printf '\n%-17s %-35s %-55s' " " "${GREY1}SUBNET" "${BLUE2}${subnet}${END}"
	echo -e

    add_to_nat ${cont_bridge_name} ${subnet}
    add_to_forward ${cont_bridge_name}
    add_to_docker_isolation ${cont_bridge_name}
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
#   get all containers from docker
# #

containers=`docker ps -q`

# #
#   count docker containers; must be greater than 1
# #

if [ `echo ${containers} | wc -c` -gt "1" ]; then

    # #
    #   Loop containers
    # #

    for cont_id in ${containers}; do

        # #
        #   Output:
        #       CONTAINER ............... : 5b251b810e7d
        #       NETMODE ................. : 63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
        #
        #   Example:
        #       Running `docker inspect -f "{{.HostConfig.NetworkMode}}" 5b251b810e7d` outputs:
        #       63599565ed58b275d60087e218e2875aec3c3258976433d061721f0cb666e0b8
        # #

        cont_netmode=`docker inspect -f "{{.HostConfig.NetworkMode}}" ${cont_id}`
        cont_network=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' ${cont_id}`
        cont_network_list=`docker inspect -f '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s " $net}}{{end}}' ${cont_id}`
        cont_network_json=`docker inspect -f "{{json .NetworkSettings.Networks}}" ${cont_id}`
        cont_name=`docker inspect -f "{{.Name}}" ${cont_id}`
        cont_name=${cont_name#/}                                        # remove forward slash
        cont_name=$(echo "$cont_name" | sed "s/ //g")                   # remove spaces
        cont_iflink=`docker exec -i "$cont_id" bash -c 'cat /sys/class/net/eth0/iflink' 2> /dev/null`
        cont_shell="Bash"

        err_bash_notfound=`echo "$cont_iflink" 2> /dev/null | grep -c "exec failed"`
    
        # #
        #   Bash Not Found
        # #

        if [[ "$err_bash_notfound" == "1" ]]; then
            cont_iflink=`docker exec -it "$cont_id" sh -c 'cat /sys/class/net/eth0/iflink' 2>/dev/null`
            err_sh_notfound=`echo "$cont_iflink" 2> /dev/null | grep -c "exec failed"`

            # #
            #   Sh Not Found
            # #

            if [[ "$err_sh_notfound" == "1" ]]; then
                cont_shell="Unknown"
                cont_iflink="Unknown"
            else
                cont_iflink=`echo "$cont_iflink" | sed 's/[^0-9]*//g'`
                cont_shell="SH"
            fi
        else
            cont_iflink=`echo "$cont_iflink" | sed 's/[^0-9]*//g'`
        fi

        # #
        #   Container > Running
        # #

        cont_status=$(docker ps --format '{{.Names}}' | grep -c "^${cont_name}$")
        if [ "$( docker container inspect -f '{{.State.Running}}' $cont_name )" != "true" ]; then
            cont_iflink="Not running"
        fi

        if [ -z "${cont_iflink}" ]; then
            cont_iflink="Unresponsive"
        fi

        # #
        #   Get veth network interface
        # #

        if [ -n "${cont_iflink}" ]; then
            cont_veth=$(sudo grep -l -s "$cont_iflink" /sys/class/net/veth*/ifindex)
            cont_veth=`echo "$cont_veth" | sed -e 's;^.*net/\(.*\)/ifindex$;\1;'`

            if [ -z "${cont_veth}" ]; then
                cont_veth="Unknown"
            fi

        fi

        # #
        #   Chart Truncation
        # #

        cont_name_chart=$(trim "$cont_name" 20 "...")
        cont_network_list_chart=$(trim "$cont_network_list" 50 "...")
        cont_network_mode_chart=$(trim "$cont_netmode" 18 "...")
        cont_network_ip_chart="Not Found"
        cont_network_list="$cont_network"
        declare -a cont_network_arr=( $cont_network )

        # #
        #   Netmode > Default
        # #

        if [ $cont_netmode == "default" ]; then
            cont_bridge_name=${docker0_eth}
            cont_ipaddr=`docker inspect -f "{{.NetworkSettings.IPAddress}}" ${cont_id}`
            cont_network_ip_chart="$cont_ipaddr"

        # #
        #   Netmode > Other
        # #

        else
            # Loop Networks
            while IFS= read -r cont_network_list; do
                # cont_bridge_name=`docker inspect -f "{{with index .NetworkSettings.Networks \"bridge\"}}{{.NetworkID}}{{end}}" cb9a6ae9c19e | cut -c -12`
                cont_bridge=$(docker inspect -f "{{with index .NetworkSettings.Networks \"${cont_network_list}\"}}{{.NetworkID}}{{end}}" ${cont_id} | cut -c -12)           # 2e0fde4b0664

                # docker network inspect -f {{"br-e95004d90f8d" | or (index .Options "com.docker.network.bridge.name")}} e95004d90f8d
                cont_bridge_name=`docker network inspect -f '{{"'br-$cont_bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $cont_bridge`                  # br-2e0fde4b0664
                cont_ipaddr=`docker inspect -f "{{with index .NetworkSettings.Networks \"${cont_network_list}\"}}{{.IPAddress}}{{end}}" ${cont_id}`                         # 172.18.0.13
                cont_ipaddr_orig=${cont_ipaddr}                                                                                                                             # 172.18.0.13
                cont_network_ip_chart="$cont_ipaddr"                                                                                                                        # 172.18.0.13

                if [ -z "${cont_bridge}" ]; then cont_bridge="${RED2}Not found${END}"; fi
                if [ -z "${cont_bridge_name}" ]; then cont_bridge_name="${RED2}Not found${END}"; fi
                if [ -z "${cont_ipaddr}" ]; then 
                    cont_ipaddr="${RED2}Not found${END}";
                    cont_network_ip_chart="Not Found";
                fi
            done <<< "$cont_network_list"
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
            "${GREY2}   ${cont_id}${END}" \
            "${GREY2}   ${cont_name_chart}" \
            "${GREY2}   ${cont_shell}${END}" \
            "${GREY2}   ${cont_network_ip_chart}${END}" \
            "${GREY2}   ${cont_iflink}${END}" \
            "${GREY2}   ${cont_veth}${END}" \
            "${GREY2}   ${cont_network_mode_chart}${END}" \
            "${GREY2}   [${#cont_network_arr[@]}] ${cont_network_list_chart}${END}"

        echo -e
        echo " ${GREY1}                 │                                                                                                                                                                │"
        echo " ${GREY1}                 └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘${END}"

        # #
        #   Netmode > Default
        # #

        if [ $cont_netmode == "default" ]; then
            cont_bridge_name=${docker0_eth}

            #   This will return empty if IP manually assigned from docker-compose.yml for container
            #   docker inspect -f "{{.NetworkSettings.IPAddress}}" 5b251b810e7d

            cont_ipaddr=`docker inspect -f "{{.NetworkSettings.IPAddress}}" ${cont_id}`

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
            while IFS= read -r cont_network; do

                printf '\n%-17s %-46s' " " "${GREY1}│ ${END}"

                cont_bridge=$(docker inspect -f "{{with index .NetworkSettings.Networks \"${cont_network}\"}}{{.NetworkID}}{{end}}" ${cont_id} | cut -c -12)

                # #
                #   should return:
                #       br-2e0fde4b0664
                # #

                cont_bridge_name=`docker network inspect -f '{{"'br-$cont_bridge'" | or (index .Options "com.docker.network.bridge.name")}}' $cont_bridge`

                # #
                #   should return:
                #       172.18.0.7 (or any other IP)
                # #

                cont_ipaddr=`docker inspect -f "{{with index .NetworkSettings.Networks \"${cont_network}\"}}{{.IPAddress}}{{end}}" ${cont_id}`
                cont_ipaddr_orig=${cont_ipaddr}

                if [ -z "${cont_bridge}" ]; then cont_bridge="${RED2}Not found${END}"; fi
                if [ -z "${cont_bridge_name}" ]; then cont_bridge_name="${RED2}Not found${END}"; fi
                if [ -z "${cont_ipaddr}" ]; then cont_ipaddr="${RED2}Not found${END}"; fi

                printf '\n%-17s %-46s %-55s' " " "${GREY1}├── ${GREY1}BRIDGE" "${BLUE2}${cont_bridge_name}${END}"
             #  printf '\n%-17s %-46s %-55s' " " "${GREY1}├── ${GREY1}DOCKER_NET" "${BLUE2}${cont_bridge_name}${END}"
                printf '\n%-17s %-46s %-55s' " " "${GREY1}├── ${GREY1}IP" "${BLUE2}${cont_ipaddr}${END}"

                if [ "${cfg_dev_enabled}" == "true" ]; then
                    echo -e "                                           ${GREY1}docker inspect -f \"{{with index .NetworkSettings.Networks \"${cont_network}\"}}{{.NetworkID}}{{end}}\" ${cont_id} | cut -c -12${END}"
                    echo -e "                                           ${GREY1}docker network inspect -f '{{\"'br-$cont_bridge'\" | or (index .Options \"com.docker.network.bridge.name\")}}' ${cont_bridge}${END}"
                    echo -e "                                           ${GREY1}docker inspect -f '{{with index .NetworkSettings.Networks \"${cont_network}\"}}{{.IPAddress}}{{end}}' ${cont_id}${END}"
                fi

            done <<< "$cont_network"
        fi

        # #
        #   CHeck if containers IP is currently in CSF allow list /etc/csf/csf.allow
        # #

        if [[ -n "${cont_ipaddr}" ]] && [[ "$cont_ipaddr" != "${RED2}Not found${END}" ]]; then

            if sudo grep -q "\b${cont_ipaddr}\b" ${file_csf_allow}; then
                printf '\n%-17s %-46s %-55s' " " "${GREY1}└── ${GREY1}WHITELIST" "${YELLOW2}Already whitelisted in: ${END}${file_csf_allow}${END}"
            else

                # #
                #   Found CSF binary, add container IP to allow list /etc/csf/csf.allow
                # #

                if [[ $csf_path ]]; then
                    printf '\n%-17s %-46s %-55s' " " "${GREY1}└── ${GREY1}WHITELIST" "${GREEN2}Adding ${cont_ipaddr} to allow list ${file_csf_allow}${END}"
                 #   $csf_path -a ${cont_ipaddr} ${csf_comment} >/dev/null 2>&1
                fi
            fi
        else
            printf '\n%-17s %-46s %-55s' " " "${GREY1}└── ${GREY1}WHITELIST" "${RED2}Found blank IP, cannot be added to ${file_csf_allow}${END}"
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

        rules=`docker port ${cont_id} | sed 's/ //g'`

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

                sudo ${path_iptables4} -A DOCKER -d ${cont_ipaddr}/32 ! -i ${cont_bridge_name} -o ${cont_bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT
                sudo ${path_iptables4} -t nat -A POSTROUTING -s ${cont_ipaddr}/32 -d ${cont_ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE

                echo -e "                  ${GREY1}    ├── + RULE:    ${GREY1}-A DOCKER -d ${cont_ipaddr}/32 ! -i ${cont_bridge_name} -o ${cont_bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j ACCEPT${END}"
                echo -e "                  ${GREY1}    ├── + RULE:    ${GREY1}-t nat -A POSTROUTING -s ${cont_ipaddr}/32 -d ${cont_ipaddr}/32 -p ${dst_proto} -m ${dst_proto} --dport ${dst_port} -j MASQUERADE${END}"

                # #
                #   Support for IPv4
                # #

                iptables_opt_src=""
                if [ ${src_ip} != "0.0.0.0" ]; then
                    iptables_opt_src="-d ${src_ip}/32 "
                fi

                if [[ ${src_ip} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    sudo ${path_iptables4} -t nat -A DOCKER ${iptables_opt_src}! -i ${cont_bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${cont_ipaddr}:${dst_port}
                    echo -e "                  ${GREY1}    └── + RULE:    ${GREY1}-t nat -A DOCKER ${iptables_opt_src}! -i ${cont_bridge_name} -p ${dst_proto} -m ${dst_proto} --dport ${src_port} -j DNAT --to-destination ${cont_ipaddr}:${dst_port}${END}"
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

printf '\n%-17s %-29s %-55s' " " "${GREY1}+ TASK" "${FUCHSIA2}Checking ${END}${docker0_eth}${FUCHSIA2} status${END}"
if [ `sudo ${path_iptables4} -t nat -nvL DOCKER 2> /dev/null | grep ${docker0_eth} | wc -l` -eq 0 ]; then
    sudo ${path_iptables4} -t nat -I DOCKER -i ${docker0_eth} -j RETURN
    printf '\n%-17s %-29s %-55s' " " "${GREY1}+ RULE" "${FUCHSIA2}-t nat -I DOCKER -i ${docker0_eth} -j RETURN${END}"
else
    printf '\n%-17s %-29s %-55s' " " "${GREY1}! RULE" "${END}Already exists: ${FUCHSIA2}-t nat -I DOCKER -i ${docker0_eth} -j RETURN${END}"
fi

echo -e
echo -e