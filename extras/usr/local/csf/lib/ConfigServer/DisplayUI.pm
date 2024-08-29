###############################################################################
#	Copyright 2006-2024, Way to the Web Limited
#
#	@url: 		http://www.configserver.com
#	@email: 	sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)

package ConfigServer::DisplayUI;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use File::Basename;
use File::Copy;
use Net::CIDR::Lite;
use IPC::Open3;

use ConfigServer::Config;
use ConfigServer::CheckIP qw(checkip);
use ConfigServer::Ports;
use ConfigServer::URLGet;
use ConfigServer::Sanity qw(sanity);;
use ConfigServer::ServerCheck;
use ConfigServer::ServerStats;
use ConfigServer::Service;
use ConfigServer::RBLCheck;
use ConfigServer::GetEthDev;
use ConfigServer::Slurp qw(slurp);

use Exporter qw(import);
our $VERSION     = 1.01;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

umask(0177);

our ($chart, $ipscidr6, $ipv6reg, $ipv4reg, %config, %ips, $mobile,
	 $urlget, %FORM, $script, $script_da, $images, $myv);

my $slurpreg = ConfigServer::Slurp->slurpreg;
my $cleanreg = ConfigServer::Slurp->cleanreg;

# #
#	Main
# #

sub main
{
	my $form_ref 		= shift;
	%FORM 				= %{$form_ref};
	$script 			= shift;
	$script_da 			= shift;
	$images 			= shift;
	$myv 				= shift;
	$config{THIS_UI} 	= shift;
	$| 					= 1;

	# #
	#	Date
	# #

	my @t = localtime;
	my $year = $t[5] + 1900;

	# #
	#	Dark Theme
	# #

	our $th_dark_version = 2.21;
	my $th_dark_url = "https://github.com/Aetherinox/csf-firewall";

	$ipscidr6 = Net::CIDR::Lite->new;

	my $thisui = $config{THIS_UI};
	my $config = ConfigServer::Config->loadconfig();
	%config = $config->config;
	$config{THIS_UI} = $thisui;

	$ipv4reg = $config->ipv4reg;
	$ipv6reg = $config->ipv6reg;

	if ( $config{CF_ENABLE} )
	{
		require ConfigServer::CloudFlare;
		import ConfigServer::CloudFlare;
	}

	$mobile = 0;
	if ( $FORM{mobi} )
	{
		$mobile = 1
	}

	$chart = 1;
	if ($config{ST_ENABLE})
	{
		if (!defined ConfigServer::ServerStats::init()) {$chart = 0}
	}

	$urlget = ConfigServer::URLGet->new($config{URLGET}, "csf/$myv", $config{URLPROXY});

	unless (defined $urlget)
	{
		$config{URLGET} = 1;
		$urlget = ConfigServer::URLGet->new($config{URLGET}, "csf/$myv", $config{URLPROXY});
		print "<p>*WARNING* URLGET set to use LWP but perl module is not installed, reverting to HTTP::Tiny<p>\n";
	}

	if ($config{RESTRICT_UI} == 2)
	{
		print "<table class='table table-bordered table-striped'>\n";
		print "<tr><td><font color='red'>csf UI Disabled via the RESTRICT_UI option in /etc/csf/csf.conf</font></td></tr>\n";
		print "</tr></table>\n";
		exit;
	}

	if ($FORM{ip} ne "") {$FORM{ip} =~ s/(^\s+)|(\s+$)//g}

	if (($FORM{ip} ne "") and ($FORM{ip} ne "all") and (!checkip(\$FORM{ip})))
	{
		print "[$FORM{ip}] is not a valid IP/CIDR";
	}
	elsif (($FORM{ignorefile} ne "") and ($FORM{ignorefile} =~ /[^\w\.]/))
	{
		print "[$FORM{ignorefile}] is not a valid file";
	}
	elsif (($FORM{template} ne "") and ($FORM{template} =~ /[^\w\.]/))
	{
		print "[$FORM{template}] is not a valid file";
	}
	elsif ($FORM{action} eq "manualcheck")
	{
		print "<div><p>Checking version...</p>\n\n";

		my ( $upgrade, $response ) = &manualversion( $myv );

		if ($upgrade)
		{
			print "<form action='$script' method='post'><button name='action' value='upgrade' type='submit' class='btn btn-default'>Upgrade csf</button> A new version of csf (v$response) is available. Upgrading will retain your settings. <a href='https://$config{DOWNLOADSERVER}/csf/changelog.txt' target='_blank'>View ChangeLog</a></form>\n";
		}
		else
		{
			if ( $response ne "" )
			{
				print "<div class='bs-callout bs-callout-danger'>$response</div>\n";
			}
			else
			{
				print "<div class='bs-callout bs-callout-info'>You are running the latest version of csf (v$myv). An Upgrade button will appear here if a new version becomes available</div>\n";
			}
		}

		print "</div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "lfdstatus")
	{
		print "<div><p>Show lfd status...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		ConfigServer::Service::statuslfd();

		print "</pre>\n<p>...<b>Done</b>.</div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "ms_list")
	{
		&modsec;
	}
	elsif ($FORM{action} eq "chart")
	{
		&chart;
	}
	elsif ($FORM{action} eq "systemstats")
	{
		&systemstats($FORM{graph});
	}
	elsif ($FORM{action} eq "lfdstart")
	{
		print "<div><p>Starting lfd...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		ConfigServer::Service::startlfd();

		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "lfdrestart")
	{
		if ($config{THIS_UI}) {
			print "<div><p>Signal lfd to <i>restart</i>...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";

			sysopen (my $OUT, "/var/lib/csf/lfd.restart",, O_WRONLY | O_CREAT) or die "Unable to open file: $!";
			close ($OUT);
		}
		else
		{
			print "<div><p>Restarting lfd...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
			ConfigServer::Service::restartlfd();
		}

		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "lfdstop")
	{
		print "<div><p>Stopping lfd...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		ConfigServer::Service::stoplfd();

		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "status")
	{
		&resize("top");
	
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("/usr/sbin/csf","-l");

		if ($config{IPV6})
		{
			print "\n\nip6tables:\n\n";
			&printcmd("/usr/sbin/csf","-l6");
		}

		print "</pre>\n";
		&resize("bot",1);
	
		&printreturn;
	}
	elsif ($FORM{action} eq "start")
	{
		print "<div><p>Starting csf...</p>\n";
		&resize("top");

		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("/usr/sbin/csf","-sf");

		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&resize("bot",1);

		&printreturn;
	}
	elsif ($FORM{action} eq "restart")
	{
		print "<div><p>Restarting csf...</p>\n";
		&resize("top");

		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("/usr/sbin/csf","-sf");

		print "</pre>\n<p>...<b>Done</b>.</div>\n";
		&resize("bot",1);

		&printreturn;
	}
	elsif ($FORM{action} eq "restartq")
	{
		print "<div><p>Restarting csf via lfd...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-q");

		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "temp")
	{
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th>&nbsp;</th><th>A/D</th><th>IP address</th><th>Port</th><th>Dir</th><th>Time To Live</th><th>Comment</th></tr></thead>\n";

		my @deny;

		if (! -z "/var/lib/csf/csf.tempban")
		{
			open (my $IN, "<", "/var/lib/csf/csf.tempban") or die $!;
			flock ($IN, LOCK_SH);
			@deny = <$IN>;
			chomp @deny;
			close ($IN);
		}

		foreach my $line ( reverse @deny )
		{
			if ( $line eq "" )
			{
				next
			}

			my ( $time,$ip,$port,$inout,$timeout,$message ) = split( /\|/, $line );
			$time = $timeout - ( time - $time );

			if ( $port eq "" )
			{
				$port = "*"
			
			}
			if ( $inout eq "" )
			{
				$inout = " *"
			}

			if ( $time < 1 )
			{
				$time = "<1";
			}
			else
			{
				my $days = int($time/(24*60*60));
				my $hours = ($time/(60*60))%24;
				my $mins = ($time/60)%60;
				my $secs = $time%60;

				$days = $days < 1 ? '' : $days .'d ';
				$hours = $hours < 1 ? '' : $hours .'h ';
				$mins = $mins < 1 ? '' : $mins . 'm ';
				$time = $days . $hours . $mins . $secs . 's'; 
			}
		
			print "<tr><td style='white-space: nowrap;'><a class='btn btn-success' href='$script?action=temprmd&ip=$ip' data-tooltip='tooltip' title='Unblock $ip'><span class='glyphicon glyphicon-ok-circle'></span></a> \n";
			print "<a class='btn btn-danger' href='$script?action=temptoperm&ip=$ip' data-tooltip='tooltip' title='Permanently block $ip'><span class='glyphicon glyphicon-ban-circle'></span></a></td>\n";
			print "<td>DENY</td><td>$ip</td><td>$port</td><td>$inout</td><td>$time</td><td>$message</td></tr>\n";
		}

		my @allow;
		if (! -z "/var/lib/csf/csf.tempallow")
		{
			open (my $IN, "<", "/var/lib/csf/csf.tempallow") or die $!;
			flock ($IN, LOCK_SH);
			@allow = <$IN>;
			chomp @allow;
			close ($IN);
		}

		foreach my $line (@allow)
		{
			if ($line eq "") {next}
			my ($time,$ip,$port,$inout,$timeout,$message) = split(/\|/,$line);
			$time = $timeout - (time - $time);
			if ($port eq "") {$port = "*"}
			if ($inout eq "") {$inout = " *"}
			if ($time < 1) {
				$time = "<1";
			} else {
				my $days = int($time/(24*60*60));
				my $hours = ($time/(60*60))%24;
				my $mins = ($time/60)%60;
				my $secs = $time%60;
				$days = $days < 1 ? '' : $days .'d ';
				$hours = $hours < 1 ? '' : $hours .'h ';
				$mins = $mins < 1 ? '' : $mins . 'm ';
				$time = $days . $hours . $mins . $secs . 's'; 
			}
			print "<tr><td style='white-space: nowrap;'><a class='btn btn-success' href='$script?action=temprma&ip=$ip' data-tooltip='tooltip' title='Remove $ip'><span class='glyphicon glyphicon-ok-circle'></span></a> \n";
			print "<td>ALLOW</td><td>$ip</td><td>$port</td><td>$inout</td><td>$time</td><td>$message</td></tr>\n";
		}
		print "</table>\n";
		if (@deny or @allow) {
			print "<div><a class='btn btn-success' href='$script?action=temprm&ip=all'>Flush all temporary blocks</a></div>\n";
		} else {
			print "<div>There are no temporary IP entries</div>\n";
		}
		&printreturn;
	}
	elsif ($FORM{action} eq "temprm") {
		print "<div><p>Removing all temporary entries:</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		if ($FORM{ip} eq "all") {
			&printcmd("/usr/sbin/csf","-tf");
		}
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='temp'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "temprmd") {
		print "<div><p>Removing temporary deny entry for $FORM{ip}:</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-trd",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='temp'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "temprma") {
		print "<div><p>Removing temporary allow entry for $FORM{ip}:</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-tra",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='temp'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "temptoperm") {
		print "<div><p>Permanent ban for $FORM{ip}:</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-tr",$FORM{ip});
		&printcmd("/usr/sbin/csf","-d",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='temp'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "tempdeny") {
		$FORM{timeout} =~ s/\D//g;
		if ($FORM{dur} eq "minutes") {$FORM{timeout} = $FORM{timeout} * 60}
		if ($FORM{dur} eq "hours") {$FORM{timeout} = $FORM{timeout} * 60 * 60}
		if ($FORM{dur} eq "days") {$FORM{timeout} = $FORM{timeout} * 60 * 60 * 24}
		if ($FORM{ports} eq "") {$FORM{ports} = "*"}
		print "<div><p>Temporarily $FORM{do}ing $FORM{ip} for $FORM{timeout} seconds:</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		if ($FORM{do} eq "block") {
			&printcmd("/usr/sbin/csf","-td",$FORM{ip},$FORM{timeout},"-p",$FORM{ports},$FORM{comment});
		} else {
			&printcmd("/usr/sbin/csf","-ta",$FORM{ip},$FORM{timeout},"-p",$FORM{ports},$FORM{comment});
		}
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "stop") {
		print "<div><p>Stopping csf...</p>\n";
		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("/usr/sbin/csf","-f");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&resize("bot",1);
		&printreturn;
	}
	elsif ($FORM{action} eq "disable") {
		print "<div><p>Disabling csf...</p>\n";
		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("/usr/sbin/csf","-x");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&resize("bot",1);
		&printreturn;
	}
	elsif ($FORM{action} eq "enable") {
		if ($config{THIS_UI}) {
			print "<div><p>You must login to the root shell to enable csf using:\n<p><b>csf -e</b></p>\n";
		} else {
			print "<div><p>Enabling csf...</p>\n";
			&resize("top");
			print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
			&printcmd("/usr/sbin/csf","-e");
			print "</pre>";
			&resize("bot",1);
		}
		print "<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "logtail") {
		$FORM{lines} =~ s/\D//g;
		if ($FORM{lines} eq "" or $FORM{lines} == 0) {$FORM{lines} = 30}
		my $script_safe = $script;
		my $CSFfrombot = 120;
		my $CSFfromright = 10;
		if ($config{DIRECTADMIN}) {
			$script = $script_da;
			$CSFfrombot = 400;
			$CSFfromright = 150;
		}
		my @data = slurp("/etc/csf/csf.syslogs");
		foreach my $line (@data) {
			if ($line =~ /^Include\s*(.*)$/) {
				my @incfile = slurp($1);
				push @data,@incfile;
			}
		}
		@data = sort @data;
		my $options = "<select id='CSFlognum' onchange='CSFrefreshtimer()'>\n";
		my $cnt = 0;
		foreach my $file (@data) {
			$file =~ s/$cleanreg//g;
			if ($file eq "") {next}
			if ($file =~ /^\s*\#|Include/) {next}
			my @globfiles;
			if ($file =~ /\*|\?|\[/) {
				foreach my $log (glob $file) {push @globfiles, $log}
			} else {push @globfiles, $file}

			foreach my $globfile (@globfiles) {
				if (-f $globfile) {
					my $size = int((stat($globfile))[7]/1024);
					$options .= "<option value='$cnt'";
					if ($globfile eq "/var/log/lfd.log") {$options .= " selected"}
					$options .= ">$globfile ($size kb)</option>\n";
					$cnt++;
				}
			}
		}
		$options .= "</select>\n";
		
		open (my $AJAX, "<", "/usr/local/csf/lib/csfajaxtail.js");
		flock ($AJAX, LOCK_SH);
		my @jsdata = <$AJAX>;
		close ($AJAX);
		print "<script>\n";
		print @jsdata;
		print "</script>\n";
		print <<EOF;
<div>$options Lines:<input type='text' id="CSFlines" value="100" size='4'>&nbsp;&nbsp;<button class='btn btn-default' onclick="CSFrefreshtimer()">Refresh Now</button></div>
<div>Refresh in <span id="CSFtimer">0</span> <button class='btn btn-default' id="CSFpauseID" onclick="CSFpausetimer()" style="width:80px;">Pause</button> <img src="$images/loader.gif" id="CSFrefreshing" style="display:none" /></div>
<div class='pull-right btn-group'><button class='btn btn-default' id='fontminus-btn'><strong>a</strong><span class='glyphicon glyphicon-arrow-down icon-configserver'></span></button>
<button class='btn btn-default' id='fontplus-btn'><strong>A</strong><span class='glyphicon glyphicon-arrow-up icon-configserver'></span></button></div>
<pre class='comment' id="CSFajax" style="overflow:auto;height:500px;resize:both; white-space: pre-wrap;clear:both"> &nbsp; </pre>

<script>
	CSFfrombot = $CSFfrombot;
	CSFfromright = $CSFfromright;
	CSFscript = '$script?action=logtailcmd';
	CSFtimer();

	var myFont = 14;
	\$("#fontplus-btn").on('click', function () {
		myFont++;
		if (myFont > 20) {myFont = 20}
		\$('#CSFajax').css("font-size",myFont+"px");
	});
	\$("#fontminus-btn").on('click', function () {
		myFont--;
		if (myFont < 12) {myFont = 12}
		\$('#CSFajax').css("font-size",myFont+"px");
	});
</script>
EOF
		if ($config{DIRECTADMIN}) {$script = $script_safe}
		&printreturn;
	}
	elsif ($FORM{action} eq "logtailcmd") {
		$FORM{lines} =~ s/\D//g;
		if ($FORM{lines} eq "" or $FORM{lines} == 0) {$FORM{lines} = 30}

		my @data = slurp("/etc/csf/csf.syslogs");
		foreach my $line (@data) {
			if ($line =~ /^Include\s*(.*)$/) {
				my @incfile = slurp($1);
				push @data,@incfile;
			}
		}
		@data = sort @data;
		my $cnt = 0;
		my $logfile = "/var/log/lfd.log";
		my $hit = 0;
		foreach my $file (@data) {
			$file =~ s/$cleanreg//g;
			if ($file eq "") {next}
			if ($file =~ /^\s*\#|Include/) {next}
			my @globfiles;
			if ($file =~ /\*|\?|\[/) {
				foreach my $log (glob $file) {push @globfiles, $log}
			} else {push @globfiles, $file}

			foreach my $globfile (@globfiles) {
				if (-f $globfile) {
					if ($FORM{lognum} == $cnt) {
						$logfile = $globfile;
						$hit = 1;
						last;
					}
					$cnt++;
				}
			}
			if ($hit) {last}
		}
		if (-z $logfile) {
			print "<---- $logfile is currently empty ---->";
		} else {
			if (-x $config{TAIL}) {
				my $timeout = 30;
				eval {
					local $SIG{__DIE__} = undef;
					local $SIG{'ALRM'} = sub {die};
					alarm($timeout);
					my ($childin, $childout);
					my $pid = open3($childin, $childout, $childout,$config{TAIL},"-$FORM{lines}",$logfile);
					while (<$childout>) {
						my $line = $_;
						$line =~ s/&/&amp;/g;
						$line =~ s/</&lt;/g;
						$line =~ s/>/&gt;/g;
						print $line;
					}
					waitpid ($pid, 0);
					alarm(0);
				};
				alarm(0);
				if ($@) {print "TIMEOUT: tail command took too long. Timed out after $timeout seconds\n"}
			} else {
				print "Executable [$config{TAIL}] invalid";
			}
		}
	}
	elsif ($FORM{action} eq "loggrep") {
		$FORM{lines} =~ s/\D//g;
		if ($FORM{lines} eq "" or $FORM{lines} == 0) {$FORM{lines} = 30}
		my $script_safe = $script;
		my $CSFfrombot = 120;
		my $CSFfromright = 10;
		if ($config{DIRECTADMIN}) {
			$script = $script_da;
			$CSFfrombot = 400;
			$CSFfromright = 150;
		}
		my @data = slurp("/etc/csf/csf.syslogs");
		foreach my $line (@data) {
			if ($line =~ /^Include\s*(.*)$/) {
				my @incfile = slurp($1);
				push @data,@incfile;
			}
		}
		@data = sort @data;
		my $options = "<select id='CSFlognum'>\n";
		my $cnt = 0;
		foreach my $file (@data) {
			$file =~ s/$cleanreg//g;
			if ($file eq "") {next}
			if ($file =~ /^\s*\#|Include/) {next}
			my @globfiles;
			if ($file =~ /\*|\?|\[/) {
				foreach my $log (glob $file) {push @globfiles, $log}
			} else {push @globfiles, $file}

			foreach my $globfile (@globfiles) {
				if (-f $globfile) {
					my $size = int((stat($globfile))[7]/1024);
					$options .= "<option value='$cnt'";
					if ($globfile eq "/var/log/lfd.log") {$options .= " selected"}
					$options .= ">$globfile ($size kb)</option>\n";
					$cnt++;
				}
			}
		}
		$options .= "</select>\n";
		
		open (my $AJAX, "<", "/usr/local/csf/lib/csfajaxtail.js");
		flock ($AJAX, LOCK_SH);
		my @jsdata = <$AJAX>;
		close ($AJAX);
		print "<script>\n";
		print @jsdata;
		print "</script>\n";
		print <<EOF;
<div>Log: $options</div>
<div style='white-space: nowrap;'>Text: <input type='text' size="30" id="CSFgrep" onClick="this.select()">&nbsp;
<input type="checkbox" id="CSFgrep_i" value="1">-i&nbsp;
<input type="checkbox" id="CSFgrep_E" value="1">-E&nbsp;
<input type="checkbox" id="CSFgrep_Z" value="1"> wildcard&nbsp;
<button class='btn btn-default' onClick="CSFgrep()">Search</button>&nbsp;
<img src="$images/loader.gif" id="CSFrefreshing" style="display:none" /></div>
<div class='pull-right btn-group'><button class='btn btn-default' id='fontminus-btn'><strong>a</strong><span class='glyphicon glyphicon-arrow-down icon-configserver'></span></button>
<button class='btn btn-default' id='fontplus-btn'><strong>A</strong><span class='glyphicon glyphicon-arrow-up icon-configserver'></span></button></div>
<pre class='comment' id="CSFajax" style="overflow:auto;height:500px;resize:both; white-space: pre-wrap;clear: both">
Please Note:

 1. Searches use $config{GREP}/$config{ZGREP} if wildcard is used), so the search text/regex must be syntactically correct
 2. Use the "-i" option to ignore case
 3. Use the "-E" option to perform an extended regular expression search
 4. Searching large log files can take a long time. This feature has a 30 second timeout
 5. The searched for text will usually be <mark>highlighted</mark> but may not always be successful
 6. Only log files listed in /etc/csf/csf.syslogs can be searched. You can add to this file
 7. The wildcard option will use $config{ZGREP} and search logs with a wildcard suffix, e.g. /var/log/lfd.log*
</pre>

<script>
	CSFfrombot = $CSFfrombot;
	CSFfromright = $CSFfromright;
	CSFscript = '$script?action=loggrepcmd';

	var myFont = 14;
	\$("#fontplus-btn").on('click', function () {
		myFont++;
		if (myFont > 20) {myFont = 20}
		\$('#CSFajax').css("font-size",myFont+"px");
	});
	\$("#fontminus-btn").on('click', function () {
		myFont--;
		if (myFont < 12) {myFont = 12}
		\$('#CSFajax').css("font-size",myFont+"px");
	});
</script>
EOF
		if ($config{DIRECTADMIN}) {$script = $script_safe}
		&printreturn;
	}
	elsif ($FORM{action} eq "loggrepcmd") {
		my @data = slurp("/etc/csf/csf.syslogs");
		foreach my $line (@data) {
			if ($line =~ /^Include\s*(.*)$/) {
				my @incfile = slurp($1);
				push @data,@incfile;
			}
		}
		@data = sort @data;
		my $cnt = 0;
		my $logfile = "/var/log/lfd.log";
		my $hit = 0;
		foreach my $file (@data) {
			$file =~ s/$cleanreg//g;
			if ($file eq "") {next}
			if ($file =~ /^\s*\#|Include/) {next}
			my @globfiles;
			if ($file =~ /\*|\?|\[/) {
				foreach my $log (glob $file) {push @globfiles, $log}
			} else {push @globfiles, $file}

			foreach my $globfile (@globfiles) {
				if (-f $globfile) {
					if ($FORM{lognum} == $cnt) {
						$logfile = $globfile;
						$hit = 1;
						last;
					}
					$cnt++;
				}
			}
			if ($hit) {last}
		}
		my @cmd;
		my $grepbin = $config{GREP};
		if ($FORM{grepZ}) {$grepbin = $config{ZGREP}}
		if ($FORM{grepi}) {push @cmd, "-i"}
		if ($FORM{grepE}) {push @cmd, "-E"}
		push @cmd, $FORM{grep};

		if (-z $logfile) {
			print "<---- $logfile is currently empty ---->";
		} else {
			if (-x $grepbin) {
				my $timeout = 30;
				eval {
					local $SIG{__DIE__} = undef;
					local $SIG{'ALRM'} = sub {die};
					my $total;
					if ($FORM{grepZ}) {
						foreach my $file (glob $logfile."\*") {
							print "\nSearching $file:\n";
							alarm($timeout);
							my ($childin, $childout);
							my $pid = open3($childin, $childout, $childout,$grepbin,@cmd,$file);
							while (<$childout>) {
								my $line = $_;
								$line =~ s/&/&amp;/g;
								$line =~ s/</&lt;/g;
								$line =~ s/>/&gt;/g;
								if ($FORM{grep} ne "") {
									eval {
										local $SIG{__DIE__} = undef;
										if ($FORM{grepi}) {
											$line =~ s/$FORM{grep}/<mark>$&<\/mark>/ig;
										} else {
											$line =~ s/$FORM{grep}/<mark>$&<\/mark>/g;
										}
									};
								}
								print $line;
								$total += length $line;
							}
							waitpid ($pid, 0);
							unless ($total) {print "<---- No matches found for \"$FORM{grep}\" in $file ---->\n"}
							alarm(0);
						}
					} else {
						alarm($timeout);
						my ($childin, $childout);
						my $pid = open3($childin, $childout, $childout,$grepbin,@cmd,$logfile);
						while (<$childout>) {
							my $line = $_;
							$line =~ s/&/&amp;/g;
							$line =~ s/</&lt;/g;
							$line =~ s/>/&gt;/g;
							if ($FORM{grep} ne "") {
								eval {
									local $SIG{__DIE__} = undef;
									if ($FORM{grepi}) {
										$line =~ s/$FORM{grep}/<mark>$&<\/mark>/ig;
									} else {
										$line =~ s/$FORM{grep}/<mark>$&<\/mark>/g;
									}
								};
							}
							print $line;
							$total += length $line;
						}
						waitpid ($pid, 0);
						unless ($total) {print "<---- No matches found for \"$FORM{grep}\" in $logfile ---->\n"}
						alarm(0);
					}
				};
				alarm(0);
				if ($@) {print "TIMEOUT: grep command took too long. Timed out after $timeout seconds\n"}
			} else {
				print "Executable [$grepbin] invalid";
			}
		}
	}
	elsif ($FORM{action} eq "readme") {
		&resize("top");
		print "<pre id='output' class='comment' style='white-space: pre-wrap;height: 500px; overflow: auto; resize:both; clear:both'>\n";
		open (my $IN, "<", "/etc/csf/readme.txt") or die $!;
		flock ($IN, LOCK_SH);
		my @readme = <$IN>;
		close ($IN);
		chomp @readme;

		foreach my $line (@readme) {
			$line =~ s/\</\&lt\;/g;
			$line =~ s/\>/\&gt\;/g;
			print $line."\n";
		}
		print "</pre>\n";
		&resize("bot",0);
		&printreturn;
	}
	elsif ($FORM{action} eq "servercheck") {
		print ConfigServer::ServerCheck::report($FORM{verbose});

		open (my $IN, "<", "/etc/cron.d/csf-cron");
		flock ($IN, LOCK_SH);
		my @data = <$IN>;
		close ($IN);
		chomp @data;
		my $optionselected = "never";
		my $email;
		if (my @ls = grep {$_ =~ /csf \-m/} @data) {
			if ($ls[0] =~ /\@(\w+)\s+root\s+\/usr\/sbin\/csf \-m (.*)/) {$optionselected = $1; $email = $2}
		}
		print "<br><div class='form-generate-report'><form action='$script' method='post'><input type='hidden' name='action' value='serverchecksave'>\n";
		print "Generate and email this report <select name='freq'>\n";
		foreach my $option ("never","hourly","daily","weekly","monthly") {
			if ($option eq $optionselected) {print "<option selected>$option</option>\n"} else {print "<option>$option</option>\n"}
		}
		print "</select> to the email address <input type='text' name='email' value='$email'> <input type='submit' class='btn btn-default' value='Schedule'></form></div>\n";

		print "<br><div><form action='$script' method='post'><input type='hidden' name='action' value='servercheck'><input type='submit' class='btn btn-default' value='Run Again'></form></div>\n";
		print "<br><div><form action='$script' method='post'><input type='hidden' name='action' value='servercheck'><input type='hidden' name='verbose' value='1'><input type='submit' class='btn btn-default' value='Run Again and Display All Checks'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "serverchecksave") {
		my $extra = "";
		my $freq = "daily";
		my $email;
		if ($FORM{email} ne "") {$email = "root"}
		if ($FORM{email} =~ /^[a-zA-Z0-9\-\_\.\@\+]+$/) {$email = $FORM{email}}
		foreach my $option ("never","hourly","daily","weekly","monthly") {if ($FORM{freq} eq $option) {$freq = $option}}
		unless ($email) {$freq = "never"; $extra = "(no valid email address supplied)";}
		sysopen (my $CRON, "/etc/cron.d/csf-cron", O_RDWR | O_CREAT) or die "Unable to open file: $!";
		flock ($CRON, LOCK_EX);
		my @data = <$CRON>;
		chomp @data;
		seek ($CRON, 0, 0);
		truncate ($CRON, 0);
		my $done = 0;
		foreach my $line (@data) {
			if ($line =~ /csf \-m/) {
				if ($freq and ($freq ne "never") and !$done) {
					print $CRON "\@$freq root /usr/sbin/csf -m $email\n";
					$done = 1;
				}
			} else {
				print $CRON "$line\n";
			}
		}
		if (!$done and ($freq ne "never")) {
				print $CRON "\@$freq root /usr/sbin/csf -m $email\n";
		}
		close ($CRON);

		if ($freq and $freq ne "never") {
			print "<div>Report scheduled to be emailed to $email $freq</div>\n";
		} else {
			print "<div>Report schedule cancelled $extra</div>\n";
		}
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='servercheck'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "rblcheck") {
		my ($status, undef) = ConfigServer::RBLCheck::report($FORM{verbose},$images,1);

		print "<div><b>These options can take a long time to run</b> (several minutes) depending on the number of IP addresses to check and the response speed of the DNS requests:</div>\n";
		print "<br><div class='rbl-option'><form action='$script' method='post'><input type='hidden' name='action' value='rblcheck'><input type='hidden' name='verbose' value='1'><input type='submit' class='btn btn-default' value='Update All Checks (standard)'> Generates the normal report showing exceptions only</form></div>\n";
		print "<br><div class='rbl-option'><form action='$script' method='post'><input type='hidden' name='action' value='rblcheck'><input type='hidden' name='verbose' value='2'><input type='submit' class='btn btn-default' value='Update All Checks (verbose)'> Generates the normal report but shows successes and failures</form></div>\n";
		print "<br><div class='rbl-option'><form action='$script' method='post'><input type='hidden' name='action' value='rblcheckedit'><input type='submit' class='btn btn-default' value='Edit RBL Options'> Edit csf.rblconf to enable and disable IPs and RBLs</form></div>\n";

		open (my $IN, "<", "/etc/cron.d/csf-cron");
		flock ($IN, LOCK_SH);
		my @data = <$IN>;
		close ($IN);
		chomp @data;
		my $optionselected = "never";
		my $email;
		if (my @ls = grep {$_ =~ /csf \-\-rbl/} @data) {
			if ($ls[0] =~ /\@(\w+)\s+root\s+\/usr\/sbin\/csf \-\-rbl (.*)/) {$optionselected = $1; $email = $2}
		}
		print "<br><div class='form-generate-report'><form action='$script' method='post'><input type='hidden' name='action' value='rblchecksave'>\n";
		print "Generate and email this report <select name='freq'>\n";
		foreach my $option ("never","hourly","daily","weekly","monthly") {
			if ($option eq $optionselected) {print "<option selected>$option</option>\n"} else {print "<option>$option</option>\n"}
		}
		print "</select> to the email address <input type='text' name='email' value='$email'> <input type='submit' class='btn btn-default' value='Schedule'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "rblchecksave") {
		my $extra = "";
		my $freq = "daily";
		my $email;
		if ($FORM{email} ne "") {$email = "root"}
		if ($FORM{email} =~ /^[a-zA-Z0-9\-\_\.\@\+]+$/) {$email = $FORM{email}}
		foreach my $option ("never","hourly","daily","weekly","monthly") {if ($FORM{freq} eq $option) {$freq = $option}}
		unless ($email) {$freq = "never"; $extra = "(no valid email address supplied)";}
		sysopen (my $CRON, "/etc/cron.d/csf-cron", O_RDWR | O_CREAT) or die "Unable to open file: $!";
		flock ($CRON, LOCK_EX);
		my @data = <$CRON>;
		chomp @data;
		seek ($CRON, 0, 0);
		truncate ($CRON, 0);
		my $done = 0;
		foreach my $line (@data) {
			if ($line =~ /csf \-\-rbl/) {
				if ($freq and ($freq ne "never") and !$done) {
					print $CRON "\@$freq root /usr/sbin/csf --rbl $email\n";
					$done = 1;
				}
			} else {
				print $CRON "$line\n";
			}
		}
		if (!$done and ($freq ne "never")) {
				print $CRON "\@$freq root /usr/sbin/csf --rbl $email\n";
		}
		close ($CRON);

		if ($freq and $freq ne "never") {
			print "<div>Report scheduled to be emailed to $email $freq</div>\n";
		} else {
			print "<div>Report schedule cancelled $extra</div>\n";
		}
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='rblcheck'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "rblcheckedit") {
		&editfile("/etc/csf/csf.rblconf","saverblcheckedit");
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='rblcheck'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "saverblcheckedit") {
		&savefile("/etc/csf/csf.rblconf","");
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='rblcheck'><input type='submit' class='btn btn-default' value='Return'></form></div>\n";
	}
	elsif ($FORM{action} eq "cloudflareedit") {
		&editfile("/etc/csf/csf.cloudflare","savecloudflareedit");
		&printreturn;
	}
	elsif ($FORM{action} eq "savecloudflareedit") {
		&savefile("/etc/csf/csf.cloudflare","");
		&printreturn;
	}
	elsif ($FORM{action} eq "restartboth") {
		print "<div><p>Restarting csf...</p>\n";
		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("/usr/sbin/csf","-sf");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		if ($config{THIS_UI}) {
			print "<div><p>Signal lfd to <i>restart</i>...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
			sysopen (my $OUT, "/var/lib/csf/lfd.restart",, O_WRONLY | O_CREAT) or die "Unable to open file: $!";
			close ($OUT);
		} else {
			print "<div><p>Restarting lfd...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
			ConfigServer::Service::restartlfd();
		}
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&resize("bot",1);
		&printreturn;
	}
	elsif ($FORM{action} eq "remapf") {
		print "<div><p>Removing APF/BFD...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("sh","/usr/local/csf/bin/remove_apf_bfd.sh");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div><p><b>Note: You should check the root cron and /etc/crontab to ensure that there are no apf or bfd related cron jobs remaining</b></p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "qallow") {
		print "<div><p>Allowing $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-a",$FORM{ip},$FORM{comment});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "qdeny") {
		print "<div><p>Blocking $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-d",$FORM{ip},$FORM{comment});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "qignore") {
		print "<div><p>Ignoring $FORM{ip}...\n";
		open (my $OUT, ">>", "/etc/csf/csf.ignore");
		flock ($OUT, LOCK_EX);
		print $OUT "$FORM{ip}\n";
		close ($OUT);
		print "<b>Done</b>.</p></div>\n";
		if ($config{THIS_UI}) {
			print "<div><p>Signal lfd to <i>restart</i>...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
			sysopen (my $OUT, "/var/lib/csf/lfd.restart",, O_WRONLY | O_CREAT) or die "Unable to open file: $!";
			close ($OUT);
		} else {
			print "<div><p>Restarting lfd...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
			ConfigServer::Service::restartlfd();
		}
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "kill") {
		print "<div><p>Unblock $FORM{ip}, trying permanent blocks...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-dr",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div><p>Unblock $FORM{ip}, trying temporary blocks...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-trd",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "killallow") {
		print "<div><p>Unblock $FORM{ip}, trying permanent blocks...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-ar",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div><p>Unblock $FORM{ip}, trying temporary blocks...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-tra",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "grep") {
		print "<div><p>Searching for $FORM{ip}...</p>\n";
		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		my ($childin, $childout);
		my $pid = open3($childin, $childout, $childout, "/usr/sbin/csf","-g",$FORM{ip});
		my $unblock;
		my $unallow;
		while (<$childout>) {
			my $line = $_;
			if ($line =~ /^csf.deny:\s(\S+)\s*/) {$unblock = 1}
			if ($line =~ /^Temporary Blocks: IP:(\S+)\s*/) {$unblock = 1}
			if ($line =~ /^csf.allow:\s(\S+)\s*/) {$unallow = 1}
			if ($line =~ /^Temporary Allows: IP:(\S+)\s*/) {$unallow = 1}
			print $_;
		}
		waitpid ($pid, 0);
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&resize("bot",1);
		if ($unblock) {print "<div><a class='btn btn-success' href='$script?action=kill&ip=$FORM{ip}'>Remove $FORM{ip} block</a></div>\n"}
		if ($unallow) {print "<div><a class='btn btn-success' href='$script?action=killallow&ip=$FORM{ip}'>Remove $FORM{ip} allow</a></div>\n"}
		&printreturn;
	}
	elsif ($FORM{action} eq "callow") {
		print "<div><p>Cluster Allow $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-ca",$FORM{ip},$FORM{comment});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "cignore") {
		print "<div><p>Cluster Ignore $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-ci",$FORM{ip},$FORM{comment});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "cirm") {
		print "<div><p>Cluster Remove ignore $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-cir",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "cloudflare") {
		&cloudflare;
	}
	elsif ($FORM{action} eq "cflist") {
		print "<div class='panel panel-info'><div class='panel-heading'>CloudFlare list $FORM{type} rules for user(s) $FORM{domains}:</div>\n";
		print "<div class='panel-body'><pre class='comment' style='white-space: pre-wrap;'>";
		&printcmd("/usr/sbin/csf","--cloudflare","list",$FORM{type},$FORM{domains});
		print "</pre>\n</div></div>\n";
	}
	elsif ($FORM{action} eq "cftempdeny") {
		print "<div class='panel panel-info'><div class='panel-heading'>CloudFlare $FORM{do} $FORM{target} for user(s) $FORM{domains}:</div>\n";
		print "<div class='panel-body'><pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","--cloudflare","tempadd",$FORM{do},$FORM{target},$FORM{domains});
		print "</pre>\n</div></div>\n";
	}
	elsif ($FORM{action} eq "cfadd") {
		print "<div class='panel panel-info'><div class='panel-heading'>CloudFlare Add $FORM{type} $FORM{target} for user(s) $FORM{domains}:</div>\n";
		print "<div class='panel-body'><pre class='comment' style='white-space: pre-wrap;'>";
		&printcmd("/usr/sbin/csf","--cloudflare","add",$FORM{type},$FORM{target},$FORM{domains});
		print "</pre>\n</div></div>\n";
	}
	elsif ($FORM{action} eq "cfremove") {
		print "<div class='panel panel-info'><div class='panel-heading'>CloudFlare Delete $FORM{type} $FORM{target} for user(s) $FORM{domains}:</div>\n";
		print "<div class='panel-body'><pre class='comment' style='white-space: pre-wrap;'>";
		&printcmd("/usr/sbin/csf","--cloudflare","del", $FORM{target},$FORM{domains});
		print "</pre>\n</div></div>\n";
	}
	elsif ($FORM{action} eq "cdeny") {
		print "<div><p>Cluster Deny $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-cd",$FORM{ip},$FORM{comment});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "ctempdeny") {
		$FORM{timeout} =~ s/\D//g;
		if ($FORM{dur} eq "minutes") {$FORM{timeout} = $FORM{timeout} * 60}
		if ($FORM{dur} eq "hours") {$FORM{timeout} = $FORM{timeout} * 60 * 60}
		if ($FORM{dur} eq "days") {$FORM{timeout} = $FORM{timeout} * 60 * 60 * 24}
		if ($FORM{ports} eq "") {$FORM{ports} = "*"}
		print "<div><p>cluster Temporarily $FORM{do}ing $FORM{ip} for $FORM{timeout} seconds:</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		if ($FORM{do} eq "block") {
			&printcmd("/usr/sbin/csf","-ctd",$FORM{ip},$FORM{timeout},"-p",$FORM{ports},$FORM{comment});
		} else {
			&printcmd("/usr/sbin/csf","-cta",$FORM{ip},$FORM{timeout},"-p",$FORM{ports},$FORM{comment});
		}
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "crm") {
		print "<div><p>Cluster Remove Deny $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-cr",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "carm") {
		print "<div><p>Cluster Remove Allow $FORM{ip}...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-car",$FORM{ip});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "cping") {
		print "<div><p>Cluster PING...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-cp");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "cgrep") {
		print "<div><p>Cluster GREP for $FORM{ip}...</p>\n";
		print "<pre class='comment' style='white-space: pre-wrap;'>\n";
		my ($childin, $childout);
		my $pid = open3($childin, $childout, $childout, "/usr/sbin/csf","-cg",$FORM{ip});
		my $unblock;
		my $start = 0;
		while (<$childout>) {
			my $line = $_;
			if ($line =~ /^====/) {
				if ($start) {
					print "$line</pre><pre class='comment' style='white-space: pre-wrap;'>";
					$start = 0;
				} else {
					print "</pre><pre class='comment' style='white-space: pre-wrap;background:#F4F4EA'>$line";
					$start = 1;
				}
			} else {
				print $line;
			}
		}
		waitpid ($pid, 0);
		print "...Done\n</pre></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "cconfig") {
		$FORM{option} =~ s/\s*//g;
		my %restricted;
		if ($config{RESTRICT_UI}) {
			sysopen (my $IN, "/usr/local/csf/lib/restricted.txt", O_RDWR | O_CREAT) or die "Unable to open file: $!";
			flock ($IN, LOCK_SH);
			while (my $entry = <$IN>) {
				chomp $entry;
				$restricted{$entry} = 1;
			}
			close ($IN);
		}
		if ($restricted{$FORM{option}}) {
			print "<div>Option $FORM{option} cannot be set with RESTRICT_UI enabled</div>\n";
			exit;
		}
		print "<div><p>Cluster configuration option...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","-cc",$FORM{option},$FORM{value});
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "crestart") {
		print "<div><p>Cluster restart csf and lfd...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf --crestart");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "allow") {
		&editfile("/etc/csf/csf.allow","saveallow");
		&printreturn;
	}
	elsif ($FORM{action} eq "saveallow") {
		&savefile("/etc/csf/csf.allow","both");
		&printreturn;
	}
	elsif ($FORM{action} eq "redirect") {
		&editfile("/etc/csf/csf.redirect","saveredirect");
		&printreturn;
	}
	elsif ($FORM{action} eq "saveredirect") {
		&savefile("/etc/csf/csf.redirect","both");
		&printreturn;
	}
	elsif ($FORM{action} eq "smtpauth") {
		&editfile("/etc/csf/csf.smtpauth","savesmtpauth");
		&printreturn;
	}
	elsif ($FORM{action} eq "savesmtpauth") {
		&savefile("/etc/csf/csf.smtpauth","both");
		&printreturn;
	}
	elsif ($FORM{action} eq "reseller") {
		&editfile("/etc/csf/csf.resellers","savereseller");
		&printreturn;
	}
	elsif ($FORM{action} eq "savereseller") {
		&savefile("/etc/csf/csf.resellers","");
		&printreturn;
	}
	elsif ($FORM{action} eq "dirwatch") {
		&editfile("/etc/csf/csf.dirwatch","savedirwatch");
		&printreturn;
	}
	elsif ($FORM{action} eq "savedirwatch") {
		&savefile("/etc/csf/csf.dirwatch","lfd");
		&printreturn;
	}
	elsif ($FORM{action} eq "dyndns") {
		&editfile("/etc/csf/csf.dyndns","savedyndns");
		&printreturn;
	}
	elsif ($FORM{action} eq "savedyndns") {
		&savefile("/etc/csf/csf.dyndns","lfd");
		&printreturn;
	}
	elsif ($FORM{action} eq "blocklists") {
		&editfile("/etc/csf/csf.blocklists","saveblocklists");
		&printreturn;
	}
	elsif ($FORM{action} eq "saveblocklists") {
		&savefile("/etc/csf/csf.blocklists","both");
		&printreturn;
	}
	elsif ($FORM{action} eq "syslogusers") {
		&editfile("/etc/csf/csf.syslogusers","savesyslogusers");
		&printreturn;
	}
	elsif ($FORM{action} eq "savesyslogusers") {
		&savefile("/etc/csf/csf.syslogusers","lfd");
		&printreturn;
	}
	elsif ($FORM{action} eq "logfiles") {
		&editfile("/etc/csf/csf.logfiles","savelogfiles");
		&printreturn;
	}
	elsif ($FORM{action} eq "savelogfiles") {
		&savefile("/etc/csf/csf.logfiles","lfd");
		&printreturn;
	}
	elsif ($FORM{action} eq "deny") {
		&editfile("/etc/csf/csf.deny","savedeny");
		&printreturn;
	}
	elsif ($FORM{action} eq "savedeny") {
		&savefile("/etc/csf/csf.deny","both");
		&printreturn;
	}
	elsif ($FORM{action} eq "templates") {
		&editfile("/usr/local/csf/tpl/$FORM{template}","savetemplates","template");
		&printreturn;
	}
	elsif ($FORM{action} eq "savetemplates") {
		&savefile("/usr/local/csf/tpl/$FORM{template}","",1);
		&printreturn;
	}
	elsif ($FORM{action} eq "ignorefiles") {
		&editfile("/etc/csf/$FORM{ignorefile}","saveignorefiles","ignorefile");
		&printreturn;
	}
	elsif ($FORM{action} eq "saveignorefiles") {
		&savefile("/etc/csf/$FORM{ignorefile}","lfd");
		&printreturn;
	}
	elsif ($FORM{action} eq "conf") {
		sysopen (my $IN, "/etc/csf/csf.conf", O_RDWR | O_CREAT) or die "Unable to open file: $!";
		flock ($IN, LOCK_SH);
		my @confdata = <$IN>;
		close ($IN);
		chomp @confdata;

		my %restricted;
		if ($config{RESTRICT_UI}) {
			sysopen (my $IN, "/usr/local/csf/lib/restricted.txt", O_RDWR | O_CREAT) or die "Unable to open file: $!";
			flock ($IN, LOCK_SH);
			while (my $entry = <$IN>) {
				chomp $entry;
				$restricted{$entry} = 1;
			}
			close ($IN);
		}

		print <<EOF;
<script type="text/javascript">
function CSFexpand(obj){
	if (!obj.savesize) {obj.savesize=obj.size;}
	var newsize = Math.max(obj.savesize,obj.value.length);
	if (newsize > 120) {newsize = 120;}
	obj.size = newsize;
}
</script>
EOF
		print "<style>.hidepiece\{display:none\}</style>\n";
		open (my $DIV, "<", "/usr/local/csf/lib/csf.div");
		flock ($DIV, LOCK_SH);
		my @divdata = <$DIV>;
		close ($DIV);
		print @divdata;
		print "<div id='paginatediv2' class='text-center'></div>\n";
		print "<form action='$script' method='post'>\n";
		print "<input type='hidden' name='action' value='saveconf'>\n";
		my $first = 1;
		my @divnames;
		my $comment = 0;
		foreach my $line (@confdata) {
			if (($line !~ /^\#/) and ($line =~ /=/)) {
				if ($comment) {print "</div>\n"}
				$comment = 0;
				my ($start,$end) = split (/=/,$line,2);
				my $name = $start;
				my $cleanname = $start;
				$cleanname =~ s/\s//g;
				$name =~ s/\s/\_/g;
				if ($end =~ /\"(.*)\"/) {$end = $1}
				my $size = length($end) + 4;
				my $class = "value-default";
				my ($status,$range,$default) = sanity($start,$end);
				my $showrange = "";
				my $showfrom;
				my $showto;
				if ($range =~ /^(\d+)-(\d+)$/) {
					$showfrom = $1;
					$showto = $2;
				}
				if ($default ne "") {
					$showrange = " Default: $default [$range]";
					if ($end ne $default) {$class = "value-other"}
				}
				if ($status) {$class = "value-warning"; $showrange = " Recommended range: $range (Default: $default)"}
				if ($config{RESTRICT_UI} and ($cleanname eq "CLUSTER_KEY" or $cleanname eq "UI_PASS" or $cleanname eq "UI_USER")) {
					print "<div class='$class'><b>$start</b> = <input type='text' value='********' size='14' disabled> (hidden restricted UI item)</div>\n";
				}
				elsif ($restricted{$cleanname}) {
					print "<div class='$class'><b>$start</b> = <input type='text' onFocus='CSFexpand(this);' onkeyup='CSFexpand(this);' value='$end' size='$size' disabled> (restricted UI item)</div>\n";
				} else {
					if ($range eq "0-1") {
						my $switch_checked_0 = "";
						my $switch_checked_1 = "";
						my $switch_active_0 = "";
						my $switch_active_1 = "";
						if ($end == 0) {$switch_checked_0 = "checked"; $switch_active_0 = "active"}
						if ($end == 1) {$switch_checked_1 = "checked"; $switch_active_1 = "active"}
						print "<div class='$class'><b>$start</b> = ";
						print "<div class='btn-group' data-toggle='buttons'>\n";
						print "<label class='btn btn-default btn-csf-config option-disabled $switch_active_0'>\n";
						print "<input type='radio' name='${name}' value='0' $switch_checked_0> Off\n";
						print "</label>\n";
						print "<label class='btn btn-default btn-csf-config option-enabled $switch_active_1'>\n";
						print "<input type='radio' name='${name}' value='1' $switch_checked_1> On\n";
						print "</label>\n";
						print "</div></div>\n";
					}
					elsif ($range =~ /^(\d+)-(\d+)$/ and !(-e "/etc/csuibuttondisable") and ($showto - $showfrom <= 20) and $end >= $showfrom and $end <= $showto) {
						my $selected = "";
						print "<div class='$class'><b>$start</b> = <select name='$name'>\n";
						for ($showfrom..$showto) {
							if ($_ == $end) {$selected = "selected"} else {$selected = ""}
							print "<option $selected>$_</option>\n";
						}
						print "</select></div>\n";
					} else {
						print "<div class='$class'><b>$start</b> = <input type='text' onFocus='CSFexpand(this);' onkeyup='CSFexpand(this);' name='$name' value='$end' size='$size'>$showrange</div>\n";
					}
				}
			} else {
				if ($line =~ /^\# SECTION:(.*)/) {
					push @divnames, $1;
					unless ($first) {print "</div>\n"}
					print "<div class='virtualpage hidepiece'>\n<div class='section'>";
					print "$1</div>\n";
					$first = 0;
					next;
				}
				if ($line =~ /^\# / and $comment == 0) {
					$comment = 1;
					print "<div class='comment'>\n";
				}
				$line =~ s/\#//g;
				$line =~ s/&/&amp;/g;
				$line =~ s/</&lt;/g;
				$line =~ s/>/&gt;/g;
				$line =~ s/\n/<br \/>\n/g;
				print "$line<br />\n";
			}
		}
		print "</div><br />\n";
		print "<div id='paginatediv' class='text-center'>\n<a class='btn btn-default' href='javascript:pagecontent.showall()'>Show All</a> <a class='btn btn-default' href='#' rel='previous'>Prev</a> <select style='width: 250px'></select> <a class='btn btn-default' href='#' rel='next' >Next</a>\n</div>\n";
		print <<EOD;
<script type="text/javascript">
var pagecontent=new virtualpaginate({
 piececlass: "virtualpage", //class of container for each piece of content
 piececontainer: "div", //container element type (ie: "div", "p" etc)
 pieces_per_page: 1, //Pieces of content to show per page (1=1 piece, 2=2 pieces etc)
 defaultpage: 0, //Default page selected (0=1st page, 1=2nd page etc). Persistence if enabled overrides this setting.
 wraparound: false,
 persist: false //Remember last viewed page and recall it when user returns within a browser session?
});
EOD
		print "pagecontent.buildpagination(['paginatediv','paginatediv2'],[";
		foreach my $line (@divnames) {print "'$line',"}
		print "''])\npagecontent.showall();\n</script>\n";
		print "<br /><div class='text-center'><input type='submit' class='btn btn-default' value='Change'></div>\n";
		print "</form>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "saveconf")
	{
		sysopen (my $IN, "/etc/csf/csf.conf", O_RDWR | O_CREAT) or die "Unable to open file: $!";
		flock ($IN, LOCK_SH);
		my @confdata = <$IN>;
		close ($IN);
		chomp @confdata;

		my %restricted;
		if ($config{RESTRICT_UI})
		{
			sysopen (my $IN, "/usr/local/csf/lib/restricted.txt", O_RDWR | O_CREAT) or die "Unable to open file: $!";
			flock ($IN, LOCK_SH);

			while (my $entry = <$IN>)
			{
				chomp $entry;
				$restricted{$entry} = 1;
			}
	
			close ($IN);
		}

		sysopen (my $OUT, "/etc/csf/csf.conf", O_WRONLY | O_CREAT) or die "Unable to open file: $!";
		flock ($OUT, LOCK_EX);
		seek ($OUT, 0, 0);
		truncate ($OUT, 0);

		for (my $x = 0; $x < @confdata;$x++)
		{
			if (($confdata[$x] !~ /^\#/) and ($confdata[$x] =~ /=/))
			{
				my ($start,$end) = split (/=/,$confdata[$x],2);
				if ($end =~ /\"(.*)\"/) {$end = $1}
				my $name = $start;
				my $sanity_name = $start;
				$name =~ s/\s/\_/g;
				$sanity_name =~ s/\s//g;

				if ($restricted{$sanity_name})
				{
					print $OUT "$confdata[$x]\n";
				}
				else
				{
					print $OUT "$start= \"$FORM{$name}\"\n";
					$end = $FORM{$name};
				}
			}
			else
			{
				print $OUT "$confdata[$x]\n";
			}
		}

		close ($OUT);
		ConfigServer::Config::resetconfig();
		my $newconfig = ConfigServer::Config->loadconfig();
		my %newconfig = $config->config;
		foreach my $key (keys %newconfig)
		{
			my ($insane,$range,$default) = sanity($key,$newconfig{$key});
			if ($insane) {print "<br>WARNING: $key sanity check. $key = \"$newconfig{$key}\". Recommended range: $range (Default: $default)\n"}
		}

		print "<div>Changes saved. You should restart both csf and lfd.</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "viewlogs")
	{
		if (-e "/var/lib/csf/stats/iptables_log")
		{
			open (my $IN, "<", "/var/lib/csf/stats/iptables_log") or die "Unable to open file: $!";
			flock ($IN, LOCK_SH);
			my @iptables = <$IN>;
			close ($IN);
			chomp @iptables;
			@iptables = reverse @iptables;
			my $from;
			my $to;
			my $divcnt = 0;
			my $expcnt = @iptables;

			if ($iptables[0] =~ /\|(\S+\s+\d+\s+\S+)/) {$from = $1}
			if ($iptables[-1] =~ /\|(\S+\s+\d+\s+\S+)/) {$to = $1}

			print "<div class='pull-right'><button type='button' class='btn btn-primary glyphicon glyphicon-arrow-down' data-tooltip='tooltip' title='Expand All' onClick='\$(\".submenu\").show();'></button>\n";
			print "<button type='button' class='btn btn-primary glyphicon glyphicon-arrow-up' data-tooltip='tooltip' title='Collapse All' onClick='\$(\".submenu\").hide();'></button></div>\n";
			print "<h4>Last $config{ST_IPTABLES} iptables logs*, latest:<code>$from</code> oldest:<code>$to</code></h4><br />\n";
			print "<table class='table table-bordered table-striped'>\n";
			print "<thead><tr><th>Time</th><th width='50%'>From</th><th>Port</th><th>I/O</th><th width='50%'>To</th><th>Port</th><th>Proto</th></tr></thead>\n";

			my $size = scalar @iptables;
			if ($size > $config{ST_IPTABLES}) {$size = $config{ST_IPTABLES}}

			for (my $x = 0 ;$x < $size ;$x++)
			{
				my $line = $iptables[$x];
				$divcnt++;
				my ($text,$log) = split(/\|/,$line);
				my ($time,$desc,$in,$out,$src,$dst,$spt,$dpt,$proto,$inout);
				if ($log =~ /IN=(\S+)/) {$in = $1}
				if ($log =~ /OUT=(\S+)/) {$out = $1}
				if ($log =~ /SRC=(\S+)/) {$src = $1}
				if ($log =~ /DST=(\S+)/) {$dst = $1}
				if ($log =~ /SPT=(\d+)/) {$spt = $1}
				if ($log =~ /DPT=(\d+)/) {$dpt = $1}
				if ($log =~ /PROTO=(\S+)/) {$proto = $1}

				if ($text ne "")
				{
					$text =~ s/\(/\<br\>\(/g;
					if ($in and $src) {$src = $text ; $dst .= " <br>(server)"}
					elsif ($out and $dst) {$dst = $text ; $src .= " <br>(server)"}
				}

				if ($log =~ /^(\S+\s+\d+\s+\S+)/) {$time = $1}

				$inout = "n/a";
				if ($in) {$inout = "in"}
				elsif ($out) {$inout = "out"}

				print "<tr><td style='white-space: nowrap;'><button type='button' class='btn btn-primary glyphicon glyphicon-resize-vertical' data-tooltip='tooltip' title='Toggle Info' onClick='\$(\"#s$divcnt\").toggle()'></button> $time</td><td>$src</td><td>$spt</td><td>$inout</td><td>$dst</td><td>$dpt</td><td>$proto</td></tr>\n";

				$log =~ s/\&/\&amp\;/g;
				$log =~ s/>/\&gt\;/g;
				$log =~ s/</\&lt\;/g;
				print "<tr style='display:none' class='submenu' id='s$divcnt'><td colspan='7'><span>$log</span></td></tr>\n";
			}
			print "</table>\n";
			print "<div class='bs-callout bs-callout-warning'>* These iptables logs taken from $config{IPTABLES_LOG} will not necessarily show all packets blocked by iptables. For example, ports listed in DROP_NOLOG or the settings for DROP_LOGGING/DROP_IP_LOGGING/DROP_ONLYRES/DROP_PF_LOGGING will affect what is logged. Additionally, there is rate limiting on all iptables log rules to prevent log file flooding</div>\n";
		}
		else
		{
			print "<div class='bs-callout bs-callout-info'> No logs entries found</div>\n";
		}
		&printreturn;
	}
	elsif ($FORM{action} eq "sips")
	{
		sysopen (my $IN, "/etc/csf/csf.sips", O_RDWR | O_CREAT) or die "Unable to open file: $!";
		flock ($IN, LOCK_SH);
		my @confdata = <$IN>;
		close ($IN);
		chomp @confdata;

		print "<form action='$script' method='post'><input type='hidden' name='action' value='sipsave'><br>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<tr><td><b>IP Address</b></td><td><b>Deny All Access to IP</b></td></tr>\n";

		my %sips;
		open (my $SIPS, "<","/etc/csf/csf.sips");
		flock ($SIPS, LOCK_SH);
		my @data = <$SIPS>;
		close ($SIPS);
		chomp @data;

		foreach my $line (@data)
		{
			if ($line =~ /^(\s|\#|$)/) {next}
			$sips{$line} = 1;
		}

		my $ethdev = ConfigServer::GetEthDev->new();
		my %g_ipv4 = $ethdev->ipv4;
		my %g_ipv6 = $ethdev->ipv6;

		foreach my $key (sort keys %g_ipv4)
		{
			my $ip = $key;
			if ($ip =~ /^127\.0\.0/) {next}
			my $chk = "ip_$ip";
			$chk =~ s/\./\_/g;
			my $checked = "";
			if ($sips{$ip}) {$checked = "checked"}
			print "<tr><td>$ip</td><td><input type='checkbox' name='$chk' $checked></td></tr>\n";
		}

		foreach my $key (sort keys %g_ipv6)
		{
			my $ip = $key;
			my $chk = "ip_$ip";
			$chk =~ s/\./\_/g;
			my $checked = "";
			if ($sips{$ip}) {$checked = "checked"}
			print "<tr><td>$ip</td><td><input type='checkbox' name='$chk' $checked></td></tr>\n";
		}

		print "<tr><td colspan='2'><input type='submit' class='btn btn-default' value='Change'></td></tr>\n";
		print "</table></form>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "sipsave")
	{
		open (my $IN,"<","/etc/csf/csf.sips");
		flock ($IN, LOCK_SH);
		my @data = <$IN>;
		close ($IN);
		chomp @data;

		open (my $OUT,">","/etc/csf/csf.sips");
		flock ($OUT, LOCK_EX);

		foreach my $line (@data)
		{
			if ($line =~ /^\#/) {print $OUT "$line\n"} else {last}
		}

		foreach my $key (keys %FORM)
		{
			if ($key =~ /^ip_(.*)/)
			{
				my $ip = $1;
				$ip =~ s/\_/\./g;
				print $OUT "$ip\n";
			}
		}

		close($OUT);

		print "<div>Changes saved. You should restart csf.</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restart'><input type='submit' class='btn btn-default' value='Restart csf'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "upgrade")
	{
		if ($config{THIS_UI})
		{
			print "<div>You cannot upgrade through the UI as restarting lfd will interrupt this session. You must login to the root shell to upgrade csf using:\n<p><b>csf -u</b></div>\n";
		} else
		{
			print "<div><p>Upgrading csf...</p>\n";
			&resize("top");
			print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
			&printcmd("/usr/sbin/csf","-u");
			print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
			&resize("bot",1);

			open (my $IN, "<", "/etc/csf/version.txt") or die $!;
			flock ($IN, LOCK_SH);
			$myv = <$IN>;
			close ($IN);
			chomp $myv;
		}

		&printreturn;
	}
	elsif ($FORM{action} eq "denyf")
	{
		print "<div><p>Removing all entries from csf.deny...</p>\n";
		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("/usr/sbin/csf","-df");
		&printcmd("/usr/sbin/csf","-tf");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&resize("bot",1);
		&printreturn;
	}
	elsif ($FORM{action} eq "csftest")
	{
		print "<div><p>Testing iptables...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/local/csf/bin/csftest.pl");
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div>You should restart csf after having run this test.</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restart'><input type='submit' class='btn btn-default' value='Restart csf'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "profiles")
	{
		my @profiles = sort glob("/usr/local/csf/profiles/*");
		my @backups = reverse glob("/var/lib/csf/backup/*");

		print "<form action='$script' method='post'><input type='hidden' name='action' value='profileapply'>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th>Preconfigured Profiles</th><th>&nbsp;</th></tr></thead>\n";

		foreach my $profile ( @profiles )
		{
			my ( $file, undef ) = fileparse( $profile );
			$file =~ s/\.conf$//;

			my $text;
			open ( my $IN, "<", $profile );
			flock ( $IN, LOCK_SH );

			my @profiledata = <$IN>;
			close ( $IN );
			chomp @profiledata;

			if ( $file eq "reset_to_defaults" )
			{
				$text = "This is the installation default profile and will reset all csf.conf settings, including enabling TESTING mode";
			}
			elsif ( $profiledata[ 0 ] =~ /^\# Profile:/ )
			{
				foreach my $line ( @profiledata )
				{
					if ( $line =~ /^\# (.*)$/ )
					{
						$text .= "$1 "
					}
				}
			}

			print "<tr><td class='preconfigured-profiles'>📄 <span class='item-filename'>$file</span><br>\n<span class='item-description'>$text</span></td><td class='checkbox-container'><div class='checkbox-wrapper'><div class='cbx'><input id='cbx-12' type='radio' name='profile' value='$file'><label for='cbx-12'></label><svg width='15' height='14' viewbox='0 0 15 14' fill='none'><path d='M2 8.36364L6.23077 12L13 2'></path></svg></div></div></td></tr>\n";
		}

		print "<tr><td>You can apply one or more of these profiles to csf.conf. Apart from reset_to_defaults, most of these profiles contain only a subset of settings. You can find out what will be changed by comparing the profile to the current configuration below. A backup of csf.conf will be created before any profile is applied.</td><td><input type='submit' class='btn-apply' value='Apply Profile'></td></tr>\n";
		print "</table>\n";
		print "</form>\n";

		print "<br><form action='$script' method='post'><input type='hidden' name='action' value='profilebackup'>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th>Backup csf.conf</th></tr></thead>\n";
		print "<tr><td>Create a backup of csf.conf. You can use an optional name for the backup that should only contain alphanumerics. Other characters (including spaces) will be replaced with an underscore ( _ )</td></tr>\n";
		print "<tr><td><input type='text' size='40' name='backup' placeholder='Optional name'> <input type='submit' class='btn btn-default' value='Create Backup'></td></tr>\n";
		print "</table>\n";
		print "</form>\n";

		print "<br><form action='$script' method='post'><input type='hidden' name='action' value='profilerestore'>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th>Restore Backup Of csf.conf</th></tr></thead>\n";
		print "<tr><td><select name='backup' size='10' style='min-width:400px'>\n";
		foreach my $backup (@backups)
		{
			my ($file, undef) = fileparse($backup);
			my ($stamp,undef) = split(/_/,$file);
			print "<optgroup label='".localtime($stamp).":'><option>$file</option></optgroup>\n";
		}

		print "</select></td></tr>\n";
		print "<tr><td><input type='submit' class='btn btn-long' value='Restore Backup'></td></tr>\n";
		print "</table>\n";
		print "</form>\n";

		print "<br><form action='$script' method='post'><input type='hidden' name='action' value='profilediff'>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th>Compare Configurations</th></tr></thead>\n";
		print "<tr><td>Select first configuration:<br>\n<select name='profile1' size='10' style='min-width:400px'>\n";
		print "<optgroup label='Profiles:'>\n";
		foreach my $profile (@profiles)
		{
			my ($file, undef) = fileparse($profile);
			$file =~ s/\.conf$//;
			print "<option>$file</option>\n";
		}

		print "</optgroup>\n";
		foreach my $backup (@backups)
		{
			my ($file, undef) = fileparse($backup);
			my ($stamp,undef) = split(/_/,$file);
			print "<optgroup label='".localtime($stamp).":'><option>$file</option></optgroup>\n";
		}

		print "</select></td></tr>\n";
		print "<tr><td>Select second configuration:<br>\n<select name='profile2' size='10' style='min-width:400px'>\n";
		print "<optgroup label='Current Configuration:'><option value='current' selected>/etc/csf/csf.conf</option></optgroup>\n";
		print "<optgroup label='Profiles:'>\n";
		foreach my $profile (@profiles)
		{
			my ($file, undef) = fileparse($profile);
			$file =~ s/\.conf$//;
			print "<option>$file</option>\n";
		}
		print "</optgroup>\n";
		foreach my $backup (@backups)
		{
			my ($file, undef) = fileparse($backup);
			my ($stamp,undef) = split(/_/,$file);
			print "<optgroup label='".localtime($stamp).":'><option>$file</option></optgroup>\n";
		}
		print "</select></td></tr>\n";
		print "<tr><td><input type='submit' class='btn btn-long' value='Compare Config/Backup/Profile Settings'></td></tr>\n";
		print "</table>\n";
		print "</form>\n";

		&printreturn;
	}
	elsif ($FORM{action} eq "profileapply")
	{
		my $profile = $FORM{profile};
		$profile =~ s/\W/_/g;
		print "<div><p>Applying profile ($profile)...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","--profile","apply",$profile);
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div>You should restart both csf and lfd.</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "profilebackup")
	{
		my $profile = $FORM{backup};
		$profile =~ s/\W/_/g;
		print "<div><p>Creating backup...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","--profile","backup",$profile);
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "profilerestore")
	{
		my $profile = $FORM{backup};
		$profile =~ s/\W/_/g;
		print "<div><p>Restoring backup ($profile)...</p>\n<pre class='comment' style='white-space: pre-wrap;'>\n";
		&printcmd("/usr/sbin/csf","--profile","restore",$profile);
		print "</pre>\n<p>...<b>Done</b>.</p></div>\n";
		print "<div>You should restart both csf and lfd.</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "profilediff")
	{
		my $profile1 = $FORM{profile1};
		my $profile2 = $FORM{profile2};
		$profile2 =~ s/\W/_/g;
		$profile2 =~ s/\W/_/g;

		print "<table class='table table-bordered table-striped'>\n";
		my ($childin, $childout);
		my $pid = open3($childin, $childout, $childout, "/usr/sbin/csf","--profile","diff",$profile1,$profile2);
		while (<$childout>)
		{
			$_ =~ s/\[|\]//g;
			my ($var,$p1,$p2) = split(/\s+/,$_);
			if ($var eq "") {
				next;
			}
			elsif ($var eq "SETTING")
			{
				print "<tr><td><b>$var</b></td><td><b>$p1</b></td><td><b>$p2</b></td></tr>\n";
			}
			else
			{
				print "<tr><td>$var</td><td>$p1</td><td>$p2</td></tr>\n";
			}
		}

		waitpid ($pid, 0);
		print "</table>\n";

		&printreturn;
	}
	elsif ($FORM{action} eq "viewports")
	{
		print "<div><h4>Ports listening for external connections and the executables running behind them:</h4></div>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th>Port</th><th>Proto</th><th>Open</th><th>Conns</th><th>PID</th><th>User</th><th>Command Line</th><th>Executable</th></tr></thead>\n";
		my %listen = ConfigServer::Ports->listening;
		my %ports = ConfigServer::Ports->openports;
		foreach my $protocol (sort keys %listen) {
			foreach my $port (sort {$a <=> $b} keys %{$listen{$protocol}})
			{
				foreach my $pid (sort {$a <=> $b} keys %{$listen{$protocol}{$port}})
				{
					my $fopen;
					if ($ports{$protocol}{$port}) {$fopen = "4"} else {$fopen = "-"}
					if ($config{IPV6} and $ports{$protocol."6"}{$port}) {$fopen .= "/6"} else {$fopen .= "/-"}

					my $fcmd = ($listen{$protocol}{$port}{$pid}{cmd});
					$fcmd =~ s/\</\&lt;/g;
					$fcmd =~ s/\&/\&amp;/g;

					my $fexe = $listen{$protocol}{$port}{$pid}{exe};
					$fexe =~ s/\</\&lt;/g;
					$fexe =~ s/\&/\&amp;/g;

					my $fconn = $listen{$protocol}{$port}{$pid}{conn};
					print "<tr><td>$port</td><td>$protocol</td><td>$fopen</td><td>$fconn</td><td>$pid</td><td>$listen{$protocol}{$port}{$pid}{user}</td><td style='overflow: hidden;text-overflow: ellipsis; width:50%'>$fcmd</td><td style='overflow: hidden;text-overflow: ellipsis; width:50%'>$fexe</td></tr>\n";
				}
			}
		}

		print "</table>\n";

		&printreturn;
	}
	elsif ($mobile) {
		print "<table class='table table-bordered table-striped'>\n";
		print "<tr><td><form action='$script' method='post'><input type='hidden' name='mobi' value='$mobile'><input type='hidden' name='action' value='qallow'><input type='submit' class='btn btn-default btn-allow' value='Quick Allow'></td><td style='width:100%'><input type='text' name='ip' value='' size='18'></form></td></tr>\n";
		print "<tr><td><form action='$script' method='post'><input type='hidden' name='mobi' value='$mobile'><input type='hidden' name='action' value='qdeny'><input type='submit' class='btn btn-default btn-deny' value='Quick Deny'></td><td style='width:100%'><input type='text' name='ip' value='' size='18'></form></td></tr>\n";
		print "<tr><td><form action='$script' method='post'><input type='hidden' name='mobi' value='$mobile'><input type='hidden' name='action' value='qignore'><input type='submit' class='btn btn-default' value='Quick Ignore'></td><td style='width:100%'><input type='text' name='ip' value='' size='18'></form></td></tr>\n";
		print "<tr><td><form action='$script' method='post'><input type='hidden' name='mobi' value='$mobile'><input type='hidden' name='action' value='kill'><input type='submit' class='btn btn-default' value='Quick Unblock'></td><td style='width:100%'><input type='text' name='ip' value='' size='18'></form></td></tr>\n";
		print "</table>\n";
	}
	elsif ($FORM{action} eq "fix")
	{
		print "<div class='bs-callout bs-callout-warning'>These options should only be used as a last resort as most of them will reduce the effectiveness of csf and lfd to protect the server</div>\n";

		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th colspan='2'>Fix Common Problems</th></tr></thead>";

		if ($config{LF_SPI} == 0)
		{
			print "<tr><td><button class='btn btn-default' disabled>Disable SPI</button>\n";
		}
		else
		{
			print "<tr><td><button type='button' class='btn btn-default confirmButton' data-query='Are you sure you want to disable LF_SPI?' data-href='$script?action=fixspi' data-toggle='modal' data-target='#confirmmodal'>Disable SPI</button>\n";
		}

		print "</td><td style='width:100%'>If you find that ports listed in TCP_IN/UDP_IN are being blocked by iptables (e.g. port 80) as seen in /var/log/messages and users can only connect to the server if entered in csf.allow, then it could be that the kernel (usually on virtual servers) is broken and cannot perform connection tracking. In this case, disabling the Stateful Packet Inspection functionality of csf (LF_SPI) may help\n";

		if ($config{LF_SPI} == 0)
		{
			print "<br><strong>Note: LF_SPI is already disabled</strong>";
		}

		print "</td></tr>\n";

		if ($config{TCP_IN} =~ /30000:35000/)
		{
			print "<tr><td><button class='btn btn-default' disabled>Open PASV FTP Hole</button>\n";
		}
		else
		{
			print "<tr><td><button type='button' class='btn btn-default confirmButton' data-query='Are you sure you want to open PASV FTP hole?' data-href='$script?action=fixpasvftp' data-toggle='modal' data-target='#confirmmodal'>Open PASV FTP Hole</button>\n";
		}

		print "</td><td style='width:100%'>If the kernel (usually on virtual servers) is broken and cannot perform ftp connection tracking, or if you are trying to use FTP over SSL, this option will open a hole in the firewall to allow PASV connections through\n";
		if ($config{TCP_IN} =~ /30000:35000/) {
			print "<br><strong>Note: The port range 30000 to 35000 is already open in csf</strong>\n";
		}
		print "</td></tr>\n";

		if ($config{PT_USERKILL} == 0)
		{
			print "<tr><td><button class='btn btn-default' disabled>Disable PT_USERKILL</button>\n";
		}
		else
		{
			print "<tr><td><button type='button' class='btn btn-default confirmButton' data-query='Are you sure you want to disable PT_USERKILL?' data-href='$script?action=fixkill' data-toggle='modal' data-target='#confirmmodal'>Disable PT_USERKILL</button>\n";
		}

		print "</td><td style='width:100%'>If lfd is killing running processes and you have PT_USERKILL enabled, then we recommend that you disable this feature\n";

		if ($config{PT_USERKILL} == 0)
		{
			print "<br><strong>Note: PT_USERKILL is already disabled</strong>";
		}

		print "</td></tr>\n";

		if ($config{SMTP_BLOCK} == 0) {
			print "<tr><td><button class='btn btn-default' disabled>Disable SMTP_BLOCK</button>\n";
		} else {
			print "<tr><td><button type='button' class='btn btn-default confirmButton' data-query='Are you sure you want to disable SMTP_BLOCK?' data-href='$script?action=fixsmtp' data-toggle='modal' data-target='#confirmmodal'>Disable SMTP_BLOCK</button>\n";
		}
		print "</td><td style='width:100%'>If scripts on the server are unable to send out email via external SMTP connections and you have SMTP_BLOCK enabled then those scripts should be configured to send email either through /usr/sbin/sendmail or localhost on the server. If this is not possible then disabling SMTP_BLOCK can fix this\n";
		if ($config{SMTP_BLOCK} == 0) {
			print "<br><strong>Note: SMTP_BLOCK is already disabled</strong>";
		}
		print "</td></tr>\n";

		print "<tr><td><button type='button' class='btn btn-default confirmButton' data-query='Are you sure you want to disable all alerts?' data-href='$script?action=fixalerts' data-toggle='modal' data-target='#confirmmodal'>Disable All Alerts</button>\n";
		print "</td><td style='width:100%'>If you really want to disable all alerts in lfd you can do so here. This is <strong>not</strong> recommended in any situation - you should go through the csf configuration and only disable those you do not want. As new features are added to csf you may find that you have to go into the csf configuration and disable them manually as this procedure only disables the ones that it is aware of when applied\n";
		print "</td></tr>\n";

		print "<tr><td><button type='button' class='btn btn-danger confirmButton' data-query='Are you sure you want to reinstall csf and lose all modifications?' data-href='$script?action=fixnuclear' data-toggle='modal' data-target='#confirmmodal'>Reinstall csf</button>\n";
		print "</td><td style='width:100%'>If all else fails this option will <strong>completely</strong> uninstall csf and install it again with completely default options (including TESTING mode). The previous configuration will be lost including all modifications\n";
		print "</td></tr>\n";

		print "</table>\n";
		&printreturn;
		&confirmmodal;
	}
	elsif ($FORM{action} eq "fixpasvftp")
	{
		print "<div class='panel panel-default'>\n";
		print "<div class='panel-heading panel-heading'>Enabling pure-ftpd PASV hole:</div>\n";
		print "<div class='panel-body'>";
		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";

		my $ftpdone = 0;
		if (-e "/usr/local/cpanel/version")
		{
			require Cpanel::Config;
			import Cpanel::Config;
			my $cpconf = Cpanel::Config::loadcpconf();
			if ($cpconf->{ftpserver} eq "pure-ftpd")
			{
				copy("/etc/pure-ftpd.conf","/etc/pure-ftpd.conf-".time."_prefixpasvftp");
				sysopen (my $PUREFTP,"/etc/pure-ftpd.conf", O_RDWR | O_CREAT);
				flock ($PUREFTP, LOCK_EX);
				my @ftp = <$PUREFTP>;
				chomp @ftp;
				seek ($PUREFTP, 0, 0);
				truncate ($PUREFTP, 0);
				my $hit = 0;

				foreach my $line (@ftp)
				{
					if ($line =~ /^#?\s*PassivePortRange/i)
					{
						if ($hit) {next}
						$line = "PassivePortRange 30000 35000";
						$hit = 1;
					}
	
					print $PUREFTP "$line\n";
				}

				unless ($hit) {print $PUREFTP "PassivePortRange 30000 35000"}
				close ($PUREFTP);
				&printcmd("/scripts/restartsrv_pureftpd");
				$ftpdone = 1;
			}
		}

		if ($config{TCP_IN} =~ /30000:35000/)
		{
			print "PASV port range 30000:35000 already exists in TCP_IN/TCP6_IN\n";
		}
		else
		{
			$config{TCP_IN} .= ",30000:35000";
			$config{TCP6_IN} .= ",30000:35000";

			copy("/etc/csf/csf.conf","/var/lib/csf/backup/".time."_prefixpasvftp");
			sysopen (my $CSFCONF,"/etc/csf/csf.conf", O_RDWR | O_CREAT);
			flock ($CSFCONF, LOCK_EX);
			my @csf = <$CSFCONF>;
			chomp @csf;
			seek ($CSFCONF, 0, 0);
			truncate ($CSFCONF, 0);

			foreach my $line (@csf)
			{
				if ($line =~ /^TCP6_IN/)
				{
					print $CSFCONF "TCP6_IN = \"$config{TCP6_IN}\"\n";
					print "*** PASV port range 30000:35000 added to the TCP6_IN port list\n";
				}
				elsif ($line =~ /^TCP_IN/)
				{
					print $CSFCONF "TCP_IN = \"$config{TCP_IN}\"\n";
					print "*** PASV port range 30000:35000 added to the TCP_IN port list\n";
				}
				else
				{
					print $CSFCONF $line."\n";
				}
			}

			close ($CSFCONF);
		}

		print "</pre></div>\n";
		&resize("bot",1);
		print "<div class='panel-footer panel-footer'>Completed<br>\n";
		unless ($ftpdone) {print "<p><strong>You MUST now open the same port range hole (30000 to 35000) in your FTP Server configuration</strong></p>\n"}
		print "</div>\n";
		print "</div>\n";
		print "<div>You MUST now restart both csf and lfd:</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "fixspi")
	{
		print "<div class='panel panel-default'>\n";
		print "<div class='panel-heading panel-heading'>Disabling LF_SPI:</div>\n";
		print "<div class='panel-body'>";

		copy("/etc/csf/csf.conf","/var/lib/csf/backup/".time."_prefixspi");
		sysopen (my $CSFCONF,"/etc/csf/csf.conf", O_RDWR | O_CREAT);
		flock ($CSFCONF, LOCK_EX);
		my @csf = <$CSFCONF>;
		chomp @csf;
		seek ($CSFCONF, 0, 0);
		truncate ($CSFCONF, 0);

		foreach my $line (@csf)
		{
			if ($line =~ /^LF_SPI /)
			{
				print $CSFCONF "LF_SPI = \"0\"\n";
				print "*** LF_SPI disabled ***\n";
			} else {
				print $CSFCONF $line."\n";
			}
		}

		close ($CSFCONF);

		print "</div>\n";
		print "<div class='panel-footer panel-footer'>Completed</div>\n";
		print "</div>\n";
		print "<div>You MUST now restart both csf and lfd:</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "fixkill")
	{
		print "<div class='panel panel-default'>\n";
		print "<div class='panel-heading panel-heading'>Disabling PT_USERKILL:</div>\n";
		print "<div class='panel-body'>";

		copy("/etc/csf/csf.conf","/var/lib/csf/backup/".time."_prefixkill");
		sysopen (my $CSFCONF,"/etc/csf/csf.conf", O_RDWR | O_CREAT);
		flock ($CSFCONF, LOCK_EX);
		my @csf = <$CSFCONF>;
		chomp @csf;
		seek ($CSFCONF, 0, 0);
		truncate ($CSFCONF, 0);

		foreach my $line (@csf)
		{
			if ($line =~ /^PT_USERKILL /)
			{
				print $CSFCONF "PT_USERKILL = \"0\"\n";
				print "*** PT_USERKILL disabled ***\n";
			}
			else
			{
				print $CSFCONF $line."\n";
			}
		}

		close ($CSFCONF);

		print "</div>\n";
		print "<div class='panel-footer panel-footer'>Completed</div>\n";
		print "</div>\n";
		print "<div>You MUST now restart both csf and lfd:</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "fixsmtp")
	{
		print "<div class='panel panel-default'>\n";
		print "<div class='panel-heading panel-heading'>Disabling SMTP_BLOCK:</div>\n";
		print "<div class='panel-body'>";

		copy("/etc/csf/csf.conf","/var/lib/csf/backup/".time."_prefixsmtp");
		sysopen (my $CSFCONF,"/etc/csf/csf.conf", O_RDWR | O_CREAT);
		flock ($CSFCONF, LOCK_EX);
		my @csf = <$CSFCONF>;
		chomp @csf;
		seek ($CSFCONF, 0, 0);
		truncate ($CSFCONF, 0);

		foreach my $line (@csf)
		{
			if ($line =~ /^SMTP_BLOCK /)
			{
				print $CSFCONF "SMTP_BLOCK = \"0\"\n";
				print "*** SMTP_BLOCK disabled ***\n";
			} else {
				print $CSFCONF $line."\n";
			}
		}

		close ($CSFCONF);

		print "</div>\n";
		print "<div class='panel-footer panel-footer'>Completed</div>\n";
		print "</div>\n";
		print "<div>You MUST now restart both csf and lfd:</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "fixalerts")
	{
		print "<div class='panel panel-default'>\n";
		print "<div class='panel-heading panel-heading'>Disabling All Alerts:</div>\n";
		print "<div class='panel-body'>";

		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		copy("/etc/csf/csf.conf","/var/lib/csf/backup/".time."_prefixalerts");
		&printcmd("/usr/sbin/csf","--profile","apply","disable_alerts");
		print "</pre>\n";
		&resize("bot",1);
		print "</div>\n";
		print "<div class='panel-footer panel-footer'>Completed</div>\n";
		print "</div>\n";
		print "<div>You MUST now restart both csf and lfd:</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
		&printreturn;
	}
	elsif ($FORM{action} eq "fixnuclear") {
		print "<div class='panel panel-default'>\n";
		print "<div class='panel-heading panel-heading'>Nuclear Option:</div>\n";
		print "<div class='panel-body'>";

		my $time = time;
		sysopen (my $REINSTALL, "/usr/src/reinstall_$time.sh", O_WRONLY | O_CREAT | O_TRUNC);
		flock ($REINSTALL, LOCK_EX);
		print $REINSTALL <<EOF;
#!/usr/bin/bash
bash /etc/csf/uninstall.sh
cd /usr/src
mv -fv csf.tgz csf.tgz.$time
mv -fv csf csf.$time
wget https://$config{DOWNLOADSERVER}/csf.tgz
tar -xzf csf.tgz
cd csf
sh install.sh
EOF
		close ($REINSTALL);
		&resize("top");
		print "<pre class='comment' style='white-space: pre-wrap; height: 500px; overflow: auto; resize:both; clear:both' id='output'>\n";
		&printcmd("bash","/usr/src/reinstall_$time.sh");
		unlink "/usr/src/reinstall_$time.sh";
		print "</pre>\n";
		&resize("bot",1);
		print "</div>\n";
		print "<div class='panel-footer panel-footer'>Completed</div>\n";
		print "</div>\n";
		&printreturn;
	}
	else {
		if (defined $ENV{WEBMIN_VAR} and defined $ENV{WEBMIN_CONFIG} and -e "module.info") {
			my @data = slurp("module.info");
			foreach my $line (@data) {
				if ($line =~ /^name=csf$/) {
					unless (-l "index.cgi") {
						unlink "index.cgi";
						my $status = symlink ("/usr/local/csf/lib/webmin/csf/index.cgi","index.cgi");
						if ($status and -l "index.cgi") {
							symlink ("/usr/local/csf/lib/webmin/csf/images","csfimages");
							print "<p><b>csf updated to symlink webmin module to /usr/local/csf/lib/webmin/csf/. Click <a href='index.cgi'>here</a> to continue<p></b>\n";
							exit;
						} else {
							print "<p>Failed to symlink to /usr/local/csf/lib/webmin/csf/<p>\n";
						}
					}
					last;
				}
			}
		}

		&getethdev;
		my ($childin, $childout);
		my $pid = open3($childin, $childout, $childout, "$config{IPTABLES} $config{IPTABLESWAIT} -L LOCALINPUT -n");
		my @iptstatus = <$childout>;
		waitpid ($pid, 0);
		chomp @iptstatus;
		if ($iptstatus[0] =~ /# Warning: iptables-legacy tables present/) {shift @iptstatus}

		my $status = "<div class='bs-callout bs-callout-success text-center'><h4>Firewall Status: Enabled & Running</h4></div>";

		if (-e "/etc/csf/csf.disable")
		{
			$status = "<div class='bs-callout bs-callout-danger text-center'><form action='$script' method='post'><h4>Firewall Status: Disabled and Stopped <input type='hidden' name='action' value='enable'><input type='submit' class='btn btn-default' value='Enable'></form></h4></div>\n"
		}
		elsif ($config{TESTING})
		{
			$status = "<div class='bs-callout bs-callout-warning text-center'><form action='$script' method='post'><h4>Firewall Status: Enabled but in Test Mode - Don't forget to disable TESTING in the Firewall Configuration</h4></div>";
		}
		elsif ($iptstatus[0] !~ /^Chain LOCALINPUT/)
		{
			$status = "<div class='bs-callout bs-callout-danger text-center'><form action='$script' method='post'><h4>Firewall Status: Enabled but Stopped <input type='hidden' name='action' value='start'><input type='submit' class='btn btn-default' value='Start'></form></h4></div>"
		}

		if (-e "/var/lib/csf/lfd.restart") {$status .= "<div class='bs-callout bs-callout-info text-center'><h4>lfd restart request pending</h4></div>"}
		unless ($config{RESTRICT_SYSLOG}) {$status .= "<div class='bs-callout bs-callout-warning text-center'><h4><b>WARNING:</b> RESTRICT_SYSLOG is disabled. See SECURITY WARNING in Firewall Configuration</h4></div>\n"}

		# $status .= "<div class='bs-callout bs-callout-info text-center'><h4>Test information callout</h4></div>";
		# $status .= "<div class='bs-callout bs-callout-danger text-center'><h4>Test danger callout</h4></div>";
		# $status .= "<div class='bs-callout bs-callout-warning text-center'><h4>Test warning callout</h4></div>";
		# $status .= "<div class='bs-callout bs-callout-success text-center'><h4>Test success callout</h4></div>";

		my $tempcnt = 0;
		if (! -z "/var/lib/csf/csf.tempban")
		{
			sysopen (my $IN, "/var/lib/csf/csf.tempban", O_RDWR);
			flock ($IN, LOCK_EX);
			my @data = <$IN>;
			close ($IN);
			chomp @data;
			$tempcnt = scalar @data;
		}
		my $tempbans = "(Currently: <code>$tempcnt</code> temp IP bans, ";
		$tempcnt = 0;
		if (! -z "/var/lib/csf/csf.tempallow") {
			sysopen (my $IN, "/var/lib/csf/csf.tempallow", O_RDWR);
			flock ($IN, LOCK_EX);
			my @data = <$IN>;
			close ($IN);
			chomp @data;
			$tempcnt = scalar @data;
		}
		$tempbans .= "<code>$tempcnt</code> temp IP allows)";

		my $permcnt = 0;
		if (! -z "/etc/csf/csf.deny") {
			sysopen (my $IN, "/etc/csf/csf.deny", O_RDWR);
			flock ($IN, LOCK_SH);
			while (my $line = <$IN>) {
				chomp $line;
				if ($line =~ /^(\#|\n|\r)/) {next}
				if ($line =~ /$ipv4reg|$ipv6reg/) {$permcnt++}
			}
			close ($IN);
		}
		my $permbans = "(Currently: <code>$permcnt</code> permanent IP bans)";

		$permcnt = 0;
		if (! -z "/etc/csf/csf.allow") {
			sysopen (my $IN, "/etc/csf/csf.allow", O_RDWR);
			flock ($IN, LOCK_SH);
			while (my $line = <$IN>) {
				chomp $line;
				if ($line =~ /^(\#|\n|\r)/) {next}
				if ($line =~ /$ipv4reg|$ipv6reg/) {$permcnt++}
			}
			close ($IN);
		}
		my $permallows = "(Currently: <code>$permcnt</code> permanent IP allows)";

		print $status;

		# tag 'normalcontainer' closed within mobile view
		print "<div class='normalcontainer'>\n";
		print "<div class='bs-callout bs-callout-info text-center collapse' id='upgradebs'><h4>A new version of csf is <a href='#upgradetable'>available</a></h4></div>";

		print "<ul class='nav nav-tabs' id='myTabs' style='font-weight:bold'>\n";
		print "<li class='active'><a data-toggle='tab' href='#' id='tabAll'>All</a></li>\n";
		print "<li><a data-toggle='tab' href='#home'>Info</a></li>\n";
		print "<li><a data-toggle='tab' href='#csf'>csf</a></li>\n";
		print "<li><a data-toggle='tab' href='#lfd'>lfd</a></li>\n";
	
		if ($config{CLUSTER_SENDTO})
		{
			print "<li><a data-toggle='tab' href='#cluster'>Cluster</a></li>\n";
		}

		print "<li><a data-toggle='tab' href='#other'>Other</a></li>\n";
		print "</ul><br>\n";

		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th colspan='2'>Mobile View</th></tr></thead>";
		print "<tr><td><a class='btn btn-default btn-mobile' id='MobileView'>Mobile View</a></td><td style='width:100%'>Shows mobile friendly action buttons to manage your firewall.</td></tr>\n";
		print "</table>\n";

		print "<div class='tab-content'>\n";
		print "<div id='home' class='tab-pane active'>\n";
		print "<form action='$script' method='post'>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th colspan='2'>Server Information</th></tr></thead>";
		print "<tr><td><button name='action' value='servercheck' type='submit' class='btn btn-default'>Check Server Security</button></td><td style='width:100%'>Perform a basic security, stability and settings check on the server</td></tr>\n";
		print "<tr><td><button name='action' value='readme' type='submit' class='btn btn-default'>Firewall Information</button></td><td style='width:100%'>View the csf+lfd readme.txt file</td></tr>\n";
		print "<tr><td><button name='action' value='logtail' type='submit' class='btn btn-default'>Watch System Logs</button></td><td style='width:100%'>Watch (tail) various system log files (listed in csf.syslogs)</td></tr>\n";
		print "<tr><td><button name='action' value='loggrep' type='submit' class='btn btn-default'>Search System Logs</button></td><td style='width:100%'>Search (grep) various system log files (listed in csf.syslogs)</td></tr>\n";
		print "<tr><td><button name='action' value='viewports' type='submit' class='btn btn-default'>View Listening Ports</button></td><td style='width:100%'>View ports on the server that have a running process behind them listening for external connections</td></tr>\n";
		print "<tr><td><button name='action' value='rblcheck' type='submit' class='btn btn-default'>Check for IPs in RBLs</button></td><td style='width:100%'>Check whether any of the servers IP addresses are listed in RBLs</td></tr>\n";

		if ($config{ST_ENABLE})
		{
			print "<tr><td><button name='action' value='viewlogs' type='submit' class='btn btn-default'>View iptables Log</button></td><td style='width:100%'>View the last $config{ST_IPTABLES} iptables log lines</td></tr>\n";
			if ($chart)
			{
				print "<tr><td><button name='action' value='chart' type='submit' class='btn btn-default'>View lfd Statistics</button></td><td style='width:100%'>View lfd blocking statistics</td></tr>\n";
				if ($config{ST_SYSTEM})
				{
					print "<tr><td><button name='action' value='systemstats' type='submit' class='btn btn-default'>View System Statistics</button></td><td style='width:100%'>View basic system statistics</td></tr>\n";
				}
			}
		}

		print "</table>\n";
		print "</form>\n";

		print "<form action='$script' method='post'>\n";
		print "<table class='table table-bordered table-striped' id='upgradetable'>\n";
		print "<thead><tr><th colspan='2'>Upgrade</th></tr></thead>";

		#	upgrade (int)		0, 1
		#	response (str)		upgrade status or version
		my ( $upgrade, $response ) = &csgetversion( "csf", $myv );

		if ($upgrade)
		{
			print "<tr><td><button name='action' value='upgrade' type='submit' class='btn btn-default'>Upgrade csf</button></td><td style='width:100%'><b>A new version of csf (v$response) is available. Upgrading will retain your settings<br><a href='https://$config{DOWNLOADSERVER}/csf/changelog.txt' target='_blank'>View ChangeLog</a></b></td></tr>\n";
		}
		else
		{
			print "<tr><td><button name='action' value='manualcheck' type='submit' class='btn btn-default'>Manual Check</button></td>";
			print "<td style='width:100%;'>";

			if ( $response ne "" )
			{
				print "(csget cron check) $response</td></tr>\n";
			}
			else
			{
				print "Running latest version of CSF. An Upgrade button will appear here if a new version becomes available. New version checking is performed automatically by a daily cron job (csget)</td></tr>\n";
			}
		}

		if (!$config{INTERWORX} and (-e "/etc/apf" or -e "/usr/local/bfd"))
		{
			print "<tr><td><button name='action' value='remapf' type='submit' class='btn btn-default'>Remove APF/BFD</button></td><td style='width:100%'>Remove APF/BFD from the server. You must not run both APF or BFD with csf on the same server</td></tr>\n";
		}
	
		unless (-e "/etc/cxs/cxs.pl")
		{
			if (-e "/usr/local/cpanel/version" or $config{DIRECTADMIN} or $config{INTERWORX} or $config{VESTA} or $config{CWP} or $config{CYBERPANEL})
			{
				print "<tr><td colspan='2'>\n";
				print "<div class='bs-callout bs-callout-info h4'>Add server and user data protection against exploits using <a href='https://configserver.com/cp/cxs.html' target='_blank'>ConfigServer eXploit Scanner (cxs)</a></div>\n";
				print "</td></tr>\n";
			}
		}
	
		unless (-e "/etc/osm/osmd.pl")
		{
			if (-e "/usr/local/cpanel/version" or $config{DIRECTADMIN})
			{
				print "<tr><td colspan='2'>\n";
				print "<div class='bs-callout bs-callout-info h4'>Add outgoing spam monitoring and prevention using <a href='https://configserver.com/cp/osm.html' target='_blank'>ConfigServer Outgoing Spam Monitor(osm)</a></div>\n";
				print "</td></tr>\n";
			}
		}

		unless (-e "/usr/msfe/mschange.pl")
		{
			if (-e "/usr/local/cpanel/version" or $config{DIRECTADMIN})
			{
				print "<tr><td colspan='2'>\n";
				print "<div class='bs-callout bs-callout-info h4'>Add effective incoming virus and spam detection and user level processing using <a href='https://configserver.com/cp/msfe.html' target='_blank'>ConfigServer MailScanner Front-End (msfe)</a></div>\n";
				print "</td></tr>\n";
			}
		}
		
		print "</table>\n";
		print "</form>\n";
		if ($upgrade) {print "<script>\$('\#upgradebs').show();</script>\n"}
		print "</div>\n";

		print "<div id='csf' class='tab-pane active'>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th colspan='2'>csf - Quick Actions</th></tr></thead>";
		print "<tr><td><button onClick='\$(\"#qallow\").submit();' class='btn btn-default btn-allow'>Quick Allow</button></td><td style='width:100%'><form action='$script' method='post' id='qallow'><input type='submit' class='hide'><input type='hidden' name='action' value='qallow'>Allow IP address <a href='javascript:fillfield(\"allowip\",\"$ENV{REMOTE_ADDR}\")'><span class='glyphicon glyphicon-cog icon-configserver' style='font-size:1.3em;' data-tooltip='tooltip' title='$ENV{REMOTE_ADDR}'></span></a> <input type='text' name='ip' id='allowip' value='' size='18'> through the firewall and add to the allow file (csf.allow).<br>Comment for Allow: <input type='text' name='comment' value='' size='30'></form></td></tr>\n";
		print "<tr><td><button onClick='\$(\"#qdeny\").submit();' class='btn btn-default btn-deny'>Quick Deny</button></td><td style='width:100%'><form action='$script' method='post' id='qdeny'><input type='submit' class='hide'><input type='hidden' name='action' value='qdeny'>Block IP address <input type='text' name='ip' value='' size='18'> in the firewall and add to the deny file (csf.deny).<br>Comment for Block: <input type='text' name='comment' value='' size='30'></form></td></tr>\n";
		print "<tr><td><button onClick='\$(\"#qignore\").submit();' class='btn btn-default'>Quick Ignore</button></td><td style='width:100%'><form action='$script' method='post' id='qignore'><input type='submit' class='hide'><input type='hidden' name='action' value='qignore'>Ignore IP address <a href='javascript:fillfield(\"ignoreip\",\"$ENV{REMOTE_ADDR}\")'><span class='glyphicon glyphicon-cog icon-configserver' style='font-size:1.3em;' data-tooltip='tooltip' title='$ENV{REMOTE_ADDR}'></span></a> <input type='text' name='ip' id='ignoreip' value='' size='18'> in lfd, add to the ignore file (csf.ignore) and restart lfd</form></td></tr>\n";
		print "<tr><td><button onClick='\$(\"#kill\").submit();' class='btn btn-default'>Quick Unblock</button></td><td style='width:100%'><form action='$script' method='post' id='kill'><input type='submit' class='hide'><input type='hidden' name='action' value='kill'>Remove IP address <input type='text' name='ip' value='' size='18'> from the firewall (temp and perm blocks)</form></td></tr>\n";
		print "</table>\n";

		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th colspan='2'>csf - ConfigServer Firewall</th></tr></thead>";
		print "<tr><td><form action='$script' method='post'><button name='action' value='conf' type='submit' class='btn btn-default'>Firewall Configuration</button></form></td><td style='width:100%'>Edit the configuration file for the csf firewall and lfd</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='profiles' type='submit' class='btn btn-default'>Firewall Profiles</button></form></td><td style='width:100%'>Apply pre-configured csf.conf profiles and backup/restore csf.conf</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='status' type='submit' class='btn btn-default'>View iptables Rules</button></form></td><td style='width:100%'>Display the active iptables rules</td></tr>\n";
		print "<tr><td><button onClick='\$(\"#grep\").submit();' class='btn btn-default'>Search for IP</button></td><td style='width:100%'><form action='$script' method='post' id='grep'><input type='submit' class='hide'><input type='hidden' name='action' value='grep'>Search iptables for IP address <input type='text' name='ip' value='' size='18'></form></td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='allow' type='submit' class='btn btn-default'>Firewall Allow IPs</button></form></td><td style='width:100%'>Edit csf.allow, the IP address allow file $permallows</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='deny' type='submit' class='btn btn-default'>Firewall Deny IPs</button></form></td><td style='width:100%'>Edit csf.deny, the IP address deny file $permbans</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='enable' type='submit' class='btn btn-default'>Firewall Enable</button></form></td><td style='width:100%'>Enables csf and lfd if previously Disabled</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='disable' type='submit' class='btn btn-default'>Firewall Disable</button></form></td><td style='width:100%'>Completely disables csf and lfd</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='restart' type='submit' class='btn btn-default'>Firewall Restart</button></form></td><td style='width:100%'>Restart the csf iptables firewall</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='restartq' type='submit' class='btn btn-default'>Firewall Quick Restart</button></form></td><td style='width:100%'>Have lfd restart the csf iptables firewall</td></tr>\n";
		print "<tr><td><button onClick='\$(\"#tempdeny\").submit();' class='btn btn-default'>Temporary Allow/Deny</button></td><td style='width:100%'><form action='$script' method='post' id='tempdeny'><input type='submit' class='hide'><input type='hidden' name='action' value='tempdeny'>Temporarily <select name='do'><option>block</option><option>allow</option></select> IP address <input type='text' name='ip' value='' size='18'> to port(s) <input type='text' name='ports' value='*' size='5'> for <input type='text' name='timeout' value='' size='4'> <select name='dur'><option>seconds</option><option>minutes</option><option>hours</option><option>days</option></select>.<br>Comment: <input type='text' name='comment' value='' size='30'><br>\n(ports can be either * for all ports, a single port, or a comma separated list of ports)</form></td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='temp' type='submit' class='btn btn-default'>Temporary IP Entries</button></form></td><td style='width:100%'>View/Remove the <i>temporary</i> IP entries $tempbans</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='sips' type='submit' class='btn btn-default'>Deny Server IPs</button></form></td><td style='width:100%'>Deny access to and from specific IP addresses configured on the server (csf.sips)</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='denyf' type='submit' class='btn btn-default'>Flush all Blocks</button></form></td><td style='width:100%'>Removes and unblocks all entries in csf.deny (excluding those marked \"do not delete\") and all temporary IP entries (blocks <i>and</i> allows)</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='redirect' type='submit' class='btn btn-default'>Firewall Redirect</button></form></td><td style='width:100%'>Redirect connections to this server to other ports/IP addresses</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='fix' type='submit' class='btn btn-default'>Fix Common Problems</button></form></td><td style='width:100%'>Offers solutions to some common problems when using an SPI firewall</td></tr>\n";
		print "</table>\n";
		print "<script>function fillfield (myitem,myip) {document.getElementById(myitem).value = myip;}</script>\n";
		print "</div>\n";

		print "<div id='lfd' class='tab-pane active'>\n";
		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th colspan='2'>lfd - Login Failure Daemon</th></tr></thead>";
		print "<tr><td><form action='$script' method='post'><input type='hidden' name='action' value='lfdstatus'><input type='submit' class='btn btn-default' value='lfd Status'></form></td><td style='width:100%'>Display lfd status</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><input type='hidden' name='action' value='lfdrestart'><input type='submit' class='btn btn-default' value='lfd Restart'></form></td><td style='width:100%'>Restart lfd</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><input type='hidden' name='action' value='ignorefiles'><select style='width: 13em;' name='ignorefile'>\n";
		print "<option value='csf.ignore'>csf.ignore - IP Blocking</option>\n";
		print "<option value='csf.pignore'>csf.pignore, Process Tracking</option>\n";
		print "<option value='csf.fignore'>csf.fignore, Directory Watching</option>\n";
		print "<option value='csf.signore'>csf.signore, Script Alert</option>\n";
		print "<option value='csf.rignore'>csf.rignore, Reverse DNS lookup</option>\n";
		print "<option value='csf.suignore'>csf.suignore, Superuser check</option>\n";
		print "<option value='csf.mignore'>csf.mignore, RT_LOCALRELAY</option>\n";
		print "<option value='csf.logignore'>csf.logignore, Log Scanner</option>\n";
		print "<option value='csf.uidignore'>csf.uidignore, User ID Tracking</option>\n";

		print "</select><input style='min-width: 13em;' type='submit' class='btn btn-edit' value='Edit'></form></td><td style='width:100%'>Edit lfd ignore file</td></tr>\n";

		print "<tr><td><form action='$script' method='post'><button name='action' value='dirwatch' type='submit' class='btn btn-default'>lfd Dir File Watching</button></form></td><td style='width:100%'>Edit the Directory File Watching file (csf.dirwatch) - all listed files and directories will be watched for changes by lfd</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='dyndns' type='submit' class='btn btn-default'>lfd Dynamic DNS</button></form></td><td style='width:100%'>Edit the Dynamic DNS file (csf.dyndns) - all listed domains will be resolved and allowed through the firewall</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><select style='width: 13em;' name='template'>\n";

		foreach my $tmp ("alert.txt","tracking.txt","connectiontracking.txt","processtracking.txt","accounttracking.txt","usertracking.txt","sshalert.txt","webminalert.txt","sualert.txt","sudoalert.txt","uialert.txt","cpanelalert.txt","scriptalert.txt","filealert.txt","watchalert.txt","loadalert.txt","resalert.txt","integrityalert.txt","exploitalert.txt","relayalert.txt","portscan.txt","uidscan.txt","permblock.txt","netblock.txt","queuealert.txt","logfloodalert.txt","logalert.txt","modsecipdbcheck.txt") {print "<option>$tmp</option>\n"}

		print "</select> <button name='action' value='templates' type='submit' class='btn btn-edit'>Edit</button></form></td><td style='width:100%'>Edit email alert templates. See Firewall Information for details of each file</td></tr>\n";

		print "<tr><td><form action='$script' method='post'><button name='action' value='logfiles' type='submit' class='btn btn-default'>lfd Log Scanner Files</button></form></td><td style='width:100%'>Edit the Log Scanner file (csf.logfiles) - Scan listed log files for log lines and periodically send a report</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='blocklists' type='submit' class='btn btn-default'>lfd Blocklists</button></form></td><td style='width:100%'>Edit the Blocklists configuration file (csf.blocklists)</td></tr>\n";
		print "<tr><td><form action='$script' method='post'><button name='action' value='syslogusers' type='submit' class='btn btn-default'>lfd Syslog Users</button></form></td><td style='width:100%'>Edit the syslog/rsyslog allowed users file (csf.syslogusers)</td></tr>\n";
		print "</table>\n";
		print "</div>\n";

		if ($config{CLUSTER_SENDTO}) {
			print "<div id='cluster' class='tab-pane active'>\n";
			print "<table class='table table-bordered table-striped'>\n";
			print "<thead><tr><th colspan='2'>csf - ConfigServer lfd Cluster</th></tr></thead>";

			print "<tr><td><form action='$script' method='post'><button name='action' value='cping' type='submit' class='btn btn-default'>Cluster PING</button></form></td><td style='width:100%'>Ping each member of the cluster (logged in lfd.log)</td></tr>\n";
			print "<tr><td><button onClick='\$(\"#callow\").submit();' class='btn btn-default'>Cluster Allow</button></td><td style='width:100%'><form action='$script' method='post' id='callow'><input type='submit' class='hide'><input type='hidden' name='action' value='callow'>Allow IP address <input type='text' name='ip' value='' size='18' style='background-color: lightgreen'> through the Cluster and add to the allow file (csf.allow)<br>Comment: <input type='text' name='comment' value='' size='30'></form></td></tr>\n";
			print "<tr><td><button onClick='\$(\"#cdeny\").submit();' class='btn btn-default'>Cluster Deny</button></td><td style='width:100%'><form action='$script' method='post' id='cdeny'><input type='submit' class='hide'><input type='hidden' name='action' value='cdeny'>Block IP address <input type='text' name='ip' value='' size='18' style='background-color: pink'> in the Cluster and add to the deny file (csf.deny)<br>Comment: <input type='text' name='comment' value='' size='30'></form></td></tr>\n";
			print "<tr><td><button onClick='\$(\"#cignore\").submit();' class='btn btn-default'>Cluster Ignore</button></td><td style='width:100%'><form action='$script' method='post' id='cignore'><input type='submit' class='hide'><input type='hidden' name='action' value='cignore'>Ignore IP address <input type='text' name='ip' value='' size='18'> in the Cluster and add to the ignore file (csf.ignore)<br>Comment: <input type='text' name='comment' value='' size='30'> Note: This will result in lfd being restarted</form></td></tr>\n";
			print "<tr><td><button onClick='\$(\"#cgrep\").submit();' class='btn btn-default'>Search the Cluster for IP</button></td><td style='width:100%'><form action='$script' method='post' id='cgrep'><input type='submit' class='hide'><input type='hidden' name='action' value='cgrep'>Search iptables for IP address <input type='text' name='ip' value='' size='18'></form></td></tr>\n";
			print "<tr><td><button onClick='\$(\"#ctempdeny\").submit();' class='btn btn-default'>Cluster Temp Allow/Deny</button></td><td style='width:100%'><form action='$script' method='post' id='ctempdeny'><input type='submit' class='hide'><input type='hidden' name='action' value='ctempdeny'>Temporarily <select name='do'><option>block</option><option>allow</option></select> IP address <input type='text' name='ip' value='' size='18'> to port(s) <input type='text' name='ports' value='*' size='5'> for <input type='text' name='timeout' value='' size='4'> <select name='dur'><option>seconds</option><option>minutes</option><option>hours</option><option>days</option></select>.<br>Comment: <input type='text' name='comment' value='' size='30'><br>\n(ports can be either * for all ports, a single port, or a comma separated list of ports)</form></td></tr>\n";
			print "<tr><td><button onClick='\$(\"#crm\").submit();' class='btn btn-default'>Cluster Remove Deny</button></td><td style='width:100%'><form action='$script' method='post' id='crm'><input type='submit' class='hide'><input type='hidden' name='action' value='crm'>Remove Deny IP address <input type='text' name='ip' value='' size='18' style=''> in the Cluster (temporary or permanent)</form></td></tr>\n";
			print "<tr><td><button onClick='\$(\"#carm\").submit();' class='btn btn-default'>Cluster Remove Allow</button></td><td style='width:100%'><form action='$script' method='post' id='carm'><input type='submit' class='hide'><input type='hidden' name='action' value='carm'>Remove Allow IP address <input type='text' name='ip' value='' size='18' style=''> in the Cluster (temporary or permanent)</form></td></tr>\n";
			print "<tr><td><button onClick='\$(\"#cirm\").submit();' class='btn btn-default'>Cluster Remove Ignore</button></td><td style='width:100%'><form action='$script' method='post' id='cirm'><input type='submit' class='hide'><input type='hidden' name='action' value='cirm'>Remove Ignore IP address <input type='text' name='ip' value='' size='18'> in the Cluster<br>Note: This will result in lfd being restarted</form></td></tr>\n";

			if ($config{CLUSTER_CONFIG}) {
				if ($ips{$config{CLUSTER_MASTER}} or $ipscidr6->find($config{CLUSTER_MASTER}) or ($config{CLUSTER_MASTER} eq $config{CLUSTER_NAT})) {
					my $options;
					my %restricted;
					if ($config{RESTRICT_UI}) {
						sysopen (my $IN, "/usr/local/csf/lib/restricted.txt", O_RDWR | O_CREAT) or die "Unable to open file: $!";
						flock ($IN, LOCK_SH);
						while (my $entry = <$IN>) {
							chomp $entry;
							$restricted{$entry} = 1;
						}
						close ($IN);
					}
					foreach my $key (sort keys %config) {
						unless ($restricted{$key}) {$options .= "<option>$key</option>"}
					}
					print "<tr><td><button onClick='\$(\"#cconfig\").submit();' class='btn btn-default'>Cluster Config</button></td><td style='width:100%'><form action='$script' method='post' id='cconfig'><input type='submit' class='hide'><input type='hidden' name='action' value='cconfig'>Change configuration option <select name='option'>$options</select> to <input type='text' name='value' value='' size='18'> in the Cluster";
					if ($config{RESTRICT_UI}) {print "<br />\nSome items have been removed with RESTRICT_UI enabled"}
					print "</form></td></tr>\n";
					print "<tr><td><form action='$script' method='post'><button name='action' value='crestart' type='submit' class='btn btn-default'>Cluster Restart</button></form></td><td style='width:100%'>Restart csf and lfd on Cluster members</td></tr>\n";
				}
			}
			print "</table>\n";
			print "</div>\n";
		}

		print "<div id='other' class='tab-pane active'>\n";
		if ($config{CF_ENABLE}) {
			print "<table class='table table-bordered table-striped'>\n";
			print "<thead><tr><th colspan='2'>CloudFlare Firewall</th></tr></thead>";
			print "<tr><td><form action='$script' method='post'><button name='action' value='cloudflare' type='submit' class='btn btn-default'>CloudFlare</button></form></td><td style='width:100%'>Access CloudFlare firewall functionality</td></tr>\n";
			print "<tr><td><form action='$script' method='post'><button name='action' value='cloudflareedit' type='submit' class='btn btn-default'>CloudFlare Config</button></form></td><td style='width:100%'>Edit the CloudFlare Configuration file (csf.cloudflare)</td></tr>\n";
			print "</table>\n";
		}
		if ($config{SMTPAUTH_RESTRICT}) {
			print "<table class='table table-bordered table-striped'>\n";
			print "<thead><tr><th colspan='2'>cPanel SMTP AUTH Restrictions</th></tr></thead>";
			print "<tr><td><form action='$script' method='post'><button name='action' value='smtpauth' type='submit' class='btn btn-default'>Edit SMTP AUTH</button></form></td><td style='width:100%'>Edit the file that allows SMTP AUTH to be advertised to listed IP addresses (csf.smtpauth)</td></tr>\n";
			print "</table>\n";
		}

		if (-e "/usr/local/cpanel/version" or $config{DIRECTADMIN} or $config{INTERWORX}) {
			my $resellers = "cPanel Resellers";
			if ($config{DIRECTADMIN}) {$resellers = "DirectAdmin Resellers"}
			elsif ($config{INTERWORX}) {$resellers = "InterWorx Resellers"}
			print "<table class='table table-bordered table-striped'>\n";
			print "<thead><tr><th colspan='2'>$resellers</th></tr></thead>";
			print "<tr><td><form action='$script' method='post'><button name='action' value='reseller' type='submit' class='btn btn-default'>Edit Reseller Privs</button></form></td><td style='width:100%'>Privileges can be assigned to $resellers accounts by editing this file (csf.resellers)</td></tr>\n";
			print "</table>\n";
		}

		print "<table class='table table-bordered table-striped'>\n";
		print "<thead><tr><th colspan='2'>Extra</th></tr></thead>";
		print "<tr><td><form action='$script' method='post'><button name='action' value='csftest' type='submit' class='btn btn-default'>Test iptables</button></form></td><td style='width:100%'>Check that iptables has the required modules to run csf</td></tr>\n";
		print "</table>\n";
#		if ($config{DIRECTADMIN} and !$config{THIS_UI}) {
#			print "<a href='/' class='btn btn-success' data-spy='affix' data-offset-bottom='0' style='bottom: 0; left:45%'><span class='glyphicon glyphicon-home'></span> DirectAdmin Main Page</a>\n";
#		}
		print "</div>\n</div>\n";

		if ($config{STYLE_MOBILE}) {
			if (-e "/usr/local/cpanel/version" and !$config{THIS_UI}) {
				require Cpanel::Version::Tiny;
				if ($Cpanel::Version::Tiny::major_version < 65) {
					print "<a id='cpframetr2' href='$ENV{cp_security_token}' class='btn btn-success' data-spy='affix' data-offset-bottom='0' style='bottom: 0; left:45%'><span class='glyphicon glyphicon-home'></span> cPanel Main Page</a>\n";
				}
			}

			if  (defined $ENV{WEBMIN_VAR} and defined $ENV{WEBMIN_CONFIG} and !$config{THIS_UI}) {
				print "<a id='webmintr2' href='/' class='btn btn-success' data-spy='affix' data-offset-bottom='0' style='bottom: 0; left:45%'><span class='glyphicon glyphicon-home'></span> Webmin Main Page</a>\n";
			}


			# </div> closes 'normalcontainer'
			print "</div>\n<div class='mobilecontainer'>\n";

			print "<form action='$script' method='post'>\n";
			print "<div class='form-group' style='width:100%'>\n";
			print "<p><input id='ip' type='text' placeholder='IP Address' class='form-control input-ipaddr form-mobile-ip-textbox' name='ip'></p>\n";
			print "<p><button class='btn btn-primary btn-lg btn-block btn-allow' type='submit' name='action' value='qallow'>Quick Allow IP</button></p>\n";
			print "<p><button class='btn btn-primary btn-lg btn-block btn-deny' type='submit' name='action' value='qdeny'>Quick Deny IP</button></p>\n";
			print "<p><button class='btn btn-primary btn-lg btn-block' type='submit' name='action' value='qignore'>Quick Ignore IP</button></p>\n";
			print "<p><button class='btn btn-primary btn-lg btn-block' type='submit' name='action' value='kill'>Quick Unblock IP</button></p>\n";
			print "<p><button class='btn btn-primary btn-lg btn-block' type='submit' name='action' value='grep'>Search for IP</button></p>\n";
			print "</div>\n";
			print "<br><div class='form-group'>\n";
			print "<p><button class='btn btn-success btn-lg btn-block' type='submit' name='action' value='enable'>Firewall Enable</button></p>\n";
			print "<p><button class='btn btn-danger btn-lg btn-block' type='submit' name='action' value='disable'>Firewall Disable</button></p>\n";
			print "<p><br></p>\n";
			print "<p><button class='btn btn-warning btn-lg btn-block' type='submit' name='action' value='restart'>Firewall Restart</button></p>\n";
			print "<p><button class='btn btn-primary btn-lg btn-block' type='submit' name='action' value='denyf'>Flush all Blocks</button></p>\n";
			print "</div>\n";
			print "</form>\n";

			if (-e "/usr/local/cpanel/version" and !$config{THIS_UI}) {
				if ($Cpanel::Version::Tiny::major_version < 65) {
					print "<br><p><a href='$ENV{cp_security_token}' class='btn btn-info btn-lg btn-block'><span class='glyphicon glyphicon-home'></span> cPanel Main Page</a></p>\n";
				}
			}
#			if  ($config{DIRECTADMIN} and !$config{THIS_UI}) {
#				print "<br><p id='cpframe'><a href='/' class='btn btn-info btn-lg btn-block'><span class='glyphicon glyphicon-home'></span> DirectAdmin Main Page</a></p>\n";
#			}
			if (defined $ENV{WEBMIN_VAR} and defined $ENV{WEBMIN_CONFIG} and !$config{THIS_UI}) {
				print "<br><p><a href='/' class='btn btn-info btn-lg btn-block'><span class='glyphicon glyphicon-home'></span> Webmin Main Page</a></p>\n";
			}

			print "<br><p><button class='btn btn-info btn-lg btn-block btn-desktop-view' id='NormalView'>Desktop View</button></p>\n";
			print "</div>\n<div><br>\n";
		}

		print "<div class='panel panel-info'>\n";
		print "<div class='panel-heading'>Development Contribution</div>";
		print "<div class='panel-body'>We are very happy to be able to provide this and other products for free. However, it does take time for us to develop and maintain them. If you would like to help with their development by providing a PayPal contribution, please <a href='mailto:sales\@waytotheweb.com?Subject=ConfigServer%20Contribution'>contact us</a> for details</div>\n";
		print "</div>\n";

	}

	unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
		print "<br>\n";
		print "<div class='well well-sm'>csf: v$myv</div>";
		print "<div class='copy-left'>&copy;2006-$year, <a href='http://configserver.com' target='_blank'>ConfigServer Services</a> (Way to the Web Limited)</div><div class='copy-right'><a href='$th_dark_url'>Dark Theme</a> v$th_dark_version by Aetherinox</div><div class='clear'></div>";
		print "</div>\n";
		print "<div style='padding-bottom: 50px;'></div>";
	}

	return;
}
# end main
###############################################################################
# start printcmd
sub printcmd {
	my @command = @_;

	my ($childin, $childout);
	my $pid = open3($childin, $childout, $childout, @command);
	while (<$childout>) {print $_}
	waitpid ($pid, 0);

	return;
}
# end printcmd
###############################################################################
# start getethdev
sub getethdev {
	my $ethdev = ConfigServer::GetEthDev->new();
	my %g_ipv4 = $ethdev->ipv4;
	my %g_ipv6 = $ethdev->ipv6;
	foreach my $key (keys %g_ipv4) {
		$ips{$key} = 1;
	}
	if ($config{IPV6}) {
		foreach my $key (keys %g_ipv6) {
			eval {
				local $SIG{__DIE__} = undef;
				$ipscidr6->add($key);
			};
		}
	}

	return;
}
# end getethdev
###############################################################################
# start chart
sub chart {
	my $img;
	my $imgdir = "";
	my $imghddir = "";
	if (-e "/usr/local/cpanel/version") {
		$imgdir = "/";
		$imghddir = "";
	}
	elsif (-e "/usr/local/directadmin/conf/directadmin.conf") {
		$imgdir = "/CMD_PLUGINS_ADMIN/csf/images/";
		$imghddir = "plugins/csf/images/";
		umask(0133);
	}
	elsif (-e "/usr/local/interworx") {
		$imgdir = "/configserver/csf/";
		$imghddir = "/usr/local/interworx/html/configserver/csf/";
		umask(0133);
	}
	elsif (-e "/usr/local/CyberCP/") {
		$imgdir = "/static/configservercsf/";
		$imghddir = "/usr/local/CyberCP/public/static/configservercsf/";
		umask(0133);
	}
	if ($config{THIS_UI}) {
		$imgdir = "$images/";
		$imghddir = "/etc/csf/ui/images/";
	}

	my $STATS;
	if (-e "/var/lib/csf/stats/lfdstats") {
		sysopen ($STATS,"/var/lib/csf/stats/lfdstats", O_RDWR | O_CREAT);
	}
	elsif (-e "/var/lib/csf/stats/lfdmain") {
		sysopen (my $OLDSTATS,"/var/lib/csf/stats/lfdmain", O_RDWR | O_CREAT);
		flock ($OLDSTATS, LOCK_EX);
		my @stats = <$OLDSTATS>;
		chomp @stats;

		my @newstats;
		my $cnt = 0;
		foreach my $line (@stats) {
			if ($cnt == 55) {push @newstats,""}
			push @newstats,$line;
			$cnt++;
		}
		sysopen ($STATS,"/var/lib/csf/stats/lfdstats", O_RDWR | O_CREAT);
		flock ($STATS, LOCK_EX);
		seek ($STATS, 0, 0);
		truncate ($STATS, 0);
		foreach my $line (@newstats) {
			print $STATS "$line\n";
		}
		close ($STATS);

		rename "/var/lib/csf/stats/lfdmain", "/var/lib/csf/stats/lfdmain.".time;
		close ($OLDSTATS);
		sysopen ($STATS,"/var/lib/csf/stats/lfdstats", O_RDWR | O_CREAT);
	} else {
		sysopen ($STATS,"/var/lib/csf/stats/lfdstats", O_RDWR | O_CREAT);
	}
	flock ($STATS, LOCK_SH);
	my @stats = <$STATS>;
	chomp @stats;
	close ($STATS);

	if (@stats) {
		ConfigServer::ServerStats::charts($config{CC_LOOKUPS},$imghddir);
		print ConfigServer::ServerStats::charts_html($config{CC_LOOKUPS},$imgdir);
	} else {
		print "<table class='table table-bordered table-striped'>\n";
		print "<tr><td>No statistical data has been collected yet</td></tr></table>\n";
	}
	&printreturn;

	return;
}
# end chart
###############################################################################
# start systemstats
sub systemstats {
	my $type = shift;
	if ($type eq "") {$type = "load"}
	my $img;
	my $imgdir = "";
	my $imghddir = "";
	if (-e "/usr/local/cpanel/version") {
		if (-e "/usr/local/cpanel/bin/register_appconfig") {
			$imgdir = "csf/";
			$imghddir = "cgi/configserver/csf/";
		} else {
			$imgdir = "/";
			$imghddir = "";
		}
	}
	elsif (-e "/usr/local/directadmin/conf/directadmin.conf") {
		$imgdir = "/CMD_PLUGINS_ADMIN/csf/images/";
		$imghddir = "plugins/csf/images/";
		umask(0133);
	}
	elsif (-e "/usr/local/interworx") {
		$imgdir = "/configserver/csf/";
		$imghddir = "/usr/local/interworx/html/configserver/csf/";
		umask(0133);
	}
	elsif (-e "/usr/local/CyberCP/") {
		$imgdir = "/static/configservercsf/";
		$imghddir = "/usr/local/CyberCP/public/static/configservercsf/";
		umask(0133);
	}
	if ($config{THIS_UI}) {
		$imgdir = "$images/";
		$imghddir = "/etc/csf/ui/images/";
	}
	if (defined $ENV{WEBMIN_VAR} and defined $ENV{WEBMIN_CONFIG}) {
		$imgdir = "/csf/";
		$imghddir = "";
	}

	sysopen (my $STATS,"/var/lib/csf/stats/system", O_RDWR | O_CREAT);
	flock ($STATS, LOCK_SH);
	my @stats = <$STATS>;
	chomp @stats;
	close ($STATS);

	if (@stats > 1) {
		ConfigServer::ServerStats::graphs($type,$config{ST_SYSTEM_MAXDAYS},$imghddir);

		print "<div class='text-center'><form action='$script' method='post'><input type='hidden' name='action' value='systemstats'><select name='graph'>\n";
		my $selected;
		if ($type eq "" or $type eq "load") {$selected = "selected"} else {$selected = ""}
		print "<option value='load' $selected>Load Average Statistics</option>\n";
		if ($type eq "cpu") {$selected = "selected"} else {$selected = ""}
		print "<option value='cpu' $selected>CPU Statistics</option>\n";
		if ($type eq "mem") {$selected = "selected"} else {$selected = ""}
		print "<option value='mem' $selected>Memory Statistics</option>\n";
		if ($type eq "net") {$selected = "selected"} else {$selected = ""}
		print "<option value='net' $selected>Network Statistics</option>\n";
		if (-e "/proc/diskstats") {
			if ($type eq "disk") {$selected = "selected"} else {$selected = ""}
			print "<option value='disk' $selected>Disk Statistics</option>\n";
		}
		if ($config{ST_DISKW}) {
			if ($type eq "diskw") {$selected = "selected"} else {$selected = ""}
			print "<option value='diskw' $selected>Disk Write Performance</option>\n";
		}
		if (-e "/var/lib/csf/stats/email") {
			if ($type eq "email") {$selected = "selected"} else {$selected = ""}
			print "<option value='email' $selected>Email Statistics</option>\n";
		}
		my $dotemp = 0;
		if (-e "/sys/devices/platform/coretemp.0/temp3_input") {$dotemp = 3}
		if (-e "/sys/devices/platform/coretemp.0/temp2_input") {$dotemp = 2}
		if (-e "/sys/devices/platform/coretemp.0/temp1_input") {$dotemp = 1}
		if ($dotemp) {
			if ($type eq "temp") {$selected = "selected"} else {$selected = ""}
			print "<option value='temp' $selected>CPU Temperature</option>\n";
		}
		if ($config{ST_MYSQL}) {
			if ($type eq "mysqldata") {$selected = "selected"} else {$selected = ""}
			print "<option value='mysqldata' $selected>MySQL Data</option>\n";
			if ($type eq "mysqlqueries") {$selected = "selected"} else {$selected = ""}
			print "<option value='mysqlqueries' $selected>MySQL Queries</option>\n";
			if ($type eq "mysqlslowqueries") {$selected = "selected"} else {$selected = ""}
			print "<option value='mysqlslowqueries' $selected>MySQL Slow Queries</option>\n";
			if ($type eq "mysqlconns") {$selected = "selected"} else {$selected = ""}
			print "<option value='mysqlconns' $selected>MySQL Connections</option>\n";
		}
		if ($config{ST_APACHE}) {
			if ($type eq "apachecpu") {$selected = "selected"} else {$selected = ""}
			print "<option value='apachecpu' $selected>Apache CPU Usage</option>\n";
			if ($type eq "apacheconn") {$selected = "selected"} else {$selected = ""}
			print "<option value='apacheconn' $selected>Apache Connections</option>\n";
			if ($type eq "apachework") {$selected = "selected"} else {$selected = ""}
			print "<option value='apachework' $selected>Apache Workers</option>\n";
		}
		print "</select> <input type='submit' class='btn btn-default' value='Select Graphs'></form></div><br />\n";

		print ConfigServer::ServerStats::graphs_html($imgdir);

		unless ($config{ST_MYSQL} and $config{ST_APACHE}) {
			print "<br>\n<table class='table table-bordered table-striped'>\n";
			print "<tr><td>You may be able to collect more statistics by enabling ST_MYSQL or ST_APACHE in the csf configuration</td></tr></table>\n";
		}
	} else {
		print "<table class='table table-bordered table-striped'>\n";
		print "<tr><td>No statistical data has been collected yet</td></tr></table>\n";
	}
	&printreturn;

	return;
}

# #
#	File > Edit
# #

sub editfile
{
	my $file = shift;
	my $save = shift;
	my $extra = shift;
	my $ace = 0;

	sysopen (my $IN, $file, O_RDWR | O_CREAT) or die "Unable to open file: $!";
	flock ($IN, LOCK_SH);

	my @confdata = <$IN>;

	close ($IN);
	chomp @confdata;

	if ( -e "/usr/local/cpanel/3rdparty/share/ace-editor/optimized/src-min-noconflict/ace.js") {$ace = 1}

	if ( -e "/usr/local/cpanel/version" and $ace and !$config{THIS_UI} )
	{
		print "<script src='/libraries/ace-editor/optimized/src-min-noconflict/ace.js'></script>\n";
		print "<h4>Edit <code>$file</code></h4>\n";
		print "<button class='btn btn-default' id='toggletextarea-btn'>Toggle Editor/Textarea</button>\n";
		print " <div class='pull-right btn-group'><button class='btn btn-default' id='fontminus-btn'><strong>a</strong><span class='glyphicon glyphicon-arrow-down icon-configserver'></span></button>\n";
		print "<button class='btn btn-default' id='fontplus-btn'><strong>A</strong><span class='glyphicon glyphicon-arrow-up icon-configserver'></span></button></div>\n";
		print "<form action='$script' method='post'>\n";
		print "<input type='hidden' name='action' value='$save'>\n";
		print "<input type='hidden' name='ace' value='1'>\n";
		if ($extra) {print "<input type='hidden' name='$extra' value='$FORM{$extra}'>\n";}
		print "<div id='editor' style='width:100%;height:500px;border: 1px solid #000;display:none;'>";
		print "Loading...</div>\n";
		print "<div id='textarea'><textarea class='textarea' name='formdata' id='formdata' style='width:100%;height:500px;border: 1px solid #000;font-family:\"Courier New\", Courier;font-size:14px;line-height:1.1' wrap='off'>";
		print "# Do not remove or change this line as it is a safeguard for the UI editor\n";
		foreach my $line (@confdata) {
			$line =~ s/\</\&lt\;/g;
			$line =~ s/\>/\&gt\;/g;
			print $line."\n";
		}
		print "</textarea><br></div>\n";
		print "<br><div class='text-center'><input type='submit' class='btn btn-default' value='Change'></div>\n";
		print "</form>\n";
		print <<EOF;
<script>
	var myFont = 14;
	var textarea = \$('#formdata');
	var editordiv = \$('#editor');
	var editor = ace.edit("editor");
	editor.setTheme("ace/theme/tomorrow");
	editor.setShowPrintMargin(false);
	editor.setOptions({
		fontFamily: "Courier New, Courier",
		fontSize: "14px"
	});
	editor.getSession().setMode("ace/mode/space");

	editor.getSession().on('change', function () {
		textarea.val(editor.getSession().getValue());
	});

	textarea.on('change', function () {
		editor.getSession().setValue(textarea.val());
	});

	editor.getSession().setValue(textarea.val());
	\$('#textarea').hide();
	editordiv.show();

	\$("#toggletextarea-btn").on('click', function () {
		\$('#textarea').toggle();
		editordiv.toggle();
	});
	\$("#fontplus-btn").on('click', function () {
		myFont++;
		if (myFont > 20) {myFont = 20}
		editor.setFontSize(myFont)
		textarea.css("font-size",myFont+"px");
	});
	\$("#fontminus-btn").on('click', function () {
		myFont--;
		if (myFont < 12) {myFont = 12}
		editor.setFontSize(myFont)
		textarea.css("font-size",myFont+"px");
	});
</script>
EOF
	} else {
		if ($config{DIRECTADMIN})
		{
			print "<form action='$script?pipe_post=yes' method='post'>\n<div class='panel panel-default'>\n";
		}
		else
		{
			print "<form action='$script' method='post'>\n<div class='panel panel-default'>\n";
		}

		print "<div class='panel-heading panel-heading-cxs'>Edit <code>$file</code></div>\n";
		print "<div class='panel-body'>\n";
		print "<input type='hidden' name='action' value='$save'>\n";
		if ($extra) {print "<input type='hidden' name='$extra' value='$FORM{$extra}'>\n";}
		print "<textarea class='textarea' name='formdata' style='width:100%;height:500px;border: 1px solid #000;' wrap='off'>";

		foreach my $line (@confdata)
		{
			$line =~ s/\</\&lt\;/g;
			$line =~ s/\>/\&gt\;/g;
			print $line."\n";
		}

		print "</textarea></div>\n";
		print "<div class='panel-footer text-center'><input type='submit' class='btn btn-default' value='Change'></div>\n";
		print "</div></form>\n";
	}

	return;
}

# #
#	File > Save
# #

sub savefile
{
	my $file = shift;
	my $restart = shift;

	$FORM{formdata} =~ s/\r//g;
	if ($FORM{ace} == "1")
	{
		if ($FORM{formdata} !~ /^# Do not remove or change this line as it is a safeguard for the UI editor\n/) {
			print "<div>UI editor safeguard missing, changes have not been saved.</div>\n";
			return;
		}
		$FORM{formdata} =~ s/^# Do not remove or change this line as it is a safeguard for the UI editor\n//g;
	}

	sysopen (my $OUT, $file, O_WRONLY | O_CREAT) or die "Unable to open file: $!";
	flock ($OUT, LOCK_EX);
	seek ($OUT, 0, 0);
	truncate ($OUT, 0);
	if ($FORM{formdata} !~ /\n$/) {$FORM{formdata} .= "\n"}
	print $OUT $FORM{formdata};
	close ($OUT);

	if ($restart eq "csf")
	{
		print "<div>Changes saved. You should restart csf.</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restart'><input type='submit' class='btn btn-default' value='Restart csf'></form></div>\n";
	}
	elsif ($restart eq "lfd")
	{
		print "<div>Changes saved. You should restart lfd.</div>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='lfdrestart'><input type='submit' class='btn btn-default' value='Restart lfd'></form></div>\n";
	}
	elsif ($restart eq "both") {
		print "<div>Changes saved. You should restart csf and lfd.</p>\n";
		print "<div><form action='$script' method='post'><input type='hidden' name='action' value='restartboth'><input type='submit' class='btn btn-default' value='Restart csf+lfd'></form></div>\n";
	}
	else
	{
		print "<div>Changes saved.</div>\n";
	}

	return;
}

# #
#	Cloudflare
# #

sub cloudflare
{
	my $scope = &ConfigServer::CloudFlare::getscope();
	print "<link rel='stylesheet' href='$images/bootstrap-chosen.css'>\n";
	print "<script src='$images/chosen.min.js'></script>\n";
	print "<script>\n";
	print "\$(function() {\n";
	print "  \$('.chosen-select').chosen();\n";
	print "  \$('.chosen-select-deselect').chosen({ allow_single_deselect: true });\n";
	print "});\n";
	print "</script>\n";

	print "<table class='table table-bordered table-striped'>\n";
	print "<thead><tr><th colspan='2'>csf - CloudFlare</th></tr></thead>";
	print "<tr><td>Select the user(s), then select the action below</td><td style='width:100%'><select data-placeholder='Select user(s)' class='chosen-select' id='domains' name='domains' multiple>\n";
	foreach my $user (keys %{$scope->{user}}) {print "<option>$user</option>\n"}
	print "</select></td></tr>\n";
#	} else {
#		print "<tr><td>Select the domain(s), then select the action below</td><td style='width:100%'><select data-placeholder='Select domain(s)' class='chosen-select' id='domains' name='domains' multiple>\n";
#		foreach my $domain (keys %{$scope->{domain}}) {print "<option>$domain</option>\n"}
#		print "</select></td></tr>\n";
#	}
	print "<tr><td><button type='button' id='cflistbtn' class='btn btn-default' disabled='true'>CF List Rules</button></td><td style='width:100%'><form action='#' id='cflist'>List <select name='type' id='type'><option>all</option><option>block</option><option>challenge</option><option>whitelist</option></select> rules in CloudFlare ONLY for the chosen accounts</form></td></tr>";
	print "<tr><td><button type='button' id='cfaddbtn' class='btn btn-default' disabled='true'>CloudFlare Add</button></td><td style='width:100%'><form action='#' id='cfadd'>Add <select name='type' id='type'><option>block</option><option>challenge</option><option>whitelist</option></select> rule for target <input type='text' name='target' value='' size='18' id='target'> in CloudFlare ONLY for the chosen accounts</form></td></tr>\n";
	print "<tr><td><button type='button' id='cfremovebtn' class='btn btn-default' disabled='true'>CloudFlare Delete</button></td><td style='width:100%'><form action='#' id='cfremove'>Delete rule for target <input type='text' name='target' value='' size='18' id='target'> in CloudFlare ONLY</form></td></tr>\n";
	print "<tr><td><button type='button' id='cftempdenybtn' class='btn btn-default' disabled='true'>CF Temp Allow/Deny</button></td><td style='width:100%'><form action='#' id='cftempdeny'>Temporarily <select name='do' id='do'><option>allow</option><option>deny</option></select> IP address <input type='text' name='target' value='' size='18' id='target'> for $config{CF_TEMP} secs in CloudFlare AND csf for the chosen accounts and those with to \"any\"</form></td></tr>";
	print "</table>\n";

	print "<div id='CFajax'><div class='panel panel-info'><div class='panel-heading'>Output will appear here</div></div></div>\n";
	print "<div class='bs-callout bs-callout-success'>Note:\n<ul>\n";
	print "<li><mark>target</mark> can be one of:<ul><li>An IP address</li>\n<li>2 letter Country Code</li>\n<li>IP range CIDR</li></ul>\n</li>\n";
	print "<li>Only Enterprise customers can <mark>block</mark> a Country Code, but all can <mark>allow</mark> and <mark>challenge</mark>\n";
	print "<li>\nIP range CIDR is limited to /16 and /24</blockquote></li></ul></div>\n";
	print "<script>\n";
	print "\$(document).ready(function(){\n";
	print "	\$('#cflist').submit(function(){\$('#cflistbtn').click(); return false})\n";
	print "	\$('#cftempdeny').submit(function(){\$('#cftempdenybtn').click(); return false})\n";
	print "	\$('#cfadd').submit(function(){\$('#cfaddbtn').click(); return false})\n";
	print "	\$('#cfremove').submit(function(){\$('#cfremovebtn').click(); return false})\n";
	print "	\$('button').click(function(){\n";
	print "		\$('body').css('cursor', 'progress');\n";
	print "		var myurl;\n";
	print "		if (this.id == 'cflistbtn') {myurl = '$script?action=cflist&type='+\$(\"#cflist #type\").val()+'&domains='+\$(\"#domains\").val();}\n";
	print "		if (this.id == 'cftempdenybtn') {myurl = '$script?action=cftempdeny&do='+\$(\"#cftempdeny #do\").val()+'&target='+\$(\"#cftempdeny #target\").val().replace(/\\s/g,'')+'&domains='+\$(\"#domains\").val();}\n";
	print "		if (this.id == 'cfaddbtn') {myurl = '$script?action=cfadd&type='+\$(\"#cfadd #type\").val()+'&target='+\$(\"#cfadd #target\").val().replace(/\\s/g,'')+'&domains='+\$(\"#domains\").val();}\n";
	print "		if (this.id == 'cfremovebtn') {myurl = '$script?action=cfremove&target='+\$(\"#cfremove #target\").val().replace(/\\s/g,'')+'&domains='+\$(\"#domains\").val();}\n";
#	print "		alert('URL:'+myurl);\n";
	print "		\$('#CFajax').html('<div id=\"loader\"></div><div class=\"panel panel-info\"><div class=\"panel-heading\">Loading...</div></div>');\n";
	print "		\$('#CFajax').load(myurl);\n";
	print "		\$('body').css('cursor', 'default');\n";
	print "	});\n";
	print "	\$('#domains').on('keyup change',function() {\n";
	print "		if (\$('#domains').val() == null) {\n";
	print "			\$('#cflistbtn,#cftempdenybtn,#cfaddbtn,#cfremovebtn').prop('disabled', true);\n";
	print "		} else {\n";
	print "			\$('#cflistbtn,#cftempdenybtn,#cfaddbtn,#cfremovebtn').prop('disabled', false);\n";
	print "		}\n";
	print "	});\n";
	print "});\n";
	print "</script>\n";
	&printreturn;
	return;
}

# end cloudflare
###############################################################################
# start resize

sub resize
{
	my $part = shift;
	my $scroll = shift;
	if ($part eq "top")
	{
		print "<div class='pull-right btn-group'><button class='btn btn-default' id='fontminus-btn'><strong>a</strong><span class='glyphicon glyphicon-arrow-down icon-configserver'></span></button>\n";
		print "<button class='btn btn-default' id='fontplus-btn'><strong>A</strong><span class='glyphicon glyphicon-arrow-up icon-configserver'></span></button></div>\n";
	}
	else
	{
		print "<script>\n";
		if ($scroll)
		{
			print "\$('#output').scrollTop(\$('#output')[0].scrollHeight);\n";
		}

		print <<EOF;

	var myFont = 14;
	\$("#fontplus-btn").on('click', function () {
		myFont++;
		if (myFont > 20) {myFont = 20}
		\$('#output').css("font-size",myFont+"px");
	});
	\$("#fontminus-btn").on('click', function () {
		myFont--;
		if (myFont < 12) {myFont = 12}
		\$('#output').css("font-size",myFont+"px");
	});
</script>
EOF
	}
	return;
}

# #
#	Print Return
# #

sub printreturn
{
	print "<hr><div><form action='$script' method='post'><input type='hidden' name='mobi' value='$mobile'><input id='csfreturn' type='submit' class='btn btn-default' value='Return'></form></div>\n";

	return;
}

# #
#	Confirm Modal
#
#	start confirmmodal
#		print "<button type='button' class='btn btn-default confirmButton' data-query='Are you sure?' data-href='$script?action=fix' data-toggle='modal' data-target='#confirmmodal'>Submit</button>\n";
#		&confirmmodal;
# #

sub confirmmodal
{
	print "<div class='modal fade' id='confirmmodal' tabindex='-1' role='dialog' aria-labelledby='myModalLabel' aria-hidden='true' data-backdrop='false' style='background-color: rgba(0, 0, 0, 0.5)'>\n";
	print "<div class='modal-dialog modal-sm'>\n";
	print "<div class='modal-content'>\n";
	print "<div class='modal-body'>\n";
	print "<h4 id='modal-text'>text</h4>\n";
	print "</div>\n";
	print "<div class='modal-footer'>\n";
	print "<a id='modal-submit' href='#' class='btn btn-success'>Yes - Continue</a>\n";
	print "<button type='button' class='btn btn-danger' data-dismiss='modal'>No - Cancel</button>\n";
	print "</div>\n";
	print "</div>\n";
	print "</div>\n";
	print "</div>\n";
	print "<script>\n";
	print "	\$('button.confirmButton').on('click', function(e) {\n";
	print "	var dataquery = \$(this).attr('data-query');\n";
	print "	var datahref = \$(this).attr('data-href');\n";
	print "	\$('#modal-text').html(dataquery);\n";
	print "	\$('#modal-submit').attr({'href':datahref});\n";
	print "});\n";
	print "\$('.modal').click(function(event){\n";
	print "  \$(event.target).modal('hide')\n";
	print "});\n";
	print "</script>\n";

	return;
}

# #
#	Version > Get
# #

sub csgetversion
{
	my $product = shift;
	my $current = shift;
	my $upgrade = 0;
	my $newversion;

	if ( -e "/var/lib/configserver/" . $product . ".txt.error" )
	{
		open (my $VERSION, "<", "/var/lib/configserver/" . $product . ".txt.error");
		flock ($VERSION, LOCK_SH);

		$newversion = <$VERSION>;

		close ($VERSION);
		chomp $newversion;

		if ( $newversion eq "" )
		{
			$newversion = "Failed to retrieve latest version from ConfigServer";
		}
		else
		{
			$newversion = "Failed to retrieve latest version from ConfigServer: $newversion";
		}
	}
	elsif ( -e "/var/lib/configserver/" . $product . ".txt" )
	{
		open (my $VERSION, "<", "/var/lib/configserver/" . $product . ".txt");
		flock ($VERSION, LOCK_SH);
		$newversion = <$VERSION>;
		close ($VERSION);
		chomp $newversion;

		if ( $newversion eq "" )
		{
			$newversion = "Failed to retrieve latest version from ConfigServer";
		}
		else
		{
			if ( $newversion =~ /^[\d\.]*$/ )
			{
				if ( $newversion > $current )
				{
					$upgrade = 1
				}
				else
				{
					$newversion = ""
				}
			}
			else
			{
				$newversion = ""
			}
		}
	}
	elsif (-e "/var/lib/configserver/error")
	{
		open (my $VERSION, "<", "/var/lib/configserver/error");
		flock ($VERSION, LOCK_SH);

		$newversion = <$VERSION>;

		close ($VERSION);
		chomp $newversion;

		if ( $newversion eq "" )
		{
			$newversion = "Failed to retrieve latest version from ConfigServer";
		}
		else
		{
			$newversion = "Failed to retrieve latest version from ConfigServer: $newversion";
		}
	}
	else
	{
		$newversion = "Failed to retrieve latest version from ConfigServer";
	}

	return ( $upgrade, $newversion );
}

# #
#	Version > Get Manual
# #

sub manualversion
{
	my $current = shift;
	my $upgrade = 0;
	my $url = "https://$config{DOWNLOADSERVER}/csf/version.txt";

	if ( $config{URLGET} == 1 )
	{
		$url = "http://$config{DOWNLOADSERVER}/csf/version.txt";
	}

	my ( $status, $newversion ) = $urlget->urlget( $url );

	if ( !$status and $newversion ne "" and $newversion =~ /^[\d\.]*$/ and $newversion > $current )
	{
		$upgrade = 1
	}
	else
	{
		$newversion = ""
	}

	return ( $upgrade, $newversion );
}

1;
