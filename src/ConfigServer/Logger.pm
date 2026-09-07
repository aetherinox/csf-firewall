# #
#   @app                ConfigServer Security & Firewall (CSF)
#                       Login Failure Daemon (LFD)
#   @website            https://configserver.dev
#   @docs               https://docs.configserver.dev
#   @download           https://download.configserver.dev
#   @repo               https://github.com/Aetherinox/csf-firewall
#   @copyright          Copyright (C) 2025-2026 Aetherinox
#                       Copyright (C) 2006-2025 Jonathan Michaelson
#                       Copyright (C) 2006-2025 Way to the Web Ltd.
#   @license            GPLv3
#   @updated            09.06.2026
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or (at
#   your option) any later version.
#   
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#   General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses>.
# #
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

# #
#   Debug Log
#   
#   Write debug messages when the defined LEVEL requirement is met. Determines 
#   the name of the subroutine calling debuglog() automatically.
#   
#   Calls sub logfile; stores logs in:
#       /var/log/lfd.log
#       /var/log/lfd_messenger.log
#   
#   Debuglevel is any int between 0 and 5.
#   
#   Status can be specified by str|int:
#       0   FAIL
#       1   OK
#       2   WARN
#       3   ABORT
#       4   INFO
#   
#   If status is not defined, defaults to INFO (4)
#   
#   @usage          debuglog( 1, PACKAGE_NAME, ConfigServer::Messenger::PACKAGE_NAME( ), "Debug message" );
#                   debuglog( 1, PACKAGE_NAME, ConfigServer::Messenger::PACKAGE_NAME( ), 'ok', "Debug message" );
#                   debuglog( 1, PACKAGE_NAME, ConfigServer::Messenger::PACKAGE_NAME( ), 1, "Debug message" );
#   
#   @param          level           num         minimum DEBUG level required
#   @param          package         str         package name
#   @param          module          str         module name
#   @param          status          str|num     optional message status; defaults to INFO
#   @param          message         str         message to write
#   @return                                     undef
# #

sub debuglog
{
	my ( $level, $package, $module, @args ) = @_;

	_config_load();

	return if ( $config{DEBUG} // 0 ) < $level;

	my ( $status, $message );

	if ( @args == 1 )
	{
		$status		= 'info';
		$message	= $args[ 0 ];
	}
	else
	{
		$status		= $args[ 0 ];
		$message	= $args[ 1 ];
	}

	my %status_map =
	(
		0       => 'FAIL',
		1       => 'OK',
		2       => 'WARN',
		3       => 'ABORT',
		4       => 'INFO',
		'fail'  => 'FAIL',
		'ok'    => 'OK',
		'warn'  => 'WARN',
		'abort' => 'ABORT',
		'info'  => 'INFO',
	);

	$status     = lc $status if $status !~ /^\d+$/;
	$status     = $status_map{ $status } // uc $status;
	my $sub     = ( caller(1) )[3] // 'main';

	logfile( "[DEBUG:$level] [$sub] [$module] [$status]: $message" );

	return;
}

1;