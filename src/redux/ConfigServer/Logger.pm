###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::Logger;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use Fcntl qw(:DEFAULT :flock);
use ConfigServer::Config;

use Exporter qw(import);
our $VERSION     = 1.02;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(logfile);

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();
my $hostname;
if (-e "/proc/sys/kernel/hostname") {
	open (my $IN, "<", "/proc/sys/kernel/hostname");
	flock ($IN, LOCK_SH);
	$hostname = <$IN>;
	chomp $hostname;
	close ($IN);
} else {
	$hostname = "unknown";
}
my $hostshort = (split(/\./,$hostname))[0];

my $sys_syslog;
if ($config{SYSLOG}) {
	eval('use Sys::Syslog;'); ##no critic
	unless ($@) {$sys_syslog = 1}
}

# end main
###############################################################################
# start logfile
sub logfile {
	my $line = shift;
	my @ts = split(/\s+/,scalar localtime);
	if ($ts[2] < 10) {$ts[2] = " ".$ts[2]}

	my $logfile = "/var/log/lfd.log";
	if ($< != 0) {$logfile = "/var/log/lfd_messenger.log"}
	
	sysopen (my $LOGFILE, $logfile, O_WRONLY | O_APPEND | O_CREAT);
	flock ($LOGFILE, LOCK_EX);
	print $LOGFILE "$ts[1] $ts[2] $ts[3] $hostshort lfd[$$]: $line\n";
	close ($LOGFILE);

	if ($config{SYSLOG} and $sys_syslog) {
		eval {
			local $SIG{__DIE__} = undef;
			openlog('lfd', 'ndelay,pid', 'user');
			syslog('info', $line);
			closelog();
		}
	}
	return;
}
# end logfile
###############################################################################

1;