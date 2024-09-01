#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (ProhibitBarewordFileHandles, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
use strict;
use Fcntl qw(:DEFAULT :flock);
use IPC::Open3;

umask(0177);

our (%config, %configsetting, $vps, $oldversion);

$oldversion = $ARGV[0];

open (VERSION, "<","/etc/csf/version.txt");
flock (VERSION, LOCK_SH);
my $version = <VERSION>;
close (VERSION);
chomp $version;
$version =~ s/\W/_/g;
system("/bin/cp","-avf","/etc/csf/csf.conf","/var/lib/csf/backup/".time."_pre_v${version}_upgrade");

&loadcsfconfig;

if (-e "/proc/vz/veinfo") {
	$vps = 1;
} else {
	open (IN, "<","/proc/self/status"); 
	flock (IN, LOCK_SH);
	while (my $line = <IN>) {
		chomp $line;
		if ($line =~ /^envID:\s*(\d+)\s*$/) {
			if ($1 > 0) {
				$vps = 1;
				last;
			}
		}
	}
	close (IN);
}
foreach my $alertfile ("sshalert.txt","sualert.txt","sudoalert.txt","webminalert.txt","cpanelalert.txt") {
	if (-e "/usr/local/csf/tpl/".$alertfile) {
		sysopen (my $IN, "/usr/local/csf/tpl/".$alertfile, O_RDWR | O_CREAT);
		flock ($IN, LOCK_EX);
		my @data = <$IN>;
		chomp @data;
		my $hit = 0;
		foreach my $line (@data) {
			if ($line =~ /\[text\]/) {$hit = 1}
		}
		unless ($hit) {
			print $IN "\nLog line:\n\n[text]\n";
		}
		close ($IN);
	}
}

