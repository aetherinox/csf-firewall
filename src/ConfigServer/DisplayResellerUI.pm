###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
package ConfigServer::DisplayResellerUI;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use POSIX qw(:sys_wait_h sysconf strftime);
use File::Basename;
use Net::CIDR::Lite;
use IPC::Open3;

use ConfigServer::Config;
use ConfigServer::CheckIP qw(checkip);
use ConfigServer::Sendmail;
use ConfigServer::Logger;

use Exporter qw(import);
our $VERSION     = 1.01;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

umask(0177);

our ($chart, $ipscidr6, $ipv6reg, $ipv4reg, %config, %ips, $mobile,
	 %FORM, $script, $script_da, $images, $myv, %rprivs, $hostname,
	 $hostshort, $tz, $panel);

#
###############################################################################
# start main
sub main {
	my $form_ref = shift;
	%FORM = %{$form_ref};
	$script = shift;
	$script_da = shift;
	$images = shift;
	$myv = shift;

	open (my $IN,"<","/etc/csf/csf.resellers");
	flock ($IN, LOCK_SH);
	while (my $line = <$IN>) {
		my ($user,$alert,$privs) = split(/\:/,$line);
		$privs =~ s/\s//g;
		foreach my $priv (split(/\,/,$privs)) {
			$rprivs{$user}{$priv} = 1;
		}
		$rprivs{$user}{ALERT} = $alert;
	}
	close ($IN);

	open (my $HOSTNAME, "<","/proc/sys/kernel/hostname");
	flock ($HOSTNAME, LOCK_SH);
	$hostname = <$HOSTNAME>;
	chomp $hostname;
	close ($HOSTNAME);
	$hostshort = (split(/\./,$hostname))[0];
	$tz = strftime("%z", localtime);

	my $config = ConfigServer::Config->loadconfig();
	%config = $config->config();

	$panel = "cPanel";
	if ($config{GENERIC}) {$panel = "Generic"}
	if ($config{INTERWORX}) {$panel = "InterWorx"}
	if ($config{DIRECTADMIN}) {$panel = "DirectAdmin"}

	if ($FORM{ip} ne "") {$FORM{ip} =~ s/(^\s+)|(\s+$)//g}

	if ($FORM{action} ne "" and !checkip(\$FORM{ip})) {
		print "<table class='table table-bordered table-striped'>\n";
		print "<tr><td>";
		print "[$FORM{ip}] is not a valid IP address\n";
		print "</td></tr></table>\n";
		print "<p><form action='$script' method='post'><input type='submit' class='btn btn-default' value='Return'></form></p>\n";
	} else {
		if ($FORM{action} eq "qallow" and $rprivs{$ENV{REMOTE_USER}}{ALLOW}) {
			if ($FORM{comment} eq "") {
				print "<table class='table table-bordered table-striped'>\n";
				print "<tr><td>You must provide a Comment for this option</td></tr></table>\n";
			} else {
				$FORM{comment} =~ s/"//g;
				print "<table class='table table-bordered table-striped'>\n";
				print "<tr><td>";
				print "<p>Allowing $FORM{ip}...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
				my $text = &printcmd("/usr/sbin/csf","-a",$FORM{ip},"ALLOW by Reseller $ENV{REMOTE_USER} ($FORM{comment})");
				print "</p>\n<p>...<b>Done</b>.</p>\n";
				print "</td></tr></table>\n";
				if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
					open (my $IN, "<", "/usr/local/csf/tpl/reselleralert.txt");
					flock ($IN, LOCK_SH);
					my @alert = <$IN>;
					close ($IN);
					chomp @alert;

					my @message;
					foreach my $line (@alert) {
						$line =~ s/\[reseller\]/$ENV{REMOTE_USER}/ig;
						$line =~ s/\[action\]/ALLOW/ig;
						$line =~ s/\[ip\]/$FORM{ip}/ig;
						$line =~ s/\[rip\]/$ENV{REMOTE_HOST}/ig;
						$line =~ s/\[text\]/Result of ALLOW:\n\n$text/ig;
						push @message, $line;
					}
					ConfigServer::Sendmail::relay("", "", @message);
				}
				ConfigServer::Logger::logfile("$panel Reseller [$ENV{REMOTE_USER}]: ALLOW $FORM{ip}");
			}
			print "<p><form action='$script' method='post'><input type='hidden' name='mobi' value='$FORM{mobi}'><input type='submit' class='btn btn-default' value='Return'></form></p>\n";
		}
		elsif ($FORM{action} eq "qdeny" and $rprivs{$ENV{REMOTE_USER}}{DENY}) {
			if ($FORM{comment} eq "") {
				print "<table class='table table-bordered table-striped'>\n";
				print "<tr><td>You must provide a Comment for this option</td></tr></table>\n";
			} else {
				$FORM{comment} =~ s/"//g;
				print "<table class='table table-bordered table-striped'>\n";
				print "<tr><td>";
				print "<p>Blocking $FORM{ip}...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
				my $text = &printcmd("/usr/sbin/csf","-d",$FORM{ip},"DENY by Reseller $ENV{REMOTE_USER} ($FORM{comment})");
				print "</p>\n<p>...<b>Done</b>.</p>\n";
				print "</td></tr></table>\n";
				if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
					open (my $IN, "<", "/usr/local/csf/tpl/reselleralert.txt");
					flock ($IN, LOCK_SH);
					my @alert = <$IN>;
					close ($IN);
					chomp @alert;

					my @message;
					foreach my $line (@alert) {
						$line =~ s/\[reseller\]/$ENV{REMOTE_USER}/ig;
						$line =~ s/\[action\]/DENY/ig;
						$line =~ s/\[ip\]/$FORM{ip}/ig;
						$line =~ s/\[rip\]/$ENV{REMOTE_HOST}/ig;
						$line =~ s/\[text\]/Result of DENY:\n\n$text/ig;
						push @message, $line;
					}
					ConfigServer::Sendmail::relay("", "", @message);
				}
				ConfigServer::Logger::logfile("$panel Reseller [$ENV{REMOTE_USER}]: DENY $FORM{ip}");
			}
			print "<p><form action='$script' method='post'><input type='hidden' name='mobi' value='$FORM{mobi}'><input type='submit' class='btn btn-default' value='Return'></form></p>\n";
		}
		elsif ($FORM{action} eq "qkill" and $rprivs{$ENV{REMOTE_USER}}{UNBLOCK}) {
			my $text = "";
			if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
				my ($childin, $childout);
				my $pid = open3($childin, $childout, $childout, "/usr/sbin/csf","-g",$FORM{ip});
				while (<$childout>) {$text .= $_}
				waitpid ($pid, 0);
			}
			print "<table class='table table-bordered table-striped'>\n";
			print "<tr><td>";
			print "<p>Unblock $FORM{ip}, trying permanent blocks...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
			my $text1 = &printcmd("/usr/sbin/csf","-dr",$FORM{ip});
			print "</p>\n<p>...<b>Done</b>.</p>\n";
			print "<p>Unblock $FORM{ip}, trying temporary blocks...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
			my $text2 = &printcmd("/usr/sbin/csf","-tr",$FORM{ip});
			print "</p>\n<p>...<b>Done</b>.</p>\n";
			print "</td></tr></table>\n";
			print "<p><form action='$script' method='post'><input type='hidden' name='mobi' value='$FORM{mobi}'><input type='submit' class='btn btn-default' value='Return'></form></p>\n";
			if ($rprivs{$ENV{REMOTE_USER}}{ALERT}) {
				open (my $IN, "<", "/usr/local/csf/tpl/reselleralert.txt");
				flock ($IN, LOCK_SH);
				my @alert = <$IN>;
				close ($IN);
				chomp @alert;

				my @message;
				foreach my $line (@alert) {
					$line =~ s/\[reseller\]/$ENV{REMOTE_USER}/ig;
					$line =~ s/\[action\]/UNBLOCK/ig;
					$line =~ s/\[ip\]/$FORM{ip}/ig;
					$line =~ s/\[rip\]/$ENV{REMOTE_HOST}/ig;
					$line =~ s/\[text\]/Result of GREP before UNBLOCK:\n$text\n\nResult of UNBLOCK:\nPermanent:\n$text1\nTemporary:\n$text2\n/ig;
					push @message, $line;
				}
				ConfigServer::Sendmail::relay("", "", @message);
			}
			ConfigServer::Logger::logfile("$panel Reseller [$ENV{REMOTE_USER}]: UNBLOCK $FORM{ip}");
		}
		elsif ($FORM{action} eq "grep" and $rprivs{$ENV{REMOTE_USER}}{GREP}) {
			print "<table class='table table-bordered table-striped'>\n";
			print "<tr><td>";
			print "<p>Searching for $FORM{ip}...</p>\n<p><pre style='font-family: Courier New, Courier; font-size: 12px'>\n";
			&printcmd("/usr/sbin/csf","-g",$FORM{ip});
			print "</p>\n<p>...<b>Done</b>.</p>\n";
			print "</td></tr></table>\n";
			print "<p><form action='$script' method='post'><input type='submit' class='btn btn-default' value='Return'></form></p>\n";
		}
		else {
			print "<table class='table table-bordered table-striped'>\n";
			print "<thead><tr><th align='left' colspan='2'>csf - ConfigServer Firewall options for $ENV{REMOTE_USER}</th></tr></thead>";
			if ($rprivs{$ENV{REMOTE_USER}}{ALLOW}) {print "<tr><td><form action='$script' method='post'><input type='hidden' name='action' value='qallow'><input type='submit' class='btn btn-default' value='Quick Allow'></td><td width='100%'>Allow IP address <input type='text' name='ip' id='allowip' value='' size='18' style='background-color: lightgreen'> through the firewall and add to the allow file (csf.allow).<br>Comment for Allow: <input type='text' name='comment' value='' size='30'> (required)</form></td></tr>\n"}
			if ($rprivs{$ENV{REMOTE_USER}}{DENY}) {print "<tr><td><form action='$script' method='post'><input type='hidden' name='action' value='qdeny'><input type='submit' class='btn btn-default' value='Quick Deny'></td><td width='100%'>Block IP address <input type='text' name='ip' value='' size='18' style='background-color: pink'> in the firewall and add to the deny file (csf.deny).<br>Comment for Block: <input type='text' name='comment' value='' size='30'> (required)</form></td></tr>\n"}
			if ($rprivs{$ENV{REMOTE_USER}}{UNBLOCK}) {print "<tr><td><form action='$script' method='post'><input type='hidden' name='action' value='qkill'><input type='submit' class='btn btn-default' value='Quick Unblock'></td><td width='100%'>Remove IP address <input type='text' name='ip' value='' size='18'> from the firewall (temp and perm blocks)</form></td></tr>\n"}
			if ($rprivs{$ENV{REMOTE_USER}}{GREP}) {print "<tr><td><form action='$script' method='post'><input type='hidden' name='action' value='grep'><input type='submit' class='btn btn-default' value='Search for IP'></td><td width='100%'>Search iptables for IP address <input type='text' name='ip' value='' size='18'></form></td></tr>\n"}
			print "</table><br>\n";
		}
	}

	print "<br>\n";
	print "<pre>csf: v$myv</pre>";
	print "<p>&copy;2006-2023, <a href='http://www.configserver.com' target='_blank'>ConfigServer Services</a> (Way to the Web Limited)</p>\n";

	return;
}
# end main
###############################################################################
# start printcmd
sub printcmd {
	my @command = @_;
	my $text;
	my ($childin, $childout);
	my $pid = open3($childin, $childout, $childout, @command);
	while (<$childout>) {print $_ ; $text .= $_}
	waitpid ($pid, 0);
	return $text;
}
# end printcmd
###############################################################################

1;
