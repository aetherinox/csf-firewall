# #
#   @app                ConfigServer Security & Firewall (CSF)
#                       Login Failure Daemon (LFD)
#   @website            https://configserver.dev
#   @docs               https://docs.configserver.dev
#   @download           https://download.configserver.dev
#   @repo               https://github.com/Aetherinox/csf-firewall
#   @copyright          Copyright (C) 2025-2026 Aetherinox
#                       Copyright (C) 2006-2025 Jonathan Michaelson
#                       Copyright (C) 2006-2025 Way to the Web Ltd.
#   @license            GPLv3
#   @updated            09.06.2026
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or (at
#   your option) any later version.
#   
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#   General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses>.
# #
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::CheckIP;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use Net::IP;
use ConfigServer::Config;

use Exporter qw(import);
our $VERSION     = 1.03;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(checkip cccheckip);

my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

# end main
###############################################################################
# start checkip
sub checkip {
	my $ipin = shift;
	my $ret = 0;
	my $ipref = 0;
# #
#   Changelog Notes
#   
#   @tag            checkip::cidr-prefix-0
#   @since          CSF v15.11
#   @subroutines    checkip(), cccheckip()
#   @fixed          CIDR prefix /0 treated as false by Perl and bypassed the
#                   CIDR range check.
#                       checkip( '192.168.1.1/0' )  => pass / returned 4 (int)
#                       checkip( '2001:db8::1/0' )  => pass / returned 6 (int)
#                   
#                   /0 prefix used directly in firewall rules could match entire
#                   IPv4 or IPv6 address space, potentially blocking all IPs.
#                       IPv4:       Firewall Rule:  44.252.80.5/0
#                                   Blocks:         0.0.0.0 - 255.255.255.255
#   
#                       IPv6:       Firewall Rule:  2001:db8::1/0
#                                   Blocks:         0000:0000:0000:0000:0000:0000:0000:0000
#                                                   ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
#   
#                   CSF >= v15.11 validates provided CIDR values, rejects
#                   IPv4 and IPv6 /0 prefix lengths.
#                       CSF <= v15.10:      if ( $cidr )
#                       CSF >= v15.11:      if ( $cidr ne "" )
#   
#   @note           Found no existing functionality which explicitly requires
#                   an IP prefix length to be /0
# #

	my $ip;
	my $cidr;
	if (ref $ipin) {
		($ip,$cidr) = split(/\//,${$ipin});
		$ipref = 1;
	} else {
		($ip,$cidr) = split(/\//,$ipin);
	}
	my $testip = $ip;

	if ($cidr ne "") {
		unless ($cidr =~ /^\d+$/) {return 0}
	}

	if ($ip =~ /^$ipv4reg$/) {
		$ret = 4;

        # #
        #   IPv4 › CIDR Prefix Length
        #   
        #   Reject prefix lower than /1
        #   Reject prefix higher than /32
        #   
        #   @note       See [checkip::cidr-prefix-0]
        # #

		if ( $cidr ne "" )
        {
			if ( $cidr < 1 || $cidr > 32 )
            {
                return 0
            }
		}
		if ($ip eq "127.0.0.1") {return 0}
	}

	if ($ip =~ /^$ipv6reg$/) {
		$ret = 6;

        # #
        #   IPv6 › CIDR Prefix Length
        #   
        #   Reject prefix lower than /1
        #   Reject prefix higher than /128
        #   
        #   @note       See [checkip::cidr-prefix-0]
        # #

		if ( $cidr ne "" )
        {
            if ( $cidr < 1 || $cidr > 128 )
            {
                return 0
            }
		}
		$ip =~ s/://g;
		$ip =~ s/^0*//g;
		if ($ip == 1) {return 0}
		if ($ipref) {
			eval {
				local $SIG{__DIE__} = undef;
				my $netip = Net::IP->new($testip);
				my $myip = $netip->short();
				if ($myip ne "") {
					if ($cidr eq "") {
						${$ipin} = $myip;
					} else {
						${$ipin} = $myip."/".$cidr;
					}
				}
			};
			if ($@) {return 0}
		}
	}

	return $ret;
}
# end checkip
###############################################################################
# start cccheckip
sub cccheckip {
	my $ipin = shift;
	my $ret = 0;
	my $ipref = 0;
	my $ip;
	my $cidr;
	if (ref $ipin) {
		($ip,$cidr) = split(/\//,${$ipin});
		$ipref = 1;
	} else {
		($ip,$cidr) = split(/\//,$ipin);
	}
	my $testip = $ip;

	if ($cidr ne "") {
		unless ($cidr =~ /^\d+$/) {return 0}
	}

	if ($ip =~ /^$ipv4reg$/) {
		$ret = 4;

        # #
        #   IPv4 › CIDR Prefix Length
        #   
        #   Reject prefix lower than /1
        #   Reject prefix higher than /32
        #   
        #   @note       See [checkip::cidr-prefix-0]
        # #

		if ( $cidr ne "" )
        {
			if ( $cidr < 1 || $cidr > 32 )
            {
                return 0
            }
		}
		if ($ip eq "127.0.0.1") {return 0}
		my $type;
		eval {
			local $SIG{__DIE__} = undef;
			my $netip = Net::IP->new($testip);
			$type = $netip->iptype();
		};
		if ($@) {return 0}
		if ($type ne "PUBLIC") {return 0}
	}

	if ($ip =~ /^$ipv6reg$/) {
		$ret = 6;

        # #
        #   IPv6 › CIDR Prefix Length
        #   
        #   Reject prefix lower than /1
        #   Reject prefix higher than /128
        #   
        #   @note       See [checkip::cidr-prefix-0]
        # #

		if ( $cidr ne "" )
        {
            if ( $cidr < 1 || $cidr > 128 )
            {
                return 0
            }
		}
		$ip =~ s/://g;
		$ip =~ s/^0*//g;
		if ($ip == 1) {return 0}
		if ($ipref) {
			eval {
				local $SIG{__DIE__} = undef;
				my $netip = Net::IP->new($testip);
				my $myip = $netip->short();
				if ($myip ne "") {
					if ($cidr eq "") {
						${$ipin} = $myip;
					} else {
						${$ipin} = $myip."/".$cidr;
					}
				}
			};
			if ($@) {return 0}
		}
	}

	return $ret;
}
# end cccheckip
###############################################################################

1;