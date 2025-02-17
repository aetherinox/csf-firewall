#!/bin/bash

# #
#   
#   ConfigServer Firewall - Patch Installation Script
#   
#   @author         Aetherinox
#   @package        ConfigServer Firewall
#   @type           Patch
#   @desc           This script copies the following files to the below paths:
#						/usr/local/include/csf/post.d/openvpn.sh
#						/usr/local/include/csf/post.d/docker.sh
#						/usr/local/csf/bin/csfpre.sh
#						/usr/local/csf/bin/csfpost.sh
#   
#					You can find the ConfigServer Firewall config at:
#						/etc/csf/csf.conf
#
#   @usage          chmod +x /usr/local/include/csf/post.d/ports-drop.sh
#                   sudo /usr/local/include/csf/post.d/ports-drop.sh
#   
# #

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
#   vars > internal
# #

STEP1_SKIP="false"
STEP2_SKIP="false"

# #
#   vars > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   vars > generic
# #

app_title="ConfigServer Firewall - Installation Patch"
app_about="Installs Docker and OpenVPN patches for ConfigServer Firewall."
app_ver=("14" "22" "0")
app_this_file=$(basename "$0")                          # current script file
app_this_dir_a="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
app_this_dir_b="${PWD}"                                 # current script directory
app_file_this=$(basename "$0")                          # ports-block.sh (with ext)
app_file_bin="${app_file_this%.*}"                      # ports-block (without ext)
app_pid=$BASHPID

# #
#	define > files
# #

file_docker=docker.sh
file_openvpn=openvpn.sh

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
#   define > folders
# #

folder_usr_local_include="/usr/local/include"
folder_csf_include_csf="${folder_usr_local_include}/csf"
folder_csf_pre="${folder_usr_local_include}/csf/pre.d"
folder_csf_post="${folder_usr_local_include}/csf/post.d"
folder_csf_bin="/usr/local/csf/bin"

# #
#	define > files
# #

file_csf_config="/etc/csf/csf.conf"
file_csf_pre="csfpre.sh"
file_csf_post="csfpost.sh"

# #
#	define > paths
# #

path_csf_pre="${folder_csf_bin}/${file_csf_pre}"
path_csf_post="${folder_csf_bin}/${file_csf_post}"

# #
#   print an error and exit with failure
#   $1: error message
# #

function error()
{
    echo -e "  ⭕ ${GREY2}${app_this_file}${END}: \n     ${BOLD}${RED}Error${END}: ${END}$1"
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
        echo

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
#   Service Exists
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
#   func > disable ConfigServer Firewall testing
# #

csf_edit_conf() {
    sed -i 's/TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
    sed -i 's/ETH_DEVICE_SKIP = ""/ETH_DEVICE_SKIP = "docker0"/' /etc/csf/csf.conf
    sed -i 's/DOCKER = "0"/DOCKER = "1"/' /etc/csf/csf.conf
}

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

cd "${app_this_dir_a}"

# #
#   find > curl
# #

if ! [ -x "$(command -v curl)" ]; then
    check_sudo
    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}curl${END}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install curl -y -qq >/dev/null 2>&1
fi

# #
#   find > iptables
# #

if ! [ -x "$(command -v iptables)" ]; then
    check_sudo
    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}iptables${END}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install iptables -y -qq >/dev/null 2>&1
fi

# #
#   find > ipset
# #

if ! [ -x "$(command -v ipset)" ]; then
    check_sudo
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
#   Install > ConfigServer Firewall
# #

if ! command -v -- "csf" > /dev/null 2>&1; then
    check_sudo

    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}ConfigServer Firewall${END}"

    # #
    #   csf > install prerequisites
    # #

    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install perl ipset -y -qq >/dev/null 2>&1

    # #
    #   csf > download, extract, install
    # #

    wget https://download.configserver.com/csf.tgz >> /dev/null 2>&1
    tar -xzf csf.tgz >> /dev/null 2>&1
    cd "${app_this_dir_a}/csf"
    sudo sh install.sh >> /dev/null 2>&1

    # #
    #   csf > cleanup
    # #

    cd "${app_this_dir_a}"
    sudo rm csf.tgz >> /dev/null 2>&1
    sudo rm -rf csf/ >> /dev/null 2>&1

    echo -e
    echo -e "  ${WHITE}CSF patcher will now start ...${END}"
    echo -e

    # #
    #   iptables > assign path to var
    # #

    path_iptables4=$(which iptables)
    path_iptables6=$(which ip6tables)

    sleep 2
