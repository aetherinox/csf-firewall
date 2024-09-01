#!/usr/bin/perl
#WHMADDON:csf:ConfigServer Security & Firewall
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
use strict;
use File::Find;
use Fcntl qw(:DEFAULT :flock);
use Sys::Hostname qw(hostname);
use IPC::Open3;

use lib '/usr/local/csf/lib';
use ConfigServer::DisplayUI;
use ConfigServer::DisplayResellerUI;
use ConfigServer::Config;
use ConfigServer::Slurp qw(slurp);

use lib '/usr/local/cpanel';
require Cpanel::Form;
require Cpanel::Config;
require Whostmgr::ACLS;
require Cpanel::Rlimit;
require Cpanel::Template;
require Cpanel::Version::Tiny;
###############################################################################
# start main

our ($reseller, $script, $images, %rprivs, $myv, %FORM);

Whostmgr::ACLS::init_acls();

%FORM = Cpanel::Form::parseform();

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config;
my $slurpreg = ConfigServer::Slurp->slurpreg;
my $cleanreg = ConfigServer::Slurp->cleanreg;

Cpanel::Rlimit::set_rlimit_to_infinity();

if (-e "/usr/local/cpanel/bin/register_appconfig") {
	$script = "csf.cgi";
	$images = "csf";
} else {
	$script = "addon_csf.cgi";
	$images = "csf";
}

foreach my $line (slurp("/etc/csf/csf.resellers")) {
	$line =~ s/$cleanreg//g;
	my ($user,$alert,$privs) = split(/\:/,$line);
	$privs =~ s/\s//g;
	foreach my $priv (split(/\,/,$privs)) {
		$rprivs{$user}{$priv} = 1;
	}
	$rprivs{$user}{ALERT} = $alert;
}

$reseller = 0;
if (!Whostmgr::ACLS::hasroot()) {
	if ($rprivs{$ENV{REMOTE_USER}}{USE}) {
		$reseller = 1;
	} else {
		print "Content-type: text/html\r\n\r\n";
		print "You do not have access to this feature\n";
		exit();
	}
}

open (my $IN, "<", "/etc/csf/version.txt") or die $!;
$myv = <$IN>;
close ($IN);
chomp $myv;

my $bootstrapcss = "<link rel='stylesheet' href='$images/bootstrap/css/bootstrap.min.css'>";
my $jqueryjs = "<script src='$images/jquery.min.js'></script>";
my $bootstrapjs = "<script src='$images/bootstrap/js/bootstrap.min.js'></script>";

my @header;
my @footer;
my $htmltag = "data-post='$FORM{action}'";
if (-e "/etc/csf/csf.header") {
	open (my $HEADER, "<", "/etc/csf/csf.header");
	flock ($HEADER, LOCK_SH);
	@header = <$HEADER>;
	close ($HEADER);
}
if (-e "/etc/csf/csf.footer") {
	open (my $FOOTER, "<", "/etc/csf/csf.footer");
	flock ($FOOTER, LOCK_SH);
	@footer = <$FOOTER>;
	close ($FOOTER);
}
unless ($config{STYLE_CUSTOM}) {
	undef @header;
	undef @footer;
	$htmltag = "";
}

my $thisapp = "csf";
my $reregister;
my $modalstyle;
if ($Cpanel::Version::Tiny::major_version >= 65) {
	if (-e "/usr/local/cpanel/whostmgr/docroot/cgi/configserver/${thisapp}/${thisapp}.conf") {
		sysopen (my $CONF, "/usr/local/cpanel/whostmgr/docroot/cgi/configserver/${thisapp}/${thisapp}.conf", O_RDWR | O_CREAT);
		flock ($CONF, LOCK_EX);
		my @confdata = <$CONF>;
		chomp @confdata;
		for (0..scalar(@confdata)) {
			if ($confdata[$_] =~ /^target=mainFrame/) {
				$confdata[$_] = "target=_self";
				$reregister = 1;
			}
		}
		if ($reregister) {
			seek ($CONF, 0, 0);
			truncate ($CONF, 0);
			foreach (@confdata) {
				print $CONF "$_\n";
			}
			&printcmd("/usr/local/cpanel/bin/register_appconfig","/usr/local/cpanel/whostmgr/docroot/cgi/configserver/${thisapp}/${thisapp}.conf");
			$reregister = "<div class='bs-callout bs-callout-info'><h4>Updated application. The next time you login to WHM this will open within the native WHM main window instead of launching a separate window</h4></div>\n";
		}
		close ($CONF);
	}
}

print "Content-type: text/html\r\n\r\n";
#if ($Cpanel::Version::Tiny::major_version < 65) {$modalstyle = "style='top:120px'"}

my $templatehtml;
my $SCRIPTOUT;
unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
#	open(STDERR, ">&STDOUT");
	open ($SCRIPTOUT, '>', \$templatehtml);
	select $SCRIPTOUT;

	print <<EOF;
	<!-- $bootstrapcss -->
	<link href='$images/configserver.css' rel='stylesheet' type='text/css'>
	$jqueryjs
	$bootstrapjs
