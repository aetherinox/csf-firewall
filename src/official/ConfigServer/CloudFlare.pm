###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::CloudFlare;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use Fcntl qw(:DEFAULT :flock);
use JSON::Tiny();
use LWP::UserAgent;
use Time::Local();
use ConfigServer::Config;
use ConfigServer::Slurp qw(slurp);
use ConfigServer::Logger qw(logfile);

use Exporter qw(import);
our $VERSION     = 1.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();

my $slurpreg = ConfigServer::Slurp->slurpreg;
my $cleanreg = ConfigServer::Slurp->cleanreg;

my %args;
$args{"content-type"} = "application/json";

if ($config{DEBUG} >= 2) {
	require Data::Dumper;
	import Data::Dumper;
}

if (-e "/usr/local/cpanel/version") {
	require YAML::Tiny;
}

# end main
###############################################################################
# start action
sub action {
	my $action = shift;
	my $ip = shift;
	my $mode = shift;
	my $id = shift;
	my $domainlist = shift;
	my $allowany = shift;

	my $status;
	my $return;

	if ($config{DEBUG} == 1) {logfile("Debug: CloudFlare - [$action] [$ip] [$mode] [$id] [$domainlist] [$allowany]")}
	unless ($config{URLGET}) {
		logfile("CloudFlare: URLGET must be set to 1 to use LWP for this feature");
		return;
	}

	if ($action eq "remove") {
		my @newfile;
		sysopen (my $TEMP, "/var/lib/csf/cloudflare.temp", O_RDWR | O_CREAT);
		flock($TEMP, LOCK_EX);
		my $hit;
		while (my $line = <$TEMP>) {
			chomp $line;
			my ($rip,$mode,$user,$raccount,$rapikey,$rid,$time) = split(/\|/,$line);

			if ($ip eq $rip) {
				$args{"X-Auth-Email"} = $raccount;
				$args{"X-Auth-Key"} = $rapikey;

				$status = &remove($ip,$mode,$rid);
				logfile($status." ($user)");
				$hit = 1;
			} else {
				push @newfile, $line;
			}
		}
		if ($hit) {
			seek ($TEMP, 0, 0);
			truncate ($TEMP, 0);
			foreach my $line (@newfile) {
				print $TEMP $line."\n";
			}
		}
		close ($TEMP);
	} else {
		my %authlist;
		my %domains;
		foreach my $domain (split(/\,/,$domainlist)) {
			$domain =~ s/\s//g;
			if ($domain eq "") {next}
			$domain =~ s/^www\.//;
			$domains{$domain} = 1;
		}

		my $scope = &getscope();

		foreach my $user (keys %{$scope->{user}}) {
			if ($allowany and ($scope->{user}{$user}{domain} eq "any" or $scope->{user}{$user}{any})) {
				$authlist{$scope->{user}{$user}{account}}{apikey} = $scope->{user}{$user}{apikey};
				$authlist{$scope->{user}{$user}{account}}{user} = $user;
			}

			foreach my $domain (keys %domains) {
				if ($scope->{domain}{$domain}{user} eq $user) {
					$authlist{$scope->{domain}{$domain}{account}}{apikey} = $scope->{domain}{$domain}{apikey};
					$authlist{$scope->{domain}{$domain}{account}}{user} = $scope->{domain}{$domain}{user};
				}
				foreach my $userdomain (keys %{$scope->{user}{$user}{domain}}) {
					if ($user eq $domain and $scope->{user}{$user}{domain}{$userdomain} ne "") {
						$authlist{$scope->{user}{$user}{account}}{apikey} = $scope->{user}{$user}{apikey};
						$authlist{$scope->{user}{$user}{account}}{user} = $user;
					}
				}
			}
		}

		my @list;
		foreach my $account (sort keys %authlist) {
			$args{"X-Auth-Email"} = $account;
			$args{"X-Auth-Key"} = $authlist{$account}{apikey};
			my $user = $authlist{$account}{user};

			if ($action eq "deny") {
				my ($id,$status) = &block($ip);
				logfile($status." ($user)");
				sysopen (my $TEMP, "/var/lib/csf/cloudflare.temp", O_WRONLY | O_APPEND | O_CREAT);
				flock($TEMP, LOCK_EX);
				print $TEMP "$ip|$mode|$user|$account|$authlist{$account}{apikey}|$id|".time."\n";
				close ($TEMP);
			}
			elsif ($action eq "allow") {
				my ($id,$status) = &whitelist($ip);
				logfile($status." ($user)");
				sysopen (my $TEMP, "/var/lib/csf/cloudflare.temp", O_WRONLY | O_APPEND | O_CREAT);
				flock($TEMP, LOCK_EX);
				print $TEMP "$ip|$mode|$user|$account|$authlist{$account}{apikey}|$id|".time."\n";
				close ($TEMP);
			}
			elsif ($action eq "del") {
				my $status = &remove($ip,$mode);
				print "csf - $status ($user)\n";
			}
			elsif ($action eq "add") {
				my $id;
				my $status;
				if ($mode eq "block") {($id,$status) = &block($ip)}
				if ($mode eq "challenge") {($id,$status) = &challenge($ip)}
				if ($mode eq "whitelist") {($id,$status) = &whitelist($ip)}
				print "csf - $status ($user)\n";
			}
			elsif ($action eq "getlist") {
				push @list, &getlist($user);
			}
		}
		if ($action eq "getlist") {return @list}
	}

	return;
}
# end action
###############################################################################
# start block
sub block {
	my $ip = shift;
	my $target = &checktarget($ip);

	my $block->{mode} = $config{CF_BLOCK};
	$block->{configuration}->{target} = $target;
	$block->{configuration}->{value} = $ip;
	$block->{notes} = "csf $config{CF_BLOCK}";

	my $content;
	eval {
		local $SIG{__DIE__} = undef;
		$content = JSON::Tiny::encode_json($block);
	};

	my $ua = LWP::UserAgent->new;
	my $res = $ua->post('https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules', %args, Content => $content);

	if ($res->is_success) {
		my $id = JSON::Tiny::decode_json($res->content);
		return $id->{result}->{id},"CloudFlare: $config{CF_BLOCK} $target $ip";
	} else {
		if ($config{DEBUG} == 1) {print "Debug: ".$res->content."\n"}
		elsif ($config{DEBUG} >= 2) {
			eval {
				local $SIG{__DIE__} = undef;
				print Dumper(JSON::Tiny::decode_json($res->content));
			};
		}
		return "CloudFlare: [$ip] $config{CF_BLOCK} failed: ".$res->status_line;
	}
}
# end block
###############################################################################
# start whitelist
sub whitelist {
	my $ip = shift;
	my $target = &checktarget($ip);

	my $whitelist->{mode} = "whitelist";
	$whitelist->{configuration}->{target} = $target;
	$whitelist->{configuration}->{value} = $ip;
	$whitelist->{notes} = "csf whitelist";

	my $content;
	eval {
		local $SIG{__DIE__} = undef;
		$content = JSON::Tiny::encode_json($whitelist);
	};

	my $ua = LWP::UserAgent->new;
	my $res = $ua->post('https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules', %args, Content => $content);

	if ($res->is_success) {
		my $id = JSON::Tiny::decode_json($res->content);
		return $id->{result}->{id}, "CloudFlare: whitelisted $target $ip";
	} else {
		if ($config{DEBUG} == 1) {print "Debug: ".$res->content."\n"}
		elsif ($config{DEBUG} >= 2) {
			eval {
				local $SIG{__DIE__} = undef;
				print Dumper(JSON::Tiny::decode_json($res->content));
			};
		}
		return "CloudFlare: [$ip] whitelist failed: ".$res->status_line;
	}
}
# end whitelist
###############################################################################
# start challenge
sub challenge {
	my $ip = shift;
	my $target = &checktarget($ip);

	my $challenge->{mode} = "challenge";
	$challenge->{configuration}->{target} = $target;
	$challenge->{configuration}->{value} = $ip;
	$challenge->{notes} = "csf challenge";

	my $content;
	eval {
		local $SIG{__DIE__} = undef;
		$content = JSON::Tiny::encode_json($challenge);
	};

	my $ua = LWP::UserAgent->new;
	my $res = $ua->post('https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules', %args, Content => $content);

	if ($res->is_success) {
		my $id = JSON::Tiny::decode_json($res->content);
		return $id->{result}->{id}, "CloudFlare: challenged $target $ip";
	} else {
		if ($config{DEBUG} == 1) {print "Debug: ".$res->content."\n"}
		elsif ($config{DEBUG} >= 2) {
			eval {
				local $SIG{__DIE__} = undef;
				print Dumper(JSON::Tiny::decode_json($res->content));
			};
		}
		return "CloudFlare: [$ip] challenge failed: ".$res->status_line;
	}
}
# end challenge
###############################################################################
# start add
sub add {
	my $ip = shift;
	my $mode = shift;
	my $target = &checktarget($ip);

	my $add->{mode} = $mode;
	$add->{configuration}->{target} = $target;
	$add->{configuration}->{value} = $ip;

	my $content;
	eval {
		local $SIG{__DIE__} = undef;
		$content = JSON::Tiny::encode_json($add);
	};

	my $ua = LWP::UserAgent->new;
	my $res = $ua->post('https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules', %args, Content => $content);

	if ($res->is_success) {
		my $id = JSON::Tiny::decode_json($res->content);
		return $id->{result}->{id}, "CloudFlare: $mode added $target $ip";
	} else {
		if ($config{DEBUG} == 1) {print "Debug: ".$res->content."\n"}
		elsif ($config{DEBUG} >= 2) {
			eval {
				local $SIG{__DIE__} = undef;
				print Dumper(JSON::Tiny::decode_json($res->content));
			};
		}
		return "CloudFlare: [$ip] $mode failed: ".$res->status_line;
	}
}
# end whitelist
###############################################################################
# start remove
sub remove {
	my $ip = shift;
	my $mode = shift;
	my $id = shift;
	my $target = &checktarget($ip);

	if ($id eq "") {
		$id = getid($ip,$mode);
		if ($id =~ /CloudFlare:/) {return $id}
		if ($id eq "") {return "CloudFlare: [$ip] remove failed: id not found"}
	}

	my $ua = LWP::UserAgent->new;
	my $res = $ua->delete('https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules/'.$id, %args);

	if ($res->is_success) {
		return "CloudFlare: removed $target $ip";
	} else {
		if ($config{DEBUG} == 1) {print "Debug: ".$res->content."\n"}
		elsif ($config{DEBUG} >= 2) {
			eval {
				local $SIG{__DIE__} = undef;
				print Dumper(JSON::Tiny::decode_json($res->content));
			};
		}
		return "CloudFlare: [$ip] [$id] remove failed: ".$res->status_line;
	}
}
# end remove
###############################################################################
# start getid
sub getid {
	my $ip = shift;
	my $mode = shift;
	my $target = &checktarget($ip);

	my $ua = LWP::UserAgent->new;
	my $res = $ua->get('https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules?page=1&per_page=100&configuration.target='.$target.'&configuration.value='.$ip.'&match=all&order=mode&direction=desc', %args);

	if ($res->is_success) {
		my $result = JSON::Tiny::decode_json($res->content);
		my $entry = @{$result->{result}}[0];
		return $entry->{id};
	} else {
		if ($config{DEBUG} == 1) {print "Debug: ".$res->content."\n"}
		elsif ($config{DEBUG} >= 2) {
			eval {
				local $SIG{__DIE__} = undef;
				print Dumper(JSON::Tiny::decode_json($res->content));
			};
		}
		return "CloudFlare: [$ip] id [$mode] failed: ".$res->status_line;
	}
}
# end getid
###############################################################################
# start getlist
sub getlist {
	my $domain = shift;

	my %ips;
	my $page = 1;
	my $pages = 1;
	my $result;

	my $ua = LWP::UserAgent->new;

	while (1) {
		my $res = $ua->get('https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules?page='.$page.'&per_page=100&order=created_on&direction=asc&match=all', %args);
		if ($res->is_success) {
			my $result = JSON::Tiny::decode_json($res->content);

			$pages = $result->{result_info}->{total_pages};
			foreach my $entry (@{$result->{result}}) {
				if ($entry->{configuration}->{target} eq "ip" or $entry->{configuration}->{target} eq "country" or $entry->{configuration}->{target} eq "ip_range") {
					my ($date, $time) = split /T/ => $entry->{created_on};
					my ($year, $mon, $mday) = split /-/ => $date;
					$year -= 1900;
					$mon -= 1;
					my ($hour, $min, $sec) = split /:/ => $time;
					my $timelocal = Time::Local::timelocal($sec, $min, $hour, $mday, $mon, $year);

					$ips{$entry->{configuration}->{value}}{notes} = $entry->{notes};
					$ips{$entry->{configuration}->{value}}{mode} = $entry->{mode};
					$ips{$entry->{configuration}->{value}}{created_on} = $timelocal;
					$ips{$entry->{configuration}->{value}}{domain} = $domain;
					$ips{$entry->{configuration}->{value}}{success} = 1;
				}
			}
		} else {
			if ($config{DEBUG} >= 2) {
				eval {
					local $SIG{__DIE__} = undef;
					print Dumper(JSON::Tiny::decode_json($res->content));
				};
			}
			$ips{$domain}{success} = 0;
			$ips{$domain}{domain} = "CloudFlare: list failed for ($domain): ".$res->status_line;
			return \%ips;
		}
		$page++;
		if ($pages < $page) {last}
	}
	return \%ips;
}
# end getlist
###############################################################################
# start getscope
sub getscope {
	my %scope;
	my %disabled;
	my %any;
	my @entries = slurp("/etc/csf/csf.cloudflare");
	foreach my $line (@entries) {
		if ($line =~ /^Include\s*(.*)$/) {
			my @incfile = slurp($1);
			push @entries,@incfile;
		}
	}
	foreach my $line (@entries) {
		$line =~ s/$cleanreg//g;
		if ($line eq "") {next}
		if ($line =~ /^\s*\#|Include/) {next}

		my @setting = split(/\:/,$line);

		if ($setting[0] eq "DOMAIN") {
			my $domain = $setting[1];
			my $user = $setting[3];
			my $account = $setting[5];
			my $apikey = $setting[7];

			$scope{domain}{$domain}{account} = $account;
			$scope{domain}{$domain}{apikey} = $apikey;
			$scope{domain}{$domain}{user} = $user;
			$scope{user}{$user}{account} = $account;
			$scope{user}{$user}{apikey} = $apikey;
			$scope{user}{$user}{domain}{$domain} = $domain;
			if ($domain eq "any") {$scope{user}{$user}{any} = 1}
		}
		if ($setting[0] eq "DISABLE") {
			$disabled{$setting[1]} = 1;
		}
		if ($setting[0] eq "ANY") {
			$any{$setting[1]} = 1;
		}
	}
	if ($config{CF_CPANEL}) {
		my %userdomains;
		my %accounts;
		my %creds;

		open (my $IN, "<","/etc/userdomains");
		flock ($IN, LOCK_SH);
		my @localusers = <$IN>;
		close ($IN);
		chomp @localusers;
		foreach my $line (@localusers) {
			my ($domain,$user) = split(/\:\s*/,$line,2);
			$userdomains{$domain} = $user;
			$accounts{$user} = 1;
		}

		foreach my $user (keys %accounts) {
			if ($disabled{$user}) {next}
			my $userhome = (getpwnam($user))[7];

			if (-e "$userhome/.cpanel/datastore/cloudflare_data.yaml") {
				my $yaml = YAML::Tiny->read("$userhome/.cpanel/datastore/cloudflare_data.yaml");
				if ($yaml->[0]->{client_api_key} ne "") {
					$creds{$user}{account} = $yaml->[0]->{cloudflare_email};
					$creds{$user}{apikey} = $yaml->[0]->{client_api_key};
				}
			}
		}

		foreach my $domain (keys %userdomains) {
			my $user = $userdomains{$domain};
			if ($disabled{$user}) {next}
			if ($creds{$user}{apikey} ne "") {
				$scope{domain}{$domain}{account} = $creds{$user}{account};
				$scope{domain}{$domain}{apikey} = $creds{$user}{apikey};
				$scope{domain}{$domain}{user} = $user;
				$scope{user}{$user}{account} = $creds{$user}{account};
				$scope{user}{$user}{apikey} = $creds{$user}{apikey};
				$scope{user}{$user}{domain}{$domain} = $domain;
				if ($any{$user}) {
					$scope{domain}{any}{account} = $creds{$user}{account};
					$scope{domain}{any}{apikey} = $creds{$user}{apikey};
					$scope{domain}{any}{user} = $user;
					$scope{user}{$user}{domain}{any} = "any";
					$scope{user}{$user}{any} = 1;
				}
			}
		}
	}
	return \%scope;
}
# end getscope
###############################################################################
# start checktarget
sub checktarget {
	my $arg = shift;
	if ($arg =~ /^\w\w$/) {return "country"}
	elsif ($arg =~ /\/16$/) {return "ip_range"}
	elsif ($arg =~ /\/24$/) {return "ip_range"}
	else {return "ip"}
}
# end checktarget
###############################################################################
1;