fi

# #
#   Display Usage Help
#
#   activate using ./install.sh --help or -h
# #

opt_usage()
{
    echo -e "aa"
    echo -e 
    printf "  ${BLUE}${app_title}${END}\n" 1>&2
    printf "  ${GREY2}${app_about}${END}\n" 1>&2
    echo -e 
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREY2}options${END}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREY2}-h${END}] [${GREY2}-v${END}] [${GREY2}-d${END}] [${GREY2}-r${END}] [${GREY2}-f${END}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "developer mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "displays advanced logs" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-f, --flush" "completely wipe all iptable rules" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "this includes v4 and v6 rules -- cannot be undone" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-r, --report" "show info about ${app_file_this}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "current paths, installed dependencies, etc." 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of csf script" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    echo -e 
    echo -e 
    exit 1
}

# #
#   Display Report
# #

opt_report()
{

    clear

    sleep 0.3

    # #
    #  Section > Manifest
    # #

    manifest_bUpdateAvail="false"
    manifest_version=$(curl -s https://api.github.com/repos/${repo_author}/${repo_name}/releases/latest | jq -r '.tag_name')
    manifest_published=$(curl -s https://api.github.com/repos/${repo_author}/${repo_name}/releases/latest | jq -r '.published_at')

    # #
    #  Check update
    # #

    version_now=$(get_version)
    version_new=${manifest_version}

    if get_version_compare_gt $version_new $version_now; then
        manifest_bUpdateAvail="true"
    else
        manifest_bUpdateAvail="false"
    fi

    # #
    #  Section > Header
    # #

    echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${END}"
    echo -e " ${GREY2} ${app_about}${END}"
    echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"

    # #
    #  Section > General
    # #

    echo -e
    echo -e "  ${YELLOW2}${BOLD}[ General ]${END}"

    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Script" "${WHITE}${app_file_this}" "${END}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Path" "${WHITE}${app_this_dir_a}" "${END}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Version" "${WHITE}v$(get_version)" "${END}"
    if [ "${manifest_bUpdateAvail}" == "true" ]; then
        printf "%-5s %-35s %-40s %-40s\n" "" "${BLUE2}           " "${YELLOW}Update Available( v${version_new} )" "${END}"
    fi
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Released" "${WHITE}${manifest_published}" "${END}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Repository" "${WHITE}${repo_url}" "${END}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  sys_os" "${WHITE}${sys_os} - ${sys_os_ver}" "${END}"

    # #
    #  Section > Dependencies 
    # #

    echo -e
    echo -e "  ${YELLOW2}${BOLD}[ Dependencies ]${END}"

    bInstalled_CSF=$([ ! "$(! command -v -- "csf")" ] && echo "Missing" || echo 'Installed')
    bInstalled_Ipset=$([ ! -x "$(command -v ipset)" ] && echo "Missing" || echo $(dpkg-query -W -f='${Version}\n' ipset))
    bInstalled_Iptables=$([ ! -x "$(command -v iptables)" ] && echo "Missing" || echo $(dpkg-query -W -f='${Version}\n' iptables))
    bInstalled_Perl=$([ ! -x "$(command -v perl)" ] && echo "Missing" || echo $(dpkg-query -W -f='${Version}\n' perl))

    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  ConfgServer" "${WHITE}${bInstalled_CSF}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  Ipset" "${WHITE}${bInstalled_Ipset}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  Iptables" "${WHITE}${bInstalled_Iptables}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  Perl" "${WHITE}${bInstalled_Perl}${END}"

    # #
    #  Section > Structure
    # #

    echo -e
    echo -e "  ${YELLOW2}${BOLD}[ Structure ]${END}"

    bFound_DirIncludeCSF=$(sudo [ ! -d ${folder_csf_include_csf} ] && echo "Missing" || echo 'Found')
    bFound_DirPred=$(sudo [ ! -d ${folder_csf_pre} ] && echo "Missing" || echo 'Found')
    bFound_DirPostd=$(sudo [ ! -d ${folder_csf_post} ] && echo "Missing" || echo 'Found')
    bFound_DirBin=$(sudo [ ! -d ${folder_csf_bin} ] && echo "Missing" || echo 'Found')
    bFound_FileCSFPreSh=$(sudo [ ! -f ${file_csf_pre} ] && echo "Missing" || echo 'Found')
    bFound_FileCSFPostSh=$(sudo [ ! -f ${file_csf_post} ] && echo "Missing" || echo 'Found')
    bFound_FileCSFConf=$(sudo [ ! -f ${file_csf_config} ] && echo "Missing" || echo 'Found')

    printf "%-5s %-55s %-40s\n" "" "${BLUE2}📁  ${folder_csf_include_csf}" "${WHITE}${bFound_DirIncludeCSF}${END}"
    printf "%-5s %-55s %-40s\n" "" "${BLUE2}📁  ${folder_csf_pre}" "${WHITE}${bFound_DirPred}${END}"
    printf "%-5s %-55s %-40s\n" "" "${BLUE2}📁  ${folder_csf_post}" "${WHITE}${bFound_DirPostd}${END}"
    printf "%-5s %-55s %-40s\n" "" "${BLUE2}📁  ${folder_csf_bin}" "${WHITE}${bFound_DirBin}${END}"
    printf "%-5s %-55s %-40s\n" "" "${BLUE2}📄  ${file_csf_pre}" "${WHITE}${bFound_FileCSFPreSh}${END}"
    printf "%-5s %-55s %-40s\n" "" "${BLUE2}📄  ${file_csf_post}" "${WHITE}${bFound_FileCSFPostSh}${END}"
    printf "%-5s %-55s %-40s\n" "" "${BLUE2}📄  ${file_csf_config}" "${WHITE}${bFound_FileCSFConf}${END}"

    # #
    #  Section > Footer
    # #

    echo -e 
    echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
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
#   --flush         completely remove all iptable rules, including v6
#   --help          show help and usage information
#   --version       display version information
# #

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dev)
            OPT_DEV_ENABLE=true
            echo -e
            echo -e "  ${MAGENTA}${BLINK}Devmode Enabled${END}"
            echo -e
            ;;

    -f|--flush)
            echo -e "  ${BOLD}${GREY1}IPTABLES        ${END}Flushing ${GREY1}Started${END}"

            ${path_iptables4} -P INPUT ACCEPT
            ${path_iptables4} -P FORWARD ACCEPT
            ${path_iptables4} -P OUTPUT ACCEPT
            ${path_iptables4} -t nat -F
            ${path_iptables4} -t mangle -F
            ${path_iptables4} -F
            ${path_iptables4} -X

            ${path_iptables6} -P INPUT ACCEPT
            ${path_iptables6} -P FORWARD ACCEPT
            ${path_iptables6} -P OUTPUT ACCEPT
            ${path_iptables6} -t nat -F
            ${path_iptables6} -t mangle -F
            ${path_iptables6} -F
            ${path_iptables6} -X

            echo -e "  ${BOLD}${GREY1}IPTABLES        ${END}Flushing ${GREY1}Finished${END}"
            echo -e
            exit 1
            ;;

    -r*|--report*)
            opt_report
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -v|--version)
            echo -e
            echo -e "  ${GREEN}${BOLD}${app_title}${END} - v$(get_version)${END}"
            echo -e "  ${GREY2}${BOLD}${repo_url}${END}"
            echo -e "  ${GREY2}${BOLD}${sys_os} | ${sys_os_ver}${END}"
            echo -e
            exit 1
            ;;
    *)
            opt_usage
            ;;
  esac
  shift
