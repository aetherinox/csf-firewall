#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
use strict;
use warnings;
use diagnostics;

if (my $pid = fork) {
	exit 0;
} elsif (defined($pid)) {
	$pid = $$;
} else {
	die "Error: Unable to fork: $!";
}
chdir("/");
close (STDIN);
close (STDOUT);
close (STDERR);
open STDIN, "<","/dev/null";
open STDOUT, ">","/dev/null";
open STDERR, ">","/dev/null";

$0 = "ConfigServer Version Check";

my @downloadservers = ("https://download.configserver.com", "https://download2.configserver.com");

system("mkdir -p /var/lib/configserver/");
system("rm -f /var/lib/configserver/*.txt /var/lib/configserver/*error");

my $cmd;
if (-e "/usr/bin/curl") {$cmd = "/usr/bin/curl -skLf -m 120 -o"}
elsif (-e "/usr/bin/wget") {$cmd = "/usr/bin/wget -q -T 120 -O"}
else {
	open (my $ERROR, ">", "/var/lib/configserver/error");
	print $ERROR "Cannot find /usr/bin/curl or /usr/bin/wget to retrieve product versions\n";
	close ($ERROR);
	exit;
}
my $GET;
if (-e "/usr/bin/GET") {$GET = "/usr/bin/GET -sd -t 120"}

my %versions;
if (-e "/etc/csf/csf.pl") {$versions{"/csf/version.txt"} = "/var/lib/configserver/csf.txt"}
if (-e "/etc/cxs/cxs.pl") {$versions{"/cxs/version.txt"} = "/var/lib/configserver/cxs.txt"}
if (-e "/usr/local/cpanel/whostmgr/docroot/cgi/configserver/cmm.cgi") {$versions{"/cmm/cmmversion.txt"} = "/var/lib/configserver/cmm.txt"}
if (-e "/usr/local/cpanel/whostmgr/docroot/cgi/configserver/cse.cgi") {$versions{"/cse/cseversion.txt"} = "/var/lib/configserver/cse.txt"}
if (-e "/usr/local/cpanel/whostmgr/docroot/cgi/configserver/cmq.cgi") {$versions{"/cmq/cmqversion.txt"} = "/var/lib/configserver/cmq.txt"}
if (-e "/usr/local/cpanel/whostmgr/docroot/cgi/configserver/cmc.cgi") {$versions{"/cmc/cmcversion.txt"} = "/var/lib/configserver/cmc.txt"}
if (-e "/etc/osm/osmd.pl") {$versions{"/osm/osmversion.txt"} = "/var/lib/configserver/osm.txt"}
if (-e "/usr/msfe/version.txt") {$versions{"/version.txt"} = "/var/lib/configserver/msinstall.txt"}
if (-e "/usr/msfe/msfeversion.txt") {$versions{"/msfeversion.txt"} = "/var/lib/configserver/msfe.txt"}

if (scalar(keys %versions) == 0) {
	unlink $0;
	exit;
}

unless ($ARGV[0] eq "--nosleep") {
	system("sleep",int(rand(60 * 60 * 6)));
}
for (my $x = @downloadservers; --$x;) {
		my $y = int(rand($x+1));
		if ($x == $y) {next}
		@downloadservers[$x,$y] = @downloadservers[$y,$x];
}

foreach my $server (@downloadservers) {
	foreach my $version (keys %versions) {
		unless (-e $versions{$version}) {
			if (-e $versions{$version}.".error") {unlink $versions{$version}.".error"}
			my $status = system("$cmd $versions{$version} $server$version");
#			print "$cmd $versions{$version} $server$version\n";
			if ($status) {
				if ($GET ne "") {
					open (my $ERROR, ">", $versions{$version}.".error");
					print $ERROR "$server$version - ";
					close ($ERROR);
					my $GETstatus = system("$GET $server$version >> $versions{$version}".".error");
				} else {
					open (my $ERROR, ">", $versions{$version}.".error");
					print $ERROR "Failed to retrieve latest version from ConfigServer";
					close ($ERROR);
				}
			}
		}
	}
}