<style>
.toplink {
top: 140px;
}
.mobilecontainer {
display:none;
}
.normalcontainer {
display:block;
}
EOF
	if ($config{STYLE_MOBILE} or $reseller) {
		print <<EOF;
\@media (max-width: 600px) {
.mobilecontainer {
	display:block;
}
.normalcontainer {
	display:none;
}
}
EOF
	}
	print "</style>\n";
	print @header;
}

unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print <<EOF;
<div id="loader"></div><br />
<div class='panel panel-default'>
<h4><img src='$images/csf_small.png' style='padding-left: 10px'> ConfigServer Security &amp; Firewall - csf v$myv</h4></div>
EOF
	if ($reregister ne "") {print $reregister}
}

#eval {
if ($reseller) {
	ConfigServer::DisplayResellerUI::main(\%FORM, $script, 0, $images, $myv);
} else {
	ConfigServer::DisplayUI::main(\%FORM, $script, 0, $images, $myv);
}
#};
#if ($@) {
#	print "Error during UI output generation: [$@]\n";
#	warn "Error during UI output generation: [$@]\n";
#}

unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print <<EOF;
<script>
function getCookie(cname) {
	var name = cname + "=";
	var ca = document.cookie.split(';');
	for(var i = 0; i <ca.length; i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') {
			c = c.substring(1);
		}
		if (c.indexOf(name) == 0) {
			return c.substring(name.length,c.length);
		}
	}
	return "";
} 
\$("#loader").hide();
\$("#docs-link").hide();
\$.fn.scrollBottom = function() { 
  return \$(document).height() - this.scrollTop() - this.height(); 
};
\$('#botlink').on("click",function(){
	\$('html,body').animate({ scrollTop: 0 }, 'slow', function () {});
});
\$('#toplink').on("click",function() {
	var window_height = \$(window).height();
	var document_height = \$(document).height();
	\$('html,body').animate({ scrollTop: window_height + document_height }, 'slow', function () {});
});
\$('#tabAll').click(function(){
	\$('#tabAll').addClass('active');  
	\$('.tab-pane').each(function(i,t){
		\$('#myTabs li').removeClass('active'); 
		\$(this).addClass('active');  
	});
});
\$(document).ready(function(){
	\$('[data-tooltip="tooltip"]').tooltip();
	\$(window).scroll(function () {
		if (\$(this).scrollTop() > 500) {
			\$('#botlink').fadeIn();
		} else {
			\$('#botlink').fadeOut();
		}
		if (\$(this).scrollBottom() > 500) {
			\$('#toplink').fadeIn();
		} else {
			\$('#toplink').fadeOut();
		}
	});
EOF
	if ($config{STYLE_MOBILE} or $reseller) {
		print <<EOF;
	var csfview = getCookie('csfview');
	if (csfview == 'mobile') {
		\$(".mobilecontainer").css('display','block');
		\$(".normalcontainer").css('display','none');
		\$("#csfreturn").addClass('btn-primary btn-lg btn-block').removeClass('btn-default');
	} else if (csfview == 'desktop') {
		\$(".mobilecontainer").css('display','none');
		\$(".normalcontainer").css('display','block');
		\$("#csfreturn").removeClass('btn-primary btn-lg btn-block').addClass('btn-default');
	}
	if (top.location == location) {
		\$("#cpframetr2").show();
	} else {
		\$("#cpframetr2").hide();
	}
	if (\$(".mobilecontainer").css('display') == 'block' ) {
		document.cookie = "csfview=mobile; path=/";
		if (top.location != location) {
			top.location.href = document.location.href ;
		}
	}
	\$(window).resize(function() {
		if (\$(".mobilecontainer").css('display') == 'block' ) {
			document.cookie = "csfview=mobile; path=/";
			if (top.location != location) {
				top.location.href = document.location.href ;
			}
		}
	});
EOF
	}
	print "});\n";
	if ($config{STYLE_MOBILE} or $reseller) {
		print <<EOF;
\$("#NormalView").click(function(){
	document.cookie = "csfview=desktop; path=/";
	\$(".mobilecontainer").css('display','none');
	\$(".normalcontainer").css('display','block');
});
\$("#MobileView").click(function(){
	document.cookie = "csfview=mobile; path=/";
	if (top.location == location) {
		\$(".normalcontainer").css('display','none');
		\$(".mobilecontainer").css('display','block');
	} else {
		top.location.href = document.location.href;
	}
});
EOF
	}
	print "</script>\n";
	print @footer;
}
unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	close ($SCRIPTOUT);
	select STDOUT;
	Cpanel::Template::process_template(
		'whostmgr',
		{
			"template_file" => "${thisapp}.tmpl",
			"${thisapp}_output" => $templatehtml,
			"print"         => 1,
		}
	);
}
# end main
###############################################################################
## start printcmd
sub printcmd {
	my @command = @_;
	my ($childin, $childout);
	my $pid = open3($childin, $childout, $childout, @command);
	while (<$childout>) {print $_}
	waitpid ($pid, 0);
	return;
}
## end printcmd
###############################################################################

1;
