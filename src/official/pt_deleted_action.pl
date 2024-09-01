#!/usr/bin/perl
###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
# Example PT_DELETED_ACTION script
use strict;

my $exe = $ARGV[0];
my $pid = $ARGV[1];
my $user = $ARGV[2];
my $ppid = $ARGV[3];

if ($exe =~ m[^/usr/libexec/dovecot/imap-login]) {exec("/etc/init.d/dovecot restart")}
elsif ($exe =~ m[^/usr/libexec/dovecot/pop3-login]) {exec("/etc/init.d/dovecot restart")}
elsif ($exe =~ m[^/usr/sbin/pure-ftpd]) {exec("/etc/init.d/pure-ftpd restart")}
elsif ($exe =~ m[^/usr/sbin/pure-authd]) {exec("/etc/init.d/pure-ftpd restart")}
elsif ($exe =~ m[^/bin/dbus-daemon]) {exec("/etc/init.d/messagebus restart")}
elsif ($exe =~ m[^/usr/sbin/hald]) {exec("/etc/init.d/haldaemon restart")}
elsif ($exe =~ m[^/usr/sbin/mysqld]) {exec("/etc/init.d/mysql restart")}
elsif ($exe =~ m[^/usr/sbin/exim]) {exec("/etc/init.d/exim restart")}

exit;

###############################################################################