if (-e "/usr/local/vesta") {
	sysopen (my $VESTA, "/usr/local/vesta/web/templates/admin/panel.html", O_RDWR | O_CREAT);
	flock ($VESTA, LOCK_EX);
	my @data = <$VESTA>;
	chomp @data;
	seek ($VESTA, 0, 0);
	truncate ($VESTA, 0);
	foreach my $line (@data) {
		if (!(grep {$_ =~ /CSF/} @data) and $line =~ /if\(\$TAB == 'SERVER'/) {
			print $VESTA $line."\n";
			print $VESTA "<div class=\"l-menu__item <?php if(\$TAB == 'CSF' ) echo 'l-menu__item--active' ?>\"><a href=\"/list/csf/\"><?=__('CSF')?></a></div>\n";
		} else {
			print $VESTA $line."\n";
		}
	}
	close ($VESTA);
}

if (&checkversion("10.11") and !-e "/var/lib/csf/auto1011") {
	if (-e "/var/lib/csf/stats/lfdstats") {
		sysopen (STATS,"/var/lib/csf/stats/lfdstats", O_RDWR | O_CREAT);
		flock (STATS, LOCK_EX);
		my @stats = <STATS>;
		chomp @stats;
		my %ccs;
		my @line = split(/\,/,$stats[69]);
		for (my $x = 0; $x < @line; $x+=2) {$ccs{$line[$x]} = $line[$x+1]}
		$stats[69] = "";
		foreach my $key (keys %ccs) {$stats[69] .= "$key,$ccs{$key},"}
		seek (STATS, 0, 0);
		truncate (STATS, 0);
		foreach my $line (@stats) {
			print STATS "$line\n";
		}
		close (STATS);
	}

	open (OUT, ">", "/var/lib/csf/auto1011");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("10.23") and !-e "/var/lib/csf/auto1023") {
	if (-e "/etc/csf/csf.blocklists") {
		sysopen (IN,"/etc/csf/csf.blocklists", O_RDWR | O_CREAT);
		flock (IN, LOCK_EX);
		my @data = <IN>;
		chomp @data;
		seek (IN, 0, 0);
		truncate (IN, 0);
		my $SPAMDROPV6 = 0;
		my $STOPFORUMSPAMV6 = 0;
		foreach my $line (@data) {
			if ($line =~ /^(\#)?SPAMDROPV6/) {$SPAMDROPV6 = 1}
			if ($line =~ /^(\#)?STOPFORUMSPAMV6/) {$STOPFORUMSPAMV6 = 1}
			print IN "$line\n";
		}
		unless ($SPAMDROPV6) {
			print IN "\n# Spamhaus IPv6 Don't Route Or Peer List (DROPv6)\n";
			print IN "# Details: http://www.spamhaus.org/drop/\n";
			print IN "#SPAMDROPV6|86400|0|https://www.spamhaus.org/drop/dropv6.txt\n";
		}
		unless ($STOPFORUMSPAMV6) {
			print IN "\n# Stop Forum Spam IPv6\n";
			print IN "# Details: http://www.stopforumspam.com/downloads/\n";
			print IN "# Many of the lists available contain a vast number of IP addresses so special\n";
			print IN "# care needs to be made when selecting from their lists\n";
			print IN "#STOPFORUMSPAMV6|86400|0|http://www.stopforumspam.com/downloads/listed_ip_1_ipv6.zip\n";
		}
		close (IN);
	}

	open (OUT, ">", "/var/lib/csf/auto1023");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("12.02") and !-e "/var/lib/csf/auto1202") {
	if (-e "/etc/csf/csf.blocklists") {
		sysopen (IN,"/etc/csf/csf.blocklists", O_RDWR | O_CREAT);
		flock (IN, LOCK_EX);
		my @data = <IN>;
		chomp @data;
		seek (IN, 0, 0);
		truncate (IN, 0);
		foreach my $line (@data) {
			if ($line =~ /greensnow/) {$line =~ s/http:/https:/g}
			print IN "$line\n";
		}
		close (IN);
	}

	open (OUT, ">", "/var/lib/csf/auto1202");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("14.03") and !-e "/var/lib/csf/auto1403") {
	if (-e "/etc/csf/csf.blocklists") {
		sysopen (IN,"/etc/csf/csf.blocklists", O_RDWR | O_CREAT);
		flock (IN, LOCK_EX);
		my @data = <IN>;
		chomp @data;
		seek (IN, 0, 0);
		truncate (IN, 0);
		foreach my $line (@data) {
			if ($line =~ /dshield/) {$line =~ s/http:/https:/g}
			print IN "$line\n";
		}
		close (IN);
	}

	open (OUT, ">", "/var/lib/csf/auto1403");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}

if (-e "/etc/csf/csf.allow") {
	sysopen (IN,"/etc/csf/csf.allow", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /^Include \/etc\/csf\/cpanel\.comodo\.allow/) {next}
		print IN "$line\n";
	}
	close (IN);
}
if (-e "/etc/csf/csf.ignore") {
	sysopen (IN,"/etc/csf/csf.ignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /^Include \/etc\/csf\/cpanel\.comodo\.ignore/) {next}
		print IN "$line\n";
	}
	close (IN);
}
if (-e "/usr/local/csf/bin/regex.custom.pm") {
	sysopen (IN,"/usr/local/csf/bin/regex.custom.pm", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /^use strict;/) {next}
		print IN "$line\n";
	}
	close (IN);
}
if (-e "/etc/csf/csf.blocklists") {
	sysopen (IN,"/etc/csf/csf.blocklists", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /feeds\.dshield\.org/) {$line =~ s/feeds\.dshield\.org/www\.dshield\.org/g}
		if ($line =~ /openbl\.org/i) {next}
		if ($line =~ /autoshun/i) {next}
		print IN "$line\n";
	}
	close (IN);
}
if (-e "/var/lib/csf/csf.tempban") {
	sysopen (IN,"/var/lib/csf/csf.tempban", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /^\d+\:/) {$line =~ s/\:/\|/g}
		print IN "$line\n";
	}
	close (IN);
}
if (-e "/var/lib/csf/csf.tempallow") {
	sysopen (IN,"/var/lib/csf/csf.tempallow", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /^\d+\:/) {$line =~ s/\:/\|/g}
		print IN "$line\n";
	}
	close (IN);
}

