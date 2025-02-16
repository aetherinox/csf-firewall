#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
## no critic (ProhibitBarewordFileHandles, ProhibitExplicitReturnUndef, ProhibitMixedBooleanOperators, RequireBriefOpen)
# start main
use strict;
use IPC::Open3;

umask(0177);

our ($return, $fatal, $error);

$fatal = 0;
$error = 0;

#my @modules = ("ip_tables","ipt_state","ipt_multiport","iptable_filter","ipt_limit","ipt_LOG","ipt_REJECT","ipt_conntrack","ip_conntrack","ip_conntrack_ftp","iptable_mangle","ip_tables","xt_state","xt_multiport","iptable_filter","xt_limit","ipt_LOG","ipt_REJECT","ip_conntrack_ftp","iptable_mangle","xt_conntrack");
#push @modules,"ipt_owner";
#push @modules,"xt_owner";
#push @modules,"ipt_REDIRECT";
#push @modules,"iptable_nat";
#push @modules,"ipt_recent ip_list_tot=1000 ip_list_hash_size=0";
#foreach my $module (@modules) {&loadmodule($module)}

print "Testing ip_tables/iptable_filter...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp --dport 9999 -j ACCEPT");
if ($return ne "") {
	print "FAILED [FATAL Error: $return] - Required for csf to function\n";
	$fatal++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp --dport 9999 -j ACCEPT");
}

print "Testing ipt_LOG...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp --dport 9999 -j LOG");
if ($return ne "") {
	print "FAILED [FATAL Error: $return] - Required for csf to function\n";
	$fatal++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp --dport 9999 -j LOG");
}

print "Testing ipt_multiport/xt_multiport...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp -m multiport --dports 9998,9999 -j LOG");
if ($return ne "") {
	print "FAILED [FATAL Error: $return] - Required for csf to function\n";
	$fatal++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp -m multiport --dports 9998,9999 -j LOG");
}

print "Testing ipt_REJECT...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp --dport 9999 -j REJECT");
if ($return ne "") {
	print "FAILED [FATAL Error: $return] - Required for csf to function\n";
	$fatal++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp --dport 9999 -j REJECT");
}

print "Testing ipt_state/xt_state...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp --dport 9999 -m state --state NEW -j LOG");
if ($return ne "") {
	print "FAILED [FATAL Error: $return] - Required for csf to function\n";
	$fatal++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp --dport 9999 -m state --state NEW -j LOG");
}

print "Testing ipt_limit/xt_limit...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp --dport 9999 -m limit --limit 30/m --limit-burst 5 -j LOG");
if ($return ne "") {
	print "FAILED [FATAL Error: $return] - Required for csf to function\n";
	$fatal++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp --dport 9999 -m limit --limit 30/m --limit-burst 5 -j LOG");
}

print "Testing ipt_recent...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp --dport 9999 -m recent --set");
if ($return ne "") {
	print "FAILED [Error: $return] - Required for PORTFLOOD and PORTKNOCKING features\n";
	$error++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp --dport 9999 -m recent --set");
}

print "Testing xt_connlimit...";
$return = &testiptables("/sbin/iptables -I INPUT -p tcp --dport 9999 -m connlimit --connlimit-above 100 -j REJECT --reject-with tcp-reset");
if ($return ne "") {
	print "FAILED [Error: $return] - Required for CONNLIMIT feature\n";
	$error++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D  INPUT -p tcp --dport 9999 -m connlimit --connlimit-above 100 -j REJECT --reject-with tcp-reset");
}

print "Testing ipt_owner/xt_owner...";
$return = &testiptables("/sbin/iptables -I OUTPUT -p tcp --dport 9999 -m owner --uid-owner 0 -j LOG");
if ($return ne "") {
	print "FAILED [Error: $return] - Required for SMTP_BLOCK and UID/GID blocking features\n";
	$error++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -D OUTPUT -p tcp --dport 9999 -m owner --uid-owner 0 -j LOG");
}

print "Testing iptable_nat/ipt_REDIRECT...";
$return = &testiptables("/sbin/iptables -t nat -I OUTPUT -p tcp --dport 9999 -j REDIRECT --to-ports 9900");
if ($return ne "") {
	print "FAILED [Error: $return] - Required for MESSENGER feature\n";
	$error++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -t nat -D OUTPUT -p tcp --dport 9999 -j REDIRECT --to-ports 9900");
}

print "Testing iptable_nat/ipt_DNAT...";
$return = &testiptables("/sbin/iptables -t nat -I PREROUTING -p tcp --dport 9999 -j DNAT --to-destination 192.168.254.1");
if ($return ne "") {
	print "FAILED [Error: $return] - Required for csf.redirect feature\n";
	$error++;
} else {
	print "OK\n";
	&testiptables("/sbin/iptables -t nat -D PREROUTING -p tcp --dport 9999 -j DNAT --to-destination 192.168.254.1");
}

if ($fatal) {print "\nRESULT: csf will not function on this server due to FATAL errors from missing modules [$fatal]\n"}
elsif ($error) {print "\nRESULT: csf will function on this server but some features will not work due to some missing iptables modules [$error]\n"}
else {print "\nRESULT: csf should function on this server\n"}

sub testiptables {
	my $command = shift;
	my ($childin, $childout);
	my $cmdpid = open3($childin, $childout, $childout, $command);
	my @ipdata = <$childout>;
	waitpid ($cmdpid, 0);
	chomp @ipdata;
	return $ipdata[0];
}

sub loadmodule {
	my $module = shift;
	my @output;

	eval {
		local $SIG{__DIE__} = undef;
		local $SIG{'ALRM'} = sub {die};
		alarm(5);
		my ($childin, $childout);
		my $pid = open3($childin, $childout, $childout, "modprobe $module");
		@output = <$childout>;
		waitpid ($pid, 0);
		alarm(0);
	};
	alarm(0);

	return @output;
}
