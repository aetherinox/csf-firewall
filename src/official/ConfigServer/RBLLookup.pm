###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::RBLLookup;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use IPC::Open3;
use Net::IP;
use ConfigServer::Config;
use ConfigServer::CheckIP qw(checkip);

use Exporter qw(import);
our $VERSION     = 1.01;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(rbllookup);

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();
my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

# end main
###############################################################################
# start rbllookup
sub rbllookup {
	my $ip = shift;
	my $rbl = shift;
	my %rblhits;
	my $netip;
	my $reversed_ip;
	my $timeout = 4;
	my $rblhit;
	my $rblhittxt;

	if (checkip(\$ip)) {
		eval {
			local $SIG{__DIE__} = undef;
			$netip = Net::IP->new($ip);
			$reversed_ip = $netip->reverse_ip();
		};
		
		if ($reversed_ip =~ /^(\S+)\.in-addr\.arpa/) {$reversed_ip = $1}
		if ($reversed_ip =~ /^(\S+)\s+(\S+)\.in-addr\.arpa/) {$reversed_ip = $2}
		if ($reversed_ip =~ /^(\S+)\.ip6\.arpa/) {$reversed_ip = $1}
		if ($reversed_ip =~ /^(\S+)\s+(\S+)\.ip6\.arpa/) {$reversed_ip = $2}

		if ($reversed_ip ne "") {
			my $lookup_ip = $reversed_ip.".".$rbl;

			my $cmdpid;
			eval {
				local $SIG{__DIE__} = undef;
				local $SIG{'ALRM'} = sub {die};
				alarm($timeout);
				my ($childin, $childout);
				$cmdpid = open3($childin, $childout, $childout, $config{HOST},"-t","A",$lookup_ip);
				close $childin;
				my @results = <$childout>;
				waitpid ($cmdpid, 0);
				chomp @results;
				if ($results[0] =~ /^${reversed_ip}.+ ($ipv4reg|$ipv6reg)$/) {$rblhit = $1}
				alarm(0);
			};
			alarm(0);
			if ($@) {$rblhit = "timeout"}
			if ($cmdpid =~ /\d+/ and $cmdpid > 1 and kill(0,$cmdpid)) {kill(9,$cmdpid)}

			if ($rblhit ne "") {
				if ($rblhit ne "timeout") {
					my $cmdpid;
					eval {
						local $SIG{__DIE__} = undef;
						local $SIG{'ALRM'} = sub {die};
						alarm($timeout);
						my ($childin, $childout);
						$cmdpid = open3($childin, $childout, $childout, $config{HOST},"-t","TXT",$lookup_ip);
						close $childin;
						my @results = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @results;
						foreach my $line (@results) {
							if ($line =~ /^${reversed_ip}.+ "([^\"]+)"$/) {$rblhittxt .= "$1\n"}
						}
						alarm(0);
					};
					alarm(0);
					if ($cmdpid =~ /\d+/ and $cmdpid > 1 and kill(0,$cmdpid)) {kill(9,$cmdpid)}
				}
			}
		}
	}
	return ($rblhit,$rblhittxt);
}
# end rbllookup
###############################################################################

1;
