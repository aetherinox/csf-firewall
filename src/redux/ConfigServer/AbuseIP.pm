###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::AbuseIP;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use IPC::Open3;
use Net::IP;
use ConfigServer::Config;
use ConfigServer::CheckIP qw(checkip);

use Exporter qw(import);
our $VERSION     = 1.03;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(abuseip);

my $abusemsg = 'Abuse Contact for [ip]: [[contact]]

The Abuse Contact of this report was provided by the Abuse Contact DB by abusix.com. abusix.com does not maintain the content of the database. All information which we pass out, derives from the RIR databases and is processed for ease of use. If you want to change or report non working abuse contacts please contact the appropriate RIR. If you have any further question, contact abusix.com directly via email (info@abusix.com). Information about the Abuse Contact Database can be found here:

https://abusix.com/global-reporting/abuse-contact-db

abusix.com is neither responsible nor liable for the content or accuracy of this message.';

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();

# end main
###############################################################################
# start abuseip
sub abuseip {
	my $ip = shift;
	my $abuse = "";
	my $netip;
	my $reversed_ip;

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
			$reversed_ip .= ".abuse-contacts.abusix.org";

			my $cmdpid;
			eval {
				local $SIG{__DIE__} = undef;
				local $SIG{'ALRM'} = sub {die};
				alarm(10);
				my ($childin, $childout);
				$cmdpid = open3($childin, $childout, $childout, $config{HOST},"-W","5","-t","TXT",$reversed_ip);
				close $childin;
				my @results = <$childout>;
				waitpid ($cmdpid, 0);
				chomp @results;
				if ($results[0] =~ /^${reversed_ip}.+"(.*)"$/) {$abuse = $1}
				alarm(0);
			};
			alarm(0);
			if ($cmdpid =~ /\d+/ and $cmdpid > 1 and kill(0,$cmdpid)) {kill(9,$cmdpid)}

			if ($abuse ne "") {
				my $msg = $abusemsg;
				$msg =~ s/\[ip\]/$ip/g;
				$msg =~ s/\[contact\]/$abuse/g;
				return $abuse, $msg;
			}
		}
	}
}
# end abuseip
###############################################################################

1;
