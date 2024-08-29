###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
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
		if ($cidr) {
			unless ($cidr >= 1 && $cidr <= 32) {return 0}
		}
		if ($ip eq "127.0.0.1") {return 0}
	}

	if ($ip =~ /^$ipv6reg$/) {
		$ret = 6;
		if ($cidr) {
			unless ($cidr >= 1 && $cidr <= 128) {return 0}
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
		if ($cidr) {
			unless ($cidr >= 1 && $cidr <= 32) {return 0}
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
		if ($cidr) {
			unless ($cidr >= 1 && $cidr <= 128) {return 0}
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