###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::Messenger;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use File::Copy;
use JSON::Tiny;
use IO::Socket::INET;
use Net::CIDR::Lite;
use Net::IP;
use IPC::Open3;
use ConfigServer::Config;
use ConfigServer::CheckIP qw(checkip);
use ConfigServer::Logger qw(logfile);
use ConfigServer::URLGet;
use ConfigServer::Slurp qw(slurp);
use ConfigServer::GetIPs qw(getips);
use ConfigServer::GetEthDev;

use Exporter qw(import);
our $VERSION     = 3.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my $slurpreg = ConfigServer::Slurp->slurpreg;
my $cleanreg = ConfigServer::Slurp->cleanreg;

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();
my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

my $childproc;
my $hostname;

my %ips;
my $ipscidr6;
my %sslcerts;
my %sslkeys;
my %ssldomains;
my @ssldomainkeys;
my $webserver = "apache";
my $sslhost;
my $sslcert;
my $sslkey;
my $sslca;
my $osslcert;
my $osslkey;
my $osslca;
my $sslaliases;
my $litestart = 0;
my $ssldir = "/var/lib/csf/ssl/";
my $phphandler;
my $version = 1;
my $serverroot;

# end main
###############################################################################
# start init
sub init {
	my $class = shift;
	$version = shift;
	my $self = {};
	bless $self,$class;

	if (-e "/proc/sys/kernel/hostname") {
		open (my $IN, "<", "/proc/sys/kernel/hostname");
		flock ($IN, LOCK_SH);
		$hostname = <$IN>;
		chomp $hostname;
		close ($IN);
	} else {
		$hostname = "unknown";
	}
	if ($version == 1) {
		if ($config{MESSENGER6}) {
			eval('use IO::Socket::INET6;'); ##no critic
			if ($@) {$config{MESSENGER6} = "0"}
		}
		$ipscidr6 = Net::CIDR::Lite->new;
		&getethdev;
		foreach my $ip (split(/,/,$config{RECAPTCHA_NAT})) {
			$ip =~ s/\s*//g;
			$ips{$ip} = 1;
		}
	}
	elsif ($version == 2) {
	}
	elsif ($version == 3) {
		mkdir $ssldir;
		mkdir $ssldir."certs/";
		mkdir $ssldir."keys/";
		mkdir $ssldir."ca/";
	}
	
	return $self;
}
# end init
###############################################################################
# start start
sub start {
	my $self = shift;
	my $port = shift;
	my $user = shift;
	my $type = shift;
	my $status;
	my $reason;
	if ($version == 1) {
		($status,$reason) = &messenger($port, $user, $type);
	}
	elsif ($version == 2) {
		($status,$reason) = &messengerv2();
	}
	elsif ($version == 3) {
		($status,$reason) = &messengerv3();
	}
	
	return ($status,$reason);
}
# end start
###############################################################################
# start messenger
sub messenger {
	my $port = shift;
	my $user = shift;
	my $type = shift;
	my $oldtype = $type;
	my $server;
	my %sslcerts;
	my %sslkeys;

	$SIG{CHLD} = 'IGNORE';
	$SIG{INT} = \&childcleanup;
	$SIG{TERM} = \&childcleanup;
	$SIG{HUP} = \&childcleanup;
	$SIG{__DIE__} = sub {&childcleanup(@_);};
	$0 = "lfd $type messenger";
	$childproc = "Messenger ($type)";

	if ($type eq "HTTPS") {
		eval {
			local $SIG{__DIE__} = undef;
			require IO::Socket::SSL;
			import IO::Socket::SSL;
		};

		my $start = 0;
		my $sslhost;
		my $sslcert;
		my $sslkey;
		my $sslaliases;
		my %messengerports;
		foreach my $serverports (split(/\,/,$config{MESSENGER_HTTPS_IN})) {$messengerports{$serverports} = 1}
		foreach my $file (glob($config{MESSENGER_HTTPS_CONF})) {
			if (-e $file) {
				foreach my $line (slurp($file)) {
					$line =~ s/\'|\"//g;
					if ($line =~ /^\s*<VirtualHost\s+[^\>]+>/) {
						$start = 1;
					}
					if ($webserver eq "apache" and $start) {
						if ($line =~ /\s*ServerName\s+(\w+:\/\/)?([a-zA-Z0-9\.\-]+)(:\d+)?/) {$sslhost = $2}
						if ($line =~ /\s*ServerAlias\s+(.*)/) {$sslaliases .= " ".$1}
						if ($line =~ /\s*SSLCertificateFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {$sslcert = $match}
						}
						if ($line =~ /\s*SSLCertificateKeyFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {$sslkey = $match}
						}
					}

					if (($webserver eq "apache" and $line =~ /^\s*<\/VirtualHost\s*>/)) {
						$start = 0;
						if ($sslhost ne "" and !checkip($sslhost) and $sslcert ne "") {
							$sslcerts{$sslhost} = $sslcert;
							if ($sslkey eq "") {$sslkey = $sslcert}
							$sslkeys{$sslhost} = $sslkey;
							foreach my $alias (split(/\s+/,$sslaliases)) {
								if ($alias eq "") {next}
								if (checkip($alias)) {next}
								if ($alias =~ /^[a-zA-Z0-9\.\-]+$/) {
									if ($config{MESSENGER_HTTPS_SKIPMAIL} and $alias =~ /^mail\./) {next}
									$sslcerts{$alias} = $sslcert;
									$sslkeys{$alias} = $sslkey;
								}
							}
						}
						$sslhost = "";
						$sslcert = "";
						$sslkey = "";
						$sslaliases = "";
					}
				}
			}
		}
		if (scalar(keys %sslcerts < 1)) {
			return (1, "No SSL certs found in MESSENGER_HTTPS_CONF location");
		}
		if (-e $config{MESSENGER_HTTPS_KEY}) {
			$sslkeys{''} = $config{MESSENGER_HTTPS_KEY};
		}
		if (-e $config{MESSENGER_HTTPS_CRT}) {
			$sslcerts{''} = $config{MESSENGER_HTTPS_CRT};
		}
		if ($config{DEBUG} >= 1) {
			foreach my $key (keys %sslcerts) {
				logfile("SSL: [$key] [$sslcerts{$key}] [$sslkeys{$key}]");
			}
		}
		eval {
			local $SIG{__DIE__} = undef;
			if ($config{MESSENGER6}) {
				$server = IO::Socket::SSL->new(
							Domain => AF_INET6,
							LocalPort => $port,
							Type => SOCK_STREAM,
							ReuseAddr => 1,
							Listen => $config{MESSENGER_CHILDREN},
							SSL_server => 1,
							SSL_use_cert => 1,
							SSL_cert_file => \%sslcerts,
							SSL_key_file => \%sslkeys,
				) or &error("MESSENGER: *Error* cannot open server on port $port: ".IO::Socket::SSL->errstr);
			} else {
				$server = IO::Socket::SSL->new(
							Domain => AF_INET,
							LocalPort => $port,
							Type => SOCK_STREAM,
							ReuseAddr => 1,
							Listen => $config{MESSENGER_CHILDREN},
							SSL_server => 1,
							SSL_use_cert => 1,
							SSL_cert_file => \%sslcerts,
							SSL_key_file => \%sslkeys,
				) or &error("MESSENGER: *Error* cannot open server on port $port: ".IO::Socket::SSL->errstr);
			}
			&logfile("Messenger HTTPS Service started for ".scalar(keys %sslcerts)." domains");
			$type = "HTML";
		};
		if ($@) {
			return (1, $@);
		}
	}
	elsif ($config{MESSENGER6}) {
		$server = IO::Socket::INET6->new(
			LocalPort => $port, 
			Type => SOCK_STREAM, 
			ReuseAddr => 1, 
			Listen => $config{MESSENGER_CHILDREN}) or &childcleanup(__LINE__,"*Error* cannot open server on port $port: $!");
	} else {
		$server = IO::Socket::INET->new(
			LocalPort => $port, 
			Type => SOCK_STREAM, 
			ReuseAddr => 1, 
			Listen => $config{MESSENGER_CHILDREN}) or &childcleanup(__LINE__,"*Error* cannot open server on port $port: $!");
	}
	
	my $index;
	if ($type eq "HTML" and $config{RECAPTCHA_SITEKEY} ne "") {$index = "/etc/csf/messenger/index.recaptcha.html"}
	elsif ($type eq "HTML") {$index = "/etc/csf/messenger/index.html"}
	else {$index = "/etc/csf/messenger/index.text"}
	open (my $IN, "<", $index);
	flock ($IN, LOCK_SH);
	my @message = <$IN>;
	close ($IN);
	chomp @message;

	my %images;
	if ($type eq "HTML") {
		opendir (DIR, "/etc/csf/messenger");
		foreach my $file (readdir(DIR)) {
			if ($file =~ /\.(gif|png|jpg)$/) {
				open (my $IN, "<", "/etc/csf/messenger/$file");
				flock ($IN, LOCK_SH);
				my @data = <$IN>;
				close ($IN);
				chomp @data;
				foreach my $line (@data) {
					$images{$file} .= "$line\n";
				}
			}
		}
		closedir (DIR);
	}
	my $chldallow = $config{MESSENGER_CHILDREN};

	if ($oldtype eq "HTTPS") {
		open (my $STATUS,"<", "/proc/$$/status") or next;
		flock ($STATUS, LOCK_SH);
		my @status = <$STATUS>;
		close ($STATUS);
		chomp @status;
		my $vmsize = 0;
		my $vmrss = 0;
		foreach my $line (@status) {
			if ($line =~ /^VmSize:\s+(\d+) kB$/) {$vmsize = $1}
			if ($line =~ /^VmRSS:\s+(\d+) kB$/) {$vmrss = $1}
		}

		logfile("lfd $oldtype messenger using $vmrss kB of RSS memory at startup, adding up to $config{MESSENGER_CHILDREN} children = ".(($config{MESSENGER_CHILDREN} + 1) * $vmrss)." kB");
		logfile("lfd $oldtype messenger using $vmsize kB of VIRT memory at startup, adding up to $config{MESSENGER_CHILDREN} children = ".(($config{MESSENGER_CHILDREN} + 1) * $vmsize)." kB");
	}

	if ($user ne "") {
		my (undef,undef,$uid,$gid,undef,undef,undef,$homedir) = getpwnam($user);
		if (($uid > 0) and ($gid > 0)) {
			local $( = $gid;
			local $) = "$gid $gid";
			local $> = local $< = $uid;
			if (($) != $gid) or ($> != $uid) or ($( != $gid) or ($< != $uid)) {
				logfile("MESSENGER_USER unable to drop privileges - stopping $oldtype Messenger");
				exit;
			}
			my %children;
			while (1) {
				while (my $client = $server->accept()) {
					while (scalar (keys %children) >= $chldallow) {
						sleep 1;
						foreach my $pid (keys %children) {
							unless (kill(0,$pid)) {delete $children{$pid}}
						}
						$0 = "lfd $oldtype messenger (busy)";
					}
					$0 = "lfd $oldtype messenger";

					$SIG{CHLD} = 'IGNORE';
					my $pid = fork;
					$children{$pid} = 1;
					if ($pid == 0) {
						eval {
							local $SIG{__DIE__} = undef;
							local $SIG{'ALRM'} = sub {die};
							alarm(10);
							close $server;

							$0 = "lfd $oldtype messenger client";

							binmode $client;
							$| = 1;
							my $firstline;

							my $hostaddress = $client->sockhost();
							my $peeraddress = $client->peerhost();
							$peeraddress =~ s/^::ffff://;
							$hostaddress =~ s/^::ffff://;

							if ($type eq "HTML") {
								while ($firstline !~ /\n$/) {
									my $char;
									$client->read($char,1);
									$firstline .= $char;
									if ($char eq "") {exit}
									if (length $firstline > 2048) {last}
								}
								chomp $firstline;
								if ($firstline =~ /\r$/) {chop $firstline}
							}

							&messengerlog($homedir,"Client connection [$peeraddress] [$firstline]");
							my $error;
							my $success;
							my $failure;
							if (($type eq "HTML") and ($firstline =~ /^GET \/unblk\?g-recaptcha-response=(\S+)/i)) {
								my $recv = $1;
								my $status = 1;
								my $text;
								eval {
									local $SIG{__DIE__} = undef;
									eval("no lib '/usr/local/csf/lib'");
									my $urlget = ConfigServer::URLGet->new(2, "", $config{URLPROXY});
									my $url = "https://www.google.com/recaptcha/api/siteverify?secret=$config{RECAPTCHA_SECRET}&response=$recv";
									($status, $text) = $urlget->urlget($url);
								};
								if ($status) {
									&messengerlog($homedir,"*Error*, ReCaptcha ($peeraddress): $text");
									if ($config{DEBUG} >= 1) {
										if ($@) {$error .= "Error:".$@}
										if ($!) {$error .= "Error:".$!}
										$error .= " Error Status: $status";
									}
									$error .= "Unable to verify with Google reCAPTCHA";
								} else {
									my $resp  = JSON::Tiny::decode_json($text);
									if ($resp->{success}) {
										my $ip = $resp->{hostname};
										unless ($ip =~ /^($ipv4reg|$ipv6reg)$/) {$ip = (getips($ip))[0]}
										if ($ips{$ip} or $ip eq $hostaddress or $ipscidr6->find($ip)) {
											sysopen (my $UNBLOCK, "$homedir/unblock.txt", O_WRONLY | O_APPEND | O_CREAT) or $error .= "Unable to write to [$homedir/unblock.txt] (make sure that MESSENGER_USER has a home directory)";
											flock($UNBLOCK, LOCK_EX);
											print $UNBLOCK "$peeraddress;$resp->{hostname};$ip\n";
											close ($UNBLOCK);
											$success = 1;
											&messengerlog($homedir,"*Success*, ReCaptcha ($peeraddress): [$resp->{hostname} ($ip)] requested unblock");
										} else {
											$error .= "Failed, [$resp->{hostname} ($ip)] does not appear to be hosted on this server.";
											&messengerlog($homedir,"*Failed*, ReCaptcha ($peeraddress): [$resp->{hostname} ($ip)] does not appear to be hosted on this server");
										}
									} else {
										$failure = 1;
										my @codes = @{$resp->{'error-codes'}};
										&messengerlog($homedir,"*Failure*, ReCaptcha ($peeraddress): [$codes[0]]");
									}
								}
							}
							if (($type eq "HTML") and ($firstline =~ /^GET\s+(\S*\/)?(\S*\.(gif|png|jpg))\s+/i)) {
								my $type = $3;
								if ($type eq "jpg") {$type = "jpeg"}
								print $client "HTTP/1.1 200 OK\r\n";
								print $client "Content-type: image/$type\r\n";
								print $client "\r\n";
								print $client $images{$2};
							} else {
								if ($type eq "HTML") {
									print $client "HTTP/1.1 403 OK\r\n";
									print $client "Content-type: text/html\r\n";
									print $client "\r\n";
									foreach my $line (@message) {
										if ($line =~ /\[IPADDRESS\]/) {$line =~ s/\[IPADDRESS\]/$peeraddress/}
										if ($line =~ /\[HOSTNAME\]/) {$line =~ s/\[HOSTNAME\]/$hostname/}
										if ($line =~ /\[RECAPTCHA_SITEKEY\]/) {$line =~ s/\[RECAPTCHA_SITEKEY\]/$config{RECAPTCHA_SITEKEY}/}
										if ($line =~ /\[RECAPTCHA_ERROR=\"([^\"]+)\"\]/) {
											my $text = $1;
											if ($error ne "") {$line =~ s/\[RECAPTCHA_ERROR=\"([^\"]+)\"\]/$text $error/} else {$line =~ s/\[RECAPTCHA_ERROR=\"([^\"]+)\"\]//}
										}
										if ($line =~ /\[RECAPTCHA_SUCCESS=\"([^\"]+)\"\]/) {
											my $text = $1;
											if ($success) {$line =~ s/\[RECAPTCHA_SUCCESS=\"([^\"]+)\"\]/$text/} else {$line =~ s/\[RECAPTCHA_SUCCESS=\"([^\"]+)\"\]//}
										}
										if ($line =~ /\[RECAPTCHA_FAILURE=\"([^\"]+)\"\]/) {
											my $text = $1;
											if ($failure) {$line =~ s/\[RECAPTCHA_FAILURE=\"([^\"]+)\"\]/$text/} else {$line =~ s/\[RECAPTCHA_FAILURE=\"([^\"]+)\"\]//}
										}
										print $client "$line\r\n";
									}
									print $client "\r\n";
								} else {
									foreach my $line (@message) {
										if ($line =~ /\[IPADDRESS\]/) {$line =~ s/\[IPADDRESS\]/$peeraddress/}
										if ($line =~ /\[HOSTNAME\]/) {$line =~ s/\[HOSTNAME\]/$hostname/}
										print $client "$line ";
									}
									print $client "\n";
								}
							}
							alarm(0);
						};
						shutdown ($client,2);
						$client->close();
						alarm(0);
						exit;
					}
					if ($oldtype eq "HTTPS") {
						$client->close(SSL_no_shutdown => 1);
					} else {
						$client->close();
					}
				}
			}
		} else {
			logfile("MESSENGER_USER invalid - stopping $oldtype Messenger");
		}
	} else {
		logfile("MESSENGER_USER not set - stopping $oldtype Messenger");
	}
	return;
}
# end messenger
###############################################################################
# start messengerv2
sub messengerv2 {
	my (undef,undef,$uid,$gid,undef,undef,undef,$homedir) = getpwnam($config{MESSENGER_USER});
	if ($homedir eq "" or $homedir eq "/" or $homedir =~ m[/etc/csf]) {
		return (1, "The home directory for $config{MESSENGER_USER} is not valid [$homedir]");
	}
	if (! -e $homedir) {
		return (1, "The home directory for $config{MESSENGER_USER} does not exist [$homedir]");
	}
	system("chmod","711",$homedir);
	my $public_html = $homedir."/public_html";
	unless (-e $public_html) {
		system("mkdir","-p",$public_html);
		system("chown","$config{MESSENGER_USER}:nobody",$public_html);
		system("chmod","711",$public_html);
	}
	unless (-e $public_html."/.htaccess") {
		open (my $HTACCESS, ">", $public_html."/.htaccess");
		flock ($HTACCESS, LOCK_EX);
		print $HTACCESS "Require all granted\n";
		print $HTACCESS "DirectoryIndex index.php index.cgi index.html index.htm\n";
		print $HTACCESS "Options +FollowSymLinks +ExecCGI\n";
		print $HTACCESS "RewriteEngine On\n";
		print $HTACCESS "RewriteCond \%{REQUEST_FILENAME} !-f\n";
		print $HTACCESS "RewriteCond \%{REQUEST_FILENAME} !-d\n";
		print $HTACCESS "RewriteRule ^ /index.php [L,QSA]\n";
		system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$public_html."/.htaccess");
		system("chmod","644",$public_html."/.htaccess");
	}
	unless (-e $public_html."/index.php") {
		if ($config{RECAPTCHA_SITEKEY}) {
			system("cp","/etc/csf/messenger/index.recaptcha.php",$public_html."/index.php");
		} else {
			system("cp","/etc/csf/messenger/index.php",$public_html."/index.php");
		}
		system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$public_html."/index.php");
		system("chmod","644",$public_html."/index.php");
	}
	unless (-e $homedir."/en.php") {
		system("cp","/etc/csf/messenger/en.php",$homedir."/en.php");
		system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$homedir."/en.php");
		system("chmod","644",$homedir."/en.php");
	}
	open (my $CONF, ">", $homedir."/recaptcha.php");
	flock ($CONF, LOCK_EX);
	print $CONF "<?php\n";
	print $CONF "\$secret = '$config{RECAPTCHA_SECRET}';\n";
	print $CONF "\$sitekey = '$config{RECAPTCHA_SITEKEY}';\n";
	print $CONF "\$unblockfile = '$homedir/unblock.txt';\n";
	print $CONF "\$logfile = '/var/log/lfd_messenger.log';\n";
	print $CONF "?>\n";
	system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$homedir."/recaptcha.php");
	system("chmod","644",$homedir."/recaptcha.php");

	
	open (my $OUT, ">", "/var/lib/csf/csf.conf");
	flock ($OUT, LOCK_EX);

	if ($config{MESSENGER_HTML_IN} ne "") {
		print $OUT "Listen 0.0.0.0:$config{MESSENGER_HTML}\n";
		if ($config{IPV6}) {print $OUT "Listen [::]:$config{MESSENGER_HTML}\n"}
		print $OUT "<VirtualHost *:$config{MESSENGER_HTML}>\n";
		print $OUT " ServerName $hostname\n";
		print $OUT " DocumentRoot $public_html\n";
		print $OUT " <Directory \"$homedir\">\n";
		print $OUT "  AllowOverride All\n";
		print $OUT " </Directory>\n";
		print $OUT " <IfModule suphp_module>\n";
		print $OUT "   suPHP_UserGroup $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
		print $OUT " </IfModule>\n";
		print $OUT " <IfModule suexec_module>\n";
		print $OUT "   <IfModule !mod_ruid2.c>\n";
		print $OUT "     SuexecUserGroup $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
		print $OUT "   </IfModule>\n";
		print $OUT " </IfModule>\n";
		print $OUT " <IfModule ruid2_module>\n";
		print $OUT "   RMode config\n";
		print $OUT "   RUidGid $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
		print $OUT " </IfModule>\n";
		print $OUT " <IfModule mpm_itk.c>\n";
		print $OUT "   AssignUserID $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
		print $OUT " </IfModule>\n";
		print $OUT " KeepAlive Off\n";
		print $OUT "</VirtualHost>\n";
	}

	if ($config{MESSENGER_HTTPS_IN} ne "") {
		my %sslcerts;
		my %sslkeys;
		my %ssldomains;
		my $start = 0;
		my $sslhost;
		my $sslcert;
		my $sslkey;
		my $sslaliases;
		my $ssldir = "/var/lib/csf/ssl/";
		unless (-d $ssldir) {
			mkdir $ssldir;
			mkdir $ssldir."certs/";
			mkdir $ssldir."keys/";
		}
		foreach my $file (glob($config{MESSENGER_HTTPS_CONF})) {
			if (-e $file) {
				foreach my $line (slurp($file)) {
					$line =~ s/\'|\"//g;
					if ($line =~ /^\s*<VirtualHost\s+[^\>]+>/) {
						$start = 1;
					}
					if ($webserver eq "apache" and $start) {
						if ($line =~ /\s*ServerName\s+(\w+:\/\/)?([a-zA-Z0-9\.\-]+)(:\d+)?/) {$sslhost = $2}
						if ($line =~ /\s*ServerAlias\s+(.*)/) {$sslaliases .= " ".$1}
						if ($line =~ /\s*SSLCertificateFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {
								copy($match, $ssldir."certs/".$sslhost."\.crt");
								$sslcert = $ssldir."certs/".$sslhost."\.crt";
							}
						}
						if ($line =~ /\s*SSLCertificateKeyFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {
								copy($match, $ssldir."keys/".$sslhost."\.key");
								$sslkey = $ssldir."keys/".$sslhost."\.key";
							}
						}
					}
					
					if (($webserver eq "apache" and $line =~ /^\s*<\/VirtualHost\s*>/)) {
						$start = 0;
						if ($sslhost ne "" and !checkip($sslhost) and $sslcert ne "") {
							$ssldomains{$sslhost}{key} = $sslkey;
							$ssldomains{$sslhost}{aliases} = $sslaliases;
							$ssldomains{$sslhost}{cert} = $sslcert;
						}
						$sslhost = "";
						$sslcert = "";
						$sslkey = "";
						$sslaliases = "";
					}
				}
			}
		}
		if (scalar(keys %ssldomains < 1)) {
			return (1, "No SSL domains found in MESSENGER_HTTPS_CONF location");
		}

		print $OUT "Listen 0.0.0.0:$config{MESSENGER_HTTPS}\n";
		if ($config{IPV6}) {print $OUT "Listen [::]:$config{MESSENGER_HTTPS}\n"}
		if (-e $config{MESSENGER_HTTPS_KEY}) {
			print $OUT "<VirtualHost *:$config{MESSENGER_HTTPS}>\n";
			print $OUT " ServerName $hostname\n";
			print $OUT " DocumentRoot $public_html\n";
			print $OUT " UseCanonicalName Off\n";
			print $OUT " <Directory \"$homedir\">\n";
			print $OUT "  AllowOverride All\n";
			print $OUT " </Directory>\n";
			print $OUT " <IfModule suphp_module>\n";
			print $OUT "   suPHP_UserGroup $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
			print $OUT " </IfModule>\n";
			print $OUT " <IfModule suexec_module>\n";
			print $OUT "   <IfModule !mod_ruid2.c>\n";
			print $OUT "     SuexecUserGroup $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
			print $OUT "   </IfModule>\n";
			print $OUT " </IfModule>\n";
			print $OUT " <IfModule ruid2_module>\n";
			print $OUT "   RMode config\n";
			print $OUT "   RUidGid $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
			print $OUT " </IfModule>\n";
			print $OUT " <IfModule mpm_itk.c>\n";
			print $OUT "   AssignUserID $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
			print $OUT " </IfModule>\n";
			print $OUT " SSLEngine on\n";
			if (-e $config{MESSENGER_HTTPS_KEY}) {
				copy($config{MESSENGER_HTTPS_KEY}, $ssldir."keys/".$hostname."\.key");
				print $OUT " SSLCertificateKeyFile ".$ssldir."keys/".$hostname."\.key\n";
			}
			if (-e $config{MESSENGER_HTTPS_CRT}) {
				copy($config{MESSENGER_HTTPS_CRT}, $ssldir."certs/".$hostname."\.crt");
				print $OUT " SSLCertificateFile ".$ssldir."certs/".$hostname."\.crt\n";
			}
			print $OUT " SSLUseStapling off\n";
			print $OUT " KeepAlive Off\n";
			print $OUT "</VirtualHost>\n";
		}
		foreach my $key (keys %ssldomains) {
			if ($key eq "") {next}
			if ($key =~ /^\s+$/) {next}
			if (-e $ssldomains{$key}{cert}) {
				print $OUT "<VirtualHost *:$config{MESSENGER_HTTPS}>\n";
				print $OUT " ServerName $key\n";
				print $OUT " ServerAlias $ssldomains{$key}{aliases}\n";
				print $OUT " DocumentRoot $public_html\n";
				print $OUT " UseCanonicalName Off\n";
				print $OUT " <Directory \"$homedir\">\n";
				print $OUT "  AllowOverride All\n";
				print $OUT " </Directory>\n";
				print $OUT " <IfModule suphp_module>\n";
				print $OUT "   suPHP_UserGroup $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
				print $OUT " </IfModule>\n";
				print $OUT " <IfModule suexec_module>\n";
				print $OUT "   <IfModule !mod_ruid2.c>\n";
				print $OUT "     SuexecUserGroup $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
				print $OUT "   </IfModule>\n";
				print $OUT " </IfModule>\n";
				print $OUT " <IfModule ruid2_module>\n";
				print $OUT "   RMode config\n";
				print $OUT "   RUidGid $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
				print $OUT " </IfModule>\n";
				print $OUT " <IfModule mpm_itk.c>\n";
				print $OUT "   AssignUserID $config{MESSENGER_USER} $config{MESSENGER_USER}\n";
				print $OUT " </IfModule>\n";
				print $OUT " SSLEngine on\n";
				if (-e $ssldomains{$key}{cert}) {print $OUT " SSLCertificateFile $ssldomains{$key}{cert}\n"}
				if (-e $ssldomains{$key}{key}) {print $OUT " SSLCertificateKeyFile $ssldomains{$key}{key}\n"}
				print $OUT " SSLUseStapling off\n";
				print $OUT " KeepAlive Off\n";
				print $OUT "</VirtualHost>\n";
			}
		}
	}
	close ($OUT);

	system("cp","-f","/var/lib/csf/csf.conf","/etc/apache2/conf.d/csf.messenger.conf");

	my ($childin, $childout);
	my $cmdpid = open3($childin, $childout, $childout, "/usr/sbin/apachectl", "configtest");
	my @data = <$childout>;
	waitpid ($cmdpid, 0);

	if (-e "/var/lib/csf/apachectl.error") {unlink("/var/lib/csf/apachectl.error")}
	my $ok = 0;
	foreach (@data) {
		if ($_ =~ /^Syntax OK/) {$ok = 1}
	}
	if ($ok) {
		system("/scripts/restartsrv_httpd");
		logfile("MESSENGERV2: Started Apache MESSENGERV2 service using /etc/apache2/conf.d/csf.messenger.conf");
	} else {
		logfile("*MESSENGERV2*: Unable to generate a valid Apache configuration, see /var/lib/csf/apachectl.error");
		if (-e "/etc/apache2/conf.d/csf.messenger.conf") {unlink("/etc/apache2/conf.d/csf.messenger.conf")}
		system("/scripts/restartsrv_httpd");
		
		open (my $ERROR, ">", "/var/lib/csf/apachectl.error");
		flock ($ERROR, LOCK_EX);
		foreach (@data) {print $ERROR $_}
		close ($ERROR);
	}
	return;
}
# end messengerv2
###############################################################################
# start messengerv3
sub messengerv3 {
	my (undef,undef,$uid,$gid,undef,undef,undef,$homedir) = getpwnam($config{MESSENGER_USER});
	if ($homedir eq "" or $homedir eq "/" or $homedir =~ m[/etc/csf]) {
		return (1, "The home directory for $config{MESSENGER_USER} is not valid [$homedir]");
	}
	if (! -e $homedir) {
		return (1, "The home directory for $config{MESSENGER_USER} does not exist [$homedir]");
	}
	my $public_html = $homedir."/public_html";
	unless (-e $public_html) {
		system("mkdir","-p",$public_html);
		system("chown","$config{MESSENGER_USER}:$config{MESSENGERV3GROUP}",$public_html);
		system("chmod",$config{MESSENGERV3PERMS},$public_html);
	}
	unless (-e $public_html."/.htaccess") {
		open (my $HTACCESS, ">", $public_html."/.htaccess");
		flock ($HTACCESS, LOCK_EX);
		print $HTACCESS <<EOF;
Require all granted
DirectoryIndex index.php index.cgi index.html index.htm
#Options +FollowSymLinks +ExecCGI
RewriteEngine On
RewriteCond \%{REQUEST_FILENAME} !-f
RewriteCond \%{REQUEST_FILENAME} !-d
RewriteRule ^ /index.php [L,QSA]
EOF
		system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$public_html."/.htaccess");
		system("chmod","644",$public_html."/.htaccess");
	}
	unless (-e $public_html."/index.php") {
		if ($config{RECAPTCHA_SITEKEY}) {
			system("cp","/etc/csf/messenger/index.recaptcha.php",$public_html."/index.php");
		} else {
			system("cp","/etc/csf/messenger/index.php",$public_html."/index.php");
		}
		system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$public_html."/index.php");
		system("chmod","644",$public_html."/index.php");
	}
	unless (-e $homedir."/en.php") {
		system("cp","/etc/csf/messenger/en.php",$homedir."/en.php");
		system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$homedir."/en.php");
		system("chmod","644",$homedir."/en.php");
	}
	open (my $CONF, ">", $homedir."/recaptcha.php");
	flock ($CONF, LOCK_EX);
	print $CONF "<?php\n";
	print $CONF "\$secret = '$config{RECAPTCHA_SECRET}';\n";
	print $CONF "\$sitekey = '$config{RECAPTCHA_SITEKEY}';\n";
	print $CONF "\$unblockfile = '$homedir/unblock.txt';\n";
	print $CONF "\$logfile = '/var/log/lfd_messenger.log';\n";
	print $CONF "?>\n";
	system("chown","$config{MESSENGER_USER}:$config{MESSENGER_USER}",$homedir."/recaptcha.php");
	system("chmod","644",$homedir."/recaptcha.php");

	if ($config{MESSENGERV3WEBSERVER} eq "apache") {
		$webserver = "apache";
	}
	elsif ($config{MESSENGERV3WEBSERVER} eq "litespeed") {
		$webserver = "litespeed";
	}

	open (my $OUT, ">", "/var/lib/csf/csf.conf");
	flock ($OUT, LOCK_EX);

	if ($config{MESSENGERV3PHPHANDLER} ne "") {
		$phphandler = $config{MESSENGERV3PHPHANDLER};
	} else {
		my $file = "/etc/httpd/conf/extra/httpd-hostname.conf";
		if (-e $file) {
			foreach my $line (slurp($file)) {
				if ($line =~ /^\s*AddHandler\s+.+\s+\.php/) {
					$phphandler = $line;
					if ($config{DEBUG} >= 1) {logfile("SSL: PHP Handler found in [$file]")}
				}
			}
		}
	}

	foreach my $line (slurp("/usr/local/csf/tpl/$webserver.main.txt")) {
		$line =~ s/\[PORT\]/$config{MESSENGER_HTML}/g;
		if ($line =~ /Listen \[::\]:/ and !$config{IPV6}) {next}
		$line =~ s/\[SERVERNAME\]/$hostname/g;
		$line =~ s/\[DOCUMENTROOT\]/$public_html/g;
		$line =~ s/\[DIRECTORY\]/$homedir/g;
		$line =~ s/\[USER\]/$config{MESSENGER_USER}/g;
		$line =~ s/\[PHPHANDLER\]/$phphandler/g;
		print $OUT $line."\n";
	}
	
	if ($config{MESSENGER_HTML_IN} ne "") {
		foreach my $line (slurp("/usr/local/csf/tpl/$webserver.http.txt")) {
			$line =~ s/\[PORT\]/$config{MESSENGER_HTML}/g;
			if ($line =~ /Listen \[::\]:/ and !$config{IPV6}) {next}
			$line =~ s/\[SERVERNAME\]/$hostname/g;
			$line =~ s/\[DOCUMENTROOT\]/$public_html/g;
			$line =~ s/\[DIRECTORY\]/$homedir/g;
			$line =~ s/\[USER\]/$config{MESSENGER_USER}/g;
			$line =~ s/\[PHPHANDLER\]/$phphandler/g;
			print $OUT $line."\n";
		}
	}

	if ($config{MESSENGER_HTTPS_IN} ne "") {
		if ($webserver eq "litespeed") {
			if ($config{MESSENGERV3HTTPS_CONF} =~ /(.*\/lsws\/)/) {
				$serverroot = $1;
			}
		}
		&conftree($config{MESSENGERV3HTTPS_CONF});
		if ($webserver eq "litespeed") {
			if ($sslhost ne "" and $osslcert ne "" and $ssldomains{$sslhost}{cert} eq "") {
				if (-e $osslcert) {
					$sslcert = $ssldir."certs/".$sslhost."\.crt";
					copy($osslcert, $ssldir."certs/".$sslhost."\.crt");
				}
				if (-e $osslkey) {
					$sslkey = $ssldir."keys/".$sslhost."\.key";
					copy($osslkey, $ssldir."keys/".$sslhost."\.key");
				}
				if (-e $osslca) {
					$sslca = $ssldir."ca/".$sslhost."\.ca";
					copy($osslca, $ssldir."ca/".$sslhost."\.ca");
				}
				$sslaliases =~ s/\$VH_NAME/$sslhost/;
				$ssldomains{$sslhost}{key} = $sslkey;
				$ssldomains{$sslhost}{aliases} = $sslaliases;
				$ssldomains{$sslhost}{cert} = $sslcert;
				$ssldomains{$sslhost}{ca} = $sslca;
				push @ssldomainkeys, $sslhost;

				$sslhost = "";
				$sslcert = "";
				$sslkey = "";
				$sslca = "";
				$osslcert = "";
				$osslkey = "";
				$osslca = "";
				$sslaliases = "";
			}
		}

		if (scalar(keys %ssldomains < 1)) {
			return (1, "No SSL domains found in MESSENGERV3HTTPS_CONF location [$config{MESSENGERV3HTTPS_CONF}] for $webserver web server");
		}

		my @virtualhost;
		my $start = 0;
		my $key = $ssldomainkeys[0];
		foreach my $line (slurp("/usr/local/csf/tpl/$webserver.https.txt")) {
			if ($line =~ /^\# Virtualhost start/) {$start = 1}
			if ($start) {
				if ($line =~ /^\# Virtualhost end/) {$start = 0}
				push @virtualhost, $line;
				next;
			}
			$line =~ s/\[SSLPORT\]/$config{MESSENGER_HTTPS}/g;
			if ($line =~ /Listen \[::\]:/ and !$config{IPV6}) {next}
			$line =~ s/\[SERVERNAME\]/$hostname/g;
			$line =~ s/\[DOCUMENTROOT\]/$public_html/g;
			$line =~ s/\[DIRECTORY\]/$homedir/g;
			$line =~ s/\[USER\]/$config{MESSENGER_USER}/g;
			$line =~ s/\[PHPHANDLER\]/$phphandler/g;
			if ($line =~ /[MAPS]/) {
				my $mapping;
				foreach my $map (@ssldomainkeys) {
					if (-e $ssldomains{$map}{cert}) {
						$mapping .= "map csfssl.${map} ${map}\n\t";
					}
				}
				$line =~ s/\[MAPS\]/$mapping/g;
			}
			if ($line =~ /\[SSLCERTIFICATEFILE\]/) {
				if ( -e $ssldomains{$key}{cert}) {
					$line =~ s/\[SSLCERTIFICATEFILE\]/$ssldomains{$key}{cert}/g;
				} else {next}
			}

			if ($line =~ /\[SSLCERTIFICATEKEYFILE\]/) {
				if (-e $ssldomains{$key}{key}) {
					$line =~ s/\[SSLCERTIFICATEKEYFILE\]/$ssldomains{$key}{key}/g;
				} else {next}
			}

			if ($line =~ /\[SSLCACERTIFICATEFILE\]/) {
				if (-e $ssldomains{$key}{ca}) {
					$line =~ s/\[SSLCACERTIFICATEFILE\]/$ssldomains{$key}{ca}/g;
				} else {next}
			}

			print $OUT $line."\n";
		}

		foreach my $key (@ssldomainkeys) {
			if ($key eq "") {next}
			if ($key =~ /^\s+$/) {next}
			if ($config{DEBUG} >= 1) {logfile("SSL: Processing [$key]")}

			if (-e $ssldomains{$key}{cert}) {
				foreach (@virtualhost) {
					my $line = $_;
					$line =~ s/\[SSLPORT\]/$config{MESSENGER_HTTPS}/g;
					$line =~ s/\[SERVERNAME\]/$key/g;
					$line =~ s/\[SERVERALIAS\]/$ssldomains{$key}{aliases}/g;
					$line =~ s/\[DOCUMENTROOT\]/$public_html/g;
					$line =~ s/\[DIRECTORY\]/$homedir/g;
					$line =~ s/\[USER\]/$config{MESSENGER_USER}/g;
					$line =~ s/\[PHPHANDLER\]/$phphandler/g;

					if ($line =~ /\[SSLCERTIFICATEFILE\]/) {
						if ( -e $ssldomains{$key}{cert}) {
							$line =~ s/\[SSLCERTIFICATEFILE\]/$ssldomains{$key}{cert}/g;
						} else {next}
					}

					if ($line =~ /\[SSLCERTIFICATEKEYFILE\]/) {
						if (-e $ssldomains{$key}{key}) {
							$line =~ s/\[SSLCERTIFICATEKEYFILE\]/$ssldomains{$key}{key}/g;
						} else {next}
					}

					if ($line =~ /\[SSLCACERTIFICATEFILE\]/) {
						if (-e $ssldomains{$key}{ca}) {
							$line =~ s/\[SSLCACERTIFICATEFILE\]/$ssldomains{$key}{ca}/g;
						} else {next}
					}

					print $OUT $line."\n";
				}
			}
		}
	}
	close ($OUT);

	my $location;
	if (-d $config{MESSENGERV3LOCATION}) {
		system("cp","-f","/var/lib/csf/csf.conf",$config{MESSENGERV3LOCATION}."/csf.messenger.conf");
		$location = $config{MESSENGERV3LOCATION}."/csf.messenger.conf";
	}
	elsif (-f $config{MESSENGERV3LOCATION}) {
		my @conf = slurp($config{MESSENGERV3LOCATION});
		unless (grep {$_ =~ m[^Include /var/lib/csf/csf.conf]i} @conf) {
			sysopen (my $FILE, $config{MESSENGERV3LOCATION}, O_WRONLY | O_APPEND | O_CREAT);
			flock ($FILE, LOCK_EX);
			if ($webserver eq "apache") {
				print $FILE "Include /var/lib/csf/csf.conf\n";
			}
			elsif ($webserver eq "litespeed") {
				print $FILE "include /var/lib/csf/csf.conf\n";
			}
			close ($FILE);
		}
		$location = $config{MESSENGERV3LOCATION};
	}
	else {
		logfile("MESSENGERV3: [$config{MESSENGERV3LOCATION}] is neither a directory nor a file. You must manually include /var/lib/csf/csf.conf into the $webserver configuration");
		return;
	}

	if ($config{MESSENGERV3TEST} ne "") {
		my ($childin, $childout);
		my $cmdpid = open3($childin, $childout, $childout, $config{MESSENGERV3TEST});
		my @data = <$childout>;
		waitpid ($cmdpid, 0);

		if (-e "/var/lib/csf/messenger.error") {unlink("/var/lib/csf/messenger.error")}
		my $ok = 0;
		foreach (@data) {
			if ($_ =~ /^Syntax OK/) {$ok = 1}
		}
		if ($ok) {
			system($config{MESSENGERV3RESTART});
			logfile("MESSENGERV3: Restarted $webserver MESSENGERV3 service using $location");
		} else {
			open (my $ERROR, ">", "/var/lib/csf/messenger.error");
			flock ($ERROR, LOCK_EX);
			foreach (@data) {print $ERROR $_}
			close ($ERROR);

			if (-d $config{MESSENGERV3LOCATION}) {
				unlink ($config{MESSENGERV3LOCATION}."/csf.messenger.conf");
			}
			elsif (-f $config{MESSENGERV3LOCATION}) {
				my @conf = slurp($config{MESSENGERV3LOCATION});
				if (grep {$_ =~ m[^Include /var/lib/csf/csf.conf]i} @conf) {
					sysopen (my $FILE, $config{MESSENGERV3LOCATION}, O_WRONLY | O_CREAT | O_TRUNC);
					flock ($FILE, LOCK_EX);
					foreach my $line (@conf) {
						$line =~ s/$cleanreg//g;
						if ($line =~ m[^Include /var/lib/csf/csf.conf]i) {next}
						print $FILE $line."\n";
					}
					close ($FILE);
				}
			}

			system($config{MESSENGERV3RESTART});

			logfile("*MESSENGERV3*: Unable to generate a valid $webserver configuration, see /var/lib/csf/messenger.error");
		}
	} else {
		system($config{MESSENGERV3RESTART});
		logfile("MESSENGERV3: Restarted $webserver MESSENGERV3 service using $location");
	}
	return;
}
# end messengerv3
###############################################################################
# start messengerlog
sub messengerlog {
	my $homedir = shift;
	my $message = shift;
	if ($config{DEBUG}) {
		sysopen (my $LOG, "/var/log/lfd_messenger.log", O_WRONLY | O_APPEND | O_CREAT);
		print $LOG "[$$]: ".$message."\n";
		close ($LOG);
	}
	return;
}
# end messengerlog
###############################################################################
# start childcleanup
sub childcleanup {
	$SIG{INT} = 'IGNORE';
	$SIG{TERM} = 'IGNORE';
	$SIG{HUP} = 'IGNORE';
	my $line = shift;
	my $message = shift;

	if (($message eq "") and $line) {
		$message = "Child $childproc: $line";
		$line = "";
	}

	$0 = "child - aborting";

	if ($message) {
		if ($line ne "") {$message .= ", at line $line"}
		logfile("$message");
	}
    exit;
}
# end childcleanup
###############################################################################
# start getethdev
sub getethdev {
	my $ethdev = ConfigServer::GetEthDev->new();
	my %g_ipv4 = $ethdev->ipv4;
	my %g_ipv6 = $ethdev->ipv6;
	foreach my $key (keys %g_ipv4) {
		my $netip = Net::IP->new($key);
		my $type = $netip->iptype();
		if ($type eq "PUBLIC") {$ips{$key} = 1}
	}
	if ($config{IPV6}) {
		foreach my $key (keys %g_ipv6) {
			if ($key !~ m[::1/128]) {
				eval {
					local $SIG{__DIE__} = undef;
					$ipscidr6->add($key);
				};
			}
		}
	}
	return;
}
# end getethdev
###############################################################################
# start error
sub error {
	my $error = shift;
	logfile($error);
	exit;
}
# end error
###############################################################################
# start conftree
sub conftree {
	my $fileglob = shift;
	foreach my $file (glob($fileglob)) {
		if ($file =~ /csf\.messenger\.conf$/) {next}
		if ($file =~ /\/var\/lib\/csf\/csf.conf$/) {next}
		if (-e $file) {
			if ($config{DEBUG} >= 1) {logfile("SSL: Processing [$file]")}
			my $start = 0;
			foreach my $line (slurp($file)) {
				if ($webserver eq "apache") {
					$line =~ s/\'|\"//g;
					if ($line =~ /^\s*ServerRoot\s+\"?(\S+)\"?/) {
						$serverroot = $1;
						unless (-d $serverroot) {$serverroot = ""}
					}
					if ($serverroot eq "" and -d "/etc/apache2") {$serverroot = "/etc/apache2"}
					if ($line =~ /^\s*Include\s+(\S+)/) {
						my $include = $1;
						if ($include !~ /^\//) {$include = "$serverroot/$include"}
						if ($config{DEBUG} >= 1) {logfile("SSL: Including [$include]")}
						&conftree($include);
					}
					if ($line =~ /^\s*IncludeOptional\s+(\S+)/) {
						my $include = $1;
						if ($include !~ /^\//) {$include = "$serverroot/$include"}
						if ($config{DEBUG} >= 1) {logfile("SSL: IncludeOptional [$include]")}
						&conftree($include);
					}
					if ($line =~ /^\s*<VirtualHost\s+[^\>]+>/) {
						$start = 1;
					}
					if ($start) {
						if ($line =~ /\s*ServerName\s+(\w+:\/\/)?([a-zA-Z0-9\.\-]+)(:\d+)?/) {$sslhost = $2}
						if ($line =~ /\s*ServerAlias\s+(.*)/) {$sslaliases .= " ".$1}
						if ($line =~ /\s*SSLCertificateFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {
								$osslcert = $match;
								logfile("SSL: Found [$sslhost] certificate in [$file]");
							}
						}
						if ($line =~ /\s*SSLCertificateKeyFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {
								$osslkey = $match;
								logfile("SSL: Found [$sslhost] key in [$file]");
							}
						}
						if ($line =~ /\s*SSLCACertificateFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {
								$osslca = $match;
								logfile("SSL: Found [$sslhost] ca bundle in [$file]");
							}
						}
					}
					
					if ($line =~ /^\s*<\/VirtualHost\s*>/) {
						$start = 0;
						if ($sslhost ne "" and !checkip($sslhost) and $osslcert ne "") {
							if (-e $osslcert) {
								$sslcert = $ssldir."certs/".$sslhost."\.crt";
								copy($osslcert, $ssldir."certs/".$sslhost."\.crt");
							}
							if (-e $osslkey) {
								$sslkey = $ssldir."keys/".$sslhost."\.key";
								copy($osslkey, $ssldir."keys/".$sslhost."\.key");
							}
							if (-e $osslca) {
								$sslca = $ssldir."ca/".$sslhost."\.ca";
								copy($osslca, $ssldir."ca/".$sslhost."\.ca");
							}
							$ssldomains{$sslhost}{key} = $sslkey;
							$ssldomains{$sslhost}{aliases} = $sslaliases;
							$ssldomains{$sslhost}{cert} = $sslcert;
							$ssldomains{$sslhost}{ca} = $sslca;
							push @ssldomainkeys, $sslhost;
							if ($config{DEBUG} >= 1) {logfile("SSL: Found [$sslhost] in [$file]")}
						}
						$sslhost = "";
						$sslcert = "";
						$sslkey = "";
						$sslca = "";
						$osslcert = "";
						$osslkey = "";
						$osslca = "";
						$sslaliases = "";
					}
				}
				elsif ($webserver eq "litespeed") {
					$line =~ s/\'|\"//g;
					if ($line =~ /^\s*include\s+(\S+)/) {
						my $include = $1;
						$include =~ s/\$SERVER_ROOT/$serverroot/;
						$include =~ s/\$VH_NAME/$sslhost/;
						if ($include !~ /^\//) {$include = "$serverroot/$include"}
						if ($config{DEBUG} >= 1) {logfile("SSL: include [$include]")}
						&conftree($include);
					}
					if ($line =~ /^\s*configFile\s+(\S+)/) {
						my $include = $1;
						$include =~ s/\$SERVER_ROOT/$serverroot/;
						$include =~ s/\$VH_NAME/$sslhost/;
						if ($include !~ /^\//) {$include = "$serverroot/$include"}
						if ($config{DEBUG} >= 1) {logfile("SSL: configFile [$include]")}
						&conftree($include);
					}
					if ($line =~ /^\s*virtualHost\s+([^\{]+)\s+\{/) {
						my $newsslhost = $1;
						if ($newsslhost ne "" and $config{DEBUG} >= 1) {logfile("SSL: Found [$newsslhost] in [$file]")}
						if ($litestart == 1) {
							if ($sslhost ne "" and $osslcert ne "") {
								if (-e $osslcert) {
									$sslcert = $ssldir."certs/".$sslhost."\.crt";
									copy($osslcert, $ssldir."certs/".$sslhost."\.crt");
								}
								if (-e $osslkey) {
									$sslkey = $ssldir."keys/".$sslhost."\.key";
									copy($osslkey, $ssldir."keys/".$sslhost."\.key");
								}
								if (-e $osslca) {
									$sslca = $ssldir."ca/".$sslhost."\.ca";
									copy($osslca, $ssldir."ca/".$sslhost."\.ca");
								}
								$sslaliases =~ s/\$VH_NAME/$sslhost/;
								$ssldomains{$sslhost}{key} = $sslkey;
								$ssldomains{$sslhost}{aliases} = $sslaliases;
								$ssldomains{$sslhost}{cert} = $sslcert;
								$ssldomains{$sslhost}{ca} = $sslca;
								push @ssldomainkeys, $sslhost;

								$sslhost = "";
								$sslcert = "";
								$sslkey = "";
								$sslca = "";
								$osslcert = "";
								$osslkey = "";
								$osslca = "";
								$sslaliases = "";
							}
						}
						$litestart = 1;
						$sslhost = $newsslhost;
					}
					if ($litestart) {
						if ($line =~ /\s*vhDomain\s+(\w+:\/\/)?([a-zA-Z0-9\.\-]+)(:\d+)?/) {$sslhost = $2}
						if ($line =~ /\s*vhAliases\s+(.*)/) {$sslaliases .= " ".$1}
						if ($line =~ /\s*certFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {
								$osslcert = $match;
								logfile("SSL: Found [$sslhost] certificate in [$file]");
							}
						}
						if ($line =~ /\s*keyFile\s+(\S+)/) {
							my $match = $1;
							if (-e $match) {
								$osslkey = $match;
								logfile("SSL: Found [$sslhost] key in [$file]");
							}
						}
					}
				}
			}
		}
	}
	return;
}
# end conftree
###############################################################################

1;
