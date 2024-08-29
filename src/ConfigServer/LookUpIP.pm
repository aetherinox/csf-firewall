###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::LookUpIP;

use strict;
use lib '/usr/local/csf/lib';
use Carp;
use Fcntl qw(:DEFAULT :flock);
use IPC::Open3;
use JSON::Tiny;
use Net::IP;
use Socket;
use ConfigServer::CheckIP qw(checkip);
use ConfigServer::Config;
use ConfigServer::URLGet;

use Exporter qw(import);
our $VERSION     = 2.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(iplookup);

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();

my $urlget;
if ($config{CC_LOOKUPS} == 4) {
	$urlget = ConfigServer::URLGet->new($config{URLGET}, "", $config{URLPROXY});
	unless (defined $urlget) {
		$config{URLGET} = 1;
		$urlget = ConfigServer::URLGet->new($config{URLGET}, "", $config{URLPROXY});
	}
}

# end main
###############################################################################
# start iplookup
sub iplookup {
	my $ip = shift;
	my $cconly = shift;
	my $host = "-";
	my $iptype = checkip(\$ip);

	if ($config{LF_LOOKUPS} and !$cconly) {
		my $dnsip;
		my $dnsrip;
		my $dnshost;
		my $cachehit;
		open (my $DNS, "<", "/var/lib/csf/csf.dnscache");
		flock ($DNS, LOCK_SH);
		while (my $line = <$DNS>) {
			chomp $line;
			($dnsip,$dnsrip,$dnshost) = split(/\|/,$line);
			if ($ip eq $dnsip) {
				$cachehit = 1;
				last;
			}
		}
		close ($DNS);
		if ($cachehit) {
			$host = $dnshost;
		} else {
			if (-e $config{HOST} and -x $config{HOST}) {
				my $cmdpid;
				eval {
					local $SIG{__DIE__} = undef;
					local $SIG{'ALRM'} = sub {die};
					alarm(10);
					my ($childin, $childout);
					$cmdpid = open3($childin, $childout, $childout, $config{HOST},"-W","5",$ip);
					close $childin;
					my @results = <$childout>;
					waitpid ($cmdpid, 0);
					chomp @results;
					if ($results[0] =~ /(\S+)\.$/) {$host = $1}
					alarm(0);
				};
				alarm(0);
				if ($cmdpid =~ /\d+/ and $cmdpid > 1 and kill(0,$cmdpid)) {kill(9,$cmdpid)}
			} else {
				if ($iptype == 4) {
					eval {
						local $SIG{__DIE__} = undef;
						local $SIG{'ALRM'} = sub {die};
						alarm(10);
						my $ipaddr = inet_aton($ip);
						$host = gethostbyaddr($ipaddr, AF_INET);
						alarm(0);
					};
					alarm(0);
				}
				elsif ($iptype == 6) {
					eval {
						local $SIG{__DIE__} = undef;
						local $SIG{'ALRM'} = sub {die};
						alarm(10);
						eval('use Socket6;'); ##no critic
						my $ipaddr = inet_pton(AF_INET6, $ip);
						$host = gethostbyaddr($ipaddr, AF_INET6);
						alarm(0);
					};
					alarm(0);
				}
			}
			sysopen (DNS, "/var/lib/csf/csf.dnscache", O_WRONLY | O_APPEND | O_CREAT);
			flock (DNS, LOCK_EX);
			print DNS "$ip|$ip|$host\n";
			close (DNS);
		}
		if ($host eq "") {$host = "-"}
	}

	if (($config{CC_LOOKUPS} and $iptype == 4) or ($config{CC_LOOKUPS} and $config{CC6_LOOKUPS} and $iptype == 6)) {
		my @result;
		eval {
			local $SIG{__DIE__} = undef;
			@result = &geo_binary($ip,$iptype);
		};
		my $asn = $result[4];
		if ($result[0] eq "") {$result[0] = "-"}
		if ($result[1] eq "") {$result[1] = "-"}
		if ($result[2] eq "") {$result[2] = "-"}
		if ($result[3] eq "") {$result[3] = "-"}
		if ($result[4] eq "") {$result[4] = "-"} else {$result[4] = "[$result[4]]"}
		if ($config{CC_LOOKUPS} == 3) {
			if ($cconly) {return ($result[0],$asn)}
			my $return = "$ip ($result[0]/$result[1]/$result[2]/$result[3]/$host/$result[4])";
			if ($result[0] eq "-") {$return = "$ip ($host)"}
			$return =~ s/'|"//g;
			return $return;
		}
		elsif ($config{CC_LOOKUPS} == 2 or $config{CC_LOOKUPS} == 4) {
			if ($cconly) {return $result[0]}
			my $return = "$ip ($result[0]/$result[1]/$result[2]/$result[3]/$host)";
			if ($result[0] eq "-") {$return = "$ip ($host)"}
			$return =~ s/'|"//g;
			return $return;
		}
		else {
			if ($cconly) {return $result[0]}
			my $return = "$ip ($result[0]/$result[1]/$host)";
			if ($result[0] eq "-") {$return = "$ip ($host)"}
			$return =~ s/'|"//g;
			return $return;
		}
	}

	if ($config{LF_LOOKUPS}) {
		if ($host eq "-") {$host = "Unknown"}
		my $return = "$ip ($host)";
		$return =~ s/'//g;
		return $return;
	} else {
		return $ip;
	}
}
# end iplookup
###############################################################################
# start geo_binary
sub geo_binary {
	my $myip = shift;
	my $ipv = shift;
	my @return;

	my $netip = Net::IP->new($myip);
	my $ip = $netip->binip();
	my $type = $netip->iptype();
	if ($type eq "PRIVATE") {return}

	if ($config{CC_LOOKUPS} == 4) {
		my ($status, $text) = $urlget->urlget("http://api.db-ip.com/v2/free/$myip");
		if ($status) {$text = ""}
		if ($text ne "") {
			my $json = JSON::Tiny::decode_json($text);
			return ($json->{countryCode},$json->{countryName},$json->{stateProv},$json->{city});
		} else {
			return;
		}
		return;
	}

	if ($config{CC_SRC} eq "" or $config{CC_SRC} eq "1") {
		my $file = "/var/lib/csf/Geo/GeoLite2-Country-Blocks-IPv${ipv}.csv";
		if ($config{CC_LOOKUPS} == 2 or $config{CC_LOOKUPS} == 3) {
			$file = "/var/lib/csf/Geo/GeoLite2-City-Blocks-IPv${ipv}.csv";
		}
		my $start = 0;
		my $end = -s $file;
		$end += 4;
		my $cnt = 0;
		my $last;
		my $range;
		my $geoid;
		open (my $CSV, "<", $file);
		flock ($CSV, LOCK_SH);
		while (1) {
			my $mid = int (($end + $start) / 2);
			seek ($CSV, $mid, 0);
			my $a = <$CSV>;
			my $b = <$CSV>;
			chomp $b;
			($range,$geoid,undef) = split(/\,/,$b);
			if ($range !~ /^\d/ or $range eq $last or $range eq "") {return}
			$last = $range;
			my $netip = Net::IP->new($range);
			my $lastip = $netip->last_ip();
			$lastip = Net::IP::ip_iptobin($lastip,$ipv);
			my $firstip = $netip->ip();
			$firstip = Net::IP::ip_iptobin($firstip,$ipv);
			if (Net::IP::ip_bincomp($ip,'lt',$firstip) == 1) {
				$end = $mid;
			}
			elsif (Net::IP::ip_bincomp($ip,'gt',$lastip) == 1) {
				$start = $mid;
			} else {
				last;
			}
			$cnt++;
			if ($cnt > 200) {return}
		}
		close ($CSV);

		if ($geoid > 0) {
			my $file = "/var/lib/csf/Geo/GeoLite2-Country-Locations-en.csv";
			if ($config{CC_LOOKUPS} == 2 or $config{CC_LOOKUPS} == 3) {
				$file = "/var/lib/csf/Geo/GeoLite2-City-Locations-en.csv";
			}
			my $start = 0;
			my $end = -s $file;
			$end += 4;
			my $cnt = 0;
			my $last;
			open (my $CSV, "<", $file);
			flock ($CSV, LOCK_SH);
			while (1) {
				my $mid = int (($end + $start) / 2);
				seek ($CSV, $mid, 0);
				my $a = <$CSV>;
				my $b = <$CSV>;
				chomp $b;
				my @bits = split(/\,/,$b);
				if ($range !~ /^\d/ or $bits[0] eq $last or $bits[0] eq "") {last}
				$last = $bits[0];
				if ($geoid < $bits[0]) {
					$end = $mid;
				}
				elsif ($geoid > $bits[0]) {
					$start = $mid + 1;
				} else {
					$b =~ s/\"//g;
					my ($geoname_id, $locale_code, $continent_code, $continent_name, $country_iso_code, $country_name, $subdivision_1_iso_code, $subdivision_1_name, $subdivision_2_iso_code, $subdivision_2_name, $city_name, $metro_code, $time_zone) = split(/\,/,$b);
					my $region = $subdivision_2_name;
					if ($region eq "" or $region eq $city_name) {$region = $subdivision_1_name}
					$return[0] = $country_iso_code;
					$return[1] = $country_name;
					$return[2] = $region;
					$return[3] = $city_name;
					last;
				}
				$cnt++;
				if ($cnt > 200) {return}
			}
			close ($CSV);
		}

		if ($config{CC_LOOKUPS} == 3) {
			my $file = "/var/lib/csf/Geo/GeoLite2-ASN-Blocks-IPv${ipv}.csv";
			my $start = 0;
			my $end = -s $file;
			$end += 4;
			my $cnt = 0;
			my $last;
			my $range;
			my $asn;
			my $asnorg;
			open (my $CSV, "<", $file);
			flock ($CSV, LOCK_SH);
			while (1) {
				my $mid = int (($end + $start) / 2);
				seek ($CSV, $mid, 0);
				my $a = <$CSV>;
				my $b = <$CSV>;
				chomp $b;
				($range,$asn,$asnorg) = split(/\,/,$b,3);
				if ($range !~ /^\d/ or $range eq $last or $range eq "") {last}
				$last = $range;
				my $netip = Net::IP->new($range);
				my $lastip = $netip->last_ip();
				$lastip = Net::IP::ip_iptobin($lastip,$ipv);
				my $firstip = $netip->ip();
				$firstip = Net::IP::ip_iptobin($firstip,$ipv);
				if (Net::IP::ip_bincomp($ip,'lt',$firstip) == 1) {
					$end = $mid;
				}
				elsif (Net::IP::ip_bincomp($ip,'gt',$lastip) == 1) {
					$start = $mid + 1;
				} else {
					$return[4] = "AS$asn $asnorg";
					last;
				}
				$cnt++;
				if ($cnt > 200) {last}
			}
			close ($CSV);
		}
	} elsif ($config{CC_SRC} eq "2") {
		my %country_name;
		open (my $CC, "<", "/var/lib/csf/Geo/countryInfo.txt");
		flock ($CC, LOCK_SH);
		foreach my $line (<$CC>) {
			if ($line eq "" or $line =~ /^\#/ or $line =~ /^\s/) {next}
			my ($cc,undef,undef,undef,$country,undef) = split(/\t/, $line);
			if ($cc ne "" and $country ne "") {$country_name{$cc} = $country}
		}
		close ($CC);

		my $file = "/var/lib/csf/Geo/dbip-country-lite.csv";
		if ($config{CC_LOOKUPS} == 2 or $config{CC_LOOKUPS} == 3) {
			$file = "/var/lib/csf/Geo/dbip-city-lite.csv";
		}
		my $start = 0;
		my $end = -s $file;
		$end += 4;
		my $cnt = 0;
		my $last;
		my $range;
		my $geoid;
		open (my $CSV, "<", $file);
		flock ($CSV, LOCK_SH);
		while (1) {
			my $mid = int (($end + $start) / 2);
			seek ($CSV, $mid, 0);
			my $a = <$CSV>;
			my $b = <$CSV>;
			chomp $b;
			my ($firstip,$lastip,$cc_lookups1,$country_iso_code,$region,$city_name,undef) = split(/\,/,$b);
			if ($firstip eq $lastip or $firstip eq "") {return}
			if (checkip(\$firstip) ne $ipv) {
				if ($ipv eq "6") {
					$start = $mid;
				} else {
					$end = $mid;
				}
			} else {
				my $netfirstip = Net::IP->new($firstip);
				my $firstip = $netfirstip->binip();
				my $netlastip = Net::IP->new($lastip);
				my $lastip = $netlastip->binip();
				if (Net::IP::ip_bincomp($ip,'lt',$firstip) == 1) {
					$end = $mid;
				}
				elsif (Net::IP::ip_bincomp($ip,'gt',$lastip) == 1) {
					$start = $mid + 1;
				} else {
					if ($config{CC_LOOKUPS} == 1) {$country_iso_code = $cc_lookups1}
					if ($country_iso_code eq "ZZ") {last}
					$return[0] = $country_iso_code;
					$return[1] = $country_name{$country_iso_code};
					$return[2] = $region;
					$return[3] = $city_name;
					last;
				}
			}
			$cnt++;
			if ($cnt > 200) {return}
		}
		close ($CSV);

		if ($config{CC_LOOKUPS} == 3) {
			my $file = "/var/lib/csf/Geo/ip2asn-combined.tsv";
			my $start = 0;
			my $end = -s $file;
			$end += 4;
			my $cnt = 0;
			my $last;
			my $range;
			my $asn;
			my $asnorg;
			open (my $CSV, "<", $file);
			flock ($CSV, LOCK_SH);
			while (1) {
				my $mid = int (($end + $start) / 2);
				seek ($CSV, $mid, 0);
				my $a = <$CSV>;
				my $b = <$CSV>;
				chomp $b;
				my ($firstip,$lastip,$asn,undef,$asnorg) = split(/\t/,$b);
				if ($firstip eq $lastip or $firstip eq "") {last}
				if (checkip(\$firstip) ne $ipv) {
					if ($ipv eq "6") {
						$start = $mid;
					} else {
						$end = $mid;
					}
				} else {
					my $netfirstip = Net::IP->new($firstip);
					my $firstip = $netfirstip->binip();
					my $netlastip = Net::IP->new($lastip);
					my $lastip = $netlastip->binip();
					if (Net::IP::ip_bincomp($ip,'lt',$firstip) == 1) {
						$end = $mid;
					}
					elsif (Net::IP::ip_bincomp($ip,'gt',$lastip) == 1) {
						$start = $mid + 1;
					} else {
						if ($asn eq "0") {last}
						$return[4] = "AS$asn $asnorg";
						last;
					}
				}
				$cnt++;
				if ($cnt > 200) {last}
			}
			close ($CSV);
		}
	}
	return @return;
}
# end geo_binary
###############################################################################

1;