done

# #
#   clear screen before starting step 1
# #

clear

# #
#   check sudo
# #

check_sudo

# #
#   STEP 1 > Copy Script
#
#	call function with
#		copy_script "csfpre.sh" "/usr/local/csf/bin/csfpre.sh"
#		copy_script "csfpost.sh" "/usr/local/csf/bin/csfpost.sh"
# #

    function copy_script
    {
        # #
        #   STEP 1 > Header
        # #

        echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo -e "  ${GREY1}${BOLD}${app_title} - v$(get_version)${END}"
        echo -e
        echo -e "  ${GREEN}${BOLD}Step 1 - Pre & Post Script${END}"
        echo -e "        This patch will now install the Docker and OpenVPN functionality to your existing copy of"
        echo -e "        ConfigServer Firewall. The installed patches will then be ran each time you restart"
        echo -e "        or start up CSF."
        echo -e
        echo -e "        All patches will be installed to the path:"
        echo -e "                ${GREY2}${folder_csf_bin}${END}"
        echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"

        # #
        #   csf_script ............. csfpre.sh
        #   csf_dst_path ........... /usr/local/csf/bin/csfpre.sh
        # #

        local csf_script=$1
        local csf_dst_path=$2

        echo -e
        echo -e "  ${BOLD}${YELLOW}[ ${csf_script} ]  ${END}"
        echo -e

        echo -e "  ${BOLD}${GREY1}PATHS           ${END}Checking paths for script ${BLUE2}${app_this_dir_a}/${csf_script}${END}"
        printf '%-17s %-55s %-55s' " " "${GREY1}Path: Local" "${MAGENTA}${app_this_dir_a}/${csf_script}${END}"
        echo -e
        printf '%-17s %-55s %-55s' " " "${GREY1}Path: Destination" "${MAGENTA}${csf_dst_path}${END}"
        echo -e

        echo -e
        echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo -e

        sleep 1

        # #
        #   STEP 1 > If path_csf_post exists
        # #

        if [ -f "${path_csf_post}" ]; then

            # #
            #	missing local pre file
            # #

            if [ ! -f "${csf_script}" ]; then
                echo
                echo -e "  ${ORANGE}WARNING      ${WHITE}Could not locate the file ${YELLOW2}${app_this_dir_a}/${csf_script}${END}"
                echo -e "               Cannot compare MD5 hash when local file is missing${END}"
                echo

                exit 0
            fi

            md5_0=`md5sum ${csf_script} | awk '{ print $1 }'`
            md5_1=`md5sum ${path_csf_post} | awk '{ print $1 }'`

            echo -e "  ${BOLD}${GREY1}MD5             ${END}Compare local ${BLUE2}${csf_script}${WHITE} with ${BLUE2}${csf_dst_path}${END}"
            printf '%-17s %-55s %-55s' " " "${GREY1}${app_this_dir_a}/${csf_script}" "${MAGENTA}${md5_0}${END}"
            echo -e
            printf '%-17s %-55s %-55s' " " "${GREY1}${csf_dst_path}" "${MAGENTA}${md5_1}${END}"
            echo -e

            if [ ${md5_0} == ${md5_1} ]; then
                echo -e
                echo -e "  ${BOLD}${WHITE}                ✔️  ${WHITE}MD5 matches: ${ORANGE}Aborting update${END}"
            else
                echo -e
                echo -e "  ${BOLD}${WHITE}                ❌  ${WHITE}MD5 mismatch: ${GREEN}Copying new version of file${END}"
            fi

            echo -e
            echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
            echo -e

            # #
            #   MD5 Compare
            # #

            if [ ${md5_0} == ${md5_1} ]; then
                echo -e "  ${BOLD}${YELLOW}NOTICE          ${WHITE}Script ${GREEN}${csf_script}${WHITE} is already up to date${END}"
                printf '%-17s %-55s %-55s' " " "${GREY1}skipping step ....${END}"
                echo -e

                STEP1_SKIP="true"
            else
                ok=0
                while [ ${ok} -eq 0 ]; do
                    echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}A different version of the script ${GREEN}${csf_dst_path}${WHITE} is already present${END}"
                    printf '%-17s %-55s %-55s' " " "${GREY1}Do you want to replace it (y/n)?${END}"
                    echo -e

                    read answer

                    if [ ${answer} == "y" -o ${answer} == "n" ]; then
                        ok=1
                    fi
                done

                if [ ${answer} == "n" ]; then
                    exit 1
                fi
            fi
        fi

        # #
        #   Determine if step 1 should be skipped
        # #

        if [ -z ${STEP1_SKIP} ] || [ ${STEP1_SKIP} == "false" ]; then

            if [ -f "${csf_dst_path}" ]; then

                # #
                #   Copy
                # #

                echo -e "  ${WHITE}                Copy            ${MAGENTA}${app_this_dir_a}/${csf_script}${WHITE} > ${MAGENTA}${csf_dst_path}${END}"
                cp -f "${csf_script}" "${csf_dst_path}"

                # #
                #   Chown
                # #

                echo -e "  ${WHITE}                Chown           ${MAGENTA}root:root${WHITE} > ${MAGENTA}${csf_dst_path}${END}"
                chown root:root "${csf_dst_path}"

                # #
                #   Chmod
                # #

                echo -e "  ${WHITE}                Chmod           ${MAGENTA}700${WHITE} > ${MAGENTA}${csf_dst_path}${END}"
                chmod 700 "${csf_dst_path}"
            else
                echo
                echo -e "  ${ORANGE}WARNING      ${WHITE}Could not locate the file ${YELLOW2}${csf_dst_path}${END}"
                echo -e "               This file is required for the ConfigServer Firewall patches to work properly.${END}"
                echo

                exit 0
            fi

        fi

        sleep 1
        clear
    }

    # #
    #   STEP 1 > Setup
    # #

    # Create directories needed for custom csf{pre,post}
    if [ ! -d ${folder_csf_pre} ]; then
        if [ "${OPT_DEV_ENABLE}" = true ]; then
            echo -e "  ${WHITE}                Mkdir           ${MAGENTA}${folder_csf_pre}${END}"
        fi
        mkdir -p ${folder_csf_pre}
    fi

    if [ ! -d ${folder_csf_post} ]; then
        if [ "${OPT_DEV_ENABLE}" = true ]; then
            echo -e "  ${WHITE}                Mkdir           ${MAGENTA}${folder_csf_post}${END}"
        fi
        mkdir -p ${folder_csf_post}
    fi

    # #
    #   STEP 1 > Copy Scripts
    # #

    copy_script "${file_csf_pre}" "${path_csf_pre}"
    copy_script "${file_csf_post}" "${path_csf_post}"

    # #
    #   STEP 1 > Clear Console
    # #

    clear

