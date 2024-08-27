###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::URLGet;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use Carp;
use IPC::Open3;
use ConfigServer::Config;

use Exporter qw(import);
our $VERSION     = 2.00;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my $agent = "ConfigServer";
my $option = 1;
my $proxy = "";

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config();
$SIG{PIPE} = 'IGNORE';

# end main
###############################################################################
# start new
sub new {
	my $class = shift;
	$option = shift;
	$agent = shift;
	$proxy = shift;
	my $self = {};
	bless $self,$class;

	if ($option == 3) {
		return $self;
	}
	elsif ($option == 2) {
		eval ('use LWP::UserAgent;'); ##no critic
		if ($@) {return undef}
	}
	else {
		eval {
			local $SIG{__DIE__} = undef;
			eval ('use HTTP::Tiny;'); ##no critic
		};
	}

	return $self;
}
# end new
###############################################################################
# start urlget
sub urlget {
	my $self = shift;
	my $url = shift;
	my $file = shift;
	my $quiet = shift;
	my $status;
	my $text;

	if (!defined $url) {carp "url not specified"; return}

	if ($option == 3) {
		($status, $text) = &binget($url,$file,$quiet);
	}
	elsif ($option == 2) {
		($status, $text) = &urlgetLWP($url,$file,$quiet);
	}
	else {
		($status, $text) = &urlgetTINY($url,$file,$quiet);
	}
	return ($status, $text);
}
# end urlget
###############################################################################
# start urlgetTINY
sub urlgetTINY {
	my $url = shift;
	my $file = shift;
	my $quiet = shift;
	my $status = 0;
	my $timeout = 1200;
	if ($proxy eq "") {undef $proxy}
	my $ua = HTTP::Tiny->new(
		'agent' => $agent,
		'timeout' => 300,
		'proxy' => $proxy
		);
	my $res;
	my $text;
	($status, $text) = eval {
		local $SIG{__DIE__} = undef;
		local $SIG{'ALRM'} = sub {die "Download timeout after $timeout seconds"};
		alarm($timeout);
		if ($file) {
			local $|=1;
			my $expected_length;
			my $bytes_received = 0;
			my $per = 0;
			my $oldper = 0;
			open (my $OUT, ">", "$file\.tmp") or return (1, "Unable to open $file\.tmp: $!");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			$res = $ua->request('GET', $url, {
				data_callback => sub {
					my($chunk, $res) = @_;
					$bytes_received += length($chunk);
					unless (defined $expected_length) {$expected_length = $res->{headers}->{'content-length'} || 0}
					if ($expected_length) {
						my $per = int(100 * $bytes_received / $expected_length);
						if ((int($per / 5) == $per / 5) and ($per != $oldper) and !$quiet) {
							print "...$per\%\n";
							$oldper = $per;
						}
					} else {
						unless ($quiet) {print "."}
					}
					print $OUT $chunk;
				}
			});
			close ($OUT);
			unless ($quiet) {print "\n"}
		} else {
			$res = $ua->request('GET', $url);
		}
		alarm(0);
		if ($res->{success}) {
			if ($file) {
				rename ("$file\.tmp","$file") or return (1, "Unable to rename $file\.tmp to $file: $!");
				return (0, $file);
			} else {
				return (0, $res->{content});
			}
		} else {
			my $reason = $res->{reason};
			if ($res->{status} == 599) {$reason = $res->{content}}
			($status, $text) = &binget($url,$file,$quiet,$reason);
			return ($status, $text);
		}
	};
	alarm(0);
	if ($@) {return (1, $@)}
	return ($status,$text);
}
# end urlgetTINY
###############################################################################
# start urlgetLWP
sub urlgetLWP {
	my $url = shift;
	my $file = shift;
	my $quiet = shift;
	my $status = 0;
	my $timeout = 300;
	my $ua = LWP::UserAgent->new;
	$ua->agent($agent);
	$ua->timeout(30);
	if ($proxy ne "") {$ua->proxy([ 'http', 'https' ], $proxy)}
#use LWP::ConnCache;
#my $cache = LWP::ConnCache->new;
#$cache->total_capacity([1]);
#$ua->conn_cache($cache);
	my $req = HTTP::Request->new(GET => $url);
	my $res;
	my $text;
	($status, $text) = eval {
		local $SIG{__DIE__} = undef;
		local $SIG{'ALRM'} = sub {die "Download timeout after $timeout seconds"};
		alarm($timeout);
		if ($file) {
			local $|=1;
			my $expected_length;
			my $bytes_received = 0;
			my $per = 0;
			my $oldper = 0;
			open (my $OUT, ">", "$file\.tmp") or return (1, "Unable to open $file\.tmp: $!");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			$res = $ua->request($req,
				sub {
				my($chunk, $res) = @_;
				$bytes_received += length($chunk);
				unless (defined $expected_length) {$expected_length = $res->content_length || 0}
				if ($expected_length) {
					my $per = int(100 * $bytes_received / $expected_length);
					if ((int($per / 5) == $per / 5) and ($per != $oldper) and !$quiet) {
						print "...$per\%\n";
						$oldper = $per;
					}
				} else {
					unless ($quiet) {print "."}
				}
				print $OUT $chunk;
			});
			close ($OUT);
			unless ($quiet) {print "\n"}
		} else {
			$res = $ua->request($req);
		}
		alarm(0);
		if ($res->is_success) {
			if ($file) {
				rename ("$file\.tmp","$file") or return (1, "Unable to rename $file\.tmp to $file: $!");
				return (0, $file);
			} else {
				return (0, $res->content);
			}
		} else {
			($status, $text) = &binget($url,$file,$quiet,$res->message);
			return ($status, $text);
		}
	};
	alarm(0);
	if ($@) {
		return (1, $@);
	}
	if ($text) {
		return ($status,$text);
	} else {
		return (1, "Download timeout after $timeout seconds");
	}
}
# end urlget
###############################################################################
# start binget
sub binget {
	my $url = shift;
	my $file = shift;
	my $quiet = shift;
	my $errormsg = shift;
	$url = "'$url'";

	my $cmd;
	if (-e $config{CURL}) {
		$cmd = $config{CURL}." -skLf -m 120";
		if ($file) {$cmd = $config{CURL}." -kLf -m 120 -o";}
	}
	elsif (-e $config{WGET}) {
		$cmd = $config{WGET}." -qT 120 -O-";
		if ($file) {$cmd = $config{WGET}." -T 120 -O"}
	}
	if ($cmd ne "") {
		if ($file) {
			my ($childin, $childout);
			my $cmdpid = open3($childin, $childout, $childout, $cmd." $file\.tmp $url");
			my @output = <$childout>;
			waitpid ($cmdpid, 0);
			unless ($quiet and $option != 3) {
				print "Using fallback [$cmd]\n";
				print @output;
			}
			if (-e "$file\.tmp") {
				rename ("$file\.tmp","$file") or return (1, "Unable to rename $file\.tmp to $file: $!");
				return (0, $file);
			} else {
				if ($option == 3) {
					return (1, "Unable to download: ".$cmd." $file\.tmp $url".join("",@output));
				} else {
					return (1, "Unable to download: ".$errormsg);
				}
			}
		} else {
			my ($childin, $childout);
			my $cmdpid = open3($childin, $childout, $childout, $cmd." $url");
			my @output = <$childout>;
			waitpid ($cmdpid, 0);
			if (scalar @output > 0) {
				return (0, join("",@output));
			} else {
				if ($option == 3) {
					return (1, "Unable to download: [$cmd $url]".join("",@output));
				} else {
					return (1, "Unable to download: ".$errormsg);
				}
			}
		}
	}
	if ($option == 3) {
		return (1, "Unable to download (CURL/WGET also not present, see csf.conf)");
	} else {
		return (1, "Unable to download (CURL/WGET also not present, see csf.conf): ".$errormsg);
	}
}
# end binget
###############################################################################
1;