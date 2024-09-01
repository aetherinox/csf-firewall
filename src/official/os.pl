#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);

umask(0177);


if (-l "/var/run" and readlink("/var/run") eq "../run" and -d "/run") {
	sysopen (my $LFD, "lfd.service", O_RDWR);
	my @data = <$LFD>;
	seek ($LFD, 0, 0);
	truncate ($LFD, 0);
	foreach my $line (@data) {
		if ($line =~ /^PIDFile=/) {
			print $LFD "PIDFile=/run/lfd.pid\n";
		} else {
			print $LFD $line;
		}
	}
	close ($LFD);
}

my $return = 0;
my @modules = ("Fcntl","File::Find","File::Path","IPC::Open3","Net::SMTP","POSIX","Socket","Math::BigInt");
foreach my $module (@modules) {
#	print STDERR "Checking for $module\n";
	local $SIG{__DIE__} = undef;
	eval ("use $module"); ##no critic
	if ($@) {
		print STDERR "\n".$@;
		$return = 1;
	}
}

if (-e "/usr/sbin/iptables-nft") {
	print STDERR "Configuration modified to use iptables-nft\n";
	system("update-alternatives", "--set", "iptables", "/usr/sbin/iptables-nft");
	if (-e "/usr/sbin/ip6tables-nft") {
		print STDERR "Configuration modified to use ip6tables-nft\n";
		system("update-alternatives", "--set", "ip6tables", "/usr/sbin/ip6tables-nft");
	}
}