# #
#   STEP 2 > SCRIPT > DOCKER
# #

    # #
    #   STEP 2 > Header
    # #

    echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e "  ${GREY1}${BOLD}${app_title} - v$(get_version)${END}"
    echo -e
    echo -e "  ${GREEN}${BOLD}Step 2 - Install Docker Patch${END}"
    echo -e "        This step will copy the docker patch ${file_docker} to the following location:"
    echo -e "        All patches will be installed to the path:"
    echo -e "                ${GREY2}${folder_csf_post}${END}"
    echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"

    # #
    #	STEP 2:
    #   	check if script has been ran before:
    #		- /csf-firewall/patch/install.sh
    # #

    if [ ! -d "${folder_csf_include_csf}" ]; then
        echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}Step 1 did not run properly, folder is missing from your system:${END}"
        printf '%-17s %-55s %-55s' " " "${GREY1}${folder_csf_include_csf}${END}"
        echo -e
        exit 1
    fi

    opt_prefix="None"
    if [ "$1" == "-p" ] || [ "$1" == "--prefix" ]; then
        opt_prefix=$2
        shift 2
    fi

    file_docker_b="${file_docker}"
    if [ ${opt_prefix} != "None" ]; then
        file_docker_b="${opt_prefix}_${file_docker}"
    fi

    # #
    #	STEP 2:
    #   	check if file exists:
    #		- /usr/local/include/csf/post.d/docker.sh
    # #

    if [ -f "${folder_csf_post}/${file_docker_b}" ]; then

        # #
        #	missing local docker.sh file
        # #
        
        if [ ! -f "${file_docker}" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Could not locate the file ${YELLOW2}${app_this_dir_a}/${file_docker}${END}"
            echo -e "               Cannot compare MD5 hash when local file is missing${END}"
            echo

            exit 0
        fi

        md5_0=`md5sum ${file_docker} | awk '{ print $1 }'`
        md5_1=`md5sum ${folder_csf_post}/${file_docker_b} | awk '{ print $1 }'`

        echo -e
        echo -e "  ${BOLD}${GREY1}MD5             ${END}Compare local ${BLUE2}${app_this_dir_a}/${file_docker}${END} with ${BLUE2}${folder_csf_post}/${file_docker_b}${END}"
        printf '%-17s %-55s %-55s' " " "${GREY1}${app_this_dir_a}/${file_docker}" "${MAGENTA}${md5_0}${END}"
        echo -e
        printf '%-17s %-55s %-55s' " " "${GREY1}${folder_csf_post}/${file_docker_b}" "${MAGENTA}${md5_1}${END}"
        echo -e

        if [ ${md5_0} == ${md5_1} ]; then
            echo -e
            echo -e "  ${BOLD}${WHITE}                ✔️  ${WHITE}MD5 matches: ${ORANGE}Aborting update${END}"
        else
            echo -e
            echo -e "  ${BOLD}${WHITE}                ❌  ${WHITE}MD5 mismatch: ${GREEN}Copying new version of file${END}"
        fi

        echo -e
        echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo -e

        # #
        #   MD5 Compare
        # #

        if [ ${md5_0} == ${md5_1} ]; then
            echo -e "  ${BOLD}${YELLOW}NOTICE          ${WHITE}Script ${GREEN}${folder_csf_post}/${file_docker_b}${WHITE} is already up to date${END}"
            printf '%-17s %-55s %-55s' " " "${GREY1}skipping step ....${END}"
            echo -e

            STEP2_SKIP="true"
        else
            ok=0
            while [ ${ok} -eq 0 ]; do
                echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}A different version of the script ${GREEN}${folder_csf_post}/${file_docker_b}${WHITE} is already present${END}"
                printf '%-17s %-55s %-55s' " " "${GREY1}Do you want to replace it (y/n)?${END}"
                echo -e

                read answer

                if [ ${answer} == "y" -o ${answer} == "n" ]; then
                    ok=1
                fi
            done

            if [ ${answer} == "n" ]; then
                exit 1
            fi
        fi
    fi

    # #
    #	STEP 2:
    #   	Determine if step 2 should be skipped
    # #

    if [ -z ${STEP2_SKIP} ] || [ ${STEP2_SKIP} == "false" ]; then
        echo -e "  ${WHITE}                Copy            ${MAGENTA}${file_docker}${WHITE} > ${MAGENTA}${folder_csf_post}/${file_docker_b}${END}"
        cp -f "${file_docker}" "${folder_csf_post}/${file_docker_b}"

        echo -e "  ${WHITE}                Chown           ${MAGENTA}root:root${WHITE} > ${MAGENTA}${folder_csf_post}/${file_docker_b}${END}"
        chown root:root "${folder_csf_post}/${file_docker_b}"

        echo -e "  ${WHITE}                Chmod           ${MAGENTA}700${WHITE} > ${MAGENTA}${folder_csf_post}/${file_docker_b}${END}"
        chmod 700 "${folder_csf_post}/${file_docker_b}"
    fi

    # #
    #	STEP 2:
    #   	All steps skipped, no changes made
    # #

    if [ ${STEP1_SKIP} == "true" ] && [ ${STEP2_SKIP} == "true" ]; then
        echo -e
        echo -e "  ${BOLD}${GREEN}FINISH          ${WHITE}All of your configs were already up to date${END}"
        printf '%-17s %-55s %-55s' " " "${GREY1}No changes were made to CSF and docker${END}"
        echo -e
    fi

    # #
    #	STEP 2:
    #   	Services
    #		After applying all the changes, restart the services csf and lfd
    # #

    echo -e
    echo -e "  ${BOLD}${GREY1}SERVICES        ${END}Checking for ${BLUE2}lfd.service${END} and ${BLUE2}csf.service${END}"

    if service_exists lfd; then
        printf '%-17s %-55s %-55s' " " "lfd.service" "${GREEN}Restarting${END}"
        echo -e
        systemctl restart lfd.service
    else
        printf '%-17s %-55s %-55s' " " "lfd.service" "${ORANGE}Not Found${END}"
        echo -e
    fi

    if service_exists csf; then
        printf '%-17s %-55s %-55s' " " "csf.service" "${GREEN}Restarting${END}"
        echo -e
        systemctl restart csf.service
    else
        printf '%-17s %-55s %-55s' " " "csf.service" "${ORANGE}Not Found${END}"
        echo -e
    fi

    # #
    #   STEP 2 > CLEAR CONSOLE
    # #

    clear

