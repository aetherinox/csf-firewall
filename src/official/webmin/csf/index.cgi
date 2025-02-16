#!/usr/bin/perl
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
use ConfigServer::Config;

our ($script, $images, $myv, %FORM, %in);

my $config = ConfigServer::Config->loadconfig();
my %config = $config->config;

open (my $IN, "<", "/etc/csf/version.txt") or die $!;
$myv = <$IN>;
close ($IN);
chomp $myv;

$script = "index.cgi";
$images = "csfimages";

do '../web-lib.pl';      
&init_config();         
&ReadParse();
%FORM = %in;

if ($config{STYLE_CUSTOM} and $ENV{'REQUEST_URI'} =~ /xnavigation=1/ and $ENV{'HTTP_X_REQUESTED_WITH'} ne "XMLHttpRequest" and $ENV{'HTTP_X_PJAX'} ne "true") {redirect("/")}

print "Content-type: text/html\r\n\r\n";

my $bootstrapcss = "<link rel='stylesheet' href='$images/bootstrap/css/bootstrap.min.css'>";
my $jqueryjs = "<script src='$images/jquery.min.js'></script>";
my $bootstrapjs = "<script src='$images/bootstrap/js/bootstrap.min.js'></script>";

my @header;
my @body;
my @footer;
my $bodytag;
my $htmltag = " data-post='$FORM{action}' ";
if (-e "/etc/csf/csf.header") {
	open (my $HEADER, "<", "/etc/csf/csf.header");
	flock ($HEADER, LOCK_SH);
	@header = <$HEADER>;
	close ($HEADER);
}
if (-e "/etc/csf/csf.body") {
	open (my $BODY, "<", "/etc/csf/csf.body");
	flock ($BODY, LOCK_SH);
	@body = <$BODY>;
	close ($BODY);
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
	undef @body;
	undef @footer;
	$htmltag = "";
	$bodytag = "";
}

unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print "<!doctype html>\n";
	print "<html lang='en' $htmltag>\n";
	print "<head>\n";
	print "	<title>ConfigServer Security &amp; Firewall</title>\n";
	print "	<meta charset='utf-8'>\n";
	print "	<meta name='viewport' content='width=device-width, initial-scale=1'>\n";
	print "	$bootstrapcss\n";
	print "	<link href='$images/configserver.css' rel='stylesheet' type='text/css'>\n";
	print "	$jqueryjs\n";
	print "	$bootstrapjs\n";
	print "<style>\n";
	print ".mobilecontainer {\n";
	print "	display:none;\n";
	print "}\n";
	print ".normalcontainer {\n";
	print "	display:block;\n";
	print "}\n";
	if ($config{STYLE_MOBILE}) {
		print "\@media (max-width: 600px) {\n";
		print "	.mobilecontainer {\n";
		print "		display:block;\n";
		print "	}\n";
		print "	.normalcontainer {\n";
		print "		display:none;\n";
		print "	}\n";
		print "}\n";
	}
	print "</style>\n";
	print @header;
	print "</head>\n";
	print "<body $bodytag>\n";
	print @body;
	print "<div id='loader'></div>\n";
	print "<a id='toplink' class='toplink' title='Go to bottom'><span class='glyphicon glyphicon-hand-down'></span></a>\n";
	print "<div class='container-fluid'>\n";
	print "<div class='panel panel-default'>\n";
	print "<h4><img src='$images/csf_small.png' style='padding-left: 10px'> ConfigServer Security &amp; Firewall - csf v$myv</h4>\n";
	print "</div>\n";
}

ConfigServer::DisplayUI::main(\%FORM, $script, 0, $images, $myv);

unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print "<a class='botlink' id='botlink' title='Go to top'><span class='glyphicon glyphicon-hand-up'></span></a>\n";
	print "<script>\n";
	print "	\$('#loader').hide();\n";
	print "	function getCookie(cname) {\n";
	print "		var name = cname + '=';\n";
	print "		var ca = document.cookie.split(';');\n";
	print "		for(var i = 0; i <ca.length; i++) {\n";
	print "			var c = ca[i];\n";
	print "			while (c.charAt(0)==' ') {\n";
	print "				c = c.substring(1);\n";
	print "			}\n";
	print "			if (c.indexOf(name) == 0) {\n";
	print "				return c.substring(name.length,c.length);\n";
	print "			}\n";
	print "		}\n";
	print "		return '';\n";
	print "	} \n";
	print "	\$.fn.scrollBottom = function() { \n";
	print "	  return \$(document).height() - this.scrollTop() - this.height(); \n";
	print "	};\n";
	print "	\$('#botlink').on('click',function(){\n";
	print "		\$('html,body').animate({ scrollTop: 0 }, 'slow', function () {});\n";
	print "	});\n";
	print "	\$('#toplink').on('click',function() {\n";
	print "		var window_height = \$(window).height();\n";
	print "		var document_height = \$(document).height();\n";
	print "		\$('html,body').animate({ scrollTop: window_height + document_height }, 'slow', function () {});\n";
	print "	});\n";
	print "	\$('#tabAll').click(function(){\n";
	print "		\$('#tabAll').addClass('active');\n";
	print "		\$('.tab-pane').each(function(i,t){\n";
	print "			\$('#myTabs li').removeClass('active');\n";
	print "			\$(this).addClass('active');\n";
	print "		});\n";
	print "	});\n";
	print "	\$(document).ready(function(){\n";
	print "		\$('[data-tooltip=\"tooltip\"]').tooltip();\n";
	print "		\$(window).scroll(function () {;\n";
	print "			if (\$(this).scrollTop() > 500) {;\n";
	print "				\$('#botlink').fadeIn();;\n";
	print "			} else {;\n";
	print "				\$('#botlink').fadeOut();;\n";
	print "			};\n";
	print "			if (\$(this).scrollBottom() > 500) {;\n";
	print "				\$('#toplink').fadeIn();;\n";
	print "			} else {;\n";
	print "				\$('#toplink').fadeOut();;\n";
	print "			};\n";
	print "		});\n";
	if ($config{STYLE_MOBILE}) {
		print "		var csfview = getCookie('csfview');\n";
		print "		if (csfview == 'mobile') {\n";
		print "			\$('.mobilecontainer').css('display','block');\n";
		print "			\$('.normalcontainer').css('display','none');\n";
		print "			\$('#csfreturn').addClass('btn-primary btn-lg btn-block').removeClass('btn-default');\n";
		print "		} else if (csfview == 'desktop') {\n";
		print "			\$('.mobilecontainer').css('display','none');\n";
		print "			\$('.normalcontainer').css('display','block');\n";
		print "			\$('#csfreturn').removeClass('btn-primary btn-lg btn-block').addClass('btn-default');\n";
		print "		}\n";
		print "		if (top.location == location) {\n";
		print "			\$('#webmintr2').show();\n";
		print "		} else {\n";
		print "			\$('#webmintr2').hide();\n";
		print "		}\n";
		print "		if (\$('.mobilecontainer').css('display') == 'block' ) {\n";
		print "			document.cookie = 'csfview=mobile; path=/';\n";
		print "			if (top.location != location) {\n";
		print "				top.location.href = document.location.href ;\n";
		print "			}\n";
		print "		}\n";
		print "		\$(window).resize(function() {\n";
		print "			if (\$('.mobilecontainer').css('display') == 'block' ) {\n";
		print "				document.cookie = 'csfview=mobile; path=/';\n";
		print "				if (top.location != location) {\n";
		print "					top.location.href = document.location.href ;\n";
		print "				}\n";
		print "			}\n";
		print "		});\n";
	}
	print "});\n";
	if ($config{STYLE_MOBILE}) {
		print "	\$('#NormalView').click(function(){\n";
		print "		document.cookie = 'csfview=desktop; path=/';\n";
		print "		\$('.mobilecontainer').css('display','none');\n";
		print "		\$('.normalcontainer').css('display','block');\n";
		print "	});\n";
		print "	\$('#MobileView').click(function(){\n";
		print "		document.cookie = 'csfview=mobile; path=/';\n";
		print "	if (top.location == location) {\n";
		print "			\$('.normalcontainer').css('display','none');\n";
		print "			\$('.mobilecontainer').css('display','block');\n";
		print "		} else {\n";
		print "			top.location.href = document.location.href;\n";
		print "		}\n";
		print "	});\n";
	}
	print "</script>\n";
	print @footer;
	print "</body>\n";
	print "</html>\n";
}

1;
