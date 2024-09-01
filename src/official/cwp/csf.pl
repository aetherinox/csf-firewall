#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
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

$script = "loader_ajax.php?ajax=csfframe";
$images = "design/csf";

my $buffer = $ENV{'QUERY_STRING'};
if ($buffer eq "") {$buffer = $ENV{POST}}
if ($buffer eq "") {read(STDIN, $buffer,$ENV{'CONTENT_LENGTH'})}
if ($buffer eq "") {foreach my $item (@ARGV) {$buffer .= $item."&"}}
my @pairs = split(/&/, $buffer);
foreach my $pair (@pairs) {
	my ($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
}

print "content-type: text/html\n\n";

#foreach my $key (keys %ENV) {
#	print "$key = [$ENV{$key}]<br>\n";
#}

my $bootstrapcss = "<link rel='stylesheet' href='$images/bootstrap/css/bootstrap.min.css'>";
my $jqueryjs = "<script src='$images/jquery.min.js'></script>";
my $bootstrapjs = "<script src='$images/bootstrap/js/bootstrap.min.js'></script>";

unless ($FORM{action} eq "tailcmd" or $FORM{action} =~ /^cf/ or $FORM{action} eq "logtailcmd" or $FORM{action} eq "loggrepcmd") {
	print <<EOF;
<!doctype html>
<html lang='en'>
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
	print <<EOF;
</head>
<body>
<div id="loader"></div>
<a id='toplink' class='toplink' title='Go to bottom'><span class='glyphicon glyphicon-hand-down'></span></a>
<div class='container-fluid'>
<br>
<div class='panel panel-default'>
<h4><img src='$images/csf_small.png' style='padding-left: 10px'> ConfigServer Security &amp; Firewall - csf v$myv</h4>
</div>
EOF
}

my $templatehtml;
open (my $SCRIPTOUT, '>', \$templatehtml);
select $SCRIPTOUT;
ConfigServer::DisplayUI::main(\%FORM, $script, $script, $images, $myv);
close ($SCRIPTOUT);
select STDOUT;
$templatehtml =~ s/csfframe\?/csfframe\&/g;
print $templatehtml;

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
	print "  parent.resizeIframe(parent.document.getElementById('myiframe'));\n";
	print "</script>\n";
	print "</body>\n";
	print "</html>\n";
}

1;