if (-e "/etc/redhat-release") {
	print STDERR "Using configuration defaults\n";
}
elsif (-e "/etc/SuSE-release") {
	open (my $IN, "<", "csf.generic.conf") or die $!;
	flock ($IN, LOCK_SH) or die $!;
	my @config = <$IN>;
	close ($IN);
	chomp @config;
	open (my $OUT, ">", "csf.generic.conf") or die $!;
	flock ($OUT, LOCK_EX) or die $!;
	foreach my $line (@config) {
		if ($line =~ /^IPTABLES /) {$line = 'IPTABLES = "/usr/sbin/iptables"'}
		if ($line =~ /^FUSER/) {$line = 'FUSER = "/bin/fuser"'}
		if ($line =~ /^HTACCESS_LOG/) {$line = 'HTACCESS_LOG = "/var/log/apache2/error_log"'}
		if ($line =~ /^MODSEC_LOG/) {$line = 'MODSEC_LOG = "/var/log/apache2/error_log"'}
		if ($line =~ /^SSHD_LOG/) {$line = 'SSHD_LOG = "/var/log/messages"'}
		if ($line =~ /^SU_LOG/) {$line = 'SU_LOG = "/var/log/messages"'}
		if ($line =~ /^FTPD_LOG/) {$line = 'FTPD_LOG = "/var/log/messages"'}
		if ($line =~ /^POP3D_LOG/) {$line = 'POP3D_LOG = "/var/log/mail"'}
		if ($line =~ /^IMAPD_LOG/) {$line = 'IMAPD_LOG = "/var/log/mail"'}
		print $OUT $line."\n";
	}
	close ($OUT);
	print STDERR "Configuration modified for SuSE settings /etc/csf/csf.conf\n";
}
elsif ((-e "/etc/debian_version") or (-e "/etc/lsb-release") or (-e "/etc/gentoo-release")) {
	open (my $IN, "<", "csf.generic.conf") or die $!;
	flock ($IN, LOCK_SH) or die $!;
	my @config = <$IN>;
	close ($IN);
	chomp @config;
	open (my $GENERIC, ">", "csf.generic.conf") or die $!;
	flock ($GENERIC, LOCK_EX) or die $!;
	foreach my $line (@config) {
		if ($line =~ /^FUSER/) {$line = 'FUSER = "/bin/fuser"'}
		if ($line =~ /^HTACCESS_LOG/) {$line = 'HTACCESS_LOG = "/var/log/apache2/error.log"'}
		if ($line =~ /^MODSEC_LOG/) {$line = 'MODSEC_LOG = "/var/log/apache2/error.log"'}
		if ($line =~ /^SSHD_LOG/) {$line = 'SSHD_LOG = "/var/log/auth.log"'}
		if ($line =~ /^WEBMIN_LOG/) {$line = 'WEBMIN_LOG = "/var/log/auth.log"'}
		if ($line =~ /^SU_LOG/) {$line = 'SU_LOG = "/var/log/messages"'}
		if ($line =~ /^FTPD_LOG/) {$line = 'FTPD_LOG = "/var/log/messages"'}
		if ($line =~ /^POP3D_LOG/) {$line = 'POP3D_LOG = "/var/log/mail.log"'}
		if ($line =~ /^IMAPD_LOG/) {$line = 'IMAPD_LOG = "/var/log/mail.log"'}
		if ($line =~ /^SYSTEMCTL /) {$line = 'SYSTEMCTL = "/bin/systemctl"'}
		if ($line =~ /^IPSET /) {$line = 'IPSET = "/sbin/ipset"'}
		if ($line =~ /^IP /) {$line = 'IP = "/bin/ip"'}
		if ($line =~ /^ZGREP /) {$line = 'ZGREP = "/bin/zgrep"'}
		print $GENERIC $line."\n";
	}
	close ($GENERIC);

	open (my $DIRECTADMIN, "<", "csf.directadmin.conf") or die $!;
	flock ($DIRECTADMIN, LOCK_SH) or die $!;
	@config = <$DIRECTADMIN>;
	close ($DIRECTADMIN);
	chomp @config;
	open (my $OUT, ">", "csf.directadmin.conf") or die $!;
	flock ($OUT, LOCK_EX) or die $!;
	foreach my $line (@config) {
		if ($line =~ /^FUSER/) {$line = 'FUSER = "/bin/fuser"'}
		if ($line =~ /^SYSTEMCTL /) {$line = 'SYSTEMCTL = "/bin/systemctl"'}
		if ($line =~ /^IPSET /) {$line = 'IPSET = "/sbin/ipset"'}
		if ($line =~ /^IP /) {$line = 'IP = "/bin/ip"'}
		if ($line =~ /^ZGREP /) {$line = 'ZGREP = "/bin/zgrep"'}
		print $OUT $line."\n";
	}
	close ($OUT);
	print STDERR "Configuration modified for Debian/Ubuntu/Gentoo settings /etc/csf/csf.conf\n";

	open (my $IN, "<", "csf.cyberpanel.conf") or die $!;
	flock ($IN, LOCK_SH) or die $!;
	my @config = <$IN>;
	close ($IN);
	chomp @config;
	open (my $GENERIC, ">", "csf.cyberpanel.conf") or die $!;
	flock ($GENERIC, LOCK_EX) or die $!;
	foreach my $line (@config) {
		if ($line =~ /^FUSER/) {$line = 'FUSER = "/bin/fuser"'}
		if ($line =~ /^IPTABLES_LOG/) {$line = 'IPTABLES_LOG = "/var/log/kern.log"'}
		if ($line =~ /^HTACCESS_LOG/) {$line = 'HTACCESS_LOG = "/var/log/apache2/error.log"'}
		if ($line =~ /^MODSEC_LOG/) {$line = 'MODSEC_LOG = "/var/log/apache2/error.log"'}
		if ($line =~ /^SSHD_LOG/) {$line = 'SSHD_LOG = "/var/log/auth.log"'}
		if ($line =~ /^WEBMIN_LOG/) {$line = 'WEBMIN_LOG = "/var/log/auth.log"'}
		if ($line =~ /^SU_LOG/) {$line = 'SU_LOG = "/var/log/messages"'}
		if ($line =~ /^FTPD_LOG/) {$line = 'FTPD_LOG = "/var/log/messages"'}
		if ($line =~ /^POP3D_LOG/) {$line = 'POP3D_LOG = "/var/log/mail.log"'}
		if ($line =~ /^IMAPD_LOG/) {$line = 'IMAPD_LOG = "/var/log/mail.log"'}
		if ($line =~ /^SYSTEMCTL /) {$line = 'SYSTEMCTL = "/bin/systemctl"'}
		if ($line =~ /^IPSET /) {$line = 'IPSET = "/sbin/ipset"'}
		if ($line =~ /^IP /) {$line = 'IP = "/bin/ip"'}
		if ($line =~ /^ZGREP /) {$line = 'ZGREP = "/bin/zgrep"'}
		print $GENERIC $line."\n";
	}
	close ($GENERIC);
}
elsif (-e "/etc/slackware-version") {
	open (my $IN, "<", "csf.generic.conf") or die $!;
	flock ($IN, LOCK_SH) or die $!;
	my @config = <$IN>;
	close ($IN);
	chomp @config;
	open (my $OUT, ">", "csf.generic.conf") or die $!;
	flock ($OUT, LOCK_EX) or die $!;
	foreach my $line (@config) {
		if ($line =~ /^IPTABLES /) {$line = 'IPTABLES = "/usr/sbin/iptables"'}
		if ($line =~ /^FUSER/) {$line = 'FUSER = "/usr/bin/fuser"'}
		if ($line =~ /^HTACCESS_LOG/) {$line = 'HTACCESS_LOG = "/var/log/httpd/error.log"'}
		if ($line =~ /^MODSEC_LOG/) {$line = 'MODSEC_LOG = "/var/log/httpd/error.log"'}
		if ($line =~ /^SSHD_LOG/) {$line = 'SSHD_LOG = "/var/log/messages"'}
		if ($line =~ /^SU_LOG/) {$line = 'SU_LOG = "/var/log/messages"'}
		if ($line =~ /^FTPD_LOG/) {$line = 'FTPD_LOG = "/var/log/messages"'}
		if ($line =~ /^POP3D_LOG/) {$line = 'POP3D_LOG = "/var/log/maillog"'}
		if ($line =~ /^IMAPD_LOG/) {$line = 'IMAPD_LOG = "/var/log/maillog"'}
		print $OUT $line."\n";
	}
	close ($OUT);
	print STDERR "Configuration modified for Slackware settings /etc/csf/csf.conf\n";
} else {print STDERR "Using configuration defaults\n"}

print $return;
exit;
