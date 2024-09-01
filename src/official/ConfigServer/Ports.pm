###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::Ports;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use ConfigServer::Config;

use Exporter qw(import);
our $VERSION     = 1.02;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my %printable = ( ( map { chr($_), unpack('H2', chr($_)) } (0..255) ), "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' ); ##no critic
my %tcpstates = ("01" => "ESTABLISHED",
				 "02" => "SYN_SENT",
				 "03" => "SYN_RECV",
				 "04" => "FIN_WAIT1",
				 "05" => "FIN_WAIT2",
				 "06" => "TIME_WAIT",
				 "07" => "CLOSE",
				 "08" => "CLOSE_WAIT",
				 "09" => "LAST_ACK",
				 "0A" => "LISTEN",
				 "0B" => "CLOSING");
# end main
###############################################################################
# start listening
sub listening {
	my %net;
	my %conn;
	my %listen;

	foreach my $proto ("tcp","udp","tcp6","udp6") {
		open (my $IN, "<","/proc/net/$proto");
		flock ($IN, LOCK_SH);
		while (<$IN>) {
			my @rec = split();
			if ($rec[9] =~ /uid/) {next}

			my ($dip,$dport) = split(/:/,$rec[1]);
			$dport = hex($dport);

			my ($sip,$sport) = split(/:/,$rec[2]);
			$sport = hex($sport);

			$dip = &hex2ip($dip);
			$sip = &hex2ip($sip);

			my $inode = $rec[9];
			my $state = $tcpstates{$rec[3]};
			my $protocol = $proto;
			$protocol =~ s/6//;
			if ($protocol eq "udp" and $state eq "CLOSE") {$state = "LISTEN"}

			if ($state eq "ESTABLISHED") {$conn{$dport}{$protocol}++}

			if ($dip =~ /^127\./) {next}
			if ($dip =~ /^0\.0\.0\.1/) {next}
			if ($state eq "LISTEN") {$net{$inode}{$protocol} = $dport}
		}
		close ($IN);
	}

	opendir (PROCDIR, "/proc");
	while (my $pid = readdir(PROCDIR)) {
		if ($pid !~ /^\d+$/) {next}
		my $exe = readlink("/proc/$pid/exe") || "";
		my $cwd = readlink("/proc/$pid/cwd") || "";
		my $uid;
		my $user;

		if (defined $exe) {$exe =~ s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$printable{$1}/sg}
		open (my $CMDLINE,"<","/proc/$pid/cmdline");
		flock ($CMDLINE, LOCK_SH);
		my $cmdline = <$CMDLINE>;
		close ($CMDLINE);
		if (defined $cmdline) {
			chomp $cmdline;
			$cmdline =~ s/\0$//g;
			$cmdline =~ s/\0/ /g;
			$cmdline =~ s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$printable{$1}/sg;
			$cmdline =~ s/\s+$//;
			$cmdline =~ s/^\s+//;
		}
		if ($exe eq "") {next}
		my @fd;
		opendir (DIR, "/proc/$pid/fd") or next;
		while (my $file = readdir (DIR)) {
			if ($file =~ /^\./) {next}
			push (@fd, readlink("/proc/$pid/fd/$file"));
		}
		closedir (DIR);
		open (my $STATUS,"<", "/proc/$pid/status") or next;
		flock ($STATUS, LOCK_SH);
		my @status = <$STATUS>;
		close ($STATUS);
		chomp @status;
		foreach my $line (@status) {
			if ($line =~ /^Uid:(.*)/) {
				my $uidline = $1;
				my @uids;
				foreach my $bit (split(/\s/,$uidline)) {
					if ($bit =~ /^(\d*)$/) {push @uids, $1}
				}
				$uid = $uids[-1];
				$user = getpwuid($uid);
				if ($user eq "") {$user = $uid}
			}
		}

		my $files;
		my $sockets;
		foreach my $file (@fd) {
			if ($file =~ /^socket:\[?([0-9]+)\]?$/) {
				my $ino = $1;
				if ($net{$ino}) {
					foreach my $protocol (keys %{$net{$ino}}) {
						$listen{$protocol}{$net{$ino}{$protocol}}{$pid}{user} = $user;
						$listen{$protocol}{$net{$ino}{$protocol}}{$pid}{exe} = $exe;
						$listen{$protocol}{$net{$ino}{$protocol}}{$pid}{cmd} = $cmdline;
						$listen{$protocol}{$net{$ino}{$protocol}}{$pid}{cmd} = $cmdline;
						$listen{$protocol}{$net{$ino}{$protocol}}{$pid}{conn} = $conn{$net{$ino}{$protocol}}{$protocol} | "-";
					}
				}
			}
		}

	}
	closedir (PROCDIR);
	return %listen;
}
# end listening
###############################################################################
# start openports
sub openports {
	my $config = ConfigServer::Config->loadconfig();
	my %config = $config->config();
	my %ports;

	$config{TCP_IN} =~ s/\s//g;
	foreach my $entry (split(/,/,$config{TCP_IN})) {
		if ($entry =~ /^(\d+):(\d+)$/) {
			my $from = $1;
			my $to = $2;
			for (my $port = $from; $port < $to ; $port++) {
				$ports{tcp}{$port} = 1;
			}
		} else {
			$ports{tcp}{$entry} = 1;
		}
	}
	$config{TCP6_IN} =~ s/\s//g;
	foreach my $entry (split(/,/,$config{TCP6_IN})) {
		if ($entry =~ /^(\d+):(\d+)$/) {
			my $from = $1;
			my $to = $2;
			for (my $port = $from; $port < $to ; $port++) {
				$ports{tcp6}{$port} = 1;
			}
		} else {
			$ports{tcp6}{$entry} = 1;
		}
	}
	$config{UDP_IN} =~ s/\s//g;
	foreach my $entry (split(/,/,$config{UDP_IN})) {
		if ($entry =~ /^(\d+):(\d+)$/) {
			my $from = $1;
			my $to = $2;
			for (my $port = $from; $port < $to ; $port++) {
				$ports{udp}{$port} = 1;
			}
		} else {
			$ports{udp}{$entry} = 1;
		}
	}
	$config{UDP6_IN} =~ s/\s//g;
	foreach my $entry (split(/,/,$config{UDP6_IN})) {
		if ($entry =~ /^(\d+):(\d+)$/) {
			my $from = $1;
			my $to = $2;
			for (my $port = $from; $port < $to ; $port++) {
				$ports{udp6}{$port} = 1;
			}
		} else {
			$ports{udp6}{$entry} = 1;
		}
	}
	return %ports;
}
# end openports
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