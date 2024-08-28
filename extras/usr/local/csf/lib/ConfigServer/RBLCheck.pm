###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
package ConfigServer::RBLCheck;

use strict;
use lib '/usr/local/csf/lib';
use Fcntl qw(:DEFAULT :flock);
use ConfigServer::Config;
use ConfigServer::CheckIP qw(checkip);
use ConfigServer::Slurp qw(slurp);
use ConfigServer::GetIPs qw(getips);
use ConfigServer::RBLLookup qw(rbllookup);
use IPC::Open3;
use Net::IP;
use ConfigServer::GetEthDev;

use Exporter qw(import);
our $VERSION     = 1.01;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw();

my ($ui, $failures, $verbose, $cleanreg, $status, %ips, $images, %config,
	$ipresult, $output);

my $ipv4reg = ConfigServer::Config->ipv4reg;
my $ipv6reg = ConfigServer::Config->ipv6reg;

# end main
###############################################################################
# start report
sub report {
	$verbose = shift;
	$images = shift;
	$ui = shift;
	my $config = ConfigServer::Config->loadconfig();
	%config = $config->config();
	$cleanreg = ConfigServer::Slurp->cleanreg;
	$failures = 0;

	$| = 1;

	&startoutput;

	&getethdev;

	my @RBLS = slurp("/usr/local/csf/lib/csf.rbls");

	if (-e "/etc/csf/csf.rblconf") {
		my @entries = slurp("/etc/csf/csf.rblconf");
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
			if ($line =~ /^enablerbl:(.*)$/) {
				push @RBLS, $1;
			}
			elsif ($line =~ /^disablerbl:(.*)$/) {
				my $hit = $1;
				for (0..@RBLS) {
					my $x = $_;
					my ($rbl,$rblurl) = split(/:/,$RBLS[$x],2);
					if ($rbl eq $hit) {$RBLS[$x] = ""}
				}
			}
			if ($line =~ /^enableip:(.*)$/) {
				if (checkip(\$1)) {$ips{$1} = 1}
			}
			elsif ($line =~ /^disableip:(.*)$/) {
				if (checkip(\$1)) {delete $ips{$1}}
			}
		}
	}
	@RBLS = sort @RBLS;

	foreach my $ip (sort keys %ips)
	{
		my $netip = Net::IP->new($ip);
		my $type = $netip->iptype();

		if ($type eq "PUBLIC")
		{

			if ($verbose and -e "/var/lib/csf/${ip}.rbls")
			{
				unlink "/var/lib/csf/${ip}.rbls";
			}

			if (-e "/var/lib/csf/${ip}.rbls")
			{
				my $text = join("\n",slurp("/var/lib/csf/${ip}.rbls"));
				if ($ui) {print $text} else {$output .= $text}
			}
			else
			{
				if ($verbose)
				{
					$ipresult = "";
					my $hits = 0;
					&addtitle("Checked $ip ($type) on ".localtime());

					foreach my $line (@RBLS)
					{
						my ($rbl,$rblurl) = split(/:/,$line,2);
						if ($rbl eq "") {next}

						my ($rblhit,$rbltxt)  = rbllookup($ip,$rbl);
						my @tmptxt = $rbltxt;
						$rbltxt = "";
	
						foreach my $line (@tmptxt)
						{
							$line =~ s/(http(\S+))/<a target="_blank" href="$1">$1<\/a>/g;
							$rbltxt .= "${line}\n";
						}
		
						$rbltxt =~ s/\n/<br>\n/g;

						if ($rblhit eq "timeout")
						{
							&addline(0,$rbl,$rblurl,"TIMEOUT");
						}
						elsif ($rblhit eq "")
						{
							if ($verbose == 2)
							{
								&addline(0,$rbl,$rblurl,"OK");
							}
						}
						else
						{
							&addline(1,$rbl,$rblurl,$rbltxt);
							$hits++;
						}
					}

					unless ($hits)
					{
						my $text;
						$text .= "<div class='server-check-result'>OK</div>\n";
						if ($ui) {print $text} else {$output .= $text}
						$ipresult .= $text;
					}

					sysopen (my $OUT, "/var/lib/csf/${ip}.rbls", O_WRONLY | O_CREAT);
					flock($OUT, LOCK_EX);
					print $OUT $ipresult;
					close ($OUT);
				} else
				{
					&addtitle("New $ip ($type)");
					my $text;
					$text .= "<div class='server-check-result'>Not Checked</div>\n";
					if ($ui) {print $text} else {$output .= $text}
				}
			}
		} else {
			if ($verbose == 2) {
				&addtitle("Skipping $ip ($type)");
				my $text;
				$text .= "<div class='server-check-result'>OK</div>\n";
				if ($ui) {print $text} else {$output .= $text}
			}
		}
	}
	&endoutput;

	return ($failures,$output);
}
# end report
###############################################################################
# start startoutput
sub startoutput {
	return;
}
# end startoutput
###############################################################################
# start addline
sub addline
{
	my $status = shift;
	my $rbl = shift;
	my $rblurl = shift;
	my $comment = shift;
	my $text;
	my $check = $rbl;
	if ($rblurl ne "") {$check = "<a href='$rblurl' target='_blank'>$rbl</a>"}

	if ($status)
	{
		$text .= "<div class='server-check-status-container'>\n";
		$text .= "<div class='server-check-status-check'>$check</div>\n";
		$text .= "<div class='server-check-status-comment'>$comment</div>\n";
		$text .= "</div>\n";
		$failures ++;
		$ipresult .= $text;
	}
	elsif ($verbose)
	{
		$text .= "<div class='server-check-verbose-container'>\n";
		$text .= "<div class='server-check-verbose-check'>$check</div>\n";
		$text .= "<div class='server-check-verbose-comment'>$comment</div>\n";
		$text .= "</div>\n";
	}
	if ($ui) {print $text} else {$output .= $text}

	return;
}
# end addline

###############################################################################

# start addtitle
sub addtitle {
	my $title = shift;
	my $text;

	$text .= "<br><div class='rbl-check-status-header'><strong>$title</strong></div>\n";

	$ipresult .= $text;
	if ($ui) {print $text} else {$output .= $text}

	return;
}

# end addtitle
###############################################################################
# start endoutput
sub endoutput {
	if ($ui) {print "<br>\n"} else {$output .= "<br>\n"}

	return;
}
# end endoutput
###############################################################################
# start getethdev
sub getethdev {
	my $ethdev = ConfigServer::GetEthDev->new();
	my %g_ipv4 = $ethdev->ipv4;
	my %g_ipv6 = $ethdev->ipv6;
	foreach my $key (keys %g_ipv4) {
		$ips{$key} = 1;
	}
#	if ($config{IPV6}) {
#		foreach my $key (keys %g_ipv6) {
#			eval {
#				local $SIG{__DIE__} = undef;
#				$ipscidr6->add($key);
#			};
#		}
#	}

	return;
}
# end getethdev
###############################################################################

1;
