#!/bin/bash

# #
#   @for                https://github.com/Aetherinox/csf-firewall
#   @assoc              blocklist-generate.yml
#   @type               bash script
#   @summary            Uses a URL to download various files from online websites.
#                       Takes IPv4/6 CIDR-Ranges (one per line) from stdin, and filters the list for imperfections / bad lines.
#                       Outputs a clean version of the ip list
#   
#                       📁 .github
#                           📁 scripts
#                               📄 tool-clean-ip.sh
#                           📁 workflows
#                               📄 blocklist-generate.yml
#
#   activated from github workflow:
#       - .github/workflows/blocklist-generate.yml
#   
#   @uage               tool-clean-ip.sh
#                       curl -s https://raw.githubusercontent.com/duckduckgo/duckduckgo-help-pages/master/_docs/results/duckduckbot.md | grep "^\- " | awk '{gsub("-",""); print}' | awk '{gsub(/ /,""); print}' | .github/scripts/clean_ips.sh > $GITHUB_WORKSPACE/blocklists/02_privacy_duckduckbot.ipset
# #

# #
#   Validate ipv4 / CIDR
# #

process_v4() {
    local ip_cidr="$1"

    if [[ $ip_cidr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        IFS='/' read -r ip cidr <<< "$ip_cidr"
        IFS='.' read -r a b c d <<< "$ip"
        [[ $a -le 255 && $b -le 255 && $c -le 255 && $d -le 255 && (-z "$cidr" || ($cidr -ge 0 && $cidr -le 32)) ]]

        return $?
    fi

    return 1
}

# #
#   Validate ipv6 / CIDR
# #

process_v6() {
    local ip_cidr="$1"

    # #
    #   Remove square brackets (if present) for URL format.
    # #

    ip_cidr=${ip_cidr#[}
    ip_cidr=${ip_cidr%]}

    if [[ $ip_cidr =~ ^([0-9a-fA-F:]+)(/[0-9]{1,3})?$ ]]; then
        IFS='/' read -r ip cidr <<< "$ip_cidr"

        # #
        #   Use grep to check if ip:port is valid
        # #

        if echo "$ip" | grep -qP '^(?:(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:(?:(:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$'; then
            [[ -z "$cidr" || ($cidr -ge 0 && $cidr -le 128) ]]
            return $?
        fi
    fi

    return 1
}

# #
#   Filter input from stdin
# #

while IFS= read -r ip || [[ -n "$ip" ]]; do

    # #
    #   Remove carriage return if found
    # #

    ip=${ip%$'\r'}
    
    # #
    #   Skip empty lines
    # #

    [[ -z "$ip" ]] && continue
    
    # #
    #   Validate either ipv4 or ipv6, or CIDR format
    # #

    if process_v4 "$ip" || process_v6 "$ip"; then
        echo "$ip"
    fi
done