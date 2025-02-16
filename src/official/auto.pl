#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (ProhibitBarewordFileHandles, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
use strict;
use lib '/usr/local/csf/lib';
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

if ($config{GENERIC}) {
	exec "./auto.generic.pl";
	exit;
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

if (&checkversion("7.72") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto772") {
	my %pignore = (
		'exe:/usr/libexec/dovecot/dict' => 1,
		'exe:/usr/libexec/mysqld' => 1,
		'exe:/usr/local/cpanel/3rdparty/sbin/p0f' => 1,
		'exe:/usr/local/cpanel/cpanel' => 1,
		'exe:/usr/sbin/chronyd' => 1,
		'exe:/usr/lib/polkit-1/polkitd' => 1,
		'#cmd:/bin/sh /usr/bin/mysqld_safe' => 1,
		'exe:/usr/sbin/exim' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto772");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("8.04") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto804") {
	my %pignore = (
		'exe:/usr/local/cpanel/bin/pkgacct' => 1,
		'exe:/usr/libexec/dovecot/anvil' => 1,
		'exe:/usr/libexec/dovecot/auth' => 1,
		'exe:/usr/sbin/nscd' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto804");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("8.06") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto806") {
	my %pignore = (
		'exe:/usr/bin/dbus-daemon' => 1,
		'exe:/usr/sbin/httpd' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto806");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("8.13") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto813") {
	my %pignore = (
		'exe:/usr/local/cpanel/3rdparty/php/54/sbin/php-fpm' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto813");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("8.26") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto826") {
	my %pignore = (
		'exe:/usr/libexec/dovecot/quota-status' => 1,
		'exe:/usr/libexec/dovecot/stats' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto826");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("8.27") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto827") {
	my %pignore = (
		'exe:/usr/libexec/dovecot/lmtp' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto827");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("9.00") and !-e "/var/lib/csf/auto900") {
	my %pignore = (
		'exe:/usr/local/cpanel/3rdparty/php/54/bin/php-cgi' => 1,
		'exe:/usr/local/cpanel/3rdparty/php/56/bin/php-cgi' => 1,
		'exe:/usr/local/cpanel/3rdparty/php/56/sbin/php-fpm' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);

	my %allow = (
		'Include /etc/csf/cpanel.comodo.allow' => 1);
	sysopen (IN,"/etc/csf/csf.allow", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	@data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($allow{$line}) {delete $allow{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %allow) {
		print IN "$line\n";
	}
	close (IN);

	my %ignore = (
		'Include /etc/csf/cpanel.comodo.ignore' => 1);
	sysopen (IN,"/etc/csf/csf.ignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	@data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($ignore{$line}) {delete $ignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %ignore) {
		print IN "$line\n";
	}
	close (IN);

	open (OUT, ">", "/var/lib/csf/auto900");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("9.12") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto912") {
	my %pignore = (
		'exe:/usr/local/cpanel/bin/whm_xfer_download-ssl' => 1,
		'exe:/usr/local/cpanel/bin/autossl_check' => 1,
		'exe:/usr/sbin/pdns_server' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto912");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("10.02") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1002") {
	my %pignore = (
		'pexe:^/usr/lib/jvm/java-.*/jre/bin/java$' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1002");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("10.06") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1006") {
	my %pignore = (
		'exe:/usr/libexec/dovecot/indexer' => 1,
		'exe:/usr/libexec/dovecot/indexer-worker' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1006");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("10.08") and !-e "/var/lib/csf/auto1008") {
	my %allow = (
		'Include /etc/csf/cpanel.allow' => 1);
	sysopen (IN,"/etc/csf/csf.allow", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($allow{$line}) {delete $allow{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %allow) {
		print IN "$line\n";
	}
	close (IN);

	my %ignore = (
		'Include /etc/csf/cpanel.ignore' => 1);
	sysopen (IN,"/etc/csf/csf.ignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	@data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($ignore{$line}) {delete $ignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %ignore) {
		print IN "$line\n";
	}
	close (IN);

	open (OUT, ">", "/var/lib/csf/auto1008");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
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
if (&checkversion("11.07") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1107") {
	my %pignore = (
		'pexe:/usr/local/cpanel/3rdparty/bin/git.*' => 1,
		'pexe:/usr/local/cpanel/3rdparty/libexec/git-core/git.*' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1107");
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
if (&checkversion("12.05") and !-e "/var/lib/csf/auto1205") {
	if (-e "/etc/csf/csf.blocklists") {
		sysopen (IN,"/etc/csf/csf.blocklists", O_RDWR | O_CREAT);
		flock (IN, LOCK_EX);
		my @data = <IN>;
		chomp @data;
		seek (IN, 0, 0);
		truncate (IN, 0);
		foreach my $line (@data) {
			if ($line =~ /projecthoneypot/) {$line =~ s/http:/https:/g}
			print IN "$line\n";
		}
		close (IN);
	}

	open (OUT, ">", "/var/lib/csf/auto1205");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("12.07") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1207") {
	my %pignore = (
		'#pcmd:ubic-guardian ubic-periodic.*' => 1,
		'#pcmd:perl /usr/local/cpanel/3rdparty/perl/\d+/bin/ubic-periodic.*' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1207");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("12.10") and -e "/etc/csf/csf.fignore" and !-e "/var/lib/csf/auto1210") {
	my %fignore = ('/tmp/yarn--[\d\-\.]+/(node|yarn)' => 1);
	sysopen (IN,"/etc/csf/csf.fignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($fignore{lc $line}) {delete $fignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %fignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1210");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("14.01") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1401") {
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($line =~ /pcmd:\/usr\/bin\/python \/usr\/local\/cpanel\/3rdparty\/mailman\/bin\//) {
			$line =~ s/pcmd:\/usr\/bin\/python /pcmd:\/usr\/bin\/python\.\? /g;
		}
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1401");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("14.02") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1402") {
	my %pignore = (
		'exe:/usr/libexec/dovecot/imap-hibernate' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1402");
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
if (&checkversion("14.05") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1405") {
	my %pignore = (
		'exe:/usr/sbin/imunify-notifier' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1405");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("14.06") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1406") {
	my %pignore = (
		'exe:/usr/bin/sw-engine' => 1,
		'exe:/usr/sbin/sw-engine-fpm' => 1,
		'exe:/usr/sbin/sw-cp-serverd' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1406");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
}
if (&checkversion("14.18") and -e "/etc/csf/csf.pignore" and !-e "/var/lib/csf/auto1418") {
	my %pignore = (
		'exe:/usr/local/cpanel/3rdparty/wp-toolkit/bin/wpt-panopticon' => 1);
	sysopen (IN,"/etc/csf/csf.pignore", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	foreach my $line (@data) {
		if ($pignore{lc $line}) {delete $pignore{$line}}
		print IN "$line\n";
	}
	foreach my $line (keys %pignore) {
		print IN "$line\n";
	}
	close (IN);
	open (OUT, ">", "/var/lib/csf/auto1418");
	flock (OUT, LOCK_EX);
	print OUT time;
	close (OUT);
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
if (-e "/usr/local/csf/tpl/reselleralert.txt") {
	sysopen (IN,"/usr/local/csf/tpl/reselleralert.txt", O_RDWR | O_CREAT);
	flock (IN, LOCK_EX);
	my @data = <IN>;
	chomp @data;
	seek (IN, 0, 0);
	truncate (IN, 0);
	my $text = 0;
	foreach my $line (@data) {
		if ($line =~ /\[text\]/) {$text = 1}
		print IN "$line\n";
	}
	unless ($text) {print IN "\n[text]\n"}
	close (IN);
}

open (IN,"<", "/etc/chkserv.d/chkservd.conf");
flock (IN, LOCK_SH);
my @chkservd = <IN>;
close (IN);
chomp @chkservd;

if (not grep {$_ =~ /^lfd/} @chkservd) {
	open (OUT,">", "/etc/chkserv.d/lfd");
	flock (OUT, LOCK_EX);
	print OUT "service[lfd]=x,x,x,service lfd restart,lfd,root\n";
	close (OUT);

	sysopen (OUT,"/etc/chkserv.d/chkservd.conf", O_WRONLY | O_CREAT);
	flock (OUT, LOCK_EX);
	foreach my $line (@chkservd) {print OUT "$line\n"}
	print OUT "lfd:1\n";
	close OUT;
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

	open (FH, "<", "/etc/os-release");
	flock (IN, LOCK_SH);
	@data = <FH>;
	close (FH);
	chomp @data;
	foreach my $line (@data) {
		if ($line =~ /Name\s*=\s*"Ubuntu"/i) {
			open (IN, "<", "/etc/csf/csf.conf") or die $!;
			flock (IN, LOCK_SH) or die $!;
			my @config = <IN>;
			close (IN);
			chomp @config;
			open (OUT, ">", "/etc/csf/csf.conf") or die $!;
			flock (OUT, LOCK_EX) or die $!;
			foreach my $line (@config) {
				if ($line =~ /^SSHD_LOG/) {$line = 'SSHD_LOG = "/var/log/auth.log"'}
				if ($line =~ /^WEBMIN_LOG/) {$line = 'WEBMIN_LOG = "/var/log/auth.log"'}
				if ($line =~ /^SU_LOG/) {$line = 'SU_LOG = "/var/log/auth.log"'}
				if ($line =~ /^SUDO_LOG/) {$line = 'SUDO_LOG = "/var/log/auth.log"'}
				if ($line =~ /^POP3D_LOG/) {$line = 'POP3D_LOG = "/var/log/mail.log"'}
				if ($line =~ /^IMAPD_LOG/) {$line = 'IMAPD_LOG = "/var/log/mail.log"'}
				if ($line =~ /^IPTABLES_LOG/) {$line = 'IPTABLES_LOG = "/var/log/syslog"'}
				if ($line =~ /^BIND_LOG/) {$line = 'BIND_LOG = "/var/log/syslog"'}
				if ($line =~ /^SYSLOG_LOG/) {$line = 'SYSLOG_LOG = "/var/log/syslog"'}
				if ($line =~ /^SUHOSIN_LOG/) {$line = 'SUHOSIN_LOG = "/var/log/syslog"'}
				print OUT $line."\n";
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

	my $exim = 0;
	opendir (DIR, "/etc/chkserv.d");
	while (my $file = readdir (DIR)) {
		if ($file =~ /exim-(\d+)/) {$exim = $1}
	}
	closedir (DIR);

	if ($exim ne "0") {
		$config{TCP_IN} .= ",$exim";
		$config{SMTP_PORTS} .= ",$exim";
		open (IN, "<", "/etc/csf/csf.conf") or die $!;
		flock (IN, LOCK_SH) or die $!;
		my @config = <IN>;
		close (IN);
		chomp @config;
		open (OUT, ">", "/etc/csf/csf.conf") or die $!;
		flock (OUT, LOCK_EX) or die $!;
		foreach my $line (@config) {
			if ($line =~ /^TCP_IN =/) {
				print OUT "TCP_IN = \"$config{TCP_IN}\"\n";
				print "\n*** Additional Exim port $exim added to the TCP_IN port list\n\n";
			}
			elsif ($line =~ /^SMTP_PORTS =/) {
				print OUT "SMTP_PORTS = \"$config{SMTP_PORTS}\"\n";
				print "\n*** Additional Exim port $exim added to the SMTP_PORTS port list\n\n";
			} else {
				print OUT $line."\n";
			}
		}
		close OUT;
		&loadcsfconfig;
	}
	if ($vps) {
		print "Adding passive port range for VZ servers\n";
		if (-e "/usr/local/cpanel/version") {
			require Cpanel::Config;
			import Cpanel::Config;
			my $cpconf = Cpanel::Config::loadcpconf();
			my $cpftpfile = "";
			if ($cpconf->{ftpserver} eq "pure-ftpd") {$cpftpfile = "/etc/pure-ftpd.conf"}
			elsif ($cpconf->{ftpserver} eq "proftpd") {$cpftpfile = "/etc/proftpd.conf"}

			if ($cpftpfile ne "") {
				my $range;
				open (my $FTPCONF,"<", $cpftpfile);
				flock ($FTPCONF, LOCK_EX);
				my @ftp = <$FTPCONF>;
				close ($FTPCONF);
				foreach my $line (@ftp) {
					if ($line =~ /\s*(PassivePortRange|PassivePorts)\s+(\d+)\s+(\d+)/i) {
						$range = $2.":".$3;
						last;
					}
				}
				if ($range ne "") {
					if ($config{TCP_IN} =~ /$range/) {
						print "PASV port range $range already exists in TCP_IN/TCP6_IN\n";
					} else {
						$config{TCP_IN} .= ",$range";
						$config{TCP6_IN} .= ",$range";

						sysopen (my $CSFCONF,"/etc/csf/csf.conf", O_RDWR | O_CREAT);
						flock ($CSFCONF, LOCK_EX);
						my @csf = <$CSFCONF>;
						chomp @csf;
						seek ($CSFCONF, 0, 0);
						truncate ($CSFCONF, 0);
						foreach my $line (@csf) {
							if ($line =~ /^TCP6_IN/) {
								print $CSFCONF "TCP6_IN = \"$config{TCP6_IN}\"\n";
								print "*** PASV port range $range added to the TCP6_IN port list\n";
							}
							elsif ($line =~ /^TCP_IN/) {
								print $CSFCONF "TCP_IN = \"$config{TCP_IN}\"\n";
								print "*** PASV port range $range added to the TCP_IN port list\n";
							}
							else {
								print $CSFCONF $line."\n";
							}
						}
						close ($CSFCONF);
						&loadcsfconfig;
					}
				}
			}
		}
	}
}

open (IN, "<", "csf.conf") or die $!;
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
		if ($name eq "CC_SRC") {$line = "CC_SRC = \"1\""}
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

if ($config{MESSENGERV2}) {
	my $hit;
	open (my $ALIASES, "<", "/etc/aliases");
	flock ($ALIASES, LOCK_SH);
	while (my $line = <$ALIASES>) {
		chomp $line;
		my ($alias,$to) = split(/\:\s*/, $line);
		if ($alias eq "csf") {
			$hit = 1;
			last;
		}
	}
	close ($ALIASES);
	if (!$hit and !-e "/var/cpanel/users/csf") {
		system("/bin/cp /etc/aliases /etc/aliases.".time);
		open (my $ALIASESw, ">>", "/etc/aliases");
		flock ($ALIASESw, LOCK_EX);
		print $ALIASESw "csf: root\n";
		close ($ALIASESw);
		print "Account [csf] added /etc/aliases to prevent cPanel account with the same name (for MESSENGERV2)\n";
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
