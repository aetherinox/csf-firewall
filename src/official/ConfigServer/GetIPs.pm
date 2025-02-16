###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::GetIPs;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use Socket;
use IPC::Open3;
use ConfigServer::Config;

use Exporter qw(import);
our $VERSION     = 1.03;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(getips);

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();
my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

# end main
###############################################################################
# start getips
sub getips {
	my $hostname = shift;
	my @ips;

	if (-e $config{HOST} and -x $config{HOST}) {
		my $cmdpid;
		eval {
			local $SIG{__DIE__} = undef;
			local $SIG{'ALRM'} = sub {die};
			alarm(10);
			my ($childin, $childout);
			$cmdpid = open3($childin, $childout, $childout, $config{HOST},"-W","5",$hostname);
			close $childin;
			my @results = <$childout>;
			waitpid ($cmdpid, 0);
			chomp @results;

			foreach my $line (@results) {
				if ($line =~ /($ipv4reg|$ipv6reg)/) {push @ips, $1}
			}
			alarm(0);
		};
		alarm(0);
		if ($cmdpid =~ /\d+/ and $cmdpid > 1 and kill(0,$cmdpid)) {kill(9,$cmdpid)}
	} else {
		local $SIG{__DIE__} = undef;
		eval ('use Socket6;');
		if ($@) {
			my @iplist;
			my (undef, undef, undef, undef, @addrs) = gethostbyname($hostname);
			foreach (@addrs) {push(@iplist,join(".",unpack("C4", $_)))}
			push @ips,$_ foreach(@iplist);
		} else {
			eval ('
				use Socket6;
				my @res = getaddrinfo($hostname, undef, AF_UNSPEC, SOCK_STREAM);
				while(scalar(@res)>=5){
					my $saddr;
					(undef, undef, undef, $saddr, undef, @res) = @res;
					my ($host, undef) = getnameinfo($saddr,NI_NUMERICHOST | NI_NUMERICSERV);
					push @ips,$host;

				}
			');
		}
	}

	return @ips;
}
# end getips
###############################################################################

1;