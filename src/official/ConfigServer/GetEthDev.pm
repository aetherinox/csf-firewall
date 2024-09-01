###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::GetEthDev;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use Fcntl qw(:DEFAULT :flock);
use IPC::Open3;
use POSIX qw(locale_h);
use ConfigServer::Config;
use ConfigServer::CheckIP qw(checkip);
use ConfigServer::Logger;

use Exporter qw(import);
our $VERSION     = 1.01;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my (%ifaces, %ipv4, %ipv6, %brd);

# end main
###############################################################################
# start new
sub new {
	my $class = shift;
	my $self = {};
	bless $self,$class;

	my $status;
	my $config = ConfigServer::Config->loadconfig();
	my %config = $config->config();
	my $ipv4reg = $config->ipv4reg;
	my $ipv6reg = $config->ipv6reg;
	$brd{"255.255.255.255"} = 1;
	setlocale(LC_ALL, "POSIX");

	if (-e $config{IP}) {
		my ($childin, $childout);
		my $pid = open3($childin, $childout, $childout, $config{IP}, "-oneline", "addr");
		my @ifconfig = <$childout>;
		waitpid ($pid, 0);
		chomp @ifconfig;

		foreach my $line (@ifconfig) {
			if ($line =~ /^\d+:\s+([\w\.\-]+)/ ) {
				$ifaces{$1} = 1;
			}
			if ($line =~ /inet.*?($ipv4reg)/) {
				my ($ip,undef) = split(/\//,$1);
				if (checkip(\$ip)) {
					$ipv4{$ip} = 1;
				}
			}
			if ($line =~ /brd\s+($ipv4reg)/) {
				my ($ip,undef) = split(/\//,$1);
				if (checkip(\$ip)) {
					$brd{$ip} = 1;
				}
			}
			if ($line =~ /inet6.*?($ipv6reg)/) {
				my ($ip,undef) = split(/\//,$1);
				$ip .= "/128";
				if (checkip(\$ip)) {
					$ipv6{$ip} = 1;
				}
			}
		}
		$status = 0;
	}
	elsif (-e $config{IFCONFIG}) {
		my ($childin, $childout);
		my $pid = open3($childin, $childout, $childout, $config{IFCONFIG});
		my @ifconfig = <$childout>;
		waitpid ($pid, 0);
		chomp @ifconfig;

		foreach my $line (@ifconfig) {
			if ($line =~ /^([\w\.\-]+)/ ) {
				$ifaces{$1} = 1;
			}
			if ($line =~ /inet.*?($ipv4reg)/) {
				my ($ip,undef) = split(/\//,$1);
				if (checkip(\$ip)) {
					$ipv4{$ip} = 1;
				}
			}
			if ($line =~ /Bcast:($ipv4reg)/) {
				my ($ip,undef) = split(/\//,$1);
				if (checkip(\$ip)) {
					$brd{$ip} = 1;
				}
			}
			if ($line =~ /inet6.*?($ipv6reg)/) {
				my ($ip,undef) = split(/\//,$1);
				$ip .= "/128";
				if (checkip(\$ip)) {
					$ipv6{$ip} = 1;
				}
			}
		}
		$status = 0;
	}
	else {
		$status = 1;
	}

	if (-e "/var/cpanel/cpnat") {
		open (my $NAT, "<", "/var/cpanel/cpnat");
		flock ($NAT, LOCK_SH);
		while (my $line = <$NAT>) {
			chomp $line;
			if ($line =~ /^(\#|\n|\r)/) {next}
			my ($internal,$external) = split(/\s+/,$line);
			if (checkip(\$internal) and checkip(\$external)) {
				$ipv4{$external} = 1;
			}
		}
		close ($NAT);
	}
	
	$self->{status} = $status;
	return $self;
}
# end main
###############################################################################
# start ifaces
sub ifaces {
	return %ifaces;
}
# end ifaces
###############################################################################
# start ipv4
sub ipv4 {
	return %ipv4;
}
# end ipv4
###############################################################################
# start ipv6
sub ipv6 {
	return %ipv6;
}
# end ipv6
###############################################################################
# start brd
sub brd {
	return %brd;
}
# end brd
###############################################################################

1;