# #
#   STEP 3 > SCRIPT > OPENVPN
# #

    # #
    #   STEP 3 > OpenVPN > Header
    # #

    echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e "  ${GREY1}${BOLD}${app_title} - v$(get_version)${END}"
    echo -e
    echo -e "  ${GREEN}${BOLD}Step 3 - Install OpenVPN Patch${END}"
    echo -e
    echo -e "  ${BLUE2}This installer will now copy the ${file_openvpn} script to:"
    echo -e "  ${BOLD}${WHITE}    ${GREY1}${folder_csf_post}${END}"
    echo -e
    echo -e "  Every time the services csf and lfd are started / restarted; firewall rules will be added so"
    echo -e "  that your containers have access to the network and can be accessed."
    echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"

    # #
    #	STEP 3:
    #   	check if script has been ran before:
    #		- csf-firewall/patch/install.sh
    # #

    if [ ! -d ${folder_csf_include_csf} ]; then
        echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}Step 1 did not run properly, folder is missing from your system:${END}"
        printf '%-17s %-55s %-55s' " " "${GREY1}${folder_csf_include_csf}${END}"
        echo -e
        exit 1
    fi

    opt_prefix="None"
    if [ "$1" == "-p" ] || [ "$1" == "--prefix" ]; then
        opt_prefix=$2
        shift 2
    fi

    SCRIPT_OPENVPN_FILE="${file_openvpn}"
    if [ ${opt_prefix} != "None" ]; then
        SCRIPT_OPENVPN_FILE="${opt_prefix}_${file_openvpn}"
    fi

    # #
    #	STEP 3:
    #   	check if file exists:
    #		- /usr/local/include/csf/post.d/openvpn.sh
    # #

    if [ -f "${folder_csf_post}/${SCRIPT_OPENVPN_FILE}" ]; then

        # #
        #	missing local openvpn.sh file
        # #
        
        if [ ! -f "${file_openvpn}" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Could not locate the file ${YELLOW2}${app_this_dir_a}/${file_openvpn}${END}"
            echo -e "               Cannot compare MD5 hash when local file is missing${END}"
            echo

            exit 0
        fi

        md5_0=`md5sum ${file_openvpn} | awk '{ print $1 }'`
        md5_1=`md5sum ${folder_csf_post}/${SCRIPT_OPENVPN_FILE} | awk '{ print $1 }'`

        echo -e
        echo -e "  ${BOLD}${GREY1}MD5             ${END}Compare local ${BLUE2}${app_this_dir_a}/${file_openvpn}${END} with ${BLUE2}${folder_csf_post}/${SCRIPT_OPENVPN_FILE}${END}"
        printf '%-17s %-55s %-55s' " " "${GREY1}${app_this_dir_a}/${file_openvpn}" "${MAGENTA}${md5_0}${END}"
        echo -e
        printf '%-17s %-55s %-55s' " " "${GREY1}${folder_csf_post}/${SCRIPT_OPENVPN_FILE}" "${MAGENTA}${md5_1}${END}"
        echo -e

        if [ ${md5_0} == ${md5_1} ]; then
            echo -e
            echo -e "  ${BOLD}${WHITE}                ✔️  ${WHITE}MD5 matches: ${ORANGE}Aborting update${END}"
        else
            echo -e
            echo -e "  ${BOLD}${WHITE}                ❌  ${WHITE}MD5 mismatch: ${GREEN}Copying new version of file${END}"
        fi

        echo -e
        echo -e " ${GREY1}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo -e

        # #
        #   MD5 Compare
        # #

        if [ ${md5_0} == ${md5_1} ]; then
            echo -e "  ${BOLD}${YELLOW}NOTICE          ${WHITE}Script ${GREEN}${folder_csf_post}/${SCRIPT_OPENVPN_FILE}${WHITE} is already up to date${END}"
            printf '%-17s %-55s %-55s' " " "${GREY1}skipping step ....${END}"
            echo -e

            STEP2_SKIP="true"
        else
            ok=0
            while [ ${ok} -eq 0 ]; do
                echo -e "  ${BOLD}${ORANGE}WARNING         ${WHITE}A different version of the script ${GREEN}${folder_csf_post}/${SCRIPT_OPENVPN_FILE}${WHITE} is already present${END}"
                printf '%-17s %-55s %-55s' " " "${GREY1}Do you want to replace it (y/n)?${END}"
                echo -e

                read answer

                if [ ${answer} == "y" -o ${answer} == "n" ]; then
                    ok=1
                fi
            done

            if [ ${answer} == "n" ]; then
                exit 1
            fi
        fi
    fi

    # #
    #	STEP 3:
    #   	Determine if step 3 should be skipped
    # #

    if [ -z ${STEP2_SKIP} ] || [ ${STEP2_SKIP} == "false" ]; then
        echo -e "  ${WHITE}                Copy            ${MAGENTA}${file_openvpn}${WHITE} > ${MAGENTA}${folder_csf_post}/${SCRIPT_OPENVPN_FILE}${END}"
        cp -f ${file_openvpn} ${folder_csf_post}/${SCRIPT_OPENVPN_FILE}

        echo -e "  ${WHITE}                Chown           ${MAGENTA}root:root${WHITE} > ${MAGENTA}${folder_csf_post}/${SCRIPT_OPENVPN_FILE}${END}"
        chown root:root ${folder_csf_post}/${SCRIPT_OPENVPN_FILE}

        echo -e "  ${WHITE}                Chmod           ${MAGENTA}700${WHITE} > ${MAGENTA}${folder_csf_post}/${SCRIPT_OPENVPN_FILE}${END}"
        chmod 700 ${folder_csf_post}/${SCRIPT_OPENVPN_FILE}
    fi

    # #
    #	STEP 3:
    #   	All steps skipped, no changes made
    # #

    if [ ${STEP1_SKIP} == "true" ] && [ ${STEP2_SKIP} == "true" ]; then
        echo -e
        echo -e "  ${BOLD}${GREEN}FINISH          ${WHITE}All of your configs were already up to date${END}"
        printf '%-17s %-55s %-55s' " " "${GREY1}No changes were made to CSF and OpenVPN${END}"
        echo -e
    fi

    # #
    #	STEP 3:
    #   	Services
    #		After applying all the changes, restart the services csf and lfd
    # #

    echo -e
    echo -e "  ${BOLD}${GREY1}SERVICES        ${WENDHITE}Checking for ${BLUE2}lfd.service${END} and ${BLUE2}csf.service${WHITE}${END}"

    if service_exists lfd; then
        printf '%-17s %-55s %-55s' " " "lfd.service" "${GREEN}Restarting${END}"
        echo -e
        systemctl restart lfd.service
    else
        printf '%-17s %-55s %-55s' " " "lfd.service" "${ORANGE}Not Found${END}"
        echo -e
    fi

    if service_exists csf; then
        printf '%-17s %-55s %-55s' " " "csf.service" "${GREEN}Restarting${END}"
        echo -e
        systemctl restart csf.service

        csf -r
    else
        printf '%-17s %-55s %-55s' " " "csf.service" "${ORANGE}Not Found${END}"
        echo -e
    fi

# #
#   Modify CSF config to disable TESTING mode
# #

    echo -e
    echo -e "  ${BOLD}${GREY1}CSF             ${END}Disabling ${BLUE2}TESTING MODE${END} in ${BLUE2}/etc/csf/csf.conf${END}"

# #
#	edit configserver config
# #

csf_edit_conf

echo -e
exit 0
