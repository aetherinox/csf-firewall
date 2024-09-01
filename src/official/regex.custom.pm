#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################

sub custom_line {
	my $line = shift;
	my $lgfile = shift;

# Do not edit before this point
###############################################################################
#
# Custom regex matching can be added to this file without it being overwritten
# by csf upgrades. The format is slightly different to regex.pm to cater for
# additional parameters. You need to specify the log file that needs to be
# scanned for log line matches in csf.conf under CUSTOMx_LOG. You can scan up
# to 9 custom logs (CUSTOM1_LOG .. CUSTOM9_LOG)
#
# The regex matches in this file will supercede the matches in regex.pm
#
# Example:
#	if (($globlogs{CUSTOM1_LOG}{$lgfile}) and ($line =~ /^\S+\s+\d+\s+\S+ \S+ pure-ftpd: \(\?\@(\d+\.\d+\.\d+\.\d+)\) \[WARNING\] Authentication failed for user/)) {
#		return ("Failed myftpmatch login from",$1,"myftpmatch","5","20,21","1","0");
#	}
#
# The return values from this example are as follows:
#
# "Failed myftpmatch login from" = text for custom failure message
# $1 = the offending IP address
# "myftpmatch" = a unique identifier for this custom rule, must be alphanumeric and have no spaces
# "5" = the trigger level for blocking
# "20,21" = the ports to block the IP from in a comma separated list, only used if LF_SELECT enabled. To specify the protocol use 53;udp,53;tcp
# "1" = n/temporary (n = number of seconds to temporarily block) or 1/permanant IP block, only used if LF_TRIGGER is disabled
# "0" = whether to trigger Cloudflare block if CF_ENABLE is set. "0" = disable, "1" = enable



# If the matches in this file are not syntactically correct for perl then lfd
# will fail with an error. You are responsible for the security of any regex
# expressions you use. Remember that log file spoofing can exploit poorly
# constructed regex's
###############################################################################
# Do not edit beyond this point

	return 0;
}

1;
