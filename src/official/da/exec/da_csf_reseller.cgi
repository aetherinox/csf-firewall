#!/usr/bin/perl
#WHMADDON:addonupdates:ConfigServer Security&<b>Firewall</b>
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (RequireUseWarnings, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
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

our ($reseller, $script, $script_da, $images, %rprivs, $myv, %FORM, %daconfig);

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config;
my $slurpreg = ConfigServer::Slurp->slurpreg;
my $cleanreg = ConfigServer::Slurp->cleanreg;

foreach my $line (slurp("/etc/csf/csf.resellers")) {
	$line =~ s/$cleanreg//g;
	my ($user,$alert,$privs) = split(/\:/,$line);
	$privs =~ s/\s//g;
	foreach my $priv (split(/\,/,$privs)) {
		$rprivs{$user}{$priv} = 1;
	}
	$rprivs{$user}{ALERT} = $alert;
}

my %session;
if ($ENV{SESSION_ID} =~ /^\w+$/) {
	open (my $SESSION, "<", "/usr/local/directadmin/data/sessions/da_sess_".$ENV{SESSION_ID}) or die "Security Error: No valid session ID for [$ENV{SESSION_ID}]";
	flock ($SESSION, LOCK_SH);
	my @data = <$SESSION>;
	close ($SESSION);
	chomp @data;
	foreach my $line (@data) {
		my ($name, $value) = split(/\=/,$line);
		$session{$name} = $value;
	}
}
if (($session{key} eq "") or ($session{ip} eq "") or ($session{key} ne $ENV{SESSION_KEY})) {
	print "Security Error: No valid session key";
	exit;
}

my ($ppid, $pexe) = &getexe(getppid());
if ($pexe ne "/usr/local/directadmin/directadmin") {
	print "Security Error: Invalid parent";
	exit;
}

delete $ENV{REMOTE_USER};

#print "content-type: text/html\n\n";
#foreach my $key (keys %ENV) {
#	print "ENV $key = [$ENV{$key}]<br>\n";
#}
#foreach my $key (keys %session) {
#	print "session $key = [$session{$key}]<br>\n";
#}

if (($session{key} ne "" and ($ENV{SESSION_KEY} eq $session{key})) and
	($session{ip} ne "" and ($ENV{REMOTE_ADDR} eq $session{ip}))) {
	my @usernames = split(/\|/,$session{username});
	$ENV{REMOTE_USER} = $usernames[-1];
}

$reseller = 0;
if ($ENV{REMOTE_USER} ne "" and $ENV{REMOTE_USER} eq $ENV{CSF_RESELLER} and $rprivs{$ENV{REMOTE_USER}}{USE}) {
	$reseller = 1;
} else {
	print "You do not have access to this feature\n";
	exit();
}

open (my $IN, "<", "/etc/csf/version.txt") or die $!;
$myv = <$IN>;
close ($IN);
chomp $myv;

$script = "/CMD_PLUGINS_RESELLER/csf/index.raw";
$script_da = "/CMD_PLUGINS_RESELLER/csf/index.raw";
$images = "/CMD_PLUGINS_RESELLER/csf/images";

my $buffer = $ENV{'QUERY_STRING'};
if ($buffer eq "") {$buffer = $ENV{POST}}
my @pairs = split(/&/, $buffer);
foreach my $pair (@pairs) {
	my ($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
}

open (my $DIRECTADMIN, "<", "/usr/local/directadmin/conf/directadmin.conf");
my @data = <$DIRECTADMIN>;
close ($DIRECTADMIN);
chomp @data;
foreach my $line (@data) {
	my ($name,$value) = split(/\=/,$line);
	$daconfig{$name} = $value;
}

my $bootstrapcss = "<link rel='stylesheet' href='$images/bootstrap/css/bootstrap.min.css'>";
my $jqueryjs = "<script src='$images/jquery.min.js'></script>";
my $bootstrapjs = "<script src='$images/bootstrap/js/bootstrap.min.js'></script>";

my @header;
my @footer;
my $bodytag;
my $htmltag = " data-post='$FORM{action}' ";
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
if (-e "/etc/csf/csf.htmltag") {
	open (my $HTMLTAG, "<", "/etc/csf/csf.htmltag");
	flock ($HTMLTAG, LOCK_SH);
	$htmltag .= <$HTMLTAG>;
	chomp $htmltag;
	close ($HTMLTAG);
}
if (-e "/etc/csf/csf.bodytag") {
	open (my $BODYTAG, "<", "/etc/csf/csf.bodytag");
	flock ($BODYTAG, LOCK_SH);
	$bodytag = <$BODYTAG>;
	chomp $bodytag;
	close ($BODYTAG);
}
unless ($config{STYLE_CUSTOM}) {
	undef @header;
	undef @footer;
	$htmltag = "";
	$bodytag = "";
}

unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print <<EOF;
<!doctype html>
<html lang='en' $htmltag>
<head>
	<title>ConfigServer Security &amp; Firewall</title>
	<meta charset='utf-8'>
	<meta name='viewport' content='width=device-width, initial-scale=1'>
	$bootstrapcss
	<link href='$images/configserver.css' rel='stylesheet' type='text/css'>
	$jqueryjs
	$bootstrapjs

<style>
.mobilecontainer {
	display:none;
}
.normalcontainer {
	display:block;
}
EOF
	if ($config{STYLE_MOBILE}) {
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
	print <<EOF;
</head>
<body $bodytag>
<div id="loader"></div>
<a id='toplink' class='toplink' title='Go to bottom'><span class='glyphicon glyphicon-hand-down'></span></a>
<div class='container-fluid'>
<br>
<div class='panel panel-default'>
<h4><img src='$images/csf_small.png' style='padding-left: 10px'> ConfigServer Security &amp; Firewall - csf v$myv</h4>
</div>
EOF
}

ConfigServer::DisplayResellerUI::main(\%FORM, $script, 0, $images, $myv);

unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print <<EOF;
<a class='botlink' id='botlink' title='Go to top'><span class='glyphicon glyphicon-hand-up'></span></a>
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
	if ($config{STYLE_MOBILE}) {
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
EOF
	}
	print "});\n";
	if ($config{STYLE_MOBILE}) {
		print <<EOF;
	\$("#NormalView").click(function(){
		document.cookie = "csfview=desktop; path=/";
		\$(".mobilecontainer").css('display','none');
		\$(".normalcontainer").css('display','block');
	});
	\$("#MobileView").click(function(){
		document.cookie = "csfview=mobile; path=/";
		\$(".mobilecontainer").css('display','block');
		\$(".normalcontainer").css('display','none');
	});
EOF
	}
	print "</script>\n";
	print @footer;
	print "</body>\n";
	print "</html>\n";
}
sub getexe {
	my $thispid = shift;
	open (my $STAT, "<", "/proc/".$thispid."/stat");
	my $stat = <$STAT>;
	close ($STAT);
	chomp $stat;
	$stat =~ /\w\s+(\d+)\s+[^\)]*$/;
	my $ppid = $1;
	my $exe = readlink("/proc/".$ppid."/exe");
	return ($ppid, $exe);
}
1;
