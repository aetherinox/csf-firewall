###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::KillSSH;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use ConfigServer::Logger;

use Exporter qw(import);
our $VERSION     = 1.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

# end main
###############################################################################
# start iplookup
sub find {
	my $ip = shift;
	my $ports = shift;

	my %inodes;

	if ($ports eq "" or $ip eq "") {return}

	foreach my $proto ("tcp","tcp6") {
		open (my $IN, "<", "/proc/net/$proto");
		flock ($IN, LOCK_SH);
		while (<$IN>) {
			my @rec = split();
			if ($rec[9] =~ /uid/) {next}

			my ($dip,$dport) = split(/:/,$rec[2]);
			$dport = hex($dport);

			my ($sip,$sport) = split(/:/,$rec[1]);
			$sport = hex($sport);

			$dip = &hex2ip($dip);
			$sip = &hex2ip($sip);

			if ($sip eq '0.0.0.1') {next}
			if ($dip eq $ip) {
				foreach my $port (split(/\,/, $ports)) {
					if ($port eq $sport) {
						$inodes{$rec[9]} = 1;
					}
				}
			}
		}
		close ($IN);
	}

	opendir (my $PROCDIR, "/proc");
	while (my $pid = readdir($PROCDIR)) {
		if ($pid !~ /^\d+$/) {next}
		opendir (DIR, "/proc/$pid/fd") or next;
		while (my $file = readdir (DIR)) {
			if ($file =~ /^\./) {next}
			my $fd = readlink("/proc/$pid/fd/$file");
			if ($fd =~ /^socket:\[?([0-9]+)\]?$/) {
				if ($inodes{$1} and readlink("/proc/$pid/exe") =~ /sshd/) {
					kill (9,$pid);
					ConfigServer::Logger::logfile("*PT_SSHDKILL*: Process PID:[$pid] killed for blocked IP:[$ip]");
				}
			}
		}
		closedir (DIR);
	}
	closedir ($PROCDIR);
	return;
}
# end find
###############################################################################
## start hex2ip
sub hex2ip {
    my $bin = pack "C*" => map hex, $_[0] =~ /../g;
    my @l = unpack "L*", $bin;
    if (@l == 4) {
        return join ':', map { sprintf "%x:%x", $_ >> 16, $_ & 0xffff } @l;
    }
    elsif (@l == 1) {
        return join '.', map { $_ >> 24, ($_ >> 16 ) & 0xff, ($_ >> 8) & 0xff, $_ & 0xff } @l;
    }
}
## end hex2ip
###############################################################################

1;