if ($config{TESTING}) {

	open (IN, "<", "/etc/ssh/sshd_config") or die $!;
	flock (IN, LOCK_SH) or die $!;
	my @sshconfig = <IN>;
	close (IN);
	chomp @sshconfig;

	my $sshport = "22";
	foreach my $line (@sshconfig) {
		if ($line =~ /^Port (\d+)/) {$sshport = $1}
	}

	$config{TCP_IN} =~ s/\s//g;
	if ($config{TCP_IN} ne "") {
		foreach my $port (split(/\,/,$config{TCP_IN})) {
			if ($port eq $sshport) {$sshport = "22"}
		}
	}

	if ($sshport ne "22") {
		$config{TCP_IN} .= ",$sshport";
		$config{TCP6_IN} .= ",$sshport";
		open (IN, "<", "/etc/csf/csf.conf") or die $!;
		flock (IN, LOCK_SH) or die $!;
		my @config = <IN>;
		close (IN);
		chomp @config;
		open (OUT, ">", "/etc/csf/csf.conf") or die $!;
		flock (OUT, LOCK_EX) or die $!;
		foreach my $line (@config) {
			if ($line =~ /^TCP6_IN/) {
				print OUT "TCP6_IN = \"$config{TCP6_IN}\"\n";
				print "\n*** SSH port $sshport added to the TCP6_IN port list\n\n";
			}
			elsif ($line =~ /^TCP_IN/) {
				print OUT "TCP_IN = \"$config{TCP_IN}\"\n";
				print "\n*** SSH port $sshport added to the TCP_IN port list\n\n";
			}
			else {
				print OUT $line."\n";
			}
		}
		close OUT;
		&loadcsfconfig;

	}

	open (FH, "<", "/proc/sys/kernel/osrelease");
	flock (IN, LOCK_SH);
	my @data = <FH>;
	close (FH);
	chomp @data;
	if ($data[0] =~ /^(\d+)\.(\d+)\.(\d+)/) {
		my $maj = $1;
		my $mid = $2;
		my $min = $3;
		if ($maj == 3 and $mid > 6) {
			open (IN, "<", "/etc/csf/csf.conf") or die $!;
			flock (IN, LOCK_SH) or die $!;
			my @config = <IN>;
			close (IN);
			chomp @config;
			open (OUT, ">", "/etc/csf/csf.conf") or die $!;
			flock (OUT, LOCK_EX) or die $!;
			foreach my $line (@config) {
				if ($line =~ /^USE_CONNTRACK =/) {
					print OUT "USE_CONNTRACK = \"1\"\n";
					print "\n*** USE_CONNTRACK Enabled\n\n";
				} else {
					print OUT $line."\n";
				}
			}
			close OUT;
			&loadcsfconfig;
		}
	}

	my @ipdata;
	eval {
		local $SIG{__DIE__} = undef;
		local $SIG{'ALRM'} = sub {die "alarm\n"};
		alarm(3);
		my ($childin, $childout);
		my $cmdpid = open3($childin, $childout, $childout, "$config{IPTABLES} --wait -L OUTPUT -nv");
		@ipdata = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @ipdata;
		if ($ipdata[0] =~ /# Warning: iptables-legacy tables present/) {shift @ipdata}
		alarm(0);
	};
	alarm(0);
	if ($@ ne "alarm\n" and $ipdata[0] =~ /^Chain OUTPUT/) {
		$config{IPTABLESWAIT} = "--wait";
		$config{WAITLOCK} = 1;
		open (IN, "<", "/etc/csf/csf.conf") or die $!;
		flock (IN, LOCK_SH) or die $!;
		my @config = <IN>;
		close (IN);
		chomp @config;
		open (OUT, ">", "/etc/csf/csf.conf") or die $!;
		flock (OUT, LOCK_EX) or die $!;
		foreach my $line (@config) {
			if ($line =~ /WAITLOCK =/) {
				print OUT "WAITLOCK = \"1\"\n";
			} else {
				print OUT $line."\n";
			}
		}
		close OUT;
		&loadcsfconfig;
	}

	if (-e $config{IP6TABLES} and !$vps) {
		my ($childin, $childout);
		my $cmdpid;
		if (-e $config{IP}) {$cmdpid = open3($childin, $childout, $childout, $config{IP}, "-oneline", "addr")}
		elsif (-e $config{IFCONFIG}) {$cmdpid = open3($childin, $childout, $childout, $config{IFCONFIG})}
		my @ifconfig = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @ifconfig;
		if (grep {$_ =~ /\s*inet6/} @ifconfig) {
			$config{IPV6} = 1;
			open (FH, "<", "/proc/sys/kernel/osrelease");
			flock (IN, LOCK_SH);
			my @data = <FH>;
			close (FH);
			chomp @data;
			if ($data[0] =~ /^(\d+)\.(\d+)\.(\d+)/) {
				my $maj = $1;
				my $mid = $2;
				my $min = $3;
				if (($maj > 2) or (($maj > 1) and ($mid > 6)) or (($maj > 1) and ($mid > 5) and ($min > 19))) {
					$config{IPV6_SPI} = 1;
				} else {
					$config{IPV6_SPI} = 0;
				}
			}
			open (IN, "<", "/etc/csf/csf.conf") or die $!;
			flock (IN, LOCK_SH) or die $!;
			my @config = <IN>;
			close (IN);
			chomp @config;
			open (OUT, ">", "/etc/csf/csf.conf") or die $!;
			flock (OUT, LOCK_EX) or die $!;
			foreach my $line (@config) {
				if ($line =~ /^IPV6 =/) {
					print OUT "IPV6 = \"$config{IPV6}\"\n";
					print "\n*** IPV6 Enabled\n\n";
				}
				elsif ($line =~ /^IPV6_SPI =/) {
					print OUT "IPV6_SPI = \"$config{IPV6_SPI}\"\n";
					print "\n*** IPV6_SPI set to $config{IPV6_SPI}\n\n";
				} else {
					print OUT $line."\n";
				}
			}
			close OUT;
			&loadcsfconfig;
		}
	}
}

open (IN, "<", "csf.vesta.conf") or die $!;
flock (IN, LOCK_SH) or die $!;
my @config = <IN>;
close (IN);
chomp @config;
open (OUT, ">", "/etc/csf/csf.conf") or die $!;
flock (OUT, LOCK_EX) or die $!;
foreach my $line (@config) {
	if ($line =~ /^\#/) {
		print OUT $line."\n";
		next;
	}
	if ($line !~ /=/) {
		print OUT $line."\n";
		next;
	}
	my ($name,$value) = split (/=/,$line,2);
	$name =~ s/\s//g;
	if ($value =~ /\"(.*)\"/) {
		$value = $1;
	} else {
		print "Error: Invalid configuration line [$line]";
	}
	if (&checkversion("10.15") and !-e "/var/lib/csf/auto1015") {
		if ($name eq "MESSENGER_RATE" and $config{$name} eq "30/m") {$config{$name} = "100/s"}
		if ($name eq "MESSENGER_BURST" and $config{$name} eq "5") {$config{$name} = "150"}
		open (my $AUTO, ">", "/var/lib/csf/auto1015");
		flock ($AUTO, LOCK_EX);
		print $AUTO time;
		close ($AUTO);
	}
	if ($configsetting{$name}) {
		print OUT "$name = \"$config{$name}\"\n";
	} else {
		if (&checkversion("9.29") and !-e "/var/lib/csf/auto929" and $name eq "PT_USERRSS") {
			$line = "PT_USERRSS = \"$config{PT_USERMEM}\"";
			open (my $AUTO, ">", "/var/lib/csf/auto929");
			flock ($AUTO, LOCK_EX);
			print $AUTO time;
			close ($AUTO);
		}
		print OUT $line."\n";
		print "New setting: $name\n";
	}
}
close OUT;

if ($config{TESTING}) {
	my @netstat = `netstat -lpn`;
	chomp @netstat;
	my @tcpports;
	my @udpports;
	my @tcp6ports;
	my @udp6ports;
	foreach my $line (@netstat) {
		if ($line =~ /^(\w+).* (\d+\.\d+\.\d+\.\d+):(\d+)/) {
			if ($2 eq '127.0.0.1') {next}
			if ($1 eq "tcp") {
				push @tcpports, $3;
			}
			elsif ($1 eq "udp") {
				push @udpports, $3;
			}
		}
		if ($line =~ /^(\w+).* (::):(\d+) /) {
			if ($1 eq "tcp") {
				push @tcp6ports, $3;
			}
			elsif ($1 eq "udp") {
				push @udp6ports, $3;
			}
		}
	}

	@tcpports = sort { $a <=> $b } @tcpports;
	@udpports = sort { $a <=> $b } @udpports;
	@tcp6ports = sort { $a <=> $b } @tcp6ports;
	@udp6ports = sort { $a <=> $b } @udp6ports;

	print "\nTCP ports currently listening for incoming connections:\n";
	my $last = "";
	foreach my $port (@tcpports) {
		if ($port ne $last) {
			if ($port ne $tcpports[0]) {print ","}
			print $port;
			$last = $port;
		}
	}
	print "\n\nUDP ports currently listening for incoming connections:\n";
	$last = "";
	foreach my $port (@udpports) {
		if ($port ne $last) {
			if ($port ne $udpports[0]) {print ","}
			print $port;
			$last = $port;
		}
	}
	my $opts = "TCP_*, UDP_*";
	if (@tcp6ports or @udp6ports) {
		$opts .= ", IPV6, TCP6_*, UDP6_*";
		print "\n\nIPv6 TCP ports currently listening for incoming connections:\n";
		my $last = "";
		foreach my $port (@tcp6ports) {
			if ($port ne $last) {
				if ($port ne $tcp6ports[0]) {print ","}
				print $port;
				$last = $port;
			}
		}
		print "\n";
		print "\nIPv6 UDP ports currently listening for incoming connections:\n";
		$last = "";
		foreach my $port (@udp6ports) {
			if ($port ne $last) {
				if ($port ne $udp6ports[0]) {print ","}
				print $port;
				$last = $port;
			}
		}
	}
	print "\n\nNote: The port details above are for information only, csf hasn't been auto-configured.\n\n";
	print "Don't forget to:\n";
	print "1. Configure the following options in the csf configuration to suite your server: $opts\n";
	print "2. Restart csf and lfd\n";
	print "3. Set TESTING to 0 once you're happy with the firewall, lfd will not run until you do so\n";
}

if ($ENV{SSH_CLIENT}) {
	my $ip = (split(/ /,$ENV{SSH_CLIENT}))[0];
	if ($ip =~ /(\d+\.\d+\.\d+\.\d+)/) {
		print "\nAdding current SSH session IP address to the csf whitelist in csf.allow:\n";
		system("/usr/sbin/csf -a $1 csf SSH installation/upgrade IP address");
	}
}

exit;
###############################################################################
sub loadcsfconfig {
	open (IN, "<", "/etc/csf/csf.conf") or die $!;
	flock (IN, LOCK_SH) or die $!;
	my @config = <IN>;
	close (IN);
	chomp @config;

	foreach my $line (@config) {
		if ($line =~ /^\#/) {next}
		if ($line !~ /=/) {next}
		my ($name,$value) = split (/=/,$line,2);
		$name =~ s/\s//g;
		if ($value =~ /\"(.*)\"/) {
			$value = $1;
		} else {
			print "Error: Invalid configuration line [$line]";
		}
		$config{$name} = $value;
		$configsetting{$name} = 1;
	}
	return;
}
###############################################################################
sub checkversion {
	my $version = shift;
	my ($maj, $min) = split(/\./,$version);
	my ($oldmaj, $oldmin) = split(/\./,$oldversion);

	if ($oldmaj == 0 or $oldmaj eq "") {return 0}

	if (($oldmaj < $maj) or ($oldmaj == $maj and $oldmin < $min)) {return 1} else {return 0}
}
###############################################################################
