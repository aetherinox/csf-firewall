###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::ServerStats;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);

use Exporter qw(import);
our $VERSION     = 1.02;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my %minmaxavg;

# end main
###############################################################################
# start init
sub init {
	eval ('use GD::Graph::bars;'); ##no critic
	if ($@) {return undef}
	eval ('use GD::Graph::pie;'); ##no critic
	if ($@) {return undef}
	eval ('use GD::Graph::lines;'); ##no critic
	if ($@) {return undef}
}
# end init
###############################################################################
# start graphs
sub graphs {
	my $type = shift;
	my $system_maxdays = shift;
	my $imghddir = shift;
	my $img;
	$| = 1;

	require GD::Graph::bars;
	import GD::Graph::bars;
	require GD::Graph::pie;
	import GD::Graph::pie;
	require GD::Graph::lines;
	import GD::Graph::lines;

	sysopen (my $STATS,"/var/lib/csf/stats/system", O_RDWR | O_CREAT);
	flock ($STATS, LOCK_SH);
	my @stats = <$STATS>;
	chomp @stats;
	close ($STATS);

	if (@stats > 1) {
		local $SIG{__DIE__} = undef;
		my $time = time;
		my %stata;
		foreach my $line (@stats) {
			my ($thistime,undef) = split(/\,/,$line);
			if (time - $thistime > (86400 * $system_maxdays)) {next}
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($thistime);
			$stata{$year}{$mon}{$mday}{$hour}{$min} = $line;
		}

		if ($type eq "cpu") {
			my (@h,@p,@t);
			my $cputotal_prev;
			my $cpuidle_prev;
			my $cpuiowait_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $cputotal eq "") {
					$cputotal_prev = 0;
					$cpuidle_prev = 0;
					$cpuiowait_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					my $idle_diff = $cpuidle - $cpuidle_prev;
					my $iowait_diff = $cpuiowait - $cpuiowait_prev;
					my $total_diff = $cputotal - $cputotal_prev;
					if ($total_diff == 0) {
						$cputotal_prev = 0;
						$cpuidle_prev = 0;
						$cpuiowait_prev = 0;
						push @p,undef;
						push @t,undef;
						next;
					}
					my $idle_use = 100 - 100 * ($total_diff - $idle_diff) / $total_diff;
					my $iowait_use = 100 - 100 * ($total_diff - $iowait_diff) / $total_diff;
					$cpuidle_prev = $cpuidle;
					$cpuiowait_prev = $cpuiowait;
					$cputotal_prev = $cputotal;
					push @p,$idle_use;
					push @t,$iowait_use;

					&minmaxavg("HOUR","1Idle",$idle_use);
					&minmaxavg("HOUR","2IOWAIT",$iowait_use);
				}
			}
			if ($minmaxavg{HOUR}{"1Idle"}{CNT} > 0) {$minmaxavg{HOUR}{"1Idle"}{AVG} /= $minmaxavg{HOUR}{"1Idle"}{CNT}}
			if ($minmaxavg{HOUR}{"2IOWAIT"}{CNT} > 0) {$minmaxavg{HOUR}{"2IOWAIT"}{AVG} /= $minmaxavg{HOUR}{"2IOWAIT"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => '% CPU',
				x_label_skip => 3,
				line_width => 2,
				title => 'CPU Usage in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Idle IOWAIT));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "cpu") {
			my (@h,@p,@t);
			my $cputotal_prev;
			my $cpuidle_prev;
			my $cpuiowait_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $cputotal eq "") {
					$cputotal_prev = 0;
					$cpuidle_prev = 0;
					$cpuiowait_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					my $idle_diff = $cpuidle - $cpuidle_prev;
					my $iowait_diff = $cpuiowait - $cpuiowait_prev;
					my $total_diff = $cputotal - $cputotal_prev;
						if ($total_diff == 0) {
							$cputotal_prev = 0;
							$cpuidle_prev = 0;
							$cpuiowait_prev = 0;
							push @p,undef;
							push @t,undef;
							next;
						}
					my $idle_use = 100 - 100 * ($total_diff - $idle_diff) / $total_diff;
					my $iowait_use = 100 - 100 * ($total_diff - $iowait_diff) / $total_diff;
					$cpuidle_prev = $cpuidle;
					$cpuiowait_prev = $cpuiowait;
					$cputotal_prev = $cputotal;
					push @p,$idle_use;
					push @t,$iowait_use;

					&minmaxavg("DAY","1Idle",$idle_use);
					&minmaxavg("DAY","2IOWAIT",$iowait_use);
				}
			}
			if ($minmaxavg{DAY}{"1Idle"}{CNT} > 0) {$minmaxavg{DAY}{"1Idle"}{AVG} /= $minmaxavg{DAY}{"1Idle"}{CNT}}
			if ($minmaxavg{DAY}{"2IOWAIT"}{CNT} > 0) {$minmaxavg{DAY}{"2IOWAIT"}{AVG} /= $minmaxavg{DAY}{"2IOWAIT"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => '% CPU',
				x_label_skip => 60,
				title => 'CPU Usage in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Idle IOWAIT));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "cpu") {
			my (@h,@p,@t);
			my $cputotal_prev;
			my $cpuidle_prev;
			my $cpuiowait_prev;
			$minmaxavg{WEEK}{"1Idle"}{MIN} = 100;
			$minmaxavg{WEEK}{"1Idle"}{MAX} = 0;
			$minmaxavg{WEEK}{"2IOWAIT"}{MIN} = 100;
			$minmaxavg{WEEK}{"2IOWAIT"}{MAX} = 0;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $idle_avg;
				my $iowait_avg;
				my $cnt_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $cputotal ne "") {
						my $idle_diff = $cpuidle - $cpuidle_prev;
						my $iowait_diff = $cpuiowait - $cpuiowait_prev;
						my $total_diff = $cputotal - $cputotal_prev;
						if ($total_diff == 0) {
							$cputotal_prev = 0;
							$cpuidle_prev = 0;
							$cpuiowait_prev = 0;
							next;
						}
						my $idle_use = 100 - 100 * ($total_diff - $idle_diff) / $total_diff;
						my $iowait_use = 100 - 100 * ($total_diff - $iowait_diff) / $total_diff;
						$cpuidle_prev = $cpuidle;
						$cpuiowait_prev = $cpuiowait;
						$cputotal_prev = $cputotal;
						$idle_avg += $idle_use;
						$iowait_avg += $iowait_use;
						$cnt_avg++;
					} else {
						$cputotal_prev = 0;
						$cpuidle_prev = 0;
						$cpuiowait_prev = 0;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$idle_avg/$cnt_avg;
					push @t,$iowait_avg/$cnt_avg;
					&minmaxavg("WEEK","1Idle",($idle_avg/$cnt_avg));
					&minmaxavg("WEEK","2IOWAIT",($iowait_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1Idle"}{CNT} > 0) {$minmaxavg{WEEK}{"1Idle"}{AVG} /= $minmaxavg{WEEK}{"1Idle"}{CNT}}
			if ($minmaxavg{WEEK}{"2IOWAIT"}{CNT} > 0) {$minmaxavg{WEEK}{"2IOWAIT"}{AVG} /= $minmaxavg{WEEK}{"2IOWAIT"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => '% CPU',
				x_label_skip => 24,
				title => 'CPU Usage in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Idle IOWAIT));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "cpu") {
			my (@h,@p,@t);
			my $cputotal_prev;
			my $cpuidle_prev;
			my $cpuiowait_prev;
			$minmaxavg{MONTH}{"1Idle"}{MIN} = 100;
			$minmaxavg{MONTH}{"1Idle"}{MAX} = 0;
			$minmaxavg{MONTH}{"2IOWAIT"}{MIN} = 100;
			$minmaxavg{MONTH}{"2IOWAIT"}{MAX} = 0;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $idle_avg;
				my $iowait_avg;
				my $cnt_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $cputotal ne "") {
						my $idle_diff = $cpuidle - $cpuidle_prev;
						my $iowait_diff = $cpuiowait - $cpuiowait_prev;
						my $total_diff = $cputotal - $cputotal_prev;
						if ($total_diff == 0) {
							$cputotal_prev = 0;
							$cpuidle_prev = 0;
							$cpuiowait_prev = 0;
							next;
						}
						my $idle_use = 100 - 100 * ($total_diff - $idle_diff) / $total_diff;
						my $iowait_use = 100 - 100 * ($total_diff - $iowait_diff) / $total_diff;
						$cpuidle_prev = $cpuidle;
						$cpuiowait_prev = $cpuiowait;
						$cputotal_prev = $cputotal;
						$idle_avg += $idle_use;
						$iowait_avg += $iowait_use;
						$cnt_avg++;
					} else {
						$cputotal_prev = 0;
						$cpuidle_prev = 0;
						$cpuiowait_prev = 0;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$idle_avg/$cnt_avg;
					push @t,$iowait_avg/$cnt_avg;
					&minmaxavg("MONTH","1Idle",($idle_avg/$cnt_avg));
					&minmaxavg("MONTH","2IOWAIT",($iowait_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1Idle"}{CNT} > 0) {$minmaxavg{MONTH}{"1Idle"}{AVG} /= $minmaxavg{MONTH}{"1Idle"}{CNT}}
			if ($minmaxavg{MONTH}{"2IOWAIT"}{CNT} > 0) {$minmaxavg{MONTH}{"2IOWAIT"}{AVG} /= $minmaxavg{MONTH}{"2IOWAIT"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => '% CPU',
				x_label_skip => 24,
				title => "CPU Usage in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Idle IOWAIT));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mem") {
			my (@h,@p,@t,@c,@a,@b);
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $memtotal eq "") {
					push @p,undef;
					push @t,undef;
					push @c,undef;
					push @a,undef;
					push @b,undef;
				} else {
					$memfree = $memtotal - $memfree;
					$memswapfree = $memswaptotal - $memswapfree;
					push @p,$memtotal;
					push @t,$memfree;
					push @c,$memcached;
					push @a,$memswaptotal;
					push @b,$memswapfree;

					&minmaxavg("HOUR","1Used",$memfree);
					&minmaxavg("HOUR","2Cached",$memcached);
					&minmaxavg("HOUR","3SwapUsed",$memswapfree);
				}
			}
			if ($minmaxavg{HOUR}{"1Used"}{CNT} > 0) {$minmaxavg{HOUR}{"1Used"}{AVG} /= $minmaxavg{HOUR}{"1Used"}{CNT}}
			if ($minmaxavg{HOUR}{"2Cached"}{CNT} > 0) {$minmaxavg{HOUR}{"2Cached"}{AVG} /= $minmaxavg{HOUR}{"2Cached"}{CNT}}
			if ($minmaxavg{HOUR}{"3SwapUsed"}{CNT} > 0) {$minmaxavg{HOUR}{"3SwapUsed"}{AVG} /= $minmaxavg{HOUR}{"3SwapUsed"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @c],[reverse @a],[reverse @b]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple blue green) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Memory (KB)',
				x_label_skip => 3,
				title => 'Memory Usage in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Total Used Cached SwapTotal SwapUsed));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mem") {
			my (@h,@p,@c,@t,@a,@b);
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $memtotal eq "") {
					push @p,undef;
					push @t,undef;
					push @c,undef;
					push @a,undef;
					push @b,undef;
				} else {
					$memfree = $memtotal - $memfree;
					$memswapfree = $memswaptotal - $memswapfree;
					push @p,$memtotal;
					push @t,$memfree;
					push @c,$memcached;
					push @a,$memswaptotal;
					push @b,$memswapfree;

					&minmaxavg("DAY","1Used",$memfree);
					&minmaxavg("DAY","2Cached",$memcached);
					&minmaxavg("DAY","3SwapUsed",$memswapfree);
				}
			}
			if ($minmaxavg{DAY}{"1Used"}{CNT} > 0) {$minmaxavg{DAY}{"1Used"}{AVG} /= $minmaxavg{DAY}{"1Used"}{CNT}}
			if ($minmaxavg{DAY}{"2Cached"}{CNT} > 0) {$minmaxavg{DAY}{"2Cached"}{AVG} /= $minmaxavg{DAY}{"2Cached"}{CNT}}
			if ($minmaxavg{DAY}{"3SwapUsed"}{CNT} > 0) {$minmaxavg{DAY}{"3SwapUsed"}{AVG} /= $minmaxavg{DAY}{"3SwapUsed"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @c],[reverse @a],[reverse @b]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple blue green) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Memory (KB)',
				x_label_skip => 60,
				title => 'Memory Usage in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Total Used Cached SwapTotal SwapUsed));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mem") {
			my (@h,@p,@t,@c,@a,@b);
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $memtotal_avg;
				my $memfree_avg;
				my $memcached_avg;
				my $memswaptotal_avg;
				my $memswapfree_avg;
				my $cnt_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $memtotal ne "") {
						$memfree = $memtotal - $memfree;
						$memswapfree = $memswaptotal - $memswapfree;
						$memtotal_avg += $memtotal;
						$memfree_avg += $memfree;
						$memcached_avg += $memcached;
						$memswaptotal_avg += $memswaptotal;
						$memswapfree_avg += $memswapfree;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
					push @c,undef;
					push @a,undef;
					push @b,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$memtotal_avg/$cnt_avg;
					push @t,$memfree_avg/$cnt_avg;
					push @c,$memcached_avg/$cnt_avg;
					push @a,$memswaptotal_avg/$cnt_avg;
					push @b,$memswapfree_avg/$cnt_avg;

					&minmaxavg("WEEK","1Used",($memfree_avg/$cnt_avg));
					&minmaxavg("WEEK","2Cached",($memcached_avg/$cnt_avg));
					&minmaxavg("WEEK","3SwapUsed",($memswapfree_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1Used"}{CNT} > 0) {$minmaxavg{WEEK}{"1Used"}{AVG} /= $minmaxavg{WEEK}{"1Used"}{CNT}}
			if ($minmaxavg{WEEK}{"2Cached"}{CNT} > 0) {$minmaxavg{WEEK}{"2Cached"}{AVG} /= $minmaxavg{WEEK}{"2Cached"}{CNT}}
			if ($minmaxavg{WEEK}{"3SwapUsed"}{CNT} > 0) {$minmaxavg{WEEK}{"3SwapUsed"}{AVG} /= $minmaxavg{WEEK}{"3SwapUsed"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @c],[reverse @a],[reverse @b]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple blue green) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Memory (KB)',
				x_label_skip => 24,
				title => 'Memory Usage in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Total Used Cached SwapTotal SwapUsed));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mem") {
			my (@h,@p,@t,@c,@a,@b);
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $memtotal_avg;
				my $memfree_avg;
				my $memcached_avg;
				my $memswaptotal_avg;
				my $memswapfree_avg;
				my $cnt_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $memtotal ne "") {
						$memfree = $memtotal - $memfree;
						$memswapfree = $memswaptotal - $memswapfree;
						$memtotal_avg += $memtotal;
						$memfree_avg += $memfree;
						$memcached_avg += $memcached;
						$memswaptotal_avg += $memswaptotal;
						$memswapfree_avg += $memswapfree;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
					push @c,undef;
					push @a,undef;
					push @b,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$memtotal_avg/$cnt_avg;
					push @t,$memfree_avg/$cnt_avg;
					push @c,$memcached_avg/$cnt_avg;
					push @a,$memswaptotal_avg/$cnt_avg;
					push @b,$memswapfree_avg/$cnt_avg;

					&minmaxavg("MONTH","1Used",($memfree_avg/$cnt_avg));
					&minmaxavg("MONTH","2Cached",($memcached_avg/$cnt_avg));
					&minmaxavg("MONTH","3SwapUsed",($memswapfree_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1Used"}{CNT} > 0) {$minmaxavg{MONTH}{"1Used"}{AVG} /= $minmaxavg{MONTH}{"1Used"}{CNT}}
			if ($minmaxavg{MONTH}{"2Cached"}{CNT} > 0) {$minmaxavg{MONTH}{"2Cached"}{AVG} /= $minmaxavg{MONTH}{"2Cached"}{CNT}}
			if ($minmaxavg{MONTH}{"3SwapUsed"}{CNT} > 0) {$minmaxavg{MONTH}{"3SwapUsed"}{AVG} /= $minmaxavg{MONTH}{"3SwapUsed"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @c],[reverse @a],[reverse @b]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple blue green) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Memory (Bytes)',
				x_label_skip => 24,
				title => "Memory Usage in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Total Used Cached SwapTotal SwapUsed));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "load") {
			my (@h,@p,@t,@a);
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $load1 eq "") {
					push @p,undef;
					push @t,undef;
					push @a,undef;
				} else {
					push @p,$load1;
					push @t,$load5;
					push @a,$load15;

					&minmaxavg("HOUR","1Load_1",$load1);
					&minmaxavg("HOUR","2Load_5",$load5);
					&minmaxavg("HOUR","3Load_15",$load15);
				}
			}
			if ($minmaxavg{HOUR}{"1Load_1"}{CNT} > 0) {$minmaxavg{HOUR}{"1Load_1"}{AVG} /= $minmaxavg{HOUR}{"1Load_1"}{CNT}}
			if ($minmaxavg{HOUR}{"2Load_5"}{CNT} > 0) {$minmaxavg{HOUR}{"2Load_5"}{AVG} /= $minmaxavg{HOUR}{"2Load_5"}{CNT}}
			if ($minmaxavg{HOUR}{"3Load_15"}{CNT} > 0) {$minmaxavg{HOUR}{"3Load_15"}{AVG} /= $minmaxavg{HOUR}{"3Load_15"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @a]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Load Average',
				x_label_skip => 3,
				title => 'Load Averages in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Load_1 Load_5 Load_15));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "load") {
			my (@h,@p,@t,@a);
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $load1 eq "") {
					push @p,undef;
					push @t,undef;
					push @a,undef;
				} else {
					push @p,$load1;
					push @t,$load5;
					push @a,$load15;

					&minmaxavg("DAY","1Load_1",$load1);
					&minmaxavg("DAY","2Load_5",$load5);
					&minmaxavg("DAY","3Load_15",$load15);
				}
			}
			if ($minmaxavg{DAY}{"1Load_1"}{CNT} > 0) {$minmaxavg{DAY}{"1Load_1"}{AVG} /= $minmaxavg{DAY}{"1Load_1"}{CNT}}
			if ($minmaxavg{DAY}{"2Load_5"}{CNT} > 0) {$minmaxavg{DAY}{"2Load_5"}{AVG} /= $minmaxavg{DAY}{"2Load_5"}{CNT}}
			if ($minmaxavg{DAY}{"3Load_15"}{CNT} > 0) {$minmaxavg{DAY}{"3Load_15"}{AVG} /= $minmaxavg{DAY}{"3Load_15"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @a]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Load Average',
				x_label_skip => 60,
				title => 'Load Averages in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Load_1 Load_5 Load_15));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "load") {
			my (@h,@p,@t,@a);
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $load1_avg;
				my $load5_avg;
				my $load15_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $load1 ne "") {
						$load1_avg += $load1;
						$load5_avg += $load5;
						$load15_avg += $load15;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
					push @a,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$load1_avg/$cnt_avg;
					push @t,$load5_avg/$cnt_avg;
					push @a,$load15_avg/$cnt_avg;

					&minmaxavg("WEEK","1Load_1",($load1_avg/$cnt_avg));
					&minmaxavg("WEEK","2Load_5",($load5_avg/$cnt_avg));
					&minmaxavg("WEEK","3Load_15",($load15_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1Load_1"}{CNT} > 0) {$minmaxavg{WEEK}{"1Load_1"}{AVG} /= $minmaxavg{WEEK}{"1Load_1"}{CNT}}
			if ($minmaxavg{WEEK}{"2Load_5"}{CNT} > 0) {$minmaxavg{WEEK}{"2Load_5"}{AVG} /= $minmaxavg{WEEK}{"2Load_5"}{CNT}}
			if ($minmaxavg{WEEK}{"3Load_15"}{CNT} > 0) {$minmaxavg{WEEK}{"3Load_15"}{AVG} /= $minmaxavg{WEEK}{"3Load_15"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @a]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Load Average',
				x_label_skip => 24,
				title => 'Load Averages in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Load_1 Load_5 Load_15));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "load") {
			my (@h,@p,@t,@a);
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $load1_avg;
				my $load5_avg;
				my $load15_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $load1 ne "") {
						$load1_avg += $load1;
						$load5_avg += $load5;
						$load15_avg += $load15;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
					push @a,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$load1_avg/$cnt_avg;
					push @t,$load5_avg/$cnt_avg;
					push @a,$load15_avg/$cnt_avg;

					&minmaxavg("MONTH","1Load_1",($load1_avg/$cnt_avg));
					&minmaxavg("MONTH","2Load_5",($load5_avg/$cnt_avg));
					&minmaxavg("MONTH","3Load_15",($load15_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1Load_1"}{CNT} > 0) {$minmaxavg{MONTH}{"1Load_1"}{AVG} /= $minmaxavg{MONTH}{"1Load_1"}{CNT}}
			if ($minmaxavg{MONTH}{"2Load_5"}{CNT} > 0) {$minmaxavg{MONTH}{"2Load_5"}{AVG} /= $minmaxavg{MONTH}{"2Load_5"}{CNT}}
			if ($minmaxavg{MONTH}{"3Load_15"}{CNT} > 0) {$minmaxavg{MONTH}{"3Load_15"}{AVG} /= $minmaxavg{MONTH}{"3Load_15"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t],[reverse @a]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple blue) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Load Average',
				x_label_skip => 24,
				title => "Load Averages in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Load_1 Load_5 Load_15));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "net") {
			my (@h,@p,@t);
			my $netin_prev;
			my $netout_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $netin eq "") {
					$netin_prev = 0;
					$netout_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($netin_prev < $netin or $netin eq "") {
						push @p,undef;
						$netin_prev = $netin;
					} else {
						my $netin_val = ($netin_prev - $netin) / 60;
						push @p,$netin_val;
						$netin_prev = $netin;
						&minmaxavg("HOUR","1Inbound",$netin_val);
					}
					if ($netout_prev < $netout or $netout eq "") {
						push @t,undef;
						$netout_prev = $netout;
					} else {
						my $netout_val = ($netout_prev - $netout) / 60;
						push @t,$netout_val;
						$netout_prev = $netout;
						&minmaxavg("HOUR","2Outbound",$netout_val);
					}
				}
			}
			if ($minmaxavg{HOUR}{"1Inbound"}{CNT} > 0) {$minmaxavg{HOUR}{"1Inbound"}{AVG} /= $minmaxavg{HOUR}{"1Inbound"}{CNT}}
			if ($minmaxavg{HOUR}{"2Outbound"}{CNT} > 0) {$minmaxavg{HOUR}{"2Outbound"}{AVG} /= $minmaxavg{HOUR}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Bytes/Second',
				x_label_skip => 3,
				title => 'Network Usage in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "net") {
			my (@h,@p,@t);
			my $netin_prev;
			my $netout_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $netin eq "") {
					$netin_prev = 0;
					$netout_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($netin_prev < $netin or $netin eq "") {
						push @p,undef;
						$netin_prev = $netin;
					} else {
						my $netin_val = ($netin_prev - $netin) / 60;
						push @p,$netin_val;
						$netin_prev = $netin;
						&minmaxavg("DAY","1Inbound",$netin_val);
					}
					if ($netout_prev < $netout or $netout eq "") {
						push @t,undef;
						$netout_prev = $netout;
					} else {
						my $netout_val = ($netout_prev - $netout) / 60;
						push @t,$netout_val;
						$netout_prev = $netout;
						&minmaxavg("DAY","2Outbound",$netout_val);
					}
				}
			}
			if ($minmaxavg{DAY}{"1Inbound"}{CNT} > 0) {$minmaxavg{DAY}{"1Inbound"}{AVG} /= $minmaxavg{DAY}{"1Inbound"}{CNT}}
			if ($minmaxavg{DAY}{"2Outbound"}{CNT} > 0) {$minmaxavg{DAY}{"2Outbound"}{AVG} /= $minmaxavg{DAY}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Bytes/Second',
				x_label_skip => 60,
				title => 'Network Usage in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "net") {
			my (@h,@p,@t);
			my $netin_prev;
			my $netout_prev;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $netin_avg;
				my $netout_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $netin eq "") {
						$netin_prev = 0;
						$netout_prev = 0;
					} else {
						if ($netin_prev < $netin or $netin eq "") {
							$netin_prev = $netin;
						} else {
							my $netin_val = ($netin_prev - $netin) / 60;
							$netin_avg = $netin_avg + $netin_val;
							$netin_prev = $netin;
						}
						if ($netout_prev < $netout or $netout eq "") {
							$netout_prev = $netout;
						} else {
							my $netout_val = ($netout_prev - $netout) / 60;
							$netout_avg = $netout_avg + $netout_val;
							$netout_prev = $netout;
						}
					}
				}
				unless (defined $netin_avg) {
					push @p,undef;
				} else {
					push @p,($netin_avg/60);
					&minmaxavg("WEEK","1Inbound",($netin_avg/60));
				}
				unless (defined $netout_avg) {
					push @t,undef;
				} else {
					push @t,($netout_avg/60);
					&minmaxavg("WEEK","2Outbound",($netout_avg/60));
				}
			}
			if ($minmaxavg{WEEK}{"1Inbound"}{CNT} > 0) {$minmaxavg{WEEK}{"1Inbound"}{AVG} /= $minmaxavg{WEEK}{"1Inbound"}{CNT}}
			if ($minmaxavg{WEEK}{"2Outbound"}{CNT} > 0) {$minmaxavg{WEEK}{"2Outbound"}{AVG} /= $minmaxavg{WEEK}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Bytes/Second',
				x_label_skip => 24,
				title => 'Network Usage in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "net") {
			my (@h,@p,@t);
			my $netin_prev;
			my $netout_prev;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $netin_avg;
				my $netout_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $netin eq "") {
						$netin_prev = 0;
						$netout_prev = 0;
					} else {
						if ($netin_prev < $netin or $netin eq "") {
							$netin_prev = $netin;
						} else {
							my $netin_val = ($netin_prev - $netin) / 60;
							$netin_avg = $netin_avg + $netin_val;
							$netin_prev = $netin;
						}
						if ($netout_prev < $netout or $netout eq "") {
							$netout_prev = $netout;
						} else {
							my $netout_val = ($netout_prev - $netout) / 60;
							$netout_avg = $netout_avg + $netout_val;
							$netout_prev = $netout;
						}
					}
				}
				unless (defined $netin_avg) {
					push @p,undef;
				} else {
					push @p,($netin_avg/60);
					&minmaxavg("MONTH","1Inbound",($netin_avg/60));
				}
				unless (defined $netout_avg) {
					push @t,undef;
				} else {
					push @t,($netout_avg/60);
					&minmaxavg("MONTH","2Outbound",($netout_avg/60));
				}
			}
			if ($minmaxavg{MONTH}{"1Inbound"}{CNT} > 0) {$minmaxavg{MONTH}{"1Inbound"}{AVG} /= $minmaxavg{MONTH}{"1Inbound"}{CNT}}
			if ($minmaxavg{MONTH}{"2Outbound"}{CNT} > 0) {$minmaxavg{MONTH}{"2Outbound"}{AVG} /= $minmaxavg{MONTH}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Bytes/Second',
				x_label_skip => 24,
				title => "Network Usage in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "disk") {
			my (@h,@p,@t);
			my $diskread_prev;
			my $diskwrite_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $diskread eq "") {
					$diskread_prev = 0;
					$diskwrite_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($diskread_prev < $diskread or $diskread eq "") {
						push @p,undef;
						$diskread_prev = $diskread;
					} else {
						my $diskread_val = ($diskread_prev - $diskread) / 60;
						push @p,$diskread_val;
						$diskread_prev = $diskread;
						&minmaxavg("HOUR","1Reads",$diskread_val);
					}
					if ($diskwrite_prev < $diskwrite or $diskwrite eq "") {
						push @t,undef;
						$diskwrite_prev = $diskwrite;
					} else {
						my $diskwrite_val = ($diskwrite_prev - $diskwrite) / 60;
						push @t,$diskwrite_val;
						$diskwrite_prev = $diskwrite;
						&minmaxavg("HOUR","2Writes",$diskwrite_val);
					}
				}
			}
			if ($minmaxavg{HOUR}{"1Reads"}{CNT} > 0) {$minmaxavg{HOUR}{"1Reads"}{AVG} /= $minmaxavg{HOUR}{"1Reads"}{CNT}}
			if ($minmaxavg{HOUR}{"2Writes"}{CNT} > 0) {$minmaxavg{HOUR}{"2Writes"}{AVG} /= $minmaxavg{HOUR}{"2Writes"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'IO/Second',
				x_label_skip => 3,
				title => 'Disk Usage in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Reads Writes));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "disk") {
			my (@h,@p,@t);
			my $diskread_prev;
			my $diskwrite_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $diskread eq "") {
					$diskread_prev = 0;
					$diskwrite_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($diskread_prev < $diskread or $diskread eq "") {
						push @p,undef;
						$diskread_prev = $diskread;
					} else {
						my $diskread_val = ($diskread_prev - $diskread) / 60;
						push @p,$diskread_val;
						$diskread_prev = $diskread;
						&minmaxavg("DAY","1Reads",$diskread_val);
				}
					if ($diskwrite_prev < $diskwrite or $diskwrite eq "") {
						push @t,undef;
						$diskwrite_prev = $diskwrite;
					} else {
						my $diskwrite_val = ($diskwrite_prev - $diskwrite) / 60;
						push @t,$diskwrite_val;
						$diskwrite_prev = $diskwrite;
						&minmaxavg("DAY","2Writes",$diskwrite_val);
					}
				}
			}
			if ($minmaxavg{DAY}{"1Reads"}{CNT} > 0) {$minmaxavg{DAY}{"1Reads"}{AVG} /= $minmaxavg{DAY}{"1Reads"}{CNT}}
			if ($minmaxavg{DAY}{"2Writes"}{CNT} > 0) {$minmaxavg{DAY}{"2Writes"}{AVG} /= $minmaxavg{DAY}{"2Writes"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'IO/Second',
				x_label_skip => 60,
				title => 'Disk Usage in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Reads Writes));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "disk") {
			my (@h,@p,@t);
			my $diskread_prev;
			my $diskwrite_prev;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $diskread_avg;
				my $diskwrite_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $diskread eq "") {
						$diskread_prev = 0;
						$diskwrite_prev = 0;
					} else {
						if ($diskread_prev < $diskread or $diskread eq "") {
							$diskread_prev = $diskread;
						} else {
							$diskread_avg = $diskread_avg + ($diskread_prev - $diskread)/60;
							$diskread_prev = $diskread;
						}
						if ($diskwrite_prev < $diskwrite or $diskwrite eq "") {
							$diskwrite_prev = $diskwrite;
						} else {
							$diskwrite_avg = $diskwrite_avg + ($diskwrite_prev - $diskwrite)/60;
							$diskwrite_prev = $diskwrite;
						}
					}
				}
				unless (defined $diskread_avg) {
					push @p,undef;
				} else {
					push @p,($diskread_avg/60);
					&minmaxavg("WEEK","1Reads",($diskread_avg/60));
				}
				unless (defined $diskwrite_avg) {
					push @t,undef;
				} else {
					push @t,($diskwrite_avg/60);
					&minmaxavg("WEEK","2Writes",($diskwrite_avg/60));
				}
			}
			if ($minmaxavg{WEEK}{"1Reads"}{CNT} > 0) {$minmaxavg{WEEK}{"1Reads"}{AVG} /= $minmaxavg{WEEK}{"1Reads"}{CNT}}
			if ($minmaxavg{WEEK}{"2Writes"}{CNT} > 0) {$minmaxavg{WEEK}{"2Writes"}{AVG} /= $minmaxavg{WEEK}{"2Writes"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'IO/Second',
				x_label_skip => 24,
				title => 'Disk Usage in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Reads Writes));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "disk") {
			my (@h,@p,@t);
			my $diskread_prev;
			my $diskwrite_prev;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $diskread_avg;
				my $diskwrite_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $diskread eq "") {
						$diskread_prev = 0;
						$diskwrite_prev = 0;
					} else {
						if ($diskread_prev < $diskread or $diskread eq "") {
							$diskread_prev = $diskread;
						} else {
							$diskread_avg = $diskread_avg + ($diskread_prev - $diskread)/60;
							$diskread_prev = $diskread;
						}
						if ($diskwrite_prev < $diskwrite or $diskwrite eq "") {
							$diskwrite_prev = $diskwrite;
						} else {
							$diskwrite_avg = $diskwrite_avg + ($diskwrite_prev - $diskwrite)/60;
							$diskwrite_prev = $diskwrite;
						}
					}
				}
				unless (defined $diskread_avg) {
					push @p,undef;
				} else {
					push @p,($diskread_avg/60);
					&minmaxavg("MONTH","1Reads",($diskread_avg/60));
				}
				unless (defined $diskwrite_avg) {
					push @t,undef;
				} else {
					push @t,($diskwrite_avg/60);
					&minmaxavg("MONTH","2Writes",($diskwrite_avg/60));
				}
			}
			if ($minmaxavg{MONTH}{"1Reads"}{CNT} > 0) {$minmaxavg{MONTH}{"1Reads"}{AVG} /= $minmaxavg{MONTH}{"1Reads"}{CNT}}
			if ($minmaxavg{MONTH}{"2Writes"}{CNT} > 0) {$minmaxavg{MONTH}{"2Writes"}{AVG} /= $minmaxavg{MONTH}{"2Writes"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'IO/Second',
				x_label_skip => 24,
				title => "Disk Usage in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Reads Writes));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		
		if ($type eq "email") {
			my (@h,@p,@t);
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mailin eq "") {
					push @p,undef;
					push @t,undef;
				} else {
					push @p,$mailin;
					push @t,$mailout;

					&minmaxavg("HOUR","1Received",$mailin);
					&minmaxavg("HOUR","2Sent",$mailout);
				}
			}
			if ($minmaxavg{HOUR}{"1Received"}{CNT} > 0) {$minmaxavg{HOUR}{"1Received"}{AVG} /= $minmaxavg{HOUR}{"1Received"}{CNT}}
			if ($minmaxavg{HOUR}{"2Sent"}{CNT} > 0) {$minmaxavg{HOUR}{"2Sent"}{AVG} /= $minmaxavg{HOUR}{"2Sent"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Emails',
				x_label_skip => 3,
				title => 'Email Usage in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Received Sent));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "email") {
			my (@h,@p,@t);
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mailin eq "") {
					push @p,undef;
					push @t,undef;
				} else {
					push @p,$mailin;
					push @t,$mailout;

					&minmaxavg("DAY","1Received",$mailin);
					&minmaxavg("DAY","2Sent",$mailout);
				}
			}
			if ($minmaxavg{DAY}{"1Received"}{CNT} > 0) {$minmaxavg{DAY}{"1Received"}{AVG} /= $minmaxavg{DAY}{"1Received"}{CNT}}
			if ($minmaxavg{DAY}{"2Sent"}{CNT} > 0) {$minmaxavg{DAY}{"2Sent"}{AVG} /= $minmaxavg{DAY}{"2Sent"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Emails',
				x_label_skip => 60,
				title => 'Email Usage in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Received Sent));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "email") {
			my (@h,@p,@t);
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mailin_avg;
				my $mailout_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $mailin ne "") {
						$mailin_avg += $mailin;
						$mailout_avg += $mailout;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$mailin_avg/$cnt_avg;
					push @t,$mailout_avg/$cnt_avg;

					&minmaxavg("WEEK","1Received",($mailin_avg/$cnt_avg));
					&minmaxavg("WEEK","2Sent",($mailout_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1Received"}{CNT} > 0) {$minmaxavg{WEEK}{"1Received"}{AVG} /= $minmaxavg{WEEK}{"1Received"}{CNT}}
			if ($minmaxavg{WEEK}{"2Sent"}{CNT} > 0) {$minmaxavg{WEEK}{"2Sent"}{AVG} /= $minmaxavg{WEEK}{"2Sent"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Emails',
				x_label_skip => 24,
				title => 'Email Usage in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Received Sent));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "email") {
			my (@h,@p,@t);
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mailin_avg;
				my $mailout_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $mailin ne "") {
						$mailin_avg += $mailin;
						$mailout_avg += $mailout;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$mailin_avg/$cnt_avg;
					push @t,$mailout_avg/$cnt_avg;

					&minmaxavg("MONTH","1Received",($mailin_avg/$cnt_avg));
					&minmaxavg("MONTH","2Sent",($mailout_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1Received"}{CNT} > 0) {$minmaxavg{MONTH}{"1Received"}{AVG} /= $minmaxavg{MONTH}{"1Received"}{CNT}}
			if ($minmaxavg{MONTH}{"2Sent"}{CNT} > 0) {$minmaxavg{MONTH}{"2Sent"}{AVG} /= $minmaxavg{MONTH}{"2Sent"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Emails',
				x_label_skip => 24,
				title => "Email Usage in last $system_maxdays",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Received Sent));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		
		if ($type eq "temp") {
			my (@h,@p);
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $cputemp eq "") {
					push @p,undef;
				} else {
					push @p,$cputemp;

					&minmaxavg("HOUR","1CPU",$cputemp);
				}
			}
			if ($minmaxavg{HOUR}{"1CPU"}{CNT} > 0) {$minmaxavg{HOUR}{"1CPU"}{AVG} /= $minmaxavg{HOUR}{"1CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Centigrade',
				x_label_skip => 3,
				title => 'CPU Temp in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Highest Core Temperature");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "temp") {
			my (@h,@p);
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $cputemp eq "") {
					push @p,undef;
				} else {
					push @p,$cputemp;

					&minmaxavg("DAY","1CPU",$cputemp);
				}
			}
			if ($minmaxavg{DAY}{"1CPU"}{CNT} > 0) {$minmaxavg{DAY}{"1CPU"}{AVG} /= $minmaxavg{DAY}{"1CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Centigrade',
				x_label_skip => 60,
				title => 'CPU Temp in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Highest Core Temperature");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "temp") {
			my (@h,@p);
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $cputemp_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $cputemp ne "") {
						$cputemp_avg += $cputemp;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$cputemp_avg/$cnt_avg;

					&minmaxavg("WEEK","1CPU",($cputemp_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1CPU"}{CNT} > 0) {$minmaxavg{WEEK}{"1CPU"}{AVG} /= $minmaxavg{WEEK}{"1CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Centigrade',
				x_label_skip => 24,
				title => 'CPU Temp in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Highest Core Temperature");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "temp") {
			my (@h,@p);
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $cputemp_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $cputemp ne "") {
						$cputemp_avg += $cputemp;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$cputemp_avg/$cnt_avg;

					&minmaxavg("MONTH","1CPU",($cputemp_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1CPU"}{CNT} > 0) {$minmaxavg{MONTH}{"1CPU"}{AVG} /= $minmaxavg{MONTH}{"1CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Centigrade',
				x_label_skip => 24,
				title => "CPU Temp in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Highest Core Temperature");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		
		if ($type eq "mysqldata") {
			my (@h,@p,@t);
			my $mysqlin_prev;
			my $mysqlout_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlin eq "") {
					$mysqlin_prev = 0;
					$mysqlout_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($mysqlin_prev < $mysqlin or $mysqlin eq "") {
						push @p,undef;
						$mysqlin_prev = $mysqlin;
					} else {
						my $mysqlin_val = ($mysqlin_prev - $mysqlin) / 60;
						push @p,$mysqlin_val;
						$mysqlin_prev = $mysqlin;
						&minmaxavg("HOUR","1Inbound",$mysqlin_val);
					}
					if ($mysqlout_prev < $mysqlout or $mysqlout eq "") {
						push @t,undef;
						$mysqlout_prev = $mysqlout;
					} else {
						my $mysqlout_val = ($mysqlout_prev - $mysqlout) / 60;
						push @t,$mysqlout_val;
						$mysqlout_prev = $mysqlout;
						&minmaxavg("HOUR","2Outbound",$mysqlout_val);
					}
				}
			}
			if ($minmaxavg{HOUR}{"1Inbound"}{CNT} > 0) {$minmaxavg{HOUR}{"1Inbound"}{AVG} /= $minmaxavg{HOUR}{"1Inbound"}{CNT}}
			if ($minmaxavg{HOUR}{"2Outbound"}{CNT} > 0) {$minmaxavg{HOUR}{"2Outbound"}{AVG} /= $minmaxavg{HOUR}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Bytes/Second',
				x_label_skip => 3,
				title => 'MySQL Data in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqldata") {
			my (@h,@p,@t);
			my $mysqlin_prev;
			my $mysqlout_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlin eq "") {
					$mysqlin_prev = 0;
					$mysqlout_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($mysqlin_prev < $mysqlin or $mysqlin eq "") {
						push @p,undef;
						$mysqlin_prev = $mysqlin;
					} else {
						my $mysqlin_val = ($mysqlin_prev - $mysqlin) / 60;
						push @p,$mysqlin_val;
						$mysqlin_prev = $mysqlin;
						&minmaxavg("DAY","1Inbound",$mysqlin_val);
					}
					if ($mysqlout_prev < $mysqlout or $mysqlout eq "") {
						push @t,undef;
						$mysqlout_prev = $mysqlout;
					} else {
						my $mysqlout_val = ($mysqlout_prev - $mysqlout) / 60;
						push @t,$mysqlout_val;
						$mysqlout_prev = $mysqlout;
						&minmaxavg("DAY","2Outbound",$mysqlout_val);
					}
				}
			}
			if ($minmaxavg{DAY}{"1Inbound"}{CNT} > 0) {$minmaxavg{DAY}{"1Inbound"}{AVG} /= $minmaxavg{DAY}{"1Inbound"}{CNT}}
			if ($minmaxavg{DAY}{"2Outbound"}{CNT} > 0) {$minmaxavg{DAY}{"2Outbound"}{AVG} /= $minmaxavg{DAY}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Bytes/Second',
				x_label_skip => 60,
				title => 'MySQL Data in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqldata") {
			my (@h,@p,@t);
			my $mysqlin_prev;
			my $mysqlout_prev;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlin_avg;
				my $mysqlout_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlin eq "") {
						$mysqlin_prev = 0;
						$mysqlout_prev = 0;
					} else {
						if ($mysqlin_prev < $mysqlin or $mysqlin eq "") {
							$mysqlin_prev = $mysqlin;
						} else {
							my $mysqlin_val = ($mysqlin_prev - $mysqlin) / 60;
							$mysqlin_avg = $mysqlin_avg + $mysqlin_val;
							$mysqlin_prev = $mysqlin;
						}
						if ($mysqlout_prev < $mysqlout or $mysqlout eq "") {
							$mysqlout_prev = $mysqlout;
						} else {
							my $mysqlout_val = ($mysqlout_prev - $mysqlout) / 60;
							$mysqlout_avg = $mysqlout_avg + $mysqlout_val;
							$mysqlout_prev = $mysqlout;
						}
					}
				}
				unless (defined $mysqlin_avg) {
					push @p,undef;
				} else {
					push @p,($mysqlin_avg/60);
					&minmaxavg("WEEK","1Inbound",($mysqlin_avg/60));
				}
				unless (defined $mysqlout_avg) {
					push @t,undef;
				} else {
					push @t,($mysqlout_avg/60);
					&minmaxavg("WEEK","2Outbound",($mysqlout_avg/60));
				}
			}
			if ($minmaxavg{WEEK}{"1Inbound"}{CNT} > 0) {$minmaxavg{WEEK}{"1Inbound"}{AVG} /= $minmaxavg{WEEK}{"1Inbound"}{CNT}}
			if ($minmaxavg{WEEK}{"2Outbound"}{CNT} > 0) {$minmaxavg{WEEK}{"2Outbound"}{AVG} /= $minmaxavg{WEEK}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Bytes/Second',
				x_label_skip => 24,
				title => 'MySQL Data in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqldata") {
			my (@h,@p,@t);
			my $mysqlin_prev;
			my $mysqlout_prev;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlin_avg;
				my $mysqlout_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlin eq "") {
						$mysqlin_prev = 0;
						$mysqlout_prev = 0;
					} else {
						if ($mysqlin_prev < $mysqlin or $mysqlin eq "") {
							$mysqlin_prev = $mysqlin;
						} else {
							my $mysqlin_val = ($mysqlin_prev - $mysqlin) / 60;
							$mysqlin_avg = $mysqlin_avg + $mysqlin_val;
							$mysqlin_prev = $mysqlin;
						}
						if ($mysqlout_prev < $mysqlout or $mysqlout eq "") {
							$mysqlout_prev = $mysqlout;
						} else {
							my $mysqlout_val = ($mysqlout_prev - $mysqlout) / 60;
							$mysqlout_avg = $mysqlout_avg + $mysqlout_val;
							$mysqlout_prev = $mysqlout;
						}
					}
				}
				unless (defined $mysqlin_avg) {
					push @p,undef;
				} else {
					push @p,($mysqlin_avg/60);
					&minmaxavg("MONTH","1Inbound",($mysqlin_avg/60));
				}
				unless (defined $mysqlout_avg) {
					push @t,undef;
				} else {
					push @t,($mysqlout_avg/60);
					&minmaxavg("MONTH","2Outbound",($mysqlout_avg/60));
				}
			}
			if ($minmaxavg{MONTH}{"1Inbound"}{CNT} > 0) {$minmaxavg{MONTH}{"1Inbound"}{AVG} /= $minmaxavg{MONTH}{"1Inbound"}{CNT}}
			if ($minmaxavg{MONTH}{"2Outbound"}{CNT}) {$minmaxavg{MONTH}{"2Outbound"}{AVG} /= $minmaxavg{MONTH}{"2Outbound"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Bytes/Second',
				x_label_skip => 24,
				title => "MySQL Data in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Inbound Outbound));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		
		if ($type eq "mysqlqueries") {
			my (@h,@p,@t);
			my $mysqlq_prev;
			my $mysqlsq_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlq eq "") {
					$mysqlq_prev = 0;
					push @p,undef;
				} else {
					if ($mysqlq_prev < $mysqlq or $mysqlq eq "") {
						push @p,undef;
						$mysqlq_prev = $mysqlq;
					} else {
						my $mysqlq_val = ($mysqlq_prev - $mysqlq);
						push @p,$mysqlq_val;
						$mysqlq_prev = $mysqlq;
						&minmaxavg("HOUR","1Queries",$mysqlq_val);
					}
				}
			}
			if ($minmaxavg{HOUR}{"1Queries"}{CNT} > 0) {$minmaxavg{HOUR}{"1Queries"}{AVG} /= $minmaxavg{HOUR}{"1Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Queries',
				x_label_skip => 3,
				title => 'MySQL Queries in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlqueries") {
			my (@h,@p,@t);
			my $mysqlq_prev;
			my $mysqlsq_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlq eq "") {
					$mysqlq_prev = 0;
					push @p,undef;
				} else {
					if ($mysqlq_prev < $mysqlq or $mysqlq eq "") {
						push @p,undef;
						$mysqlq_prev = $mysqlq;
					} else {
						my $mysqlq_val = ($mysqlq_prev - $mysqlq);
						push @p,$mysqlq_val;
						$mysqlq_prev = $mysqlq;
						&minmaxavg("DAY","1Queries",$mysqlq_val);
					}
				}
			}
			if ($minmaxavg{DAY}{"1Queries"}{CNT} > 0) {$minmaxavg{DAY}{"1Queries"}{AVG} /= $minmaxavg{DAY}{"1Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Queries',
				x_label_skip => 60,
				title => 'MySQL Queries in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlqueries") {
			my (@h,@p,@t);
			my $mysqlq_prev;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlq_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlq eq "") {
						$mysqlq_prev = 0;
					} else {
						if ($mysqlq_prev < $mysqlq or $mysqlq eq "") {
							$mysqlq_prev = $mysqlq;
						} else {
							my $mysqlq_val = ($mysqlq_prev - $mysqlq);
							$mysqlq_avg = $mysqlq_avg + $mysqlq_val;
							$mysqlq_prev = $mysqlq;
						}
					}
				}
				unless (defined $mysqlq_avg) {
					push @p,undef;
				} else {
					push @p,($mysqlq_avg/60);
					&minmaxavg("WEEK","1Queries",($mysqlq_avg/60));
				}
			}
			if ($minmaxavg{WEEK}{"1Queries"}{CNT} > 0) {$minmaxavg{WEEK}{"1Queries"}{AVG} /= $minmaxavg{WEEK}{"1Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Queries',
				x_label_skip => 24,
				title => 'MySQL Queries in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlqueries") {
			my (@h,@p,@t);
			my $mysqlq_prev;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlq_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlq eq "") {
						$mysqlq_prev = 0;
					} else {
						if ($mysqlq_prev < $mysqlq or $mysqlq eq "") {
							$mysqlq_prev = $mysqlq;
						} else {
							my $mysqlq_val = ($mysqlq_prev - $mysqlq);
							$mysqlq_avg = $mysqlq_avg + $mysqlq_val;
							$mysqlq_prev = $mysqlq;
						}
					}
				}
				unless (defined $mysqlq_avg) {
					push @p,undef;
				} else {
					push @p,($mysqlq_avg/60);
					&minmaxavg("MONTH","1Queries",($mysqlq_avg/60));
				}
			}
			if ($minmaxavg{MONTH}{"1Queries"}{CNT} > 0) {$minmaxavg{MONTH}{"1Queries"}{AVG} /= $minmaxavg{MONTH}{"1Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Queries',
				x_label_skip => 24,
				title => "MySQL Queries in last $system_maxdays",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlslowqueries") {
			my (@h,@p,@t);
			my $mysqlsq_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlq eq "") {
					$mysqlsq_prev = 0;
					push @t,undef;
				} else {
					if ($mysqlsq_prev < $mysqlsq or $mysqlsq eq "") {
						push @t,undef;
						$mysqlsq_prev = $mysqlsq;
					} else {
						my $mysqlsq_val = ($mysqlsq_prev - $mysqlsq);
						push @t,$mysqlsq_val;
						$mysqlsq_prev = $mysqlsq;
						&minmaxavg("HOUR","1Slow_Queries",$mysqlsq_val);
					}
				}
			}
			if ($minmaxavg{HOUR}{"1Slow_Queries"}{CNT} > 0) {$minmaxavg{HOUR}{"1Slow_Queries"}{AVG} /= $minmaxavg{HOUR}{"1Slow_Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Slow Queries',
				x_label_skip => 3,
				title => 'MySQL Slow Queries in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Slow_Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlslowqueries") {
			my (@h,@p,@t);
			my $mysqlsq_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlq eq "") {
					$mysqlsq_prev = 0;
					push @t,undef;
				} else {
					if ($mysqlsq_prev < $mysqlsq or $mysqlsq eq "") {
						push @t,undef;
						$mysqlsq_prev = $mysqlsq;
					} else {
						my $mysqlsq_val = ($mysqlsq_prev - $mysqlsq);
						push @t,$mysqlsq_val;
						$mysqlsq_prev = $mysqlsq;
						&minmaxavg("DAY","1Slow_Queries",$mysqlsq_val);
					}
				}
			}
			if ($minmaxavg{DAY}{"1Slow_Queries"}{CNT} > 0) {$minmaxavg{DAY}{"1Slow_Queries"}{AVG} /= $minmaxavg{DAY}{"1Slow_Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Slow Queries',
				x_label_skip => 60,
				title => 'MySQL Slow Queries in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Slow_Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlslowqueries") {
			my (@h,@p,@t);
			my $mysqlsq_prev;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlsq_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlsq eq "") {
						$mysqlsq_prev = 0;
					} else {
						if ($mysqlsq_prev < $mysqlsq or $mysqlsq eq "") {
							$mysqlsq_prev = $mysqlsq;
						} else {
							my $mysqlsq_val = ($mysqlsq_prev - $mysqlsq);
							$mysqlsq_avg = $mysqlsq_avg + $mysqlsq_val;
							$mysqlsq_prev = $mysqlsq;
						}
					}
				}
				unless (defined $mysqlsq_avg) {
					push @t,undef;
				} else {
					push @t,($mysqlsq_avg/60);
					&minmaxavg("WEEK","1Slow_Queries",($mysqlsq_avg/60));
				}
			}
			if ($minmaxavg{WEEK}{"1Slow_Queries"}{CNT} > 0) {$minmaxavg{WEEK}{"1Slow_Queries"}{AVG} /= $minmaxavg{WEEK}{"1Slow_Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Slow Queries',
				x_label_skip => 24,
				title => 'MySQL Slow Queries in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Slow_Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlslowqueries") {
			my (@h,@p,@t);
			my $mysqlsq_prev;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlsq_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlsq eq "") {
						$mysqlsq_prev = 0;
					} else {
						if ($mysqlsq_prev < $mysqlsq or $mysqlsq eq "") {
							$mysqlsq_prev = $mysqlsq;
						} else {
							my $mysqlsq_val = ($mysqlsq_prev - $mysqlsq);
							$mysqlsq_avg = $mysqlsq_avg + $mysqlsq_val;
							$mysqlsq_prev = $mysqlsq;
						}
					}
				}
				unless (defined $mysqlsq_avg) {
					push @t,undef;
				} else {
					push @t,($mysqlsq_avg/60);
					&minmaxavg("MONTH","1Slow_Queries",($mysqlsq_avg/60));
				}
			}
			if ($minmaxavg{MONTH}{"1Slow_Queries"}{CNT} > 0) {$minmaxavg{MONTH}{"1Slow_Queries"}{AVG} /= $minmaxavg{MONTH}{"1Slow_Queries"}{CNT}}
			my @data = ([reverse @h],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Slow Queries',
				x_label_skip => 24,
				title => "MySQL Slow Queries in last $system_maxdays",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Slow_Queries));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlconns") {
			my (@h,@p,@t);
			my $mysqlcn_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlq eq "") {
					$mysqlcn_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($mysqlcn_prev < $mysqlcn or $mysqlcn eq "") {
						push @p,undef;
						$mysqlcn_prev = $mysqlcn;
					} else {
						my $mysqlcn_val = ($mysqlcn_prev - $mysqlcn);
						push @p,$mysqlcn_val;
						$mysqlcn_prev = $mysqlcn;
						&minmaxavg("HOUR","1Connections",$mysqlcn_val);
					}
					if ($mysqlth eq "") {
						push @t,undef;
					} else {
						push @t,$mysqlth;
						&minmaxavg("HOUR","2Threads",$mysqlth);
					}
				}
			}
			if ($minmaxavg{HOUR}{"1Connections"}{CNT} > 0) {$minmaxavg{HOUR}{"1Connections"}{AVG} /= $minmaxavg{HOUR}{"1Connections"}{CNT}}
			if ($minmaxavg{HOUR}{"2Threads"}{CNT} > 0) {$minmaxavg{HOUR}{"2Threads"}{AVG} /= $minmaxavg{HOUR}{"2Threads"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => '',
				x_label_skip => 3,
				title => 'MySQL Connections & Threads in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections Threads));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlconns") {
			my (@h,@p,@t);
			my $mysqlcn_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $mysqlq eq "") {
					$mysqlcn_prev = 0;
					push @p,undef;
					push @t,undef;
				} else {
					if ($mysqlcn_prev < $mysqlcn or $mysqlcn eq "") {
						push @p,undef;
						$mysqlcn_prev = $mysqlcn;
					} else {
						my $mysqlcn_val = ($mysqlcn_prev - $mysqlcn);
						push @p,$mysqlcn_val;
						$mysqlcn_prev = $mysqlcn;
						&minmaxavg("DAY","1Connections",$mysqlcn_val);
					}
					if ($mysqlth eq "") {
						push @t,undef;
					} else {
						push @t,$mysqlth;
						&minmaxavg("DAY","2Threads",$mysqlth);
					}
				}
			}
			if ($minmaxavg{DAY}{"1Connections"}{CNT} > 0) {$minmaxavg{DAY}{"1Connections"}{AVG} /= $minmaxavg{DAY}{"1Connections"}{CNT}}
			if ($minmaxavg{DAY}{"2Threads"}{CNT} > 0) {$minmaxavg{DAY}{"2Threads"}{AVG} /= $minmaxavg{DAY}{"2Threads"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => '',
				x_label_skip => 60,
				title => 'MySQL Connections & Threads in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections Threads));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlconns") {
			my (@h,@p,@t);
			my $mysqlcn_prev;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlcn_avg;
				my $mysqlth_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlq eq "") {
						$mysqlcn_prev = 0;
					} else {
						if ($mysqlcn_prev < $mysqlcn or $mysqlcn eq "") {
							$mysqlcn_prev = $mysqlcn;
						} else {
							my $mysqlcn_val = ($mysqlcn_prev - $mysqlcn);
							$mysqlcn_avg = $mysqlcn_avg + $mysqlcn_val;
							$mysqlcn_prev = $mysqlcn;
						}
						$mysqlth_avg = $mysqlth_avg + $mysqlth;
					}
				}
				unless (defined $mysqlcn_avg) {
					push @p,undef;
				} else {
					push @p,($mysqlcn_avg/60);
					&minmaxavg("WEEK","1Connections",($mysqlcn_avg/60));
				}
				unless (defined $mysqlth_avg) {
					push @t,undef;
				} else {
					push @t,($mysqlth_avg/60);
					&minmaxavg("WEEK","2Threads",($mysqlth_avg/60));
				}
			}
			if ($minmaxavg{WEEK}{"1Connections"}{CNT} > 0) {$minmaxavg{WEEK}{"1Connections"}{AVG} /= $minmaxavg{WEEK}{"1Connections"}{CNT}}
			if ($minmaxavg{WEEK}{"2Threads"}{CNT} > 0) {$minmaxavg{WEEK}{"2Threads"}{AVG} /= $minmaxavg{WEEK}{"2Threads"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => '',
				x_label_skip => 24,
				title => 'MySQL Connections & Threads in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections Threads));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "mysqlconns") {
			my (@h,@p,@t);
			my $mysqlcn_prev;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $mysqlcn_avg;
				my $mysqlth_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $mysqlq eq "") {
						$mysqlcn_prev = 0;
					} else {
						if ($mysqlcn_prev < $mysqlcn or $mysqlcn eq "") {
							$mysqlcn_prev = $mysqlcn;
						} else {
							my $mysqlcn_val = ($mysqlcn_prev - $mysqlcn);
							$mysqlcn_avg = $mysqlcn_avg + $mysqlcn_val;
							$mysqlcn_prev = $mysqlcn;
						}
						$mysqlth_avg = $mysqlth_avg + $mysqlth;
					}
				}
				unless (defined $mysqlcn_avg) {
					push @p,undef;
				} else {
					push @p,($mysqlcn_avg/60);
					&minmaxavg("MONTH","1Connections",($mysqlcn_avg/60));
				}
				unless (defined $mysqlth_avg) {
					push @t,undef;
				} else {
					push @t,($mysqlth_avg/60);
					&minmaxavg("MONTH","2Threads",($mysqlth_avg/60));
				}
			}
			if ($minmaxavg{MONTH}{"1Connections"}{CNT} > 0) {$minmaxavg{MONTH}{"1Connections"}{AVG} /= $minmaxavg{MONTH}{"1Connections"}{CNT}}
			if ($minmaxavg{MONTH}{"2Threads"}{CNT} > 0) {$minmaxavg{MONTH}{"2Threads"}{AVG} /= $minmaxavg{MONTH}{"2Threads"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => '',
				x_label_skip => 24,
				title => "MySQL Connections & Threads in last $system_maxdays days",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections Threads));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		
		if ($type eq "apachecpu") {
			my (@h,@p);
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $apachecpu eq "") {
					push @p,undef;
				} else {
					push @p,$apachecpu;

					&minmaxavg("HOUR","1Apache_CPU",$apachecpu);
				}
			}
			if ($minmaxavg{HOUR}{"1Apache_CPU"}{CNT} > 0) {$minmaxavg{HOUR}{"1Apache_CPU"}{AVG} /= $minmaxavg{HOUR}{"1Apache_CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Percentage',
				x_label_skip => 3,
				title => 'Apache CPU Usage in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Apache CPU");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apachecpu") {
			my (@h,@p);
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $apachecpu eq "") {
					push @p,undef;
				} else {
					push @p,$apachecpu;

					&minmaxavg("DAY","1Apache_CPU",$apachecpu);
				}
			}
			if ($minmaxavg{DAY}{"1Apache_CPU"}{CNT} > 0) {$minmaxavg{DAY}{"1Apache_CPU"}{AVG} /= $minmaxavg{DAY}{"1Apache_CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Percentage',
				x_label_skip => 60,
				title => 'Apache CPU Usage in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Apache CPU");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apachecpu") {
			my (@h,@p);
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $apachecpu_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $apachecpu ne "") {
						$apachecpu_avg += $apachecpu;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$apachecpu_avg/$cnt_avg;

					&minmaxavg("WEEK","1Apache_CPU",($apachecpu_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1Apache_CPU"}{CNT} > 0) {$minmaxavg{WEEK}{"1Apache_CPU"}{AVG} /= $minmaxavg{WEEK}{"1Apache_CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Percentage',
				x_label_skip => 24,
				title => 'Apache CPU Usage in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Apache CPU");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apachecpu") {
			my (@h,@p);
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $apachecpu_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $apachecpu ne "") {
						$apachecpu_avg += $apachecpu;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$apachecpu_avg/$cnt_avg;

					&minmaxavg("MONTH","1Apache_CPU",($apachecpu_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1Apache_CPU"}{CNT} > 0) {$minmaxavg{MONTH}{"1Apache_CPU"}{AVG} /= $minmaxavg{MONTH}{"1Apache_CPU"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Percentage',
				x_label_skip => 24,
				title => "Apache CPU Usage in last $system_maxdays",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Apache CPU");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		
		if ($type eq "apacheconn") {
			my (@h,@p);
			my $apacheacc_prev;
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $apacheacc eq "") {
					$apacheacc_prev = 0;
					push @p,undef;
				} else {
					if ($apacheacc_prev < $apacheacc or $apacheacc eq "") {
						push @p,undef;
						$apacheacc_prev = $apacheacc;
					} else {
						my $apacheacc_val = ($apacheacc_prev - $apacheacc);
						push @p,$apacheacc_val;
						$apacheacc_prev = $apacheacc;
						&minmaxavg("HOUR","1Connections",$apacheacc_val);
					}
				}
			}
			if ($minmaxavg{HOUR}{"1Connections"}{CNT} > 0) {$minmaxavg{HOUR}{"1Connections"}{AVG} /= $minmaxavg{HOUR}{"1Connections"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => '',
				x_label_skip => 3,
				title => 'Apache Connections in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apacheconn") {
			my (@h,@p,@t);
			my $apacheacc_prev;
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $apacheacc eq "") {
					$apacheacc_prev = 0;
					push @p,undef;
				} else {
					if ($apacheacc_prev < $apacheacc or $apacheacc eq "") {
						push @p,undef;
						$apacheacc_prev = $apacheacc;
					} else {
						my $apacheacc_val = ($apacheacc_prev - $apacheacc);
						push @p,$apacheacc_val;
						$apacheacc_prev = $apacheacc;
						&minmaxavg("DAY","1Connections",$apacheacc_val);
					}
				}
			}
			if ($minmaxavg{DAY}{"1Connections"}{CNT} > 0) {$minmaxavg{DAY}{"1Connections"}{AVG} /= $minmaxavg{DAY}{"1Connections"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => '',
				x_label_skip => 60,
				title => 'Apache Connections in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apacheconn") {
			my (@h,@p,@t);
			my $apacheacc_prev;
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $apacheacc_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $apacheacc eq "") {
						$apacheacc_prev = 0;
					} else {
						if ($apacheacc_prev < $apacheacc or $apacheacc eq "") {
							$apacheacc_prev = $apacheacc;
						} else {
							my $apacheacc_val = ($apacheacc_prev - $apacheacc);
							$apacheacc_avg = $apacheacc_avg + $apacheacc_val;
							$apacheacc_prev = $apacheacc;
						}
					}
				}
				unless (defined $apacheacc_avg) {
					push @p,undef;
				} else {
					push @p,($apacheacc_avg/60);
					&minmaxavg("WEEK","1Connections",($apacheacc_avg/60));
				}
			}
			if ($minmaxavg{WEEK}{"1Connections"}{CNT} > 0) {$minmaxavg{WEEK}{"1Connections"}{AVG} /= $minmaxavg{WEEK}{"1Connections"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => '',
				x_label_skip => 24,
				title => 'Apache Connections in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections Threads));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apacheconn") {
			my (@h,@p,@t);
			my $apacheacc_prev;
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $apacheacc_avg;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time eq "" or $apacheacc eq "") {
						$apacheacc_prev = 0;
					} else {
						if ($apacheacc_prev < $apacheacc or $apacheacc eq "") {
							$apacheacc_prev = $apacheacc;
						} else {
							my $apacheacc_val = ($apacheacc_prev - $apacheacc);
							$apacheacc_avg = $apacheacc_avg + $apacheacc_val;
							$apacheacc_prev = $apacheacc;
						}
					}
				}
				unless (defined $apacheacc_avg) {
					push @p,undef;
				} else {
					push @p,($apacheacc_avg/60);
					&minmaxavg("MONTH","1Connections",($apacheacc_avg/60));
				}
			}
			if ($minmaxavg{MONTH}{"1Connections"}{CNT} > 0) {$minmaxavg{MONTH}{"1Connections"}{AVG} /= $minmaxavg{MONTH}{"1Connections"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => '',
				x_label_skip => 24,
				title => "Apache Connections in last $system_maxdays",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Connections Threads));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		
		if ($type eq "apachework") {
			my (@h,@p,@t);
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $apachebwork eq "") {
					push @p,undef;
					push @t,undef;
				} else {
					push @p,$apachebwork;
					push @t,$apacheiwork;

					&minmaxavg("HOUR","1Busy",$apachebwork);
					&minmaxavg("HOUR","2Idle",$apacheiwork);
				}
			}
			if ($minmaxavg{HOUR}{"1Busy"}{CNT} > 0) {$minmaxavg{HOUR}{"1Busy"}{AVG} /= $minmaxavg{HOUR}{"1Busy"}{CNT}}
			if ($minmaxavg{HOUR}{"2Idle"}{CNT} > 0) {$minmaxavg{HOUR}{"2Idle"}{AVG} /= $minmaxavg{HOUR}{"2Idle"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'Workers',
				x_label_skip => 3,
				title => 'Apache Workers in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Busy Idle));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apachework") {
			my (@h,@p,@t);
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $apachebwork eq "") {
					push @p,undef;
					push @t,undef;
				} else {
					push @p,$apachebwork;
					push @t,$apacheiwork;

					&minmaxavg("DAY","1Busy",$apachebwork);
					&minmaxavg("DAY","2Idle",$apacheiwork);
				}
			}
			if ($minmaxavg{DAY}{"1Busy"}{CNT} > 0) {$minmaxavg{DAY}{"1Busy"}{AVG} /= $minmaxavg{DAY}{"1Busy"}{CNT}}
			if ($minmaxavg{DAY}{"2Idle"}{CNT} > 0) {$minmaxavg{DAY}{"2Idle"}{AVG} /= $minmaxavg{DAY}{"2Idle"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'Workers',
				x_label_skip => 60,
				title => 'Apache Workers in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Busy Idle));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apachework") {
			my (@h,@p,@t);
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $apachebwork_avg;
				my $apacheiwork_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $apachebwork ne "") {
						$apachebwork_avg += $apachebwork;
						$apacheiwork_avg += $apacheiwork;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$apachebwork_avg/$cnt_avg;
					push @t,$apacheiwork_avg/$cnt_avg;

					&minmaxavg("WEEK","1Busy",($apachebwork_avg/$cnt_avg));
					&minmaxavg("WEEK","2Idle",($apacheiwork_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1Busy"}{CNT} > 0) {$minmaxavg{WEEK}{"1Busy"}{AVG} /= $minmaxavg{WEEK}{"1Busy"}{CNT}}
			if ($minmaxavg{WEEK}{"2Idle"}{CNT} > 0) {$minmaxavg{WEEK}{"2Idle"}{AVG} /= $minmaxavg{WEEK}{"2Idle"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Workers',
				x_label_skip => 24,
				title => 'Apache Workers in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Busy Idle));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "apachework") {
			my (@h,@p,@t);
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $apachebwork_avg;
				my $apacheiwork_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $apachebwork ne "") {
						$apachebwork_avg += $apachebwork;
						$apacheiwork_avg += $apacheiwork;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
					push @t,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$apachebwork_avg/$cnt_avg;
					push @t,$apacheiwork_avg/$cnt_avg;

					&minmaxavg("MONTH","1Busy",($apachebwork_avg/$cnt_avg));
					&minmaxavg("MONTH","2Idle",($apacheiwork_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1Busy"}{CNT} > 0) {$minmaxavg{MONTH}{"1Busy"}{AVG} /= $minmaxavg{MONTH}{"1Busy"}{CNT}}
			if ($minmaxavg{MONTH}{"2Idle"}{CNT} > 0) {$minmaxavg{MONTH}{"2Idle"}{AVG} /= $minmaxavg{MONTH}{"2Idle"}{CNT}}
			my @data = ([reverse @h],[reverse @p],[reverse @t]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'Workers',
				x_label_skip => 24,
				title => "Apache Workers in last $system_maxdays",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend( qw(Busy Idle));
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
		if ($type eq "diskw") {
			my (@h,@p);
			for (my $mins = 0; $mins < 60;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$min;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $diskw eq "") {
					push @p,undef;
				} else {
					push @p,$diskw;

					&minmaxavg("HOUR","1Disk_Write",$diskw);
				}
			}
			if ($minmaxavg{HOUR}{"1Disk_Write"}{CNT} > 0) {$minmaxavg{HOUR}{"1Disk_Write"}{AVG} /= $minmaxavg{HOUR}{"1Disk_Write"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Minute',
				y_label => 'MB/s',
				x_label_skip => 3,
				title => 'Disk Write Performance in last hour',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Disk_Write");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemhour.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "diskw") {
			my (@h,@p);
			for (my $mins = 0; $mins < 1440;$mins++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($mins * 60));
				push @h,$hour;
				my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$min});
				if ($time eq "" or $diskw eq "") {
					push @p,undef;
				} else {
					push @p,$diskw;

					&minmaxavg("DAY","1Disk_Write",$diskw);
				}
			}
			if ($minmaxavg{DAY}{"1Disk_Write"}{CNT} > 0) {$minmaxavg{DAY}{"1Disk_Write"}{AVG} /= $minmaxavg{DAY}{"1Disk_Write"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred purple) ] );
			$hour_graph->set(
				x_label => 'Hour',
				y_label => 'MB/s',
				x_label_skip => 60,
				title => 'Disk Write Performance in last 24 hours',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Disk_Write");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemday.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "diskw") {
			my (@h,@p);
			for (my $hours = 0; $hours < 168;$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $diskw_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $diskw ne "") {
						$diskw_avg += $diskw;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$diskw_avg/$cnt_avg;

					&minmaxavg("WEEK","1Disk_Write",($diskw_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{WEEK}{"1Disk_Write"}{CNT} > 0) {$minmaxavg{WEEK}{"1Disk_Write"}{AVG} /= $minmaxavg{WEEK}{"1Disk_Write"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'MB/s',
				x_label_skip => 24,
				title => 'Disk Write Performance in last 7 days',
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Disk_Write");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemweek.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}

		if ($type eq "diskw") {
			my (@h,@p);
			for (my $hours = 0; $hours < (24 * $system_maxdays);$hours++) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time - ($hours * 60 * 60));
				push @h,$mday;
				my $diskw_avg;
				my $cnt_avg = 0;
				for (my $mins = 59; $mins >= 0;$mins--) {
					my ($time,$cputotal,$cpuidle,$cpuiowait,$memtotal,$memfree,$memswaptotal,$memswapfree,$load1,$load5,$load15,$netin,$netout,$diskread,$diskwrite,$mailin,$mailout,$cputemp,$mysqlin,$mysqlout,$mysqlq,$mysqlsq,$mysqlcn,$mysqlth,$apachecpu,$apacheacc,$apachebwork,$apacheiwork,$diskw,$memcached) = split(/\,/,$stata{$year}{$mon}{$mday}{$hour}{$mins});
					if ($time and $diskw ne "") {
						$diskw_avg += $diskw;
						$cnt_avg++;
					}
				}
				unless (defined $cnt_avg) {
					push @p,undef;
				} else {
					if ($cnt_avg == 0) {$cnt_avg = 1}
					push @p,$diskw_avg/$cnt_avg;

					&minmaxavg("MONTH","1Disk_Write",($diskw_avg/$cnt_avg));
				}
			}
			if ($minmaxavg{MONTH}{"1Disk_Write"}{CNT} > 0) {$minmaxavg{MONTH}{"1Disk_Write"}{AVG} /= $minmaxavg{MONTH}{"1Disk_Write"}{CNT}}
			my @data = ([reverse @h],[reverse @p]);
			my $hour_graph = GD::Graph::lines->new(750,350);
			$hour_graph->set( dclrs => [ qw(yellow dred) ] );
			$hour_graph->set(
				x_label => 'Day (Hourly Average)',
				y_label => 'MB/s',
				x_label_skip => 24,
				title => "Disk Write Performance in last $system_maxdays",
				borderclrs => $hour_graph->{dclrs},
				transparent => 0,
			);
			$hour_graph->set_legend("Disk_Write");
			$hour_graph->plot(\@data);
			$img = $imghddir."lfd_systemmonth.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $hour_graph->gd->gif();
			close ($OUT);
		}
	}

	return;
}
# end graphs
###############################################################################
# start charts
sub charts {
	my $cc_lookups = shift;
	my $imghddir = shift;
	my $img;
	$| = 1;

	require GD::Graph::bars;
	import GD::Graph::bars;
	require GD::Graph::pie;
	import GD::Graph::pie;
	require GD::Graph::lines;
	import GD::Graph::lines;

	sysopen (my $STATS,"/var/lib/csf/stats/lfdstats", O_RDWR | O_CREAT);
	flock ($STATS, LOCK_SH);
	my @stats = <$STATS>;
	chomp @stats;
	close ($STATS);

	if (@stats) {
		my $time = time;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);

		# Blocks by lfd in the last 24 hours
		my $cnt = $hour + 1;
		if ($cnt > 23) {$cnt = 0}
		my (@h,@p,@t,@hp,@cp);
		my %triggers;
		for (my $hours = 0; $hours < 24;$hours++) {
			push @h,$cnt;
			my ($permdate,$permcount,$tempdate,$tempcount) = split(/\,/,$stats[$cnt]);
			if ($time - $permdate > (24 * 60 * 60)) {$permdate = 0; $permcount = 0}
			if ($time - $tempdate > (24 * 60 * 60)) {$tempdate = 0; $tempcount = 0}
			push @p,$permcount;
			push @t,$tempcount;
			my @line = split(/\,/,$stats[$cnt]);
			for (my $loop = 4; $loop < @line; $loop+=2) {
				if ($time - $line[$loop] > (24 * 60 * 60)) {next}
				my ($triggerstat,$triggercount) = split(/\:/,$line[$loop+1]);
				$triggers{$triggerstat} += $triggercount;
			}
			$cnt++;
			if ($cnt > 23) {$cnt = 0}
		}
		my @data = ([@h],[@p],[@t]);
		my $hour_graph = GD::Graph::bars->new(750,350);
		$hour_graph->set( dclrs => [ qw(yellow dred) ] );
		$hour_graph->set(
			x_label => 'Hour',
			y_label => 'Total Blocks',
			long_ticks => 1,
			tick_length => 0,
			x_ticks => 0, 
			title => 'Blocks by lfd in the last 24 hours',
			cumulate => 1,
			borderclrs => $hour_graph->{dclrs},
			bar_spacing => 4,
			shadow_depth => 1,
			transparent => 0,
			x_label_position => 1/2,
		);
		$hour_graph->set_legend( qw(Permanent Temporary));
		$hour_graph->plot(\@data);
		$img = $imghddir."lfd_hour.gif";
		open (my $OUT, ">", "$img");
		flock ($OUT, LOCK_EX);
		binmode ($OUT);
		print $OUT $hour_graph->gd->gif();
		close ($OUT);

		foreach my $key (keys %triggers) {
			push @hp, "$key ($triggers{$key})";
			push @cp, $triggers{$key};
		}
		my @piedata = ([@hp],[@cp]);
		my $hour_pie_graph = GD::Graph::pie->new( 400, 300 ); 
		$hour_pie_graph->set(
		title => 'Block triggers in the last 24 hours',
		label => 'Trigger in csf.conf',
		axislabelclr => 'black',
		pie_height => 36,
		l_margin => 15,
		r_margin => 15,
		start_angle => 235,
		transparent => 0,
		);
		$hour_pie_graph->plot(\@piedata); 
		$img = $imghddir."lfd_pie_hour.gif";
		open (my $OUT2, ">", "$img");
		flock ($OUT2, LOCK_EX);
		binmode ($OUT2);
		print $OUT2 $hour_pie_graph->gd->gif();
		close ($OUT2);


		# Blocks by lfd in the last 30 Days
		my $maxdays = 30;
		my ($hsec,$hmin,$hhour,$hmday,$hmon,$hyear,$hwday,$hyday,$hisdst) = localtime($time - (29 * 24 * 60 * 60));
		my $hdim = (31,28,31,30,31,30,31,31,30,31,30,31)[$hmon];
		if ($hmon == 1 && (($hyear % 4 == 0) && ($hyear % 100 != 0) && ($hyear % 400 == 0))) {$hdim++}
		if ($hmon == 1) {
			$maxdays = $hdim;
			($hsec,$hmin,$hhour,$hmday,$hmon,$hyear,$hwday,$hyday,$hisdst) = localtime($time - (($maxdays - 1) * 24 * 60 * 60));
		}
		$cnt = $hmday;
		my (@hh,@ph,@th,@hhp,@hcp);
		my %htriggers;
		for (my $days = 1; $days <= $maxdays;$days++) {
			push @hh,$cnt;
			my ($permdate,$permcount,$tempdate,$tempcount) = split(/\,/,$stats[$cnt+24]);
			if ($time - $permdate > (($maxdays - 1) * 24 * 60 * 60)) {$permdate = 0; $permcount = 0}
			if ($time - $tempdate > (($maxdays - 1) * 24 * 60 * 60)) {$tempdate = 0; $tempcount = 0}
			push @ph,$permcount;
			push @th,$tempcount;
			my @line = split(/\,/,$stats[$cnt+24]);
			for (my $loop = 4; $loop < @line; $loop+=2) {
				if ($time - $line[$loop] > (($maxdays - 1) * 24 * 60 * 60)) {next}
				my ($triggerstat,$triggercount) = split(/\:/,$line[$loop+1]);
				$htriggers{$triggerstat} += $triggercount;
			}
			$cnt++;
			if ($cnt > $hdim) {$cnt = 1}
		}
		my @datah = ([@hh],[@ph],[@th]);
		my $day_graph = GD::Graph::bars->new(750,350);
		$day_graph->set( dclrs => [ qw(yellow dred) ] );
		$day_graph->set(
			x_label => 'Day',
			y_label => 'Total Blocks',
			long_ticks => 1,
			tick_length => 0,
			x_ticks => 0, 
			title => "Blocks by lfd in the last $maxdays Days",
			cumulate => 1,
			borderclrs => $day_graph->{dclrs},
			bar_spacing => 4,
			shadow_depth => 1,
			transparent => 0,
			x_label_position => 1/2,
		);
		$day_graph->set_legend( qw(Permanent Temporary));
		$day_graph->plot(\@datah);
		$img = $imghddir."lfd_month.gif";
		open (my $OUT3, ">", "$img");
		flock ($OUT3, LOCK_EX);
		binmode ($OUT3);
		print $OUT3 $day_graph->gd->gif();
		close ($OUT3);

		foreach my $key (keys %htriggers) {
			push @hhp, "$key ($htriggers{$key})";
			push @hcp, $htriggers{$key};
		}
		my @hpiedata = ([@hhp],[@hcp]);
		my $day_pie_graph = GD::Graph::pie->new( 400, 300 ); 
		$day_pie_graph->set(
		title => "Block triggers in the last $maxdays days",
		label => 'Trigger in csf.conf',
		axislabelclr => 'black',
		pie_height => 36,
		l_margin => 15,
		r_margin => 15,
		start_angle => 235,
		transparent => 0,
		);
		$day_pie_graph->plot(\@hpiedata); 
		$img = $imghddir."lfd_pie_day.gif";
		open (my $OUT4, ">", "$img");
		flock ($OUT4, LOCK_EX);
		binmode ($OUT4);
		print $OUT4 $day_pie_graph->gd->gif();
		close ($OUT4);

		# Blocks by lfd in the last 12 months
		$cnt = $mon + 2;
		if ($cnt > 12) {$cnt = 1}
		my (@hy,@py,@ty,@yhp,@ycp);
		my %ytriggers;
		for (my $months = 1; $months < 13;$months++) {
			push @hy,$cnt;
			my ($permdate,$permcount,$tempdate,$tempcount) = split(/\,/,$stats[$cnt+55]);
			if ($time - $permdate > (364 * 24 * 60 * 60)) {$permdate = 0; $permcount = 0}
			if ($time - $tempdate > (364 * 24 * 60 * 60)) {$tempdate = 0; $tempcount = 0}
			push @py,$permcount;
			push @ty,$tempcount;
			my @line = split(/\,/,$stats[$cnt+55]);
			for (my $loop = 4; $loop < @line; $loop+=2) {
				if ($time - $line[$loop] > (364 * 24 * 60 * 60)) {next}
				my ($triggerstat,$triggercount) = split(/\:/,$line[$loop+1]);
				$ytriggers{$triggerstat} += $triggercount;
			}
			$cnt++;
			if ($cnt > 12) {$cnt = 1}
		}
		my @datay = ([@hy],[@py],[@ty]);
		my $year_graph = GD::Graph::bars->new(750,350);
		$year_graph->set( dclrs => [ qw(yellow dred) ] );
		$year_graph->set(
			x_label => 'Month',
			y_label => 'Total Blocks',
			long_ticks => 1,
			tick_length => 0,
			x_ticks => 0, 
			title => 'Blocks by lfd in the last 12 months',
			cumulate => 1,
			borderclrs => $year_graph->{dclrs},
			bar_spacing => 4,
			shadow_depth => 1,
			transparent => 0,
			x_label_position => 1/2,
		);
		$year_graph->set_legend( qw(Permanent Temporary));
		$year_graph->plot(\@datay);
		$img = $imghddir."lfd_year.gif";
		open (my $OUT5, ">", "$img");
		flock ($OUT5, LOCK_EX);
		binmode ($OUT5);
		print $OUT5 $year_graph->gd->gif();
		close ($OUT5);

		foreach my $key (keys %ytriggers) {
			push @yhp, "$key ($ytriggers{$key})";
			push @ycp, $ytriggers{$key};
		}
		my @ypiedata = ([@yhp],[@ycp]);
		my $year_pie_graph = GD::Graph::pie->new( 400, 300 ); 
		$year_pie_graph->set(
		title => 'Block triggers in the last 12 months',
		label => 'Trigger in csf.conf',
		axislabelclr => 'black',
		pie_height => 36,
		l_margin => 15,
		r_margin => 15,
		start_angle => 235,
		transparent => 0,
		);
		$year_pie_graph->plot(\@ypiedata); 
		$img = $imghddir."lfd_pie_year.gif";
		open (my $OUT6, ">", "$img");
		flock ($OUT6, LOCK_EX);
		binmode ($OUT6);
		print $OUT6 $year_pie_graph->gd->gif();
		close ($OUT6);

		if ($cc_lookups) {
			# Total Top 30 Country Code blocks by lfd
			my (@ccy,@ccx);
			my %ccs;
			my $cntcc;
			my @line = split(/\,/,$stats[69]);
			for (my $x = 0; $x < @line; $x+=2) {$ccs{$line[$x]} = $line[$x+1]}
			foreach my $key (sort {$ccs{$b} <=> $ccs{$a}} keys %ccs) {
				push @ccy,$key;
				push @ccx,$ccs{$key};
				$cntcc++;
				if ($cntcc > 29) {last}
			}
			my @datacc = ([@ccy],[@ccx]);
			my $cc_graph = GD::Graph::bars->new(750,350);
			$cc_graph->set( dclrs => [ qw(yellow) ] );
			$cc_graph->set(
				x_label => 'Country Code',
				y_label => 'Total Blocks',
				long_ticks => 1,
				tick_length => 0,
				x_ticks => 0, 
				title => 'Total Top 30 Country Code blocks by lfd',
				cumulate => 1,
				borderclrs => $cc_graph->{dclrs},
				bar_spacing => 4,
				shadow_depth => 1,
				transparent => 0,
				x_label_position => 1/2,
			);
			$cc_graph->plot(\@datacc);
			$img = $imghddir."lfd_cc.gif";
			open (my $OUT, ">", "$img");
			flock ($OUT, LOCK_EX);
			binmode ($OUT);
			print $OUT $cc_graph->gd->gif();
			close ($OUT);
		}
	}

	return;
}
# end charts
###############################################################################
# start minmaxavg
sub minmaxavg {
	my $graph = shift;
	my $name = shift;
	my $value = shift;

	unless (defined $minmaxavg{$graph}{$name}{MIN}) {$minmaxavg{$graph}{$name}{MIN} = $value}
	unless (defined $minmaxavg{$graph}{$name}{MAX}) {$minmaxavg{$graph}{$name}{MAX} = $value}
	if ($minmaxavg{$graph}{$name}{MIN} > $value) {$minmaxavg{$graph}{$name}{MIN} = $value}
	if ($minmaxavg{$graph}{$name}{MAX} < $value) {$minmaxavg{$graph}{$name}{MAX} = $value}
	$minmaxavg{$graph}{$name}{AVG} += $value;
	$minmaxavg{$graph}{$name}{CNT}++;

	return;
}
# end minmaxavg
###############################################################################
# start graphs_html
sub graphs_html {
	my $imgdir = shift;
	my $html;

	$html .= "<table class='table table-bordered'>\n";
	$html .= "<tr><td>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_systemhour.gif?text=".time."'><br><table border='0' align='center'>\n";
	foreach my $key (sort keys %{$minmaxavg{HOUR}}) {
		my $item = $key;
		if ($key =~ /^\d(.*)$/) {$item = $1}
		$html .= "<tr><td><b>$item</b></td>";
		$html .= "<td>Min:<b>".sprintf("%.2f",$minmaxavg{HOUR}{$key}{MIN})."</b></td>";
		$html .= "<td>Max:<b>".sprintf("%.2f",$minmaxavg{HOUR}{$key}{MAX})."</b></td>";
		$html .= "<td>Avg:<b>".sprintf("%.2f",$minmaxavg{HOUR}{$key}{AVG})."</b></td></tr>\n";
	}
	$html .= "</table></p><div class='bs-callout bs-callout-info'>Note: This graph displays per minute statistics unless otherwise stated</div></td></tr><tr><td>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_systemday.gif?text=".time."'><br><table border='0' align='center'>\n";
	foreach my $key (sort keys %{$minmaxavg{DAY}}) {
		my $item = $key;
		if ($key =~ /^\d(.*)$/) {$item = $1}
		$html .= "<tr><td><b>$item</b></td>";
		$html .= "<td>Min:<b>".sprintf("%.2f",$minmaxavg{DAY}{$key}{MIN})."</b></td>";
		$html .= "<td>Max:<b>".sprintf("%.2f",$minmaxavg{DAY}{$key}{MAX})."</b></td>";
		$html .= "<td>Avg:<b>".sprintf("%.2f",$minmaxavg{DAY}{$key}{AVG})."</b></td></tr>\n";
	}
	$html .= "</table></p><div class='bs-callout bs-callout-info'>Note: This graph displays per minute statistics unless otherwise stated</div></td></tr><tr><td>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_systemweek.gif?text=".time."'><br><table border='0' align='center'>\n";
	foreach my $key (sort keys %{$minmaxavg{WEEK}}) {
		my $item = $key;
		if ($key =~ /^\d(.*)$/) {$item = $1}
		$html .= "<tr><td><b>$item</b></td>";
		$html .= "<td>Min:<b>".sprintf("%.2f",$minmaxavg{WEEK}{$key}{MIN})."</b></td>";
		$html .= "<td>Max:<b>".sprintf("%.2f",$minmaxavg{WEEK}{$key}{MAX})."</b></td>";
		$html .= "<td>Avg:<b>".sprintf("%.2f",$minmaxavg{WEEK}{$key}{AVG})."</b></td></tr>\n";
	}
	$html .= "</table></p><div class='bs-callout bs-callout-info'>Note: This graph displays an hourly average of the per minute statistics, so you will not see the peak minute values</div></td></tr><tr><td>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_systemmonth.gif?text=".time."'><br><table border='0' align='center'>\n";
	foreach my $key (sort keys %{$minmaxavg{MONTH}}) {
		my $item = $key;
		if ($key =~ /^\d(.*)$/) {$item = $1}
		$html .= "<tr><td><b>$item</b></td>";
		$html .= "<td>Min:<b>".sprintf("%.2f",$minmaxavg{MONTH}{$key}{MIN})."</b></td>";
		$html .= "<td>Max:<b>".sprintf("%.2f",$minmaxavg{MONTH}{$key}{MAX})."</b></td>";
		$html .= "<td>Avg:<b>".sprintf("%.2f",$minmaxavg{MONTH}{$key}{AVG})."</b></td></tr>\n";
	}
	$html .= "</table></p><div class='bs-callout bs-callout-info'>Note: This graph displays an hourly average of the per minute statistics, so you will not see the peak minute values</div></td></tr>\n</table>\n";
	return $html;
}
# end graphs_html
###############################################################################
# start charts_html
sub charts_html {
	my $cc_lookups = shift;
	my $imgdir = shift;
	my $html;

	$html .= "<table class='table table-bordered'>\n";
	$html .= "<tr><td>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_hour.gif?text=".time."'></p><p>&nbsp;</p>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_pie_hour.gif?text=".time."'></p>\n";
	$html .= "</td></tr><tr><td>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_month.gif?text=".time."'></p><p>&nbsp;</p>\n";
	$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_pie_day.gif?text=".time."'></p>\n";
	if ($cc_lookups) {
		$html .= "</td></tr><tr><td>\n";
		$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_year.gif?text=".time."'></p><p>&nbsp;</p>\n";
		$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_pie_year.gif?text=".time."'></p>\n";
		$html .= "</td></tr>\n<tr><td>\n";
		$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_cc.gif?text=".time."'></p>\n";
	} else {
		$html .= "</td></tr>\n<tr><td>\n";
		$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_year.gif?text=".time."'></p><p>&nbsp;</p>\n";
		$html .= "<p align='center'><img class='img-responsive' src='".$imgdir."lfd_pie_year.gif?text=".time."'></p>\n";
	}
	$html .= "</td></tr>\n</table>\n";

	return $html;
}
# end charts_html
###############################################################################

1;