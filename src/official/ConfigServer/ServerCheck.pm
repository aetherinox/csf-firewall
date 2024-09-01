###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::ServerCheck;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use File::Basename;
use IPC::Open3;
use ConfigServer::Slurp qw(slurp);
use ConfigServer::Sanity qw(sanity);;
use ConfigServer::Config;
use ConfigServer::GetIPs qw(getips);
use ConfigServer::CheckIP qw(checkip);
use ConfigServer::Service;
use ConfigServer::GetEthDev;

use Exporter qw(import);
our $VERSION     = 1.05;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my (%config, $cpconf, %daconfig, $cleanreg, $mypid, $childin, $childout,
    $verbose, $cpurl, @processes, $total, $failures, $current, $DEBIAN,
	$output, $sysinit, %g_ifaces, %g_ipv4, %g_ipv6);

my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

use Exporter qw(import);
# end main
###############################################################################
# start report
sub report {
	$verbose = shift;
	my $config = ConfigServer::Config->loadconfig();
	%config = $config->config();
	$cleanreg = ConfigServer::Slurp->cleanreg;
	$| = 1;

	if (defined $ENV{WEBMIN_VAR} and defined $ENV{WEBMIN_CONFIG}) {
		$config{GENERIC} = 1;
		$config{DIRECTADMIN} = 0;
	}
	elsif (-e "/usr/local/cpanel/version") {
		use lib "/usr/local/cpanel";
		require Cpanel::Form;
		import Cpanel::Form;
		require Cpanel::Config;
		import Cpanel::Config;
		$cpconf = Cpanel::Config::loadcpconf();
	}
	elsif (-e "/usr/local/directadmin/conf/directadmin.conf") {
		my ($childin, $childout);
		my $mypid = open3($childin, $childout, $childout, "/usr/local/directadmin/directadmin", "c");
		my @data = <$childout>;
		waitpid ($mypid, 0);
		chomp @data;
		foreach my $line (@data) {
			my ($name,$value) = split(/\=/,$line);
			$daconfig{lc($name)} = $value;
		}
		$config{DIRECTADMIN} = 1;
	}
	elsif (-e "/etc/psa/psa.conf") {
		$config{PLESK} = 1;
	}

	$failures = 0;
	$total = 0;
	if ($ENV{cp_security_token}) {$cpurl = $ENV{cp_security_token}}
	$DEBIAN = 0;
	if (-e "/etc/lsb-release" or -e "/etc/debian_version") {$DEBIAN = 1}

	$sysinit = ConfigServer::Service::type();
	if ($sysinit ne "systemd") {$sysinit = "init"}

	opendir (PROCDIR, "/proc");
	while (my $pid = readdir(PROCDIR)) {
		if ($pid !~ /^\d+$/) {next}
		push @processes, readlink("/proc/$pid/exe");
	}

	my $ethdev = ConfigServer::GetEthDev->new();
	%g_ifaces = $ethdev->ifaces;
	%g_ipv4 = $ethdev->ipv4;
	%g_ipv6 = $ethdev->ipv6;

	&startoutput;

	&firewallcheck;
	&servercheck;
	&sshtelnetcheck;
	unless ($config{DNSONLY} or $config{GENERIC}) {&mailcheck}
	unless ($config{DNSONLY} or $config{GENERIC}) {&apachecheck}
	unless ($config{DNSONLY} or $config{GENERIC}) {&phpcheck}
	unless ($config{DNSONLY} or $config{GENERIC}) {&whmcheck}
	if ($config{DIRECTADMIN}) {
		&mailcheck;
		&apachecheck;
		&phpcheck;
		&dacheck;
	}
	&servicescheck;

	&endoutput;
	return $output;
}
# end report
###############################################################################
# start startoutput
sub startoutput {
	if ($config{THIS_UI} and !$config{GENERIC}) {
		$output .= "<p align='center'><strong>Note: Internal WHM links will not work within the csf Integrated UI</strong></p>\n";
	}

	return;
}
# end startoutput
###############################################################################
# start addline
sub addline {
	my $status = shift;
	my $check = shift;
	my $comment = shift;
	$total++;

	if ($status) {
		$output .= "<div style='display: flex;width: 100%;clear: both;'>\n";
		$output .= "<div style='width: 250px;background: #FFD1DC;padding: 8px;border-bottom: 1px solid #DDDDDD;border-left: 1px solid #DDDDDD;border-right: 1px solid #DDDDDD;'>$check</div>\n";
		$output .= "<div style='flex: 1;padding: 8px;border-bottom: 1px solid #DDDDDD;border-right: 1px solid #DDDDDD;'>$comment</div>\n";
		$output .= "</div>\n";
		$failures ++;
		$current++;
	}
	elsif ($verbose) {
		$output .= "<div style='display: flex;width: 100%;clear: both;'>\n";
		$output .= "<div style='width: 250px;background: #BDECB6;padding: 8px;border-bottom: 1px solid #DDDDDD;border-left: 1px solid #DDDDDD;border-right: 1px solid #DDDDDD;'>$check</div>\n";
		$output .= "<div style='flex: 1;padding: 8px;border-bottom: 1px solid #DDDDDD;border-right: 1px solid #DDDDDD;'>$comment</div>\n";
		$output .= "</div>\n";
		$current++;
	}
	return;
}
# end addline
###############################################################################
# start addtitle
sub addtitle {
	my $title = shift;
	if (defined $current and $current == 0) {
		$output .= "<div style='clear: both;background: #BDECB6;padding: 8px;border: 1px solid #DDDDDD;'>OK</div>\n";
	}
	$current = 0;
	$output .= "<br><div style='clear: both;padding: 8px;background: #F4F4EA;border: 1px solid #DDDDDD;border-top-right-radius: 5px;border-top-left-radius: 5px;'><strong>$title</strong></div>\n";
	return;
}
# end addtitle
###############################################################################
# start endoutput
sub endoutput {
	if (defined $current and $current == 0) {
		$output .= "<div style='clear: both;background: #BDECB6;padding: 8px;border: 1px solid #DDDDDD;'>OK</div>\n";
	}
	$output .= "<br>\n";

	my $gap = int(($total-3)/4);
	my $score = ($total - $failures);
	my $width = int ((400 / $total) * $score) - 4;
	$output .= "<br>\n<table align='center'>\n<tr><td><div style='border:1px solid #DDDDDD;padding:8px;border-radius:5px'>\n";
	$output .= "<h4 style='text-align:center'>Server Score: $score/$total*</h4>\n";
	$output .= "<div style='text-align:center;border:1px solid #DDDDDD;width:500px'>\n";
	$output .= "<table>\n";
	$output .= "<tr>\n";
	$output .= "<td nowrap style='width:300px; height:30px; background:#FFD1DC'>&nbsp;</td>\n";
	$output .= "<td nowrap style='width:60px; height:30px; background:#FFFDD8'>&nbsp;</td>\n";
	$output .= "<td nowrap style='width:40px; height:30px; background:#BDECB6'>&nbsp;</td>\n";
	$output .= "<td nowrap style='width:100px; height:30px;'>&nbsp;$total (max)&nbsp;</td>\n";
	$output .= "</tr>\n";
	$output .= "</table>\n";
	$output .= "</div>\n";
	$output .= "<div style='text-align:center;border:1px solid #DDDDDD;width:500px'>\n";
	$output .= "<table>\n";
	$output .= "<tr>\n";
	$output .= "<td nowrap style='width:${width}px; height:30px;'>&nbsp;</td>\n";
	$output .= "<td nowrap style='width:1px; height:30px; background:#990000'>&nbsp;</td>\n";
	$output .= "<td nowrap>&nbsp;$score (score)</td>\n";
	$output .= "</tr>\n";
	$output .= "</table>\n";
	$output .= "</div>\n";
	$output .= "<br><div>* This scoring does not necessarily reflect the security of the server or the relative merits of each check</div>";
	$output .= "</td></tr></table>";
	return;
}
# end endoutput
###############################################################################
# start firewallcheck
sub firewallcheck {
	&addtitle("Firewall Check");
	my $status = 0;
	open (my $IN, "<", "/etc/csf/csf.conf");
	flock ($IN, LOCK_SH);
	my @config = <$IN>;
	chomp @config;

	foreach my $line (@config) {
		if ($line =~ /^\#/) {next}
		if ($line !~ /=/) {next}
		my ($name,$value) = split (/=/,$line,2);
		$name =~ s/\s//g;
		if ($value =~ /\"(.*)\"/) {
			$value = $1;
		} else {
			&error(__LINE__,"Invalid configuration line");
		}
		$config{$name} = $value;
	}

	$status = 0;
	if (-e "/etc/csf/csf.disable") {$status = 1}
	&addline($status,"csf enabled check","csf is currently disabled and should be enabled otherwise it is not functioning");
	
	if (-x $config{IPTABLES}) {
		my ($childin, $childout);
		my $mypid = open3($childin, $childout, $childout, "$config{IPTABLES} $config{IPTABLESWAIT} -L INPUT -n");
		my @iptstatus = <$childout>;
		waitpid ($mypid, 0);
		chomp @iptstatus;
		if ($iptstatus[0] =~ /# Warning: iptables-legacy tables present/) {shift @iptstatus}
		$status = 0;
		if ($iptstatus[0] =~ /policy ACCEPT/) {$status = 1}
		&addline($status,"csf running check","iptables is not configured. You need to start csf");
	}

	$status = 0;
	if ($config{TESTING}) {$status = 1}
	&addline($status,"TESTING mode check","csf is in TESTING mode. If the firewall is working set TESTING to \"0\" in the Firewall Configuration otherwise it will continue to be stopped");

	$status = 0;
	unless ($config{RESTRICT_SYSLOG}) {$status = 1}
	&addline($status,"RESTRICT_SYSLOG option check","Due to issues with syslog/rsyslog you should consider enabling this option. See the Firewall Configuration (/etc/csf/csf.conf) for more information");

	$status = 0;
	unless ($config{AUTO_UPDATES}) {$status = 1}
	&addline($status,"AUTO_UPDATES option check","To keep csf up to date and secure you should enable AUTO_UPDATES. You should also monitor our <a href='http://blog.configserver.com' target='_blank'>blog</a>");

	$status = 0;
	unless ($config{LF_DAEMON}) {$status = 1}
	&addline($status,"lfd enabled check","lfd is disabled in the csf configuration which limits the affectiveness of this application");

	$status = 0;
	if ($config{TCP_IN} =~ /\b3306\b/) {$status = 1}
	&addline($status,"Incoming MySQL port check","The TCP incoming MySQL port (3306) is open. This can pose both a security and server abuse threat since not only can hackers attempt to break into MySQL, any user can host their SQL database on your server and access it from another host and so (ab)use your server resources");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		unless ($config{VPS}) {
			$status = 0;
			unless ($config{SMTP_BLOCK}) {$status = 1}
			&addline($status,"SMTP_BLOCK option check","This option will help prevent the most common form of spam abuse on a server that bypasses exim and sends spam directly out through port 25. Enabling this option will prevent any web script from sending out using socket connection, such scripts should use the exim or sendmail binary instead");
		}

		$status = 0;
		unless ($config{LF_SCRIPT_ALERT}) {$status = 1}
		&addline($status,"LF_SCRIPT_ALERT option check","This option will notify you when a large amount of email is sent from a particular script on the server, helping track down spam scripts");
	}

	$status = 0;
	my @options = ("LF_SSHD","LF_FTPD","LF_SMTPAUTH","LF_POP3D","LF_IMAPD","LF_HTACCESS","LF_MODSEC","LF_CPANEL","LF_CPANEL_ALERT","SYSLOG_CHECK","RESTRICT_UI");
	if ($config{GENERIC}) {@options = ("LF_SSHD","LF_FTPD","LF_SMTPAUTH","LF_POP3D","LF_IMAPD","LF_HTACCESS","LF_MODSEC","SYSLOG_CHECK","FASTSTART","RESTRICT_UI");}
	if ($config{DNSONLY}) {@options = ("LF_SSHD","LF_CPANEL","SYSLOG_CHECK","FASTSTART","RESTRICT_UI")}

	foreach my $option (@options) {
		$status = 0;
		unless ($config{$option}) {$status = 1}
		&addline($status,"$option option check","This option helps prevent brute force attacks on your server services or overall server stability");
	}

	$status = 0;
	unless ($config{LF_DIRWATCH}) {$status = 1}
	&addline($status,"LF_DIRWATCH option check","This option will notify when a suspicious file is found in one of the common temp directories on the server");

	$status = 0;
	unless ($config{LF_INTEGRITY}) {$status = 1}
	&addline($status,"LF_INTEGRITY option check","This option will notify when an executable in one of the common directories on the server changes in some way. This helps alert you to potential rootkit installation or server compromise");

	$status = 0;
	unless ($config{FASTSTART}) {$status = 1}
	&addline($status,"FASTSTART option check","This option can dramatically improve the startup time of csf and the rule loading speed of lfd");

	$status = 0;
	if ($config{URLGET} == 1) {$status = 1}
	&addline($status,"URLGET option check","This option determines which perl module is used to upgrade csf. It is recommended to set this to use LWP rather than HTTP::Tiny so that upgrades are performed over an SSL connection");

	$status = 0;
	if ($config{PT_USERKILL} == 1) {$status = 1}
	&addline($status,"PT_USERKILL option check","This option should not normally be enabled as it can easily lead to legitimate processes being terminated, use csf.pignore instead");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		$status = 0;
		if ($config{PT_SKIP_HTTP}) {$status = 1}
		&addline($status,"PT_SKIP_HTTP option check","This option disables checking of processes running under apache and can limit false-positives but may then miss running exploits");
	}

	$status = 0;
	if (!$config{LF_IPSET} and !$config{VPS} and ($config{CC_DENY} or $config{CC_ALLOW} or $config{CC_ALLOW_FILTER} or $config{CC_ALLOW_PORTS} or $config{CC_DENY_PORTS})) {$status = 1}
	&addline($status,"LF_IPSET option check","If support by your OS, you should install ipset and enable LF_IPSET when using Country Code (CC_*) filters");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		$status = 0;
		unless ($config{PT_ALL_USERS}) {$status = 1}
		&addline($status,"PT_ALL_USERS option check","This option ensures that almost all Linux accounts are checked with Process Tracking, not just the cPanel ones");
	}

	sysopen (my $CONF, "/etc/csf/csf.conf", O_RDWR | O_CREAT);
	flock ($CONF, LOCK_SH);
	my @confdata = <$CONF>;
	close ($CONF);
	chomp @confdata;

	foreach my $line (@confdata) {
		if (($line !~ /^\#/) and ($line =~ /=/)) {
			my ($start,$end) = split (/=/,$line,2);
			my $name = $start;
			$name =~ s/\s/\_/g;
			if ($end =~ /\"(.*)\"/) {$end = $1}
			my ($insane,$range,$default) = sanity($start,$end);
			if ($insane) {
				&addline(1,"$start sanity check","$start = $end. Recommended range: $range (Default: $default)");
			}
		}
	}
	return;
}
# end firewallcheck
###############################################################################
# start servercheck
sub servercheck {
	&addtitle("Server Check");
	my $status = 0;

	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("/tmp");
	my $pmode = sprintf "%03o", $mode & oct("07777");

	$status = 0;
	if ($pmode != 1777) {$status = 1}
	&addline($status,"Check /tmp permissions","/tmp should be chmod 1777");

	$status = 0;
	if (($uid != 0) or ($gid != 0)) {$status = 1}
	&addline($status,"Check /tmp ownership","/tmp should be owned by root:root");

	if (-d "/var/tmp") {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("/var/tmp");
		$pmode = sprintf "%04o", $mode & oct("07777");

		$status = 0;
		if ($pmode != 1777) {$status = 1}
		&addline($status,"Check /var/tmp permissions","/var/tmp should be chmod 1777");

		$status = 0;
		if (($uid != 0) or ($gid != 0)) {$status = 1}
		&addline($status,"Check /var/tmp ownership","/var/tmp should be owned by root:root");
	}

	if (-d "/usr/tmp") {
		($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("/usr/tmp");
		$pmode = sprintf "%04o", $mode & oct("07777");

		$status = 0;
		if ($pmode != 1777) {$status = 1}
		&addline($status,"Check /usr/tmp permissions","/usr/tmp should be chmod 1777");

		$status = 0;
		if (($uid != 0) or ($gid != 0)) {$status = 1}
		&addline($status,"Check /usr/tmp ownership","/usr/tmp should be owned by root:root");
	}

	$status = 0;
	if (&getportinfo(53)) {
		my @files = ("/var/named/chroot/etc/named.conf","/etc/named.conf","/etc/bind/named.conf","/var/named/chroot/etc/bind/named.conf");
		my @namedconf;
		my @morefiles;
		my $hit;
		foreach my $file (@files) {
			if (-e $file) {
				$hit = 1;
				open (my $IN, "<", "$file");
				flock ($IN, LOCK_SH);
				my @conf = <$IN>;
				close ($IN);
				chomp @conf;
				if (my @ls = grep {$_ =~ /^\s*include\s+(.*)\;\s*$/i} @conf) {
					foreach my $more (@ls) {
						if ($more =~ /^\s*include\s+\"(.*)\"\s*\;\s*$/i) {push @morefiles, $1}
					}
				}
				@namedconf = (@namedconf, @conf);
			}
		}
		foreach my $file (@morefiles) {
			if (-e $file) {
				open (my $IN, "<", "$file");
				flock ($IN, LOCK_SH);
				my @conf = <$IN>;
				close ($IN);
				chomp @conf;
				@namedconf = (@namedconf, @conf);
			}
		}

		if ($hit) {
#			if (my @ls = grep {$_ =~ /^\s*(recursion\s+no|allow-recursion)/} @namedconf) {$status = 0} else {$status = 1}
#			&addline($status,"Check for DNS recursion restrictions","You have a local DNS server running but do not appear to have any recursion restrictions set. This is a security and performance risk and you should look at restricting recursive lookups to the local IP addresses only");

			if (my @ls = grep {$_ =~ /^\s*(query-source\s[^\;]*53)/} @namedconf) {$status = 1} else {$status = 0}
			&addline($status,"Check for DNS random query source port","ISC recommend that you do not configure BIND to use a static query port. You should remove/disable the query-source line that specifies port 53 from the named configuration files");
		}
	}

	if (!$DEBIAN and $sysinit eq "init" and -x "/sbin/runlevel") {
		$status = 0;
		$mypid = open3($childin, $childout, $childout, "/sbin/runlevel");
		my @conf = <$childout>;
		waitpid ($mypid, 0);
		chomp @conf;
		my (undef,$runlevel) = split(/\s/,$conf[0]);
		if ($runlevel != 3) {$status = 1}
		&addline($status,"Check server runlevel","The servers runlevel is currently set to $runlevel. For a secure server environment you should only run the server at runlevel 3. You can fix this by editing /etc/inittab and changing the initdefault line to:<br><b>id:3:initdefault:</b><br>and then rebooting the server");
	}

	$status = 0;
	if ((-e "/var/spool/cron/nobody") and !(-z "/var/spool/cron/nobody")) {$status = 1}
	&addline($status,"Check nobody cron","You have a nobody cron log file - you should check that this has not been created by an exploit");

	$status = 0;
	my ($isfedora, $isrh, $version, $conf) = 0;
	if (-e "/etc/fedora-release") {
		open (my $IN, "<", "/etc/fedora-release");
		flock ($IN, LOCK_SH);
		$conf = <$IN>;
		close ($IN);
		$isfedora = 1;
		if ($conf =~ /release (\d+)/i) {$version = $1}
	} elsif (-e "/etc/redhat-release") {
		open (my $IN, "<", "/etc/redhat-release");
		flock ($IN, LOCK_SH);
		$conf = <$IN>;
		close ($IN);
		$isrh = 1;
		if ($conf =~ /release (\d+)/i) {$version = $1}
	}
	chomp $conf;

	if ($isrh or $isfedora) {
		if (($isfedora and $version < 30) or ($isrh and $version < 6)) {$status = 1}
		&addline($status,"Check Operating System support","You are running an OS - <i>$conf</i> - that is no longer supported by the OS vendor, or is about to become obsolete. This means that you will be receiving no OS updates (i.e. application or security bug fixes) or kernel updates and should consider moving to an OS that is supported as soon as possible");
	}

	$status = 0;
	if ($] < 5.008008) {
		$status = 1;
	} else {$status = 0}
	&addline($status,"Check perl version","The version of perl (v$]) is out of date and you should upgrade it");

	$status = 0;
	while (my ($name,undef,$uid) = getpwent()) {
		if (($uid == 0) and ($name ne "root")) {$status = 1}
	}
	&addline($status,"Check SUPERUSER accounts","You have accounts other than root set up with UID 0. This is a considerable security risk. You should use <b>su</b>, or best of all <b>sudo</b> for such access");

	if (-e "/usr/local/cpanel/version" or $config{DIRECTADMIN}) {
		$status = 0;
		unless (-e "/etc/cxs/cxs.pl") {
			$status = 1;
		}
		&addline($status,"Check for cxs","You should consider using <b><u><a href='http://www.configserver.com/cp/cxs.html' target='_blank'>cxs</a></u></b> to scan web script uploads and user accounts for exploits uploaded to the server");
		$status = 0;
		unless (-e "/etc/osm/osmd.pl") {
			$status = 1;
		}
		&addline($status,"Check for osm","You should consider using <b><u><a href='http://www.configserver.com/cp/osm.html' target='_blank'>osm</a></u></b> to provide protection from spammers exploiting the server");
	}

	unless ($config{IPV6}) {
		$status = 0;
		my $ipv6 = "";
		foreach my $key (keys %g_ipv6) {
			if ($ipv6) {$ipv6 .= ", "}
			$ipv6 .= $key;
			$status = 1;
		}
		if ($ipv6 eq "::1") {$ipv6 = ""; $status = 0}
		&addline($status,"Check for IPv6","IPv6 appears to be enabled [<b>$ipv6</b>]. If ip6tables is installed, you should enable the csf IPv6 firewall (IPV6 in csf.conf)");
	}

	if ($sysinit eq "init") {
		$status = 1;
		my $syslog = 0;
		if (grep {$_ =~ /\/syslogd\s*/} @processes) {
			$syslog = 1;
			if (grep {$_ =~ /\/klogd$/} @processes) {$status = 0}
			&addline($status,"Check for kernel logger","syslogd appears to be running, but not klogd which logs kernel firewall messages to syslog. You should ensure that klogd is running");
		}
		if (grep {$_ =~ /\/rsyslogd\s*/} @processes) {
			$syslog = 1;
			if (grep {$_ =~ /\/rklogd\s*/} @processes) {
				$status = 0;
			} else {
				open (my $IN, "<", "/etc/rsyslog.conf");
				flock ($IN, LOCK_SH);
				my @conf = <$IN>;
				close ($IN);
				chomp @conf;
				if (grep {$_ =~ /^\$ModLoad imklog/} @conf) {$status = 0}
			}
			&addline($status,"Check for kernel logger","rsyslogd appears to be running, but klog may not be loaded which logs kernel firewall messages to rsyslog. You should modify /etc/rsyslogd to load the klog module with:<br><b>\$ModLoad imklog</b><br>Then restart rsyslog");
		}
		unless ($syslog) {
			$status = 1;
			&addline($status,"Check for syslog or rsyslog","Neither syslog nor rsyslog appear to be running");
		}
	}

	$status = 0;
	if (grep {$_ =~ /\/dhclient\s*/} @processes) {$status = 1}
	&addline($status,"Check for dhclient","dhclient appears to be running which suggests that the server is obtaining an IP address via DHCP. This can pose a security risk. You should configure static IP addresses for all ethernet controllers");

	unless ($config{VPS}) {
		$status = 1;
		open (my $IN, "<", "/proc/swaps");
		flock ($IN, LOCK_SH);
		my @swaps = <$IN>;
		close ($IN);
		if (scalar(@swaps) > 1) {$status = 0}
		&addline($status,"Check for swap file","The server appears to have no swap file. This is usually considered a stability and performance risk. You should either add a swap partition, or <a href='http://www.cyberciti.biz/faq/linux-add-a-swap-file-howto/' target='_blank'>create one via a normal file on an existing partition</a>");

		if (-e "/etc/redhat-release") {
			open (my $IN, "<", "/etc/redhat-release");
			flock ($IN, LOCK_SH);
			$conf = <$IN>;
			close ($IN);
			chomp $conf;

			if ($conf =~ /^CloudLinux/i) {
				$status = 0;
				if (-e "/usr/sbin/cagefsctl") {
				} else {$status = 1}
				&addline($status,"CloudLinux CageFS","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?cagefs.html'>CageFS</a> is not installed. This CloudLinux option greatly improves server security on we servers by separating user accounts into their own environment");

				unless ($status) {
					$status = 0;
					$mypid = open3($childin, $childout, $childout, "/usr/sbin/cagefsctl","--cagefs-status");
					my @conf = <$childout>;
					waitpid ($mypid, 0);
					chomp @conf;
					if ($conf[0] !~ /^Enabled/) {$status = 1}
					&addline($status,"CloudLinux CageFS Enabled","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?cagefs.html'>CageFS</a> is not enabled. This CloudLinux option greatly improves server security on we servers by separating user accounts into their own environment");
				}

				$status = 0;
				open (my $ENFORCE_SYMLINKSIFOWNER, "<", "/proc/sys/fs/enforce_symlinksifowner");
				flock ($ENFORCE_SYMLINKSIFOWNER, LOCK_SH);
				$conf = <$ENFORCE_SYMLINKSIFOWNER>;
				close ($ENFORCE_SYMLINKSIFOWNER);
				chomp $conf;
				if ($conf < 1) {$status = 1}
				&addline($status,"CloudLinux Symlink Protection","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?securelinks.html'>Symlink Protection</a> is not configured. You should configure it in /etc/sysctl.conf to prevent symlink attacks on web servers");

				$status = 0;
				open (my $PROC_CAN_SEE_OTHER_UID, "<", "/proc/sys/fs/proc_can_see_other_uid");
				flock ($PROC_CAN_SEE_OTHER_UID, LOCK_SH);
				$conf = <$PROC_CAN_SEE_OTHER_UID>;
				close ($PROC_CAN_SEE_OTHER_UID);
				chomp $conf;
				if ($conf > 0) {$status = 1}
				&addline($status,"CloudLinux Virtualised /proc","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?virtualized_proc_filesystem.html'>Virtualised /proc</a> is not configured. You should configure it in /etc/sysctl.conf to prevent users accessing server resources that they do not need on web servers");

				$status = 0;
				open (my $USER_PTRACE, "<", "/proc/sys/kernel/user_ptrace");
				flock ($USER_PTRACE, LOCK_SH);
				$conf = <$USER_PTRACE>;
				close ($USER_PTRACE);
				chomp $conf;
				if ($conf > 0) {$status = 1}
				&addline($status,"CloudLinux Disable ptrace","CloudLinux <a target='_blank' href='http://docs.cloudlinux.com/index.html?ptrace_block.html'>Disable ptrace</a> is not configured. You should configure it in /etc/sysctl.conf to prevent users accessing server resources that they do not need on web servers");
			}
		}
	}
	return;
}
# end servercheck
###############################################################################
# start whmcheck
sub whmcheck {
	my $status = 0;
	&addtitle("WHM Settings Check");

	$status = 0;
	unless ($cpconf->{alwaysredirecttossl}) {$status = 1}
	&addline($status,"Check cPanel login is SSL only","You should check <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Choose the closest matched domain for which that the system has a valid certificate when redirecting from non-SSL to SSL URLs</i>");

	$status = 0;
	unless ($cpconf->{skipboxtrapper}) {$status = 1}
	&addline($status,"Check boxtrapper is disabled","Having boxtrapper enabled can very easily lead to your server being listed in common RBLs and usually has the effect of increasing the overall spam load, not reducing it. You should disable it in <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > BoxTrapper Spam Trap</i>");

	$status = 0;
	if (-e "/var/cpanel/greylist/enabled") {$status = 1}
	&addline($status,"Check GreyListing is disabled","Using GreyListing can and will lead to lost legitimate emails. It can also cause significant problems with \"password verification\" systems. See <a href='https://en.wikipedia.org/wiki/Greylisting#Disadvantages' target='_blank'>here</a> for more information");

	if (defined $cpconf->{popbeforesmtp}) {
		$status = 0;
		if ($cpconf->{popbeforesmtp}) {$status = 1}
		&addline($status,"Check popbeforesmtp is disabled","Using pop before smtp is considered a security risk, SMTP AUTH should be used instead. You should disable it in <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow users to relay mail if they use an IP address through which someone has validated an IMAP or POP3 login</i>");
	}

	$status = 0;
	unless ($cpconf->{maxemailsperhour}) {$status = 1}
	&addline($status,"Check max emails per hour is set","To limit the damage that can be caused by potential spammers on the server you should set a value for <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Max hourly emails per domain</i>");

	$status = 0;
	if ($cpconf->{resetpass}) {$status = 1}
	&addline($status,"Check Reset Password for cPanel accounts","This poses a potential security risk and should be disabled unless necessary in <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Reset Password for cPanel accounts</i>");

	$status = 0;
	if ($cpconf->{resetpass_sub}) {$status = 1}
	&addline($status,"Check Reset Password for Subaccounts","This poses a potential security risk and should be disabled unless necessary in <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Reset Password for Subaccounts </i>");

	foreach my $openid (glob "/var/cpanel/authn/openid_connect/*") {
		open (my $IN, "<", $openid);
		flock ($IN, LOCK_SH);
		my $line = <$IN>;
		close ($IN);
		chomp $line;

		my ($file, $filedir) = fileparse($openid);
		$status = 0;
		if ($line =~ /\{"cpanelid"/) {$status = 1}
		&addline($status,"Check cPanelID for $file","You should only enable this option if you are going to use it otherwise it is a potential security risk in <i>WHM > <a href='$cpurl/scripts2/manage_external_auth/providers' target='_blank'>Manage External Authentications</a> > $file</i>");
	}

	unless ($cpconf->{nativessl} eq undef) {
		$status = 0;
		unless ($cpconf->{nativessl}) {$status = 1}
		&addline($status,"Check whether native cPanel SSL is enabled","You should enable this option so that lfd tracks SSL cpanel login attempts <i>WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Use native SSL support if possible, negating need for Stunnel</i>");
	}

	$status = 0;
    my $cc = '/usr/bin/cc';
    while ( readlink($cc) ) {
        $cc = readlink($cc);
    }
    if ( $cc !~ /^\// ) { $cc = '/usr/bin/' . $cc; }
    my $mode = substr( sprintf( "%o", ( ( stat($cc) )[2] ) ), 2, 4 );
    if ( $mode > 750 ) {$status = 1}
	&addline($status,"Check compilers","You should disable compilers <i>WHM > Security Center > <a href='$cpurl/scripts2/tweakcompilers' target='_blank'>Compilers Access</a></i>");

	if (-e "/etc/pure-ftpd.conf" and ($cpconf->{ftpserver} eq "pure-ftpd") and !(-e "/etc/ftpddisable")) {
		$status = 0;
		open (my $IN, "<", "/etc/pure-ftpd.conf");
		flock ($IN, LOCK_SH);
		my @conf = <$IN>;
		close ($IN);
		chomp @conf;
		if (my @ls = grep {$_ =~ /^\s*NoAnonymous\s*(no|off)/i} @conf) {$status = 1}
		&addline($status,"Check Anonymous FTP Logins","Used as an attack vector by hackers and should be disabled unless actively used <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Anonymous Logins</b> > No</i>");
		$status = 0;
		if (my @ls = grep {$_ =~ /^\s*AnonymousCantUpload\s*(no|off)/i} @conf) {$status = 1}
		&addline($status,"Check Anonymous FTP Uploads","Used as an attack vector by hackers and should be disabled unless actively used <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Anonymous Uploads</b> > No</i>");

		$status = 0;
		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*TLSCipherSuite/} @conf) {
			if ($ls[0] =~ /TLSCipherSuite\s+(.*)$/) {$ciphers = $1}
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			}
			elsif ($ciphers !~ /SSL/) {
				$status = 0
			} else {
				if (-x "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check pure-ftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		&addline($status,"Check pure-ftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > TLS Cipher Suite</b> > Remove +SSLv2 or Add -SSLv2</i>");

		$status = 0;
		unless (-e "/var/cpanel/conf/pureftpd/root_password_disabled") {$status = 1}
		&addline($status,"Check FTP Logins with Root Password","Allowing root login via FTP is a considerable security risk and should be disabled <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Logins with Root Password</b> > No</i>");
	}

	if (-e "/var/cpanel/conf/proftpd/main" and ($cpconf->{ftpserver} eq "proftpd") and !(-e "/etc/ftpddisable")) {
		$status = 0;
		open (my $IN, "<", "/var/cpanel/conf/proftpd/main");
		flock ($IN, LOCK_SH);
		my @conf = <$IN>;
		close ($IN);
		chomp @conf;
		if (my @ls = grep {$_ =~ /^cPanelAnonymousAccessAllowed: 'yes'/i} @conf) {$status = 1}
		&addline($status,"Check Anonymous FTP Logins","Used as an attack vector by hackers and should be disabled unless actively used <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > Allow Anonymous Logins</b> > No</i>");

		$status = 0;
		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*TLSCipherSuite/} @conf) {
			if ($ls[0] =~ /TLSCipherSuite\:\s+(.*)$/) {$ciphers = $1}
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			} else {
				if (-e "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/ftpconfiguration' target='_blank'>FTP Server Configuration</a> > TLS Cipher Suite</b> > Remove +SSLv2 or Add -SSLv2</i>");

		if ($config{VPS}) {
			$status = 0;
			open (my $IN, "<", "/etc/proftpd.conf");
			flock ($IN, LOCK_SH);
			my @conf = <$IN>;
			close ($IN);
			chomp @conf;
			if (my @ls = grep {$_ =~ /^\s*PassivePorts\s+(\d+)\s+(\d+)/} @conf) {
				if ($config{TCP_IN} !~ /\b$1:$2\b/) {$status = 1}
			} else {$status = 1}
			&addline($status,"Check VPS FTP PASV hole","Since the Virtuozzo VPS iptables ip_conntrack_ftp kernel module is currently broken you have to open a PASV port hole in iptables for incoming FTP connections to work correctly. See the csf readme.txt under 'A note about FTP Connection Issues' on how to do this");
		}
	}

	$status = 0;
	if ($cpconf->{allowremotedomains}) {$status = 1}
	&addline($status,"Check allow remote domains","User can park domains that resolve to other servers on this server. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow Remote Domains");

	$status = 0;
	unless ($cpconf->{blockcommondomains}) {$status = 1}
	&addline($status,"Check block common domains","User can park common domain names on this server. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Prevent cPanel users from creating specific domains");

	$status = 0;
	if ($cpconf->{allowparkonothers}) {$status = 1}
	&addline($status,"Check allow park domains","User can park/addon domains that belong to other users on this server. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow cPanel users to create subdomains across accounts");

	$status = 0;
	if ($cpconf->{proxysubdomains}) {$status = 1}
	&addline($status,"Check proxy subdomains","This option can mask a users real IP address and hinder security. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Service subdomains");

	$status = 1;
	if ($cpconf->{cpaddons_notify_owner}) {$status = 0}
	&addline($status,"Check cPAddons update email to resellers","You should have cPAddons email users if cPAddon installations require updating WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Notify reseller of cPAddons Site Software installations");

	$status = 1;
	if ($cpconf->{cpaddons_notify_root}) {$status = 0}
	&addline($status,"Check cPAddons update email to root","You should have cPAddons email root if cPAddon installations require updating WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Notify root of cPAddons Site Software installations");

	if (-e "/etc/cpupdate.conf") {
		open (my $IN, "<", "/etc/cpupdate.conf");
		flock ($IN, LOCK_SH);
		my @conf = <$IN>;
		close ($IN);
		chomp @conf;

		$status = 0;
		if (my @ls = grep {$_ =~ /^CPANEL=(edge|beta|nightly)/i} @conf) {$status = 1}
		&addline($status,"Check cPanel tree","Running EDGE/BETA on a production server could lead to server instability");

		$status = 1;
		if (my @ls = grep {$_ =~ /^UPDATES=daily/i} @conf) {$status = 0}
		&addline($status,"Check cPanel updates","You have cPanel updating disabled, this can pose a security and stability risk. <i>WHM > <a href='$cpurl/scripts2/updateconf' target='_blank'>Update Preferences</a> > Enabled Automatic Updates</i>");

#		$status = 0;
#		if (grep {$_ =~ /^SYSUP=/i} @conf) {$status = 1}
#		if (grep {$_ =~ /^SYSUP=daily/i} @conf) {$status = 0}
#		&addline($status,"Check package updates","You have package updating disabled, this can pose a security and stability risk. <i>WHM > <a href='$cpurl/scripts2/updateconf' target='_blank'>Update Config</a> >cPanel Package Updates > Automatic</i>");

#		$status = 1;
#		if (my @ls = grep {$_ =~ /^RPMUP=daily/i} @conf) {$status = 0}
#		&addline($status,"Check security updates","You have security updating disabled, this can pose a security and stability risk. <i>WHM > <a href='$cpurl/scripts2/updateconf' target='_blank'>Update Config</a> >Operating System Package Updates > Automatic</i>");
	} else {&addline(1,"Check cPanel updates","Unable to find /etc/cpupdate.conf");}

	$status = 1;
	if ($cpconf->{account_login_access} eq "user") {$status = 0}
	&addline($status,"Check accounts that can access a cPanel user","You should consider setting this option to \"user\" after use. WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Accounts that can access a cPanel user account");

	unless ($status) {
		$status = 0;
		open (my $IN, "<", "/usr/local/cpanel/3rdparty/etc/php.ini");
		flock ($IN, LOCK_SH);
		my @conf = <$IN>;
		close ($IN);
		chomp @conf;
		if (my @ls = grep {$_ =~ /^\s*register_globals\s*=\s*on/i} @conf) {$status = 1}
		&addline($status,"Check cPanel php.ini file for register_globals","PHP register_globals is considered a high security risk. It is currently enabled in /usr/local/cpanel/3rdparty/etc/php.ini and should be disabled (disabling may break 3rd party PHP cPanel apps)");
	}

	$status = 0;
	if ($cpconf->{emailpasswords}) {$status = 1}
	&addline($status,"Check cPanel passwords in email","You should not send passwords out in plain text emails. You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Send passwords when creating a new account");

	$status = 0;
	if ($cpconf->{coredump}) {$status = 1}
	&addline($status,"Check core dumps","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow WHM/Webmail/cPanel services to create core dumps for debugging purposes");

	$status = 1;
	if ($cpconf->{cookieipvalidation} eq "strict") {$status = 0}
	&addline($status,"Check Cookie IP Validation","You should enable strict Cookie IP validation in WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Cookie IP validation");

	$status = 1;
	if ($cpconf->{use_apache_md5_for_htaccess}) {$status = 0}
	&addline($status,"Check MD5 passwords with Apache","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Use MD5 passwords with Apache");

	$status = 1;
	if ($cpconf->{referrerblanksafety}) {$status = 0}
	&addline($status,"Check Referrer Blank Security","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Blank referrer safety check");

	$status = 1;
	if ($cpconf->{referrersafety}) {$status = 0}
	&addline($status,"Check Referrer Security","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Referrer safety check");

	$status = 1;
	if ($cpconf->{skiphttpauth}) {$status = 0}
	&addline($status,"Check HTTP Authentication","You should disable skiphttpauth in /var/cpanel/cpanel.config");

	$status = 0;
	if ($cpconf->{skipparentcheck}) {$status = 1}
	&addline($status,"Check Parent Security","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow other applications to run the cPanel and admin binaries");

	$status = 0;
	if ($cpconf->{"cpsrvd-domainlookup"}) {$status = 1}
	&addline($status,"Check Domain Lookup Security","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > cpsrvd username domain lookup");

	$status = 1;
	if ($cpconf->{"cgihidepass"}) {$status = 0}
	&addline($status,"Check Password ENV variable","You should enable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Hide login password from cgi scripts ");

	$status = 0;
	if (-e "/var/cpanel/smtpgidonlytweak") {$status = 1}
	&addline($status,"Check SMTP Restrictions","This option in WHM will not function when running csf. You should disable WHM > Security Center > <a href='$cpurl/scripts2/smtpmailgidonly' target='_blank'>SMTP Restrictions</a> and use the csf configuration option SMTP_BLOCK instead");

	if (-e "/etc/wwwacct.conf") {
		$status = 1;
		open (my $IN, "<", "/etc/wwwacct.conf");
		flock ($IN, LOCK_SH);
		my @conf = <$IN>;
		close ($IN);
		chomp @conf;

		my %ips;
	foreach my $key (keys %g_ipv4) {
		$ips{$key} = 1;
	}

		my $nameservers;
		my $local = 0;
		my $allns = 0;
		foreach my $line (@conf) {
			if ($line =~ /^NS(\d)?\s+(.*)\s*$/) {
				my $ns = $2;
				$ns =~ s/\s//g;
				if ($ns) {
					$allns++;
					$nameservers .= "<b>$ns</b><br>\n";
					my $ip;
					if (checkip(\$ns)) {
						$ip = $ns;
						if ($ips{$ip}) {$local++}
					} else {
						my @ips = getips($ns);
						unless (scalar @ips) {&addline(1,"Check nameservers","Unable to resolve nameserver [$ns]")}
						my $hit = 0;
						foreach my $oip (@ips) {
							if ($ips{$oip}) {$hit = 1}
						}
						if ($hit) {$local++}
					}
				}
			}
		}
		if ($local < $allns) {$status = 0}
		&addline($status,"Check nameservers","At least one of the configured nameservers:<br>\n$nameservers should be located in a topologically and geographically dispersed location on the Internet - See RFC 2182 (Section 3.1)");
	}

	if (-e "/usr/local/cpanel/bin/register_appconfig") {
		$status = 0;
		if ($cpconf->{permit_unregistered_apps_as_reseller}) {$status = 1}
		&addline($status,"Check AppConfig Required","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow apps that have not registered with AppConfig to be run when logged in as a reseller in WHM");

		$status = 0;
		if ($cpconf->{permit_unregistered_apps_as_root}) {$status = 1}
		&addline($status,"Check AppConfig as root","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow apps that have not registered with AppConfig to be run when logged in as root or a reseller with the \"all\" ACL in WHM");

		$status = 0;
		if ($cpconf->{permit_appconfig_entries_without_acls}) {$status = 1}
		&addline($status,"Check AppConfig ACLs","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow WHM apps registered with AppConfig to be executed even if a Required ACLs list has not been defined");

		$status = 0;
		if ($cpconf->{permit_appconfig_entries_without_features}) {$status = 1}
		&addline($status,"Check AppConfig Feature List","You should disable WHM > <a href='$cpurl/scripts2/tweaksettings' target='_blank'>Tweak Settings</a> > Allow cPanel and Webmail apps registered with AppConfig to be executed even if a Required Features list has not been defined");
	}

	$status = 0;
	if ($cpconf->{"disable-security-tokens"}) {$status = 1}
	&addline($status,"Check Security Tokens","Security Tokens should not be disabled as without them security of WHM/cPanel is compromised. The setting disable-security-tokens=0 should be set in /var/cpanel/cpanel.config");
	return;
}
# end whmcheck
###############################################################################
# start dacheck
sub dacheck {
	my $status = 0;
	&addtitle("DirectAdmin Settings Check");

	$status = 0;
	unless ($daconfig{ssl}) {$status = 1}
	&addline($status,"Check DirectAdmin login is SSL only","You should enable SSL only login to <a href='http://help.directadmin.com/item.php?id=15' target='_blank'>DirectAdmin</a>");

	if (($daconfig{ftpconfig} =~ /proftpd.conf/) and ($daconfig{pureftp} != 1)) {
		$status = 0;
		open (my $IN, "<", $daconfig{ftpconfig});
		flock ($IN, LOCK_SH);
		my @conf = <$IN>;
		close ($IN);
		chomp @conf;

		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*TLSCipherSuite/} @conf) {
			if ($ls[0] =~ /TLSCipherSuite\s+(.*)$/) {$ciphers = $1}
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			} else {
				if (-e "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		&addline($status,"Check proftpd weak SSL/TLS Ciphers (TLSCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should add a TLSCipherSuite with SSLv2 disabled in $daconfig{ftpconfig}. For example,<br><b>&lt;IfModule mod_tls.c><br>TLSCipherSuite HIGH<br>&lt;/IfModule> container</b>");

		if ($config{VPS}) {
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*PassivePorts\s+(\d+)\s+(\d+)/} @conf) {
				if ($config{TCP_IN} !~ /\b$1:$2\b/) {$status = 1}
			} else {$status = 1}
			&addline($status,"Check VPS FTP PASV hole","Since the Virtuozzo VPS iptables ip_conntrack_ftp kernel module is currently broken you have to open a PASV port hole in iptables for incoming FTP connections to work correctly. See the csf readme.txt under 'A note about FTP Connection Issues' on how to do this");
		}
	}

	$status = 1;

	my %ips;
	foreach my $key (keys %g_ipv4) {
		$ips{$key} = 1;
	}

	my $nameservers;
	for (my $x = 1; $x < 3; $x++) {
		my $ns = $daconfig{"ns$x"};
		$ns =~ s/\s//g;
		if ($ns) {
			$nameservers .= "<b>$ns</b><br>\n";
			my $ip;
			if ($ns =~ /\d+\.\d+\.\d+\.d+/) {
				$ip = $ns;
			} else {
				eval {
					local $SIG{__DIE__} = undef;
					local $SIG{'ALRM'} = sub {die};
					alarm(5);
					$ip = gethostbyname($ns);
					$ip = inet_ntoa($ip);
					alarm(0);
				};
				alarm(0);
				unless ($ip) {&addline(1,"Check nameservers","Unable to resolve nameserver [$ns] within 5 seconds")}
			}
			if ($ip) {
				unless ($ips{$ip}) {$status = 0}
			}
		}
	}
	&addline($status,"Check nameservers","At least one of the configured nameservers:<br>\n$nameservers should be located in a topologically and geographically dispersed location on the Internet - See RFC 2182 (Section 3.1)");
	return;
}
# end dacheck
###############################################################################
# start mailcheck
sub mailcheck {
	&addtitle("Mail Check");

	my $status = 0;
	unless ($config{DIRECTADMIN}) {
		if (-e "/root/.forward") {
			if (-z "/root/.forward") {$status = 1}
		} else {$status = 1}
		&addline($status,"Check root forwarder","The root account should have a forwarder set so that you receive essential email from your server");
	}

	if (-e "/etc/exim.conf" and -x "/usr/sbin/exim") {
		$status = 0;
		my ($childin, $childout);
		my $cmdpid = open3($childin, $childout, $childout, "/usr/sbin/exim","-bP");
		my @eximconf = <$childout>;
		waitpid ($cmdpid, 0);
		chomp @eximconf;
		if (my @ls = grep {$_ =~ /^\s*log_selector/} @eximconf) {
			if (($ls[0] !~ /\+all/) and ($ls[0] !~ /\+arguments/) and ($ls[0] !~ /\+arguments/)) {$status = 1}
		} else {$status = 1}
		if ($config{DIRECTADMIN}) {
			&addline($status,"Check exim for extended logging (log_selector)","You should enable extended exim logging to enable easier tracking potential outgoing spam issues. Add:<br><b>log_selector = +arguments +subject +received_recipients</b><br>to /etc/exim.conf");
		} else {
			&addline($status,"Check exim for extended logging (log_selector)","You should enable extended exim logging to enable easier tracking potential outgoing spam issues. Add:<br><b>log_selector = +arguments +subject +received_recipients</b><br>in WHM > <a href='$cpurl/scripts2/displayeximconfforedit' target='_blank'>Exim Configuration Manager</a> > Advanced Editor > log_selector");
		}

		$status = 0;
		my $ciphers;
		my $error;
		if (my @ls = grep {$_ =~ /^\s*tls_require_ciphers/} @eximconf) {
			(undef,$ciphers) = split(/\=/,$ls[0]);
			$ciphers =~ s/\s*|\"|\'//g;
			if ($ciphers eq "") {
				$status = 1;
			} else {
				if (-x "/usr/bin/openssl") {
					my ($childin, $childout);
					my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
					my @openssl = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @openssl;
					if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
					if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
				}
			}
		} else {$status = 1}
		if ($status == 2) {
			&addline($status,"Check exim weak SSL/TLS Ciphers (tls_require_ciphers)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
		}
		if ($config{DIRECTADMIN}) {
			&addline($status,"Check exim weak SSL/TLS Ciphers (tls_require_ciphers)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should edit /etc/exim.conf and set tls_require_ciphers to explicitly exclude it. For example:<br><b>tls_require_ciphers=ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP</b>");
		} else {
			&addline($status,"Check exim weak SSL/TLS Ciphers (tls_require_ciphers)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable WHM > <a href='$cpurl/scripts2/displayeximconfforedit' target='_blank'>Exim Configuration Manager</a> > Allow weak ssl/tls ciphers to be used, and also ensure tls_require_ciphers in /etc/exim.conf does not allow SSLv2 as openssl currently shows that it does");
		}
	} else {&addline(1,"Check exim configuration","Unable to find /etc/exim.conf and/or /usr/sbin/exim");}

	if (-e "/etc/exim.conf.localopts") {
		$status = 0;
		open (my $IN, "<", "/etc/exim.conf.localopts");
		flock ($IN, LOCK_SH);
		my @conf = <$IN>;
		close ($IN);
		chomp @conf;

		if (my @ls = grep {$_ =~ /require_secure_auth=0/i} @conf) {$status = 1}
		&addline($status,"Check exim for secure authentication","You should require clients to connect with SSL or issue the STARTTLS command before they are allowed to authenticate with the server, otherwise passwords may be sent in plain text<br>in WHM > <a href='$cpurl/scripts2/displayeximconfforedit' target='_blank'>Exim Configuration Manager</a>");
	}

	if ($config{DIRECTADMIN}) {
		if (-e "/etc/dovecot.conf" and ($daconfig{dovecot})) {
			$status = 0;
			open (my $IN, "<", "/etc/dovecot.conf");
			flock ($IN, LOCK_SH);
			my @conf = <$IN>;
			close ($IN);
			chomp @conf;

			my @morefiles;
			if (my @ls = grep {$_ =~ /^\s*\!\s*include(_try)?\s+(.*)\s*$/i} @conf) {
				foreach my $more (@ls) {
					if ($more =~ /^\s*\!\s*include(_try)?\s+(.*)\s*$/i) {
						my $conf = $2;
						if ($conf !~ /^\//) {$conf = "/etc/dovecot/".$conf}
						push @morefiles, $conf;
					}
				}
			}
			foreach my $file (@morefiles) {
				if (-e $file) {
					open (my $IN, "<", "$file");
					flock ($IN, LOCK_SH);
					my @moreconf = <$IN>;
					close ($IN);
					chomp @conf;
					@conf = (@conf, @moreconf);
				}
			}

			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^ssl_cipher_list/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should /etc/dovecot.conf and set ssl_cipher_list to explicitly exclude it. For example:<br><b>ssl_cipher_list = ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP</b>");
		}
	} else {
		if (-e "/etc/dovecot/dovecot.conf" and ($cpconf->{mailserver} eq "dovecot")) {
			$status = 0;
			open (my $IN, "<", "/etc/dovecot/dovecot.conf");
			flock ($IN, LOCK_SH);
			my @conf = <$IN>;
			close ($IN);
			chomp @conf;

			my @morefiles;
			if (my @ls = grep {$_ =~ /^\s*\!?include(_try)?\s+(.*)\s*$/i} @conf) {
				foreach my $more (@ls) {
					if ($more =~ /^\s*\!?include(_try)?\s+(.*)\s*$/i) {push @morefiles, $2}
				}
			}
			foreach my $file (@morefiles) {
				if (-e $file) {
					open (my $IN, "<", "$file");
					flock ($IN, LOCK_SH);
					my @moreconf = <$IN>;
					close ($IN);
					chomp @conf;
					@conf = (@conf, @moreconf);
				}
			}
			
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^ssl_cipher_list/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check dovecot weak SSL/TLS Ciphers (ssl_cipher_list)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/mailserversetup' target='_blank'>Mailserver Configuration</a> > SSL Cipher List</b> > Remove +SSLv2 or Add -SSLv2</i>");
		}

		if (-e "/usr/lib/courier-imap/etc/imapd-ssl" and ($cpconf->{mailserver} eq "courier")) {
			$status = 0;
			open (my $IN, "<", "/usr/lib/courier-imap/etc/imapd-ssl");
			flock ($IN, LOCK_SH);
			my @conf = <$IN>;
			close ($IN);
			chomp @conf;
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^TLS_CIPHER_LIST/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check Courier IMAP weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check Courier IMAP weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/mailserversetup' target='_blank'>Mailserver Configuration</a> > IMAP TLS/SSL Cipher List</b> > Remove +SSLv2 or Add -SSLv2</i>");
		}

		if (-e "/usr/lib/courier-imap/etc/pop3d-ssl" and ($cpconf->{mailserver} eq "courier")) {
			$status = 0;
			open (my $IN, "<", "/usr/lib/courier-imap/etc/pop3d-ssl");
			flock ($IN, LOCK_SH);
			my @conf = <$IN>;
			close ($IN);
			chomp @conf;
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^TLS_CIPHER_LIST/} @conf) {
				(undef,$ciphers) = split(/\=/,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check Courier POP3D weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check Courier POP3D weak SSL/TLS Ciphers (TLS_CIPHER_LIST)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in <i>WHM > <a href='$cpurl/scripts2/mailserversetup' target='_blank'>Mailserver Configuration</a> > POP3 TLS/SSL Cipher List</b> > Remove +SSLv2 or Add -SSLv2</i>");
		}
	}
	return;
}
# end mailcheck
###############################################################################
# start phpcheck
sub phpcheck {
	&addtitle("PHP Check");
	my %phpbinaries;
	my %phpinis;

	if (-e "/usr/local/cpanel/version" and -e "/etc/cpanel/ea4/is_ea4") {
		foreach my $phpdir (glob("/opt/cpanel/ea-*")) {
			if (-e "${phpdir}/root/usr/bin/php") {$phpbinaries{"${phpdir}/root/usr/bin/php"} = 1}
		}
	}
	elsif ($config{DIRECTADMIN}) {
		foreach my $phpdir (glob("/usr/local/php*")) {
			if (-e "${phpdir}/bin/php") {$phpbinaries{"${phpdir}/bin/php"} = 1}
		}
	}
	elsif (-e "/usr/local/bin/php") {$phpbinaries{"/usr/local/bin/php"} = 1}
	elsif (-e "/usr/bin/php") {$phpbinaries{"/usr/bin/php"} = 1}

	if (-e "/opt/alt/alt-php-config") {
		foreach my $phpdir (glob("/opt/alt/php*")) {
			if (-e "${phpdir}/usr/bin/php") {$phpbinaries{"${phpdir}/usr/bin/php"} = 1}
		}
	}

	if (scalar(keys %phpbinaries) == 0) {
		&addline(1,"PHP Binary","PHP binary not found or not executable");
		return;
	}

	foreach my $phpbin (keys %phpbinaries) {
		if ($phpbin =~ /php44/) {$phpinis{"/opt/alt/php44/etc/php.ini"} = $phpbin}
		elsif ($phpbin =~ /php51/) {$phpinis{"/opt/alt/php51/etc/php.ini"} = $phpbin}
		else {
			my ($childin, $childout);
			my $mypid = open3($childin, $childout, $childout, $phpbin,"-d","zlib.output_compression=Off","--ini");
			my @conf = <$childout>;
			waitpid ($mypid, 0);
			chomp @conf;
			foreach my $line (@conf) {
				if ($line =~ /^Loaded Configuration File:\s*(\S+)$/) {$phpinis{$1} = $phpbin}
			}
		}
	}
	my %phpconf;
	foreach my $phpini (sort keys %phpinis) {
		my $phpbin = $phpinis{$phpini};

		my $status = 0;
		my ($childin, $childout);
		my $mypid;
		if ($phpbin =~ /php44|php51/) {
			$mypid = open3($childin, $childout, $childout, $phpbin,"-i");
		} else {
			$mypid = open3($childin, $childout, $childout, $phpbin,"-d","zlib.output_compression=Off","-i");
		}
		my @conf = <$childout>;
		waitpid ($mypid, 0);
		chomp @conf;

		if (my @ls = grep {$_ =~ /^PHP License/} @conf) {
			my $version = 0;
			my ($mas,$maj,$min);
			if (my @ls = grep {$_ =~ /^PHP Version\s*=>\s*/i} @conf) {
				my $line = $ls[0];
				$line =~ /^PHP Version\s*=>\s*(.*)/i;
				($mas,$maj,$min) = split(/\./,$1);
				$version = "$mas.$maj.$min";
				if ($mas < 8) {$status = 1}
				if ($mas == 8 and $maj < 1) {$status = 1}
			}
			open (my $IN, "<", "/usr/local/apache/conf/php.conf.yaml");
			flock ($IN, LOCK_SH);
			my @phpyamlconf = <$IN>;
			close ($IN);
			chomp @phpyamlconf;

			if (my @ls = grep {$_ =~ /php4:/i} @phpyamlconf) {
				if ($ls[0] !~ /none/) {
					$status = 1;
					$version = "4.*";
				}
			}
			unless ($phpbin =~ m[^/opt/alt/php]) {
				if ($status) {$phpconf{version} .= "$version ($phpbin),"}
			}

			$status = 1;
			if (my @ls = grep {$_ =~ /^enable_dl\s*=>\s*Off/i} @conf) {
				$status = 0;
			}
			if (my @ls = grep {$_ =~ /^disable_functions\s*=>.*dl.*/i} @conf) {
				$status = 0;
			}

			if ($status) {$phpconf{enable_dl} .= "$phpini ($phpbin),"}
			
			$status = 1;
			if (my @ls = grep {$_ =~ /^disable_functions\s*=>.*\,/i} @conf) {
				$status = 0;
			}
			if ($status) {$phpconf{disable_functions} .= "$phpini ($phpbin),"}

			$status = 1;
			if (my @ls = grep {$_ =~ /^disable_functions\s*=>.*ini_set.*/i} @conf) {
				$status = 0;
			}
			if ($status) {$phpconf{ini_set} .= "$phpini ($phpbin),"}

			my $oldver = "$mas.$maj";
			if ($oldver < 5.4) {
				$status = 1;
				if (my @ls = grep {$_ =~ /^register_globals\s*=>\s*Off/i} @conf) {
					$status = 0;
				}
				if ($status) {$phpconf{register_globals} .= "$phpini ($phpbin),"}

			}
		} else {
			$status = 1;
			&addline($status,"Check php<br>[$phpbin]","Unable to examine PHP settings due to an error in the output from: [$phpbin -i]");
		}
	}
	foreach my $key ("version","enable_dl","disable_functions","ini_set","register_globals") {
		my $values;
		foreach my $value (split(/\,/,$phpconf{$key})) {
			if ($value eq "") {next}
			$values .= "<br>$value\n";
		}
		if ($key eq "version") {
			my $status = 0;
			if ($values ne "") {$status = 1}
			&addline($status,"Check php version","Any version of PHP older than v8.1.* is now obsolete and should be considered a security threat. You should upgrade to at least PHP v8.1+:<br><b>Affected PHP versions:</b>$values");
		}
		if ($key eq "enable_dl") {
			my $status = 0;
			if ($values ne "") {$status = 1}
			&addline($status,"Check php for enable_dl or disabled dl()","You should set:<br><b>enable_dl = Off</b><br>This prevents users from loading php modules that affect everyone on the server. Note that if use dynamic libraries, such as ioncube, you will have to load them directly in the PHP configuration:<br><b>Affected PHP versions:</b>$values");
		}
		if ($key eq "disable_functions") {
			my $status = 0;
			if ($values ne "") {$status = 1}
			&addline($status,"Check php for disable_functions","You should consider disabling commonly abused php functions, e.g.:<br><b>disable_functions = show_source, system, shell_exec, passthru, exec, popen, proc_open</b><br>Some client web scripts may break with some of these functions disabled, so you may have to remove them from this list:<br><b>Affected PHP versions:</b>$values");
		}
		if ($key eq "register_globals") {
			my $status = 0;
			if ($values ne "") {$status = 1}
			&addline($status,"Check php for register_globals","You should set:<br><b>register_globals = Off</b><br>unless it is absolutely necessary as it is seen as a significant security risk:<br><b>Affected PHP versions:</b>$values");
		}
	}
	return;
}
# end phpcheck
###############################################################################
# start apachecheck
sub apachecheck {
	&addtitle("Apache Check");

	my $status = 0;
	my $mypid;
	my ($childin, $childout);
	my %ea4;

	if (-e "/usr/local/cpanel/version" and -e "/etc/cpanel/ea4/is_ea4" and -e "/etc/cpanel/ea4/paths.conf") {
		my @file = slurp("/etc/cpanel/ea4/paths.conf");
		$ea4{enabled} = 1;
		foreach my $line (@file) {
			$line =~ s/$cleanreg//g;
			if ($line =~ /^(\s|\#|$)/) {next}
			if ($line !~ /=/) {next}
			my ($name,$value) = split (/=/,$line,2);
			$value =~ s/^\s+//g;
			$value =~ s/\s+$//g;
			$ea4{$name} = $value;
		}
	}

	if ($ea4{enabled}) {
		unless (-x $ea4{bin_httpd}) {&addline(1,"HTTP Binary","$ea4{bin_httpd} not found or not executable"); return}
	}
	elsif ($config{DIRECTADMIN}) {
		unless (-x "/usr/sbin/httpd") {&addline(1,"HTTP Binary","/usr/sbin/httpd not found or not executable"); return}
	}
	else {
		unless (-x "/usr/local/apache/bin/httpd") {&addline(1,"HTTP Binary","/usr/local/apache/bin/httpd not found or not executable"); return}
	}

	if ($ea4{enabled}) {
		$mypid = open3($childin, $childout, $childout, $ea4{bin_httpd},"-v");
	}
	elsif ($config{DIRECTADMIN}) {
		$mypid = open3($childin, $childout, $childout, "/usr/sbin/httpd","-v");
	}
	else {
		$mypid = open3($childin, $childout, $childout, "/usr/local/apache/bin/httpd","-v");
	}
	my @version = <$childout>;
	waitpid ($mypid, 0);
	chomp @version;
	$version[0] =~ /Apache\/(\d+)\.(\d+)\.(\d+)/;
	my $mas = $1;
	my $maj = $2;
	my $min = $3;
	if ("$mas.$maj" < 2.2) {$status = 1}
	&addline($status,"Check apache version","You are running a legacy version of apache (v$mas.$maj.$min) and should consider upgrading to v2.2.* as recommended by the Apache developers");

	unless ($config{DIRECTADMIN}) {
		my $ruid2 = 0;
		if ($ea4{enabled}) {
			$mypid = open3($childin, $childout, $childout, $ea4{bin_httpd},"-M");
		}
		else {
			$mypid = open3($childin, $childout, $childout, "/usr/local/apache/bin/httpd","-M");
		}
		my @modules = <$childout>;
		waitpid ($mypid, 0);
		chomp @modules;
		if (my @ls = grep {$_ =~ /ruid2_module/} @modules) {$ruid2 = 1}
		if (my @ls = grep {$_ =~ /mpm_itk_module/} @modules) {$ruid2 = 1}

		$status = 0;
		if (my @ls = grep {$_ =~ /security2_module/} @modules) {$status = 0} else {$status = 1}
		&addline($status,"Check apache for ModSecurity","You should install the ModSecurity apache module during the easyapache build process to help prevent exploitation of vulnerable web scripts, together with a set of rules");

		$status = 0;
		if (my @ls = grep {$_ =~ /cloudflare_module/} @modules) {$status = 1} else {$status = 0}
		if ($config{CF_ENABLE}) {$status = 0}
		&addline($status,"Check apache for mod_cloudflare","This module logs the real users IP address to Apache. If this is reported to lfd via ModSecurity, cxs or some other vector through Apache it will lead to that IP being blocked, but because the IP is coming through the CloudFlare service the IP will <b>not</b> be blocked as so far as iptables is concerned the originating IP address is CloudFlare itself and the abuse will continue. To block these IP's in the CloudFlare Firewall look at using CF_ENABLE in csf.conf");

		$status = 0;
		if (my @ls = grep {$_ =~ /frontpage_module/} @modules) {$status = 1}
		&addline($status,"Check apache for FrontPage","Microsoft Frontpage Extensions were EOL in 2006 and there is no support for bugs or security issues. For this reason, it should be considered a security risk to continue using them. You should rebuild apache through easyapache and deselect the option to build them");

		my @conf;
		if (-e "/usr/local/apache/conf/httpd.conf") {
			open (my $IN, "<", "/usr/local/apache/conf/httpd.conf");
			flock ($IN, LOCK_SH);
			@conf = <$IN>;
			close ($IN);
			chomp @conf;
		}
		if (-e "$ea4{file_conf}") {
			open (my $IN, "<", "$ea4{file_conf}");
			flock ($IN, LOCK_SH);
			@conf = <$IN>;
			close ($IN);
			chomp @conf;
		}
		if (@conf) {
			$status = 0;
			my $ciphers;
			my $error;
			if (my @ls = grep {$_ =~ /^\s*SSLCipherSuite/} @conf) {
				$ls[0] =~ s/^\s+//g;
				(undef,$ciphers) = split(/\ /,$ls[0]);
				$ciphers =~ s/\s*|\"|\'//g;
				if ($ciphers eq "") {
					$status = 1;
				} else {
					if (-x "/usr/bin/openssl") {
						my ($childin, $childout);
						my $cmdpid = open3($childin, $childout, $childout, "/usr/bin/openssl","ciphers","-v",$ciphers);
						my @openssl = <$childout>;
						waitpid ($cmdpid, 0);
						chomp @openssl;
						if (my @ls = grep {$_ =~ /error/i} @openssl) {$error = $openssl[0]; $status=2}
						if (my @ls = grep {$_ =~ /SSLv2/} @openssl) {$status = 1}
					}
				}
			} else {$status = 1}
			if ($status == 2) {
				&addline($status,"Check Apache weak SSL/TLS Ciphers (SSLCipherSuite)","Unable to determine cipher list for [$ciphers] from openssl:<br>[$error]");
			}
			&addline($status,"Check Apache weak SSL/TLS Ciphers (SSLCipherSuite)","Cipher list [$ciphers]. Due to weaknesses in the SSLv2 cipher you should disable SSLv2 in WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > SSLCipherSuite > Add -SSLv2 to SSLCipherSuite and/or remove +SSLv2. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");

			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*TraceEnable Off/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for TraceEnable","You should set TraceEnable to Off in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > Trace Enable > Off. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*ServerSignature Off/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for ServerSignature","You should set ServerSignature to Off in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > Server Signature > Off. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*ServerTokens ProductOnly/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for ServerTokens","You should set ServerTokens to ProductOnly in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > Server Tokens > Product Only. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
			$status = 0;
			if (my @ls = grep {$_ =~ /^\s*FileETag None/} @conf) {
				$status = 0;
			} else {$status = 1}
			&addline($status,"Check apache for FileETag","You should set FileETag to None in: WHM > Apache Configuration > <a href='$cpurl/scripts2/globalapachesetup' target='_blank'>Global Configuration</a> > File ETag > None. Do not forget to Save AND then Rebuild Configuration and Restart Apache, otherwise the changes will not take effect in httpd.conf");
		}

		my @apacheconf;
		if (-e "/usr/local/apache/conf/php.conf.yaml") {
			open (my $IN, "<", "/usr/local/apache/conf/php.conf.yaml");
			flock ($IN, LOCK_SH);
			@apacheconf = <$IN>;
			close ($IN);
			chomp @apacheconf;
		}
		if (-e "$ea4{dir_conf}/php.conf.yaml") {
			open (my $IN, "<", "$ea4{dir_conf}/php.conf.yaml");
			flock ($IN, LOCK_SH);
			@apacheconf = <$IN>;
			close ($IN);
			chomp @apacheconf;
		}
		if (@apacheconf) {
			unless ($ruid2) {
				$status = 0;
				if (my @ls = grep {$_ =~ /suphp/} @apacheconf) {
					$status = 0;
				} else {$status = 1}
				&addline($status,"Check suPHP","To reduce the risk of hackers accessing all sites on the server from a compromised PHP web script, you should enable suPHP when you build apache/php. Note that there are sideeffects when enabling suPHP on a server and you should be aware of these before enabling it.<br>Don\'t forget to enable it as the default PHP handler in <i>WHM > <a href='$cpurl/scripts2/phpandsuexecconf' target='_blank'>PHP 5 Handler</a></i>");
		
				$status = 0;
				unless ($cpconf->{userdirprotect}) {$status = 1}
				&addline($status,"Check mod_userdir protection","To prevents users from stealing bandwidth or hackers hiding access to your servers, you should check <i>WHM > Security Center > <a href='$cpurl/scripts2/tweakmoduserdir' target='_blank'>mod_userdir Tweak</a></i>");

				$status = 1;
				if (my @ls = grep {$_ =~ /suexec_module/} @modules) {$status = 0}
				&addline($status,"Check Suexec","To reduce the risk of hackers accessing all sites on the server from a compromised CGI web script, you should set <i>WHM > <a href='$cpurl/scripts2/phpandsuexecconf' target='_blank'>Suexec on</a></i>");
			}
		}
	}
	return;
}
# end apachecheck
###############################################################################
# start sshtelnetcheck
sub sshtelnetcheck {
	my $status = 0;
	&addtitle("SSH/Telnet Check");

	if (-e "/etc/ssh/sshd_config") {
		open (my $IN, "<", "/etc/ssh/sshd_config");
		flock ($IN, LOCK_SH);
		my @sshconf = <$IN>;
		close ($IN);
		chomp @sshconf;
		if (my @ls = grep {$_ =~ /^\s*Protocol/i} @sshconf) {
			if ($ls[0] =~ /1/) {$status = 1}
		} else {$status = 0}
		&addline($status,"Check SSHv1 is disabled","You should disable SSHv1 by editing /etc/ssh/sshd_config and setting:<br><b>Protocol 2</b>");

		$status = 0;
		my $sshport = "22";
		if (my @ls = grep {$_ =~ /^\s*Port/i} @sshconf) {
			if ($ls[0] =~ /^\s*Port\s+(\d*)/i) {
				$sshport = $1;
				if ($sshport eq "22") {$status = 1}
			} else {$status = 1}
		} else {$status = 1}
		&addline($status,"Check SSH on non-standard port","You should consider moving SSH to a non-standard port [currently:$sshport] to evade basic SSH port scans. Don't forget to open the port in the firewall first if necessary");

		$status = 0;
		if (my @ls = grep {$_ =~ /^\s*PasswordAuthentication/i} @sshconf) {
			if ($ls[0] =~ /\byes\b/i) {$status = 1}
		} else {$status = 1}
		&addline($status,"Check SSH PasswordAuthentication","You should disable PasswordAuthentication and only allow access using PubkeyAuthentication to improve brute-force SSH security");

		$status = 0;
		if (my @ls = grep {$_ =~ /^\s*UseDNS/i} @sshconf) {
			if ($ls[0] !~ /\bno\b/i) {$status = 1}
		} else {$status = 1}
		&addline($status,"Check SSH UseDNS","You should disable UseDNS by editing /etc/ssh/sshd_config and setting:<br><b>UseDNS no</b><br>Otherwise, lfd will be unable to track SSHD login failures successfully as the log files will not report IP addresses");
	} else {&addline(1,"Check SSH configuration","Unable to find /etc/ssh/sshd_config");}

	$status = 0;
	my $check = &getportinfo("23");
	if ($check) {$status = 1}
	&addline($status,"Check telnet port 23 is not in use","It appears that something is listening on port 23 which is normally used for telnet. Telnet is an insecure protocol and you should disable the telnet daemon if it is running");

	unless ($config{DNSONLY} or $config{GENERIC}) {
		unless ($config{VPS}) {
			if (-e "/etc/redhat-release") {
				open (my $IN, "<", "/etc/redhat-release");
				flock ($IN, LOCK_SH);
				my $conf = <$IN>;
				close ($IN);
				chomp $conf;

				unless ($conf =~ /^CloudLinux/i) {
					if (-e "/etc/profile") {
						$status = 0;
						open (my $IN, "<", "/etc/profile");
						flock ($IN, LOCK_SH);
						my @profile = <$IN>;
						close ($IN);
						chomp @profile;
						if (grep {$_ =~ /^LIMITUSER=\$USER/} @profile) {
							$status = 0;
						} else {$status = 1}
						&addline($status,"Check shell limits","You should enable shell resource limits to prevent shell users from consuming server resources - DOS exploits typically do this. A quick way to set this is to use WHM > <a href='$cpurl/scripts2/modlimits' target='_blank'>Shell Fork Bomb Protection</a>");
					} else {
						&addline(1,"Check shell limits","Unable to find /etc/profile");
					}
				}
			}
		}

		$status = 0;
		if (-e "/var/cpanel/killproc.conf") {
			open (my $IN, "<", "/var/cpanel/killproc.conf");
			flock ($IN, LOCK_SH);
			my @proc = <$IN>;
			close ($IN);
			chomp @proc;
			if (@proc < 9) {$status = 1}
			&addline($status,"Check Background Process Killer","You should enable each item in the WHM > <a href='$cpurl/scripts2/dkillproc' target='_blank'>Background Process Killer</a>");
		} else {&addline(1,"Check Background Process Killer","You should enable each item in the WHM > <a href='$cpurl/scripts2/dkillproc' target='_blank'>Background Process Killer</a>")}
	}
	return;
}
# end sshtelnetcheck
###############################################################################
# start servicescheck
sub servicescheck {
	my $systemctl = "/usr/bin/systemctl";
	my $chkconfig = "/sbin/chkconfig";
	my $servicebin = "/sbin/service";
	if (-e "/bin/systemctl") {$systemctl = "/bin/systemctl"}
	if (-e "/usr/sbin/chkconfig") {$chkconfig = "/usr/sbin/chkconfig"}
	if (-e "/usr/sbin/service") {$servicebin = "/usr/sbin/service"}
	&addtitle("Server Services Check");
	my @services = ("abrt-xorg", "abrtd", "alsa-state", "anacron", "avahi-daemon", "avahi-dnsconfd", "bluetooth", "bolt", "canna", "colord", "cups", "cups-config-daemon", "cupsd", "firewalld", "FreeWnn", "gdm", "gpm", "gssproxy", "hidd", "iiim", "ksmtuned", "mDNSResponder", "ModemManager", "nfslock", "nifd", "packagekit", "pcscd", "portreserve", "pulseaudio", "qpidd", "rpcbind", "rpcidmapd", "saslauthd", "sbadm", "wpa_supplicant", "xfs", "xinetd");

	my $disable;
	my ($childin, $childout);
	my $mypid;
	if ($sysinit eq "init") {
		$disable = "$servicebin [service] stop<br>$chkconfig [service] off";
		$mypid = open3($childin, $childout, $childout, $chkconfig,"--list");
	} else {
		$disable = "$systemctl stop [service]<br>$systemctl disable [service]";
		$mypid = open3($childin, $childout, $childout, $systemctl,"list-unit-files","--state=enabled","--no-pager","--no-legend");
	}
	my @chkconfig = <$childout>;
	waitpid ($mypid, 0);
	chomp @chkconfig;

	my @enabled;
	foreach my $service (@services) {
		if ($service eq "xinetd" and $config{PLESK}) {next}
		if ($sysinit eq "init") {
			if (my @ls = grep {$_ =~ /^$service\b/} @chkconfig) {
				if ($ls[0] =~ /\:on/) {push @enabled, $service}
			}
		} else {
			if (my @ls = grep {$_ =~ /^$service\.service/} @chkconfig) {push @enabled, $service}
		}
	}
	if (scalar @enabled > 0) {
		my $list;
		foreach my $service (@enabled) {
			if (length($list) == 0) {
				$list = $service;
			} else {
				$list .= ",".$service;
			}
		}
		&addline("1","Check server services","On most servers the following services are not needed and should be stopped and disabled from starting unless used:<p><b>$list</b></p>\nEach service can usually be disabled using:<br><b>$disable</b>");
	} else {
		&addline("0","Check server services","On most servers the following services are not needed and should be stopped and disabled from starting unless used:<p><b>none found</b></p>\nEach service can usually be disabled using:<br><b>$disable</b>");
	}
	return;
}
# end servicescheck
###############################################################################
# start getportinfo
sub getportinfo {
	my $port = shift;
	my $hit = 0;

	foreach my $proto ("udp","tcp","udp6","tcp6") {
		open (my $IN, "<", "/proc/net/$proto");
		flock ($IN, LOCK_SH);
		while (<$IN>) {
			my @rec = split();
			if ($rec[9] =~ /uid/) {next}
			my (undef,$sport) = split(/:/,$rec[1]);
			if (hex($sport) == $port) {$hit = 1}
		}
		close ($IN);
	}

	return $hit;
}
# end getportinfo
###############################################################################

1;
