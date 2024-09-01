#!/usr/bin/perl
use strict;
use warnings;

my @cmd = @ARGV;

if ($cmd[0] eq "-a" or $cmd[0] eq "--allow") {
	$cmd[0] = "--add";
	system("csf",@cmd);
}
elsif ($cmd[0] eq "-d" or $cmd[0] eq "--deny") {
	$cmd[0] = "--deny";
	system("csf",@cmd);
}
elsif ($cmd[0] eq "-u" or $cmd[0] eq "--remove" or $cmd[0] eq "--unban") {
	$cmd[1] =~ s/\^|\$//g;
	$cmd[0] = "--addrm";
	system("csf",@cmd);
	$cmd[0] = "--denyrm";
	system("csf",@cmd);
	$cmd[0] = "--temprm";
	system("csf",@cmd);
}
elsif ($cmd[0] eq "-s" or $cmd[0] eq "--start") {
	$cmd[0] = "--start";
	system("csf",@cmd);
}
elsif ($cmd[0] eq "-f" or $cmd[0] eq "--flush" or $cmd[0] eq "--stop") {
	$cmd[0] = "--stop";
	system("csf",@cmd);
}
elsif ($cmd[0] eq "-r" or $cmd[0] eq "--restart") {
	$cmd[0] = "--restart";
	system("csf",@cmd);
}
elsif ($cmd[0] eq "-l" or $cmd[0] eq "--list") {
	$cmd[0] = "--status";
	system("csf",@cmd);
} else {
	print "Unknown command, please use csf directly instead of this apf stub\n";
}

exit;
