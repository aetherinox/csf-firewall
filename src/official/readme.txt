###############################################################################
# Copyright 2006-2023, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################


ConfigServer Security & Firewall
################################

This suite of scripts provides:

   1. A straight-forward SPI iptables firewall script
   2. A daemon process that checks for Login Authentication
   3. A Control Panel configuration interface
   4. ... and much more!

The reason we have developed this suite is that we have found over the years of 
providing server management services that many of the tools available for the
task are either over-complex, not very friendly, or simply aren't as effective
as they could or should be.


This document contains:

1. Introduction

2. csf Principles

3. lfd Principles

4. csf Command Line Options

5. lfd Command Line Options

6. Login Tracking

7. Script Email Alerts

8. Process Tracking

9. Directory Watching

10. Advanced Allow/Deny Filters

11. Multiple Ethernet Devices

12. Installation on a Generic Linux Server

13. A note about FTP Connection Issues

14. Messenger Service (v1, v2 and v3)

15. Block Reporting

16. Port Flood Protection

17. External Pre- and Post- Scripts

18. lfd Clustering

19. Port Knocking

20. Connection Limit Protection

21. Port/IP address Redirection

22. Integrated User Interface Feature

23. IP Block Lists

24. Mitigating issues with syslog/rsyslog logs (RESTRICT_SYSLOG)

25. Exim SMTP AUTH Restriction

26. UI Skinning and Mobile View

27. CloudFlare

28. InterWorx

29. CentOS Web Panel (CWP)


1. Introduction
###############


ConfigServer Firewall (csf)
===========================

We have developed an SPI iptables firewall that is straight-forward, easy and
flexible to configure and secure with extra checks to ensure smooth operation.

csf can be used on any (supported - see the website) generic Linux OS.

The csf installation includes preconfigured configurations and control panel
UI's for cPanel, DirectAdmin and Webmin

Directory structure:

/etc/csf/           - configuration files 
/var/lib/csf/       - temporary data files
/usr/local/csf/bin/ - scripts
/usr/local/csf/lib/ - perl modules and static data
/usr/local/csf/tpl/ - email alert templates


Login Failure Daemon (lfd)
==========================

To complement the ConfigServer Firewall, we have developed a daemon process
that runs all the time and periodically (every X seconds) scans the latest log
file entries for login attempts against your server that continually fail
within a short period of time. Such attempts are often called "Brute-force
attacks" and the daemon process responds very quickly to such patterns and
blocks offending IP's quickly. Other similar products run every x minutes via
cron and as such often miss break-in attempts until after they've finished, our
daemon eliminates such long waits and makes it much more effective at
performing its task.

There are an array of extensive checks that lfd can perform to help alert the
server administrator of changes to the server, potential problems and possible
compromises.

On cPanel servers, lfd is integrated into the WHM > Service Manager, which will
restart lfd if it fails for any reason.

Control Panel Interface
=======================

To help with the ease and flexibility of the suite we have developed a
front-end to both csf and lfd for cPanel, DirectAdmin and Webmin. From there
you can modify the configuration files and stop, start and restart the
applications and check their status. This makes configuring and managing the
firewall very simple indeed.

There is, of course, a comprehensive Command Line Interface (CLI) for csf.


2. csf Principles
#################

The idea with csf, as with most iptables firewall configurations, is to block 
everything and then allow through only those connections that you want. This is
done in iptables by DROPPING all connections in and out of the server on all 
protocols. Then allow traffic in and out from existing connections. Then open 
ports up in and outgoing for both TCP and UDP individually.

This way we can control exactly what traffic is allowed in and out of the
server and helps protect the server from malicious attack.

In particular it prevents unauthorised access to network daemons that we want
to restrict access by IP address, and also should a service suffer a
compromise, it can help prevent access to compromise networks daemons, a
typical example being a hackers sshd daemon running on a random open port.
Perhaps the greatest of reasons is to help mitigate the effects of suffering a
root compromise where often they only way to take advantage of such a failure
is to open a daemon for the hacker to access the server on. While this won't
prevent root compromises, it can help slow them down enough for you to notice
and react.

Another way that a port filtering firewall can help is when a user level 
compromise occurs and a hacker installs DOS tools to effect other servers. A 
firewall configured to block outgoing connections except on specific ports can
help prevent DOS attacks from working and make it immediately apparent to you 
from the system logs.

csf has been designed to keep this configuration simple, but still flexible 
enough to give you options to suit your server environment. Often firewall 
scripts can become cumbersome of complex making it impossible to identify where
problems lie and to easily fix them.

To take advantage of kernel logging of iptables dropped connections you should
ensure that kernel logging daemon (klogd) is enabled. Typically, VPS servers
have this disabled and you should check /etc/init.d/syslog and make sure that
any klogd lines are not commented out. If you change the file, remember to
restart syslog.


3. lfd Principles
#################

One of the best ways to protect the server from inbound attack against network 
daemons is to monitor their authentication logs. Invalid login attempts which 
happen in a short space of time from the same source can often mean someone is 
attempting to brute-force their way into the server, usually by guessing 
usernames and passwords and therefore generating authentication and login 
failures.

lfd can monitor the most commonly abused protocols, SSHD, POP3, IMAP, FTP and 
HTTP password protection. Unlike other applications, lfd is a daemon process 
that monitors logs continuously and so can react within seconds of detecting 
such attempts. It also monitors across protocols, so if attempts are made on 
different protocols in a short space of time, all those attempts will be
counted against the threshold.

Once the number of failed login attempts is reached, lfd immediately forks a
sub-process and uses csf to block the offending IP address from both in and
outgoing connections. Stopping the attack in its tracks in a quick and timely
manner. Other applications that use cron job timings to run usually completely
miss brute force attacks as they run usually every 5 minutes or by which time
the attack could be over, or simply biding its time. In the meantime lfd will
have block the offenders IP address.

By running the block and alert email actions in a sub-process, the main daemon
can continue monitoring the logs without delay.

If you want to know when lfd blocks an IP address you can enable the email
alert (which is on by default) and you should watch the log file in
/var/log/lfd.log.


4. csf Command Line Options
###########################

Before configuring and starting csf for the first time, it is a good idea to
run the script /etc/csf/csftest.pl using:

perl /etc/csf/csftest.pl

This script will test whether the required iptables modules are functioning on
the server. Don't worry if it cannot run all the features, so long as the
script doesn't report any FATAL errors.


You can view the csf command line options by using either:

# man csf

or 

# csf -h

These options allow you to easily and quickly control and view csf. All the 
configuration files for csf are in /etc/csf and include:

csf.conf	- the main configuration file, it has helpful comments explaining
		  what each option does
csf.allow	- a list of IP's and CIDR addresses that should always be allowed 
		  through the firewall
csf.deny	- a list of IP's and CIDR addresses that should never be allowed
		  through the firewall
csf.ignore	- a list of IP's and CIDR addresses that lfd should ignore and
		  not block if detected
csf.*ignore	- various ignore files that list files, users, IP's that lfd
		  should ignore. See each file for their specific purpose and
		 tax

If you modify any of the files listed above, you will need to restart csf and
then lfd to have them take effect. If you use the command line options to add
or deny IP addresses, then csf automatically does this for you.

Both csf.allow and csf.deny can have comments after the IP address listed. The
comments must be on the same line as the IP address otherwise the IP rotation
of csf.deny will remove them.

If editing the csf.allow or csf.deny files directly, either from shell or the
WHM UI, you should put a <space>#<space> between the IP address and the comment
like this:

11.22.33.44 # Added because I don't like them

You can also include comments when using the csf -a or csf -d commands, but in
those cases you must not use a # like this:

csf -d 11.22.33.44 Added because I don't like them

If you use the shell commands then each comment line will be timestamped. You
will also find that if lfd blocks an IP address it will add a descriptive
comment plus timestamp.

If you don't want csf to rotate a particular IP in csf.deny if the line limit
is reach you can do so by adding "do not delete" within the comment field,
e.g.:

11.22.33.44 # Added because I don't like them. do not delete

Include statement in configuration files
========================================

You can use an Include statement in the following files that conform to the
format of the originating file:

/etc/csf/csf.allow
/etc/csf/csf.blocklists
/etc/csf/csf.cloudflare
/etc/csf/csf.deny
/etc/csf/csf.dirwatch
/etc/csf/csf.dyndns
/etc/csf/csf.fignore
/etc/csf/csf.ignore
/etc/csf/csf.logfiles
/etc/csf/csf.logignore
/etc/csf/csf.mignore
/etc/csf/csf.pignore
/etc/csf/csf.rblconf
/etc/csf/csf.redirect
/etc/csf/csf.rignore
/etc/csf/csf.signore
/etc/csf/csf.sips
/etc/csf/csf.smtpauth
/etc/csf/csf.suignore
/etc/csf/csf.syslogs
/etc/csf/csf.syslogusers
/etc/csf/csf.uidignore

You must specify the full path to the included file, e.g. in
/etc/csf/csf.allow:

Include /etc/csf/csf.alsoallow

Do NOT put a comment after the Include filename as this will not work and will
invalidate the Include line.

Note: None of the csf commands for adding or removing entries from the
originating file will be performed on Include files. They are treated as
read-only.


5. lfd Command Line Options
###########################

lfd does not have any command line options of its own but is controlled through
init or systemd which stops and starts the daemon. It is configured using the
/etc/csf/csf.conf file.

The best way to see what lfd is up to is to take a look in /var/log/lfd.log 
where its activities are logged.

The various email alert templates follow, care should be taken if you
modify that file to maintain the correct format:

/usr/local/csf/tpl/accounttracking.txt - for account tracking alert emails
/usr/local/csf/tpl/alert.txt - for port blocking emails
/usr/local/csf/tpl/connectiontracking.txt - for connection tracking emails
/usr/local/csf/tpl/consolealert.txt - for console root login alert emails
/usr/local/csf/tpl/cpanelalert.txt - for WHM/cPanel account access emails
/usr/local/csf/tpl/exploitalert.txt - for system exploit alert emails
/usr/local/csf/tpl/filealert.txt - for suspicious file alert emails
/usr/local/csf/tpl/forkbombalert.txt - for fork bomb alert emails
/usr/local/csf/tpl/integrityalert.txt - for system integrity alert emails
/usr/local/csf/tpl/loadalert.txt - for high load average alert emails
/usr/local/csf/tpl/logalert.txt - for log scanner report emails
/usr/local/csf/tpl/logfloodalert.txt - for log file flooding alert emails
/usr/local/csf/tpl/modsecipdbcheck.txt - for ModSecurity IP DB size alert emails
/usr/local/csf/tpl/netblock.txt - for netblock alert emails
/usr/local/csf/tpl/permblock.txt - for temporary to permanent block alert emails
/usr/local/csf/tpl/portknocking.txt - for Port Knocking alert emails
/usr/local/csf/tpl/portscan.txt - for port scan tracking alert emails
/usr/local/csf/tpl/processtracking.txt - for process tracking alert emails
/usr/local/csf/tpl/queuealert.txt - for email queue alert emails
/usr/local/csf/tpl/relayalert.txt - for email relay alert emails
/usr/local/csf/tpl/resalert.txt - for process resource alert emails
/usr/local/csf/tpl/scriptalert.txt - for script alert emails
/usr/local/csf/tpl/sshalert.txt - for SSH login emails
/usr/local/csf/tpl/sualert.txt - for SU alert emails
/usr/local/csf/tpl/tracking.txt - for POP3/IMAP blocking emails
/usr/local/csf/tpl/uialert.txt - for UI alert emails
/usr/local/csf/tpl/usertracking.txt - for user process tracking alert emails
/usr/local/csf/tpl/watchalert.txt - for watched file and directory change alert emails
/usr/local/csf/tpl/webminalert.txt - for Webmin login emails

6. Login Tracking
#################

Login tracking is an extension of lfd, it keeps track of POP3 and IMAP logins
and limits them to X connections per hour per account per IP address. It uses
iptables to block offenders to the appropriate protocol port only and flushes
them every hour and starts counting logins afresh. All of these blocks are
temporary and can be cleared manually by restarting csf.

There are two settings, one of POP3 and one for IMAP logins. It's generally
not a good idea to track IMAP logins as many clients login each time to perform
a protocol transaction (there's no need for them to repeatedly login, but you
can't avoid bad client programming!). So, if you do have a need to have some
limit to IMAP logins, it is probably best to set the login limit quite high.

If you want to know when lfd temporarily blocks an IP address you can enable
the email tracking alerts option (which is on by default)

You can also add your own login failure tracking using regular expression
matching. Please read /usr/local/csf/bin/regex.custom.pm for more information

Important Note: To enable successful SSHD login tracking you should ensure that
UseDNS in /etc/ssh/sshd_config is disabled by using:

UseDNS no

and that sshd has then been restarted.

7. Script Email Alerts
######################

(cPanel installations of csf only)

lfd can scan for emails being sent through exim from scripts on the server.

To use this feature you must add an extended email logging line to WHM >
Exim Configuration Manager > Advanced Editor. Search for log_selector and
ensure that the following are included:

log_selector = +arguments +subject +received_recipients

This setting will then send an alert email if more than LF_SCRIPT_LIMIT lines
appear with the same cwd= path in them within an hour. This can be useful in
identifying spamming scripts on a server, especially PHP scripts running
under the nobody account. The email that is sent includes the exim log lines
and also attempts to find scripts that send email in the path that may be the
culprit.

This option uses the /usr/local/csf/tpl/scriptalert text file for alert emails.

If you enable the option LF_SCRIPT_ALERT then lfd will disable the path using
chattr +i and chmod 000 so that the user cannot re-enable it. The alert email
also then includes the commands needed to re-enable the offending path.

Any false-positives can be added to /etc/csf/csf.signore and lfd will then
ignore those listed scripts.

8. Process Tracking
###################

This option enables tracking of user and nobody processes and examines them for
suspicious executables or open network ports. Its purpose is to identify
potential exploit processes that are running on the server, even if they are
obfuscated to appear as system services. If a suspicious process is found an
alert email is sent with relevant information.

It is then the responsibility of the recipient to investigate the process
further as the script takes no further action. Processes (PIDs) are only
reported once unless lfd is restarted.

There is an ignore file /etc/csf/csf.pignore which can be used to whitelist
either usernames or full paths to binaries. Care should be taken with ignoring
users or files so that you don't force false-negatives.

You must use the following format:

exe:/full/path/to/file
user:username
cmd:command line

The command line as reported in /proc has the trailing null character removed
and all other occurrences replaced with a space. So, the line you specify in
the file should have space separators for the command line arguments, not null
characters.

It is strongly recommended that you use command line ignores very carefully
as any process can change what is reported to the OS.

Don't list the paths to perl or php as this will prevent detection of
suspicious web scripts.

For more information on the difference between executable and command line, you
should read and understand how the linux /proc pseudo-filesystem works:

man proc
man lsof

It is beyond the scope of this application to explain how to investigate
processes in the linux /proc architecture.

The email alerts are sent using the processtracking.txt email template.

It should be noted that this feature will not pickup a root compromise as root
processes are ignored - you should use established IDS tools for such security
considerations.

*** NOTE *** You _will_ get false-positives with this particular feature. The
reason for the feature is to bring to your attention processes that have either
been running for a long time under a user account, or that have ports open
outside of your server. You should satisfy yourself that they are indeed false-
positives before either ignoring them or trapping them in the csf.pignore file.

We've done our best to minimise false-positives, but there's a balance between
being cautious and the sensitivity needed to pick up exploits.

The script itself cannot distinguish between malicious intent and intended
script function - that's your job as the server administrator ;-)

The setting PT_SKIP_HTTP does reduce the number of false-positives by not
checking scripts running directly or through CGI in Apache. However, disabling
this setting will make a more thorough job of detecting active exploits of all
varieties.

Another alternative might be to disable PT_SKIP_HTTP and increase PT_LIMIT to
avoid picking up web scripts, however this means that real exploits will run
for longer before they're picked up.

You can, of course, turn the feature off too - if you really want to.


9. Directory Watching
#####################

Directory Watching enables lfd to check /tmp and /dev/shm and other pertinent
directories for suspicious files, i.e. script exploits.

If a suspicious file is found an email alert is sent using the template
filealert.txt.

NOTE: Only one alert per file is sent until lfd is restarted, so if you remove
a suspicious file, remember to restart lfd

To remove any suspicious files found during directory watching, enable
corresponding setting the suspicious files will be appended to a tarball in
/var/lib/csf/suspicious.tar and deleted from their original location. Symlinks
are simply removed.

If you want to extract the tarball to your current location, use:

tar -xpf /var/lib/csf/suspicious.tar

This will preserver the path and permissions of the original file.

Any false-positives can be added to /etc/csf/csf.fignore and lfd will then
ignore those listed files and directories.

Within csf.fignore is a list of files that lfd directory watching will ignore.
You must specify the full path to the file

You can also use perl regular expression pattern matching, for example:
/tmp/clamav.*
/tmp/.*\.wrk

Remember that you will need to escape special characters (precede them with a
backslash) such as \. \?

Pattern matching will only occur with strings containing an asterisk (*),
otherwise full file path matching will be applied

You can also add entries to ignore files owner by a particular user by 
preceding it with user:, for example:
user:bob


Note: files owned by root are ignored

For information on perl regular expressions:
http://www.perl.com/doc/manual/html/pod/perlre.html

The second aspect of Directory Watching is enabled with LF_DIRWATCH_FILE. This
option allows you to have lfd watch a particular file or directory for changes
and should they change and email alert using watchalert.txt is sent. It uses a
simple md5sum match from the output of "ls -laAR" on the entry and so will
traverse directories if specified.


10. Advanced Allow/Deny Filters
###############################

In /etc/csf/csf.allow and /etc/csf/csf.deny you can add more complex port and
ip filters using the following format (you must specify a port AND an IP
address):

tcp/udp|in/out|s/d=port|s/d=ip|u=uid

Broken down:

tcp/udp  : EITHER tcp OR udp OR icmp protocol
in/out   : EITHER incoming OR outgoing connections
s/d=port : EITHER source OR destination port number (or ICMP type)
           (use a _ for a port range, e.g. 2000_3000)
           (use a , for a multiport list of up to 15 ports, e.g. 22,80,443)
s/d=ip   : EITHER source OR destination IP address
u/g=UID  : EITHER UID or GID of source packet, implies outgoing connections,
           s/d=IP value is ignored

Note: ICMP filtering uses the "port" for s/d=port to set the ICMP type.
Whether you use s or d is not relevant as either simply uses the iptables
--icmp-type option. Use "iptables -p icmp -h" for a list of valid ICMP types.
Only one type per filter is supported

Examples:

# TCP connections inbound to port 3306 from IP 11.22.33.44
tcp|in|d=3306|s=11.22.33.44

# TCP connections outbound to port 22 on IP 11.22.33.44
tcp|out|d=22|d=11.22.33.44

Note| If omitted, the default protocol is set to "tcp", the default connection
direction is set to "in", so|

# TCP connections inbound to port 22 from IP 44.33.22.11
d=22|s=44.33.22.11

# TCP connections outbound to port 80 from UID 99
tcp|out|d=80||u=99

# ICMP connections inbound for type ping from 44.33.22.11
icmp|in|d=ping|s=44.33.22.11

# TCP connections inbound to port 22 from Dynamic DNS address
# www.configserver.com (for use in csf.dyndns only)
tcp|in|d=22|s=www.configserver.com

# TCP connections inbound to port 22,80,443 from IP 44.33.22.11
d=22,80,443|s=44.33.22.11


11. Multiple Ethernet Devices
#############################

If you have multiple ethernet NICs that you want to apply all rules to, then
you can set ETH_DEVICE to the interface name immediately followed by a plus
sign. For example, eth+ will apply all iptables rules to eth0, eth1, etc.

That said, if you leave ETH_DEVICE blank all rules will be applied to all
ethernet devices equally.


12. Installation on a Generic Linux Server
##########################################

csf+lfd can be configured to run on a generic Linux server. There are some
changes to the features available:

1. The default port range is for a typical non-cPanel web server and may need
   altering to suit the servers environment

2. The Process Tracking ignore file may need expanding in /etc/csf/csf.pignore
   to suit the server environment

3. A standard Webmin Module to configure csf is included - see the install.txt
   for more information

The codebase is the same for a all installations, the csf.conf file simply has
the cPanel specific options removed and the GENERIC option added


13. A note about FTP Connection Issues
######################################

It is important when using an SPI firewall to ensure FTP client applications
are configured to use Passive (PASV) mode connections to the server.

On servers running Monolithic kernels (e.g. VPS Virtuozzo/OpenVZ and custom
built kernels) ip_conntrack and ip_conntrack_ftp iptables kernel modules may
not be available or fully functional. If this happens, FTP passive mode (PASV)
won't work. In such circumstances you will have to open a hole in your firewall
and configure the FTP server to use that same hole.

For example, with pure-ftpd you could add the port range 30000:35000 to TCP_IN
and add the following line to /etc/pure-ftpd.conf and then restart pure-ftpd:
PassivePortRange	30000 35000

For example, with proftpd you could add the port range 30000:35000 to TCP_IN
and add the following line to /etc/proftpd.conf and then restart proftpd:
PassivePorts	30000 35000

FTP over SSL/TLS will usually fail when using an SPI firewall. This is because
of the way the FTP protocol established a connection between client and server.
iptables fails to establish a related connection when using FTP over SSL
because the FTP control connection is encrypted and so cannot track the
relationship between the connection and the allocation of an ephemeral port.

If you need to use FTP over SSL, you will have to open up a passive port block
in both csf and your FTP server configuration (see above).

Perversely, this makes your firewall less secure, while trying to make FTP
connections more secure.


14. Messenger Service
#####################

This feature allows the display of a message to a blocked connecting IP address
to inform the user that they are blocked in the firewall. This can help when
users get themselves blocked, e.g. due to multiple login failures. The service
is provided by several daemons running on ports providing HTTPS, HTML or TEXT
message.

This services uses the iptables nat table and the associated PREROUTING chain.
The ipt_REDIRECT module is used to redirect the incoming port to the relevant
messenger service server port.

Temporary and/or permanent (csf.deny) IP addresses can be serviced by this
feature.

It does NOT include redirection of any GLOBAL or BLOCK deny lists.

It does require the IO::Socket::INET perl module.

It does NOT work on servers that do not have the iptables module ipt_REDIRECT
loaded. Typically, this will be with Monolithic kernels. VPS server admins
should check with their VPS host provider that the iptables module is included.

If you change any of the files in /etc/csf/messenger/ you must restart lfd as
they are all cached in memory.

Use of this feature can be controlled by the Country Code options:
CC_MESSENGER_ALLOW = ""
CC_MESSENGER_DENY = ""
See /etc/csf/csf.conf for an explanation of those options.


Messenger User
==============

You should create a unique user that the messenger services will run under. 
This user should be disabled and have no shell access, but should have a home
directory.

For example, you can create such an account (in this example called "csf") from
the root shell using:

useradd csf -s /bin/false

TEXT Messenger Server
=====================

The TEXT message that is displayed is provided by the file:

/etc/csf/messenger/index.text

This file should only contain text. The TEXT server providing this file simply
sends the contents to the connecting port and no protocol exchange takes place.
this means that it may not be suitable for use with protocols such as POP3.

The server has a built-in function that will replace the text [IPADDRESS] in
index.text with the IP address that is blocked by the firewall. This will help
the blocked user know what their blocked IP address is. You can also use the
text [HOSTAME] which will be replaced by the servers FQDN hostname.

The TEXT server does not support SSL connections, so redirecting port 995 will
not work.

The TEXT server port should not be added to the TCP_IN list.

There is a maximum of 15 port allowed in MESSENGER_TEXT_IN.

HTML and HTTPS Messenger v1 Server
==================================

The HTML and HTTPS message that is displayed is provided by the file:

/etc/csf/messenger/index.html
/etc/csf/messenger/index.recaptcha.html (if using the RECAPTCHA_* feature)

The HTML server providing this page is very rudimentary but will accept the use
of linked images that are stored in the /etc/csf/messenger/ directory. The
images must be of either jpg, gif or png format. These images are loaded into
memory so you should keep the number and size to a minimum. No other linked
resource files are supported (e.g. .css, .js).

It is recommeneded to to use inline images (source embedding) to improve page
load speed and reduce lfd overheads.

As the HTML server requires interaction with the client, there is a timer on
the connection to prevent port hogging.

The server has a built-in function that will replace the text [IPADDRESS] in
index.html with the IP address that is blocked by the firewall. This will help
the blocked user know what their blocked IP address is. You can also use the
text [HOSTAME] which will be replaced by the servers FQDN hostname.

The HTTPS service obtains the necessary certificates from MESSENGER_HTTPS_CONF.

The HTML and HTTPS server ports should not be added to the TCP_IN list.

There is a maximum of 15 ports allowed in MESSENGER_HTML_IN and
MESSENGER_HTTPS_IN.

HTML and HTTPS Messenger v2 Server
==================================

This service is only available to cPanel servers running Apache. It utilises
the existing Apache service to provide the message as well as RECAPTCHA
unblocking. It is enabled through the MESSENGERV2 option.

The server must be running Apache v2.4 and using cPanel's EasyApache v4.

HTML and HTTPS Messenger v3 Server
==================================

This service is available to servers running Apache or Litespeed/Openlitespeed.
It utilises the existing web server service to provide the message as well as
RECAPTCHA unblocking. It is enabled through the MESSENGERV3 option.

The web server configuration is created in /var/lib/csf/csf.conf using the
following templates in /usr/local/csf/tpl/:

apache.main.txt
apache.http.txt
apache.https.txt

litespeed.main.txt
litespeed.http.txt
litespeed.https.txt

*.main.txt can contain any web server directives required for the service to
function.
*.http.txt contains the configuration to offer the HTTP service
*.https.txt contains the configuration to offer the HTTPS service. In this file
the virtualhost container is created for each domain served with a certificate
on the server.

These templates are not overwritten during a csf upgrade.

PHP is needed to display the MESSENGER web files (see following). This is
controlled by the MESSENGERV3PHPHANDLER setting.

If left empty, the MESSENGER service will try to configure this. If this does
not work, this should be set as an "Include /path/to/csf_php.conf" or similar
file which must contain appropriate web server configuration to allow PHP
scripts to run under the MESSENGER_USER account. This line will be included
within each MESSENGER VirtualHost container. This will replace the
[MESSENGERV3PHPHANDLER] line from the csf webserver template files.

Messenger v2 and v3
===================

For the service to work, the Messenger User MUST have a specific directory
structure. This will be created by the script if it does not exist so long as
the user has been created with a home directory. The structure needs to mimic
the standard web server setup, e.g. using "csf" as the user:

/home/csf/ (Owner csf:csf, Permissions 711)
/home/csf/public_html/ (Owner csf:nobody, Permissions 711)

lfd will populate this structure with the following files:

/home/csf/public_html/.htaccess
/home/csf/public_html/index.php

If RECAPTCHA_* is enabled these files will be created if they do not already
exist:

/home/csf/recaptcha.php
/home/csf/public_html/index.php
/home/csf/en.php

The HTML and HTTPS index file is created from (respectively):
/etc/csf/messenger/index.php
/etc/csf/messenger/index.recaptcha.php
/etc/csf/messenger/en.php

You should NOT modify the templates in /etc/csf/messenger/ as they will be
overwritten when csf upgrades. Instead modify the files within /home/csf/.

Each time lfd is restarted a check is made of the preceding structure and any
missing files are recreated. This process also creates the configuration file
for Apache in /etc/apache2/conf.d/csf.messenger.conf and restarts httpd.

/etc/apache2/conf.d/csf.messenger.conf contains all the VirtualHost directives
to serve the MESSENGERV2 services.

Translation of /home/csf/en.php is possible by creating the appropriate
[abbr].php file.

The HTML and HTTPS server ports should NOT be added to the TCP_IN list.

As Apache is handling all requests for HTML and HTTPS connections, all
scripting for the service is provided by the files in /home/csf/public_html/
which allows the use of PHP and CGI scripts.


15. Block Reporting
###################

lfd can run an external script when it performs and IP address block following
for example a login failure. This is done by setting the configuration variable
BLOCK_REPORT to a script that must be executable. The following parameters are
passed the the script as arguments:

ARG 1 = IP Address	# The IP address or CIDR being blocked
ARG 2 = ports		# Port, comma separated list or * for all ports
ARG 3 = permanent	# 0=temporary block, 1=permanent block
ARG 4 = inout		# Direction of block: in, out or inout
ARG 5 = timeout		# If a temporary block, TTL in seconds, otherwise 0
ARG 6 = message		# Message containing reason for block
ARG 7 = logs		# The logs lines that triggered the block (will contain
                        # line feeds between each log line)
ARG 8 = trigger		# The configuration settings triggered

lfd launches the BLOCK_REPORT in a forked process which terminates after 10
seconds if not completed by then. It runs under the root account, so great care
should be exercised with regard to security of the BLOCK_REPORT script.

To also run an external script when a temporary block is unblocked by lfd.
UNBLOCK_REPORT can be the full path of the external script which must be
executable. The following parameters are passed the the script as arguments:

ARG 1 = IP Address	# The IP address or CIDR being blocked
ARG 2 = port*		# Port, there could be multiple unblocks for each IP

[*] If a port was specified in the initial block.

16. Port Flood Protection
#########################

This option configures iptables to offer protection from DOS attacks against
specific ports. This option limits the number of connections per time interval
that new connections can be made to specific ports.

This feature does not work on servers that do not have the iptables module
ipt_recent loaded. Typically, this will be with Monolithic kernels. VPS server
admins should check with their VPS host provider that the iptables module is
included.

By default ipt_recent tracks only the last 100 IP addresses. The tracked IP
addresses can be viewed in /proc/net/ipt_recent/* where the port number is the
filename.

Syntax for the PORTFLOOD setting:

PORTFLOOD is a comma separated list of:
port;protocol;hit count*;interval seconds

So, a setting of PORTFLOOD = "22;tcp;5;300,80;tcp;20;5" means:

1. If more than 5 connections to tcp port 22 within 300 seconds, then block
that IP address from port 22 for at least 300 seconds after the last packet is
seen, i.e. there must be a "quiet" period of 300 seconds before the block is
lifted

2. If more than 20 connections to tcp port 80 within 5 seconds, then block
that IP address from port 80 for at least 5 seconds after the last packet is
seen, i.e. there must be a "quiet" period of 5 seconds before the block is
lifted

More information about the ipt_recent module can be found in the iptables man
page and at http://snowman.net/projects/ipt_recent/

Note: Blocked IP addresses do not appear in any of the iptables chains when
using this module. You must manipulate the /proc/net/ipt_recent/* files as per
the module documentation to view and remove IP addresses that are currently
blocked if the blocks have not yet expired.

Restarting csf resets the ipt_recent tables and removes all of its blocks.

Note: There are some restrictions when using ipt_recent:

1. By default it only tracks 100 addresses per table (we try and increase this
to 1000 via modprobe)

2. By default it only counts 20 packets per address remembered

*This means that you need to keep the hit count to below 20.


17. External Pre- and Post- Scripts
###################################

External commands (e.g. iptables rules not covered by csf) can be run before
and/or after csf sets up the iptables chains and rules.

1. To run external commands before csf configures iptables create the file:

/usr/local/csf/bin/csfpre.sh

Set that file as executable and add an appropriate shebang interpreter line and
then whatever external commands you wish to execute.

For example:

#!/bin/sh
/some/path/to/binary -a -b -c etc

Then chmod +x /usr/local/csf/bin/csfpre.sh

2. To run external commands after csf configures iptables create the file:

/usr/local/csf/bin/csfpost.sh

Set that file as executable and add an appropriate shebang interpreter line and
then whatever external commands you wish to execute.


Note: The scripts can alternatively be placed in /etc/csf/. If a script is found in
both locations (/etc/csf/ and /usr/local/csf/bin/) then only the script in
/usr/local/csf/bin/ will be executed.

csfpre.sh/csfpost.sh are run directly. If present, csf chmods the script 0700
and checks for a shebang. If the shebang is missing #!/bin/bash is added to the
top. The script is them run.

Note: While csf runs the script with a preset PATH, you MUST use the full path
to any binaries that you execute within these scripts to ensure they are run 
correctly


18. lfd Clustering
##################

This set of options (CLUSTER*) in csf.conf allows the configuration of an
lfd cluster environment where a group of servers can share blocks and, via the
CLI, configuration option changes, allows and removes

In the configuration there are two comma separated lists of IP addresses:

CLUSTER_SENDTO = ""
CLUSTER_RECVFROM = ""

Note: Do not use spaces in these lists

If you want all members of the lfd cluster to send block notifications to each
other then both settings should be them same. You also need to enable
CLUSTER_BLOCK (enabled by default) for lfd to automatically send blocks to all
members in CLUSTER_SENDTO.

However, you can also set up a cluster such that some members only provide
notifications to others and do not accept blocks from others. For example, you
may have a cluster of servers that includes one that hosts a support desk that
you do not want to block clients from accessing. In such an example you might
want to exclude the support desk server from the CLUSTER_SENDTO list, but
include it in the CLUSTER_RECVFROM list.

The option CLUSTER_MASTER is the IP address of the master node in the cluster
allowed to send CLUSTER_CONFIG changes to servers listed in the local
CLUSTER_SENDTO list. Only cluster members that have CLUSTER_MASTER set to this
IP address will accept CLUSTER_CONFIG changes.

There is another option, CLUSTER_NAT that should be used if the IP address of
the server does not appear in ip/ifconfig, for example if it is a NAT
configuration. If this is the case, add the IP address of the server that this
configuration is on and used in CLUSTER_SENDTO/CLUSTER_RECVFROM to CLUSTER_NAT.

CLUSTER_LOCALADDR can be set if you do not want to use the servers main IP,
i.e. the first one listed via 0.0.0.0.

The CLUSTER_PORT must be set to the same port on all servers. The port should
NOT be opened in TCP_IN or TCP_OUT as csf will automatically add appropriate in
and out bound rules to allow communication between cluster members.

The CLUSTER_KEY is a secret key used to encrypt cluster communications using
the Blowfish algorithm. It should be between 8 and 56 ASCII characters long,
longer is better, and must be the same on all members of the cluster.

This key must be kept secret!

When blocks are sent around the cluster they will maintain their originals
parameters, e.g. permanent/temporary, direction (in/out), ports, etc. All
blocks are traded except for LT_POP3D and LT_IMAPD.

The cluster uses 10 second timeouts in its communications, if the timeout is
reached then that cluster members notification will be lost.

Note: You must restart csf and then lfd after making any CLUSTER_* changes

lfd Cluster CLI and UI
======================

See csf --help for the list of new CLI commands. Additional options will
automatically become available in the UI once CLUSTER_SENDTO has been
configured.

Only cluster members listed in CLUSTER_RECVFROM can send out requests to those
members listed in CLUSTER_SENDTO.

Only the server listed in CLUSTER_MASTER will be accepted as the source of
CLUSTER_CONFIG configuration option requests, such as:
--cconfig, --cfile, --crestart

The CLI options --cfile and --cfiler allow you to synchronise csf configuration
files throughout a cluster from the CLUSTER_MASTER server.

There is currently only provision for permanent simple IP denies and allows
from the CLI (i.e. not Allow/Deny Filters).

The cluster PING sends a ping to each CLUSTER_SENDTO member which will report
the request in their respective lfd.log files. This is intended as a test to
confirm that cluster communications are functioning.

The options to change the configuration option in csf.conf in cluster members
should be used with caution to ensure that member specific options are not
overwritten. The intention of the two options is that the --cconfig option be
used if multiple changes are required and the final request is a --cconfigr to
restart csf and lfd to effect the requested changes immediately.


A Note on lfd Cluster Security
==============================

The clustering option is undoubtedly powerful in allowing servers to
pre-emptively block access attempts as one server is hit before the attack can
spread to other members of the cluster.

This communication, however, does introduce a security risk. Since 
communications are made over the network, they are open to interception. Also,
there is nothing to stop any local user from accessing the network port and
sending data to it, though it will be discarded unless properly encrypted[*].

There are security measures implemented to help mitigate attacks:

1. csf constructs iptables rules such that only cluster members can communicate
over the cluster port with each other

2. The clustered servers will only accept data from connections from IPs listed
in CLUSTER_RECVFROM or CLUSTER_MASTER

3. [*]All communications are encrypted using the Blowfish symmetric block cipher
through a Pure Perl cpan module using the Cipher Block Chaining module and the
configured CLUSTER_KEY

4. CLUSTER_CONFIG set to 0 prevents the processing of configuration option
requests

5. Only CLUSTER_MASTER will be accepted as the source of CLUSTER_CONFIG
configuration option requests

Should the configured secret key (passphrase) be compromised or guessed or a
flaw found in the encryption modules or their implementation in csf, a
malicious connection could reconfigure the csf firewall and then leverage a
local or remote root escalation. This should be considered if you decide to use
this option.

THERE ARE NO GUARANTEES OR WARRANTIES PROVIDED THAT THIS FACILITY IS SECURE AND
ANY DAMAGE ARISING FROM THE EXPLOITATION OF THIS OPTION IS ENTIRELY AT YOUR OWN
RISK.


19. Port Knocking
#################

This option configures iptables to offer port knocking to open sensitive ports
based on a sequence of knocked ports for the connecting IP address.

For mor information on the idea of port knocking see:
http://www.portknocking.org/

The feature requires that you list a random selection of unused ports (at least
3) with a timeout. The ports you choose must not be in use and not appear in
TCP_IN (UDP_IN for udp packets). The port to be opened must also not appear in
TCP_IN (UDP_IN for udp packets).

This feature does not work on servers that do not have the iptables module
ipt_recent loaded. Typically, this will be with Monolithic kernels. VPS server
admins should check with their VPS host provider that the iptables module is
included.

By default ipt_recent tracks only the last 100 IP addresses. The tracked IP
addresses can be viewed in /proc/net/ipt_recent/*

Syntax for the PORTKNOCKING setting:

PORTKNOCKING is a comma separated list of:
openport;protocol;timeout;kport1;kport2;kport3[...;kportN]

So, a setting of PORTKNOCKING = "22;TCP;20;100;200;300;400" means:

Open Port 22 TCP for 20 seconds to the connecting IP address to new connections
once ports 100, 200, 300 and 400 have been accessed (i.e. knocked with a SYN
packet) each knock being less than 20 seconds apart.

Access to port 22 remains active after 20 seconds until the connection is
dropped, however new connections will not be allowed.

More information about the ipt_recent module can be found in the iptables man
page and at http://snowman.net/projects/ipt_recent/

Note: IP addresses do not appear in any of the iptables chains when using this
module. You must view the /proc/net/ipt_recent/* files as per the module
documentation to view IP addresses in the various stages of the knock.

Restarting csf resets the ipt_recent tables and removes all of the knocks.


20. Connection Limit Protection
###############################

This option configures iptables to offer protection from DOS attacks against
specific ports. It can also be used as a way to simply limit resource usage by
IP address to specific server services. This option limits the number of new
concurrent connections per IP address that can be made to specific ports.

This feature does not work on servers that do not have the iptables module
xt_connlimit loaded. Typically, this will be with Monolithic kernels. VPS
server admins should check with their VPS host provider that the iptables
module is included.

Also, although included in some older versions or RedHat/CentOS, it was only
actually available from v5.3+

The protection can only be applied to the TCP protocol.

Syntax for the CONNLIMIT setting:

CONNLIMIT is a comma separated list of:
port;limit

So, a setting of CONNLIMIT = "22;5,80;20" means:

1. Only allow up to 5 concurrent new connections to port 22 per IP address

2. Only allow up to 20 concurrent new connections to port 80 per IP address

Note: Existing connections are not included in the count, only new SYN packets,
i.e. new connections

Note: Run /etc/csf/csftest.pl to check whether this option will function on the
server


21. Port/IP address Redirection
###############################

This feature uses the file /etc/csf/csf.redirect which is a list of port and/or
IP address assignments to direct traffic to alternative ports/IP addresses.

Requirements:
  nat tables
  ipt_DNAT iptables module
  ipt_SNAT iptables module
  ipt_REDIRECT iptables module

The following are the allowed redirection formats

DNAT (redirect from one IP address to a different one):
IPx|*|IPy|*|tcp/udp          - To IPx redirects to IPy
IPx|portA|IPy|portB|tcp/udp  - To IPx to portA redirects to IPy portB

DNAT examples:
192.168.254.62|*|10.0.0.1|*|tcp
192.168.254.62|666|10.0.0.1|25|tcp

REDIRECT (redirect from port to a different one):
IPx|portA|*|portB|tcp/udp    - To IPx to portA redirects to portB
*|portA|*|portB|tcp/udp      - To portA redirects to portB

REDIRECT examples:
*|666|*|25|tcp
192.168.254.60|666|*|25|tcp
192.168.254.4|666|*|25|tcp

Where a port is specified it cannot be a range, only a single port.

All redirections to another IP address will always appear on the destination
server with the source of this server, not the originating IP address.

This feature is not intended to be used for routing, NAT, VPN, etc tasks

Note: /proc/sys/net/ipv4/ip_forward must be set to 1 for DNAT connections to
work. csf will set this where it can, but if the kernel value cannot be set
then the DNAT redirection many not work.


22. Integrated User Interface Feature
#####################################

Integrated User Interface. This feature provides a HTML UI to the features of
csf and lfd, without requiring a control panel or web server. The UI runs as a
sub process to the lfd daemon.

As it runs under the root account and successful login provides root access
to the server, great care should be taken when configuring and using this
feature. There are additional restrictions to enhance secure access to the
UI:

  1. An SSL connection is required
  2. Separate ban and allow files are provided to only allow access to listed
     IP addresses
  3. Local IP addresses cannot connect to the UI (i.e. all IP addresses
     configured on the server NICs)
  4. Unique sessions, session timeouts, session cookies and browser headers are
     used to identify and restrict active sessions

Requirements:

  1. openssl
  2. Perl modules: Net::SSLeay, IO::Socket::SSL and dependent modules
  4. SSL keys
  5. Entries in /etc/csf/ui/ui.allow

The SSL server uses the following files:

  SSL Key goes into /etc/csf/ui/server.key
  SSL Certificate goes into /etc/csf/ui/server.crt

Preferably, real CA signed certificates should be used. You can use an
existing domain and cert for accessing the UI by populating the two files
mentioned. If the cert has a ca bundle, it should be appended to the server.crt
file. lfd must be restarted after making any changes:
http://httpd.apache.org/docs/current/ssl/ssl_faq.html#realcert

Alternatively, you could generate your own self-signed certificate:
http://httpd.apache.org/docs/current/ssl/ssl_faq.html#selfcert

Any keys used must have their pass-phrase removed:
http://httpd.apache.org/docs/current/ssl/ssl_faq.html#removepassphrase

The login URL should use the domain you have listed in the self-signed cert:
https://<yourdomain>:<port>

For example: https://www.somedomain.com:6666

Your browser must accept session cookies to gain access.

UI_ALLOW is enabled by default, so IP addresses (or CIDRs) allowed to use this
UI must be listed in /etc/csf/ui/ui.allow before trying to connect to the UI.

Only IP addresses can be listed/used in /etc/csf/ui/ui.ban - this file should
only be used by the UI to prevent login. Use csf blocks to prevent access to
the configured port and only use Advanced Allow/Deny Filters for access, i.e.
do not list the port in TCP_IN.

Logging for UI events are logged to the lfd /var/log/lfd.log file. Check this
file if you are unable to access the UI.

Required Perl Modules:

  For example, on Debian v6 the perl modules can be installed using:

    apt-get install libio-socket-ssl-perl libcrypt-ssleay-perl \
                    libnet-libidn-perl libio-socket-inet6-perl libsocket6-perl

  For example, on CentOS v6 the perl modules can be installed using:

    yum install perl-IO-Socket-SSL.noarch perl-Net-SSLeay perl-Net-LibIDN \
                perl-IO-Socket-INET6 perl-Socket6


23. IP Block Lists
##################

This feature allows csf/lfd to periodically download lists of IP addresses and
CIDRs from pubished block or black lists. It is controlled by the file:
/etc/csf/csf.blocklists

Uncomment the line starting with the rule name to use it, then restart csf and
then lfd.

Each block list must be listed on per line: as NAME|INTERVAL|MAX|URL
  NAME    : List name with all uppercase alphabetic characters with no
            spaces and a maximum of 25 characters - this will be used as the
            iptables chain name
  INTERVAL: Refresh interval to download the list, must be a minimum of 3600
            seconds (an hour), but 86400 (a day) should be more than enough
  MAX     : This is the maximum number of IP addresses to use from the list,
            a value of 0 means all IPs
  URL     : The URL to download the list from

Note: Some of thsese lists are very long (thousands of IP addresses) and
could cause serious network and/or performance issues, so setting a value for
the MAX field should be considered.

After making any changes to this file you must restart csf and then lfd.

If you want to redownload a blocklist you must first delete
/var/lib/csf/csf.block.NAME and then restart csf and then lfd.

Each URL is scanned for an IP/CIDR address per line and if found is blocked.


24. Mitigating issues with syslog/rsyslog logs (RESTRICT_SYSLOG)
##############################################

Unfortunately, it is trivial for end-users and scripts run by end-users to
spoof log lines that appear identical to any log line reported in logs
maintained by syslog/rsyslog. You can identify these logs by looking in
/etc/syslog.conf or /etc/rsyslog.conf

This means that anyone on the server can maliciously trigger applications that
monitor these logs, such as lfd does for the following options:

LF_SSHD LF_FTPD LF_IMAPD LF_POP3D LF_BIND LF_SUHOSIN LF_SSH_EMAIL_ALERT
LF_SU_EMAIL_ALERT LF_CONSOLE_EMAIL_ALERT LF_DISTATTACK LF_DISTFTP
LT_POP3D LT_IMAPD PS_INTERVAL UID_INTERVAL WEBMIN_LOG LF_WEBMIN_EMAIL_ALERT
PORTKNOCKING_ALERT ST_ENABLE SYSLOG_CHECK LOGSCANNER CUSTOM*_LOG

A malicious user could use this issue to trigger confusing emails regarding
both successful and failed login attempts, kernel log lines (including iptables
log lines) etc. Unfortunately, there is very little that can be done about this
as syslog/rsyslog has no security framework. Some attempt was made in newer
versions of rsyslog, but this version is not available in the current versions
used by RedHat/CentOS v6. It also has to be enabled and can will have adverse
effects on utilities that expect a certain format for the log lines.

To mitigate spoofing attempts we recommend the following, if you are willing to
accept the consequences of spoofed log lines:

1. We recommend setting RESTRICT_SYSLOG to "3" for use with option
RESTRICT_SYSLOG_GROUP to restrict access to the syslog/rsyslog unix socket(s)

2. Go through the options above ensuring that only those that you need are
enabled

3. Ensure that DENY_IP_LIMIT and DENY_TEMP_IP_LIMIT are set reasonably low (for
example, 200). This will limit attempts to block large numbers of IP addresses

4. Ensure that administrator/support IP addresses are listed in
/etc/csf/csf.allow and perhaps /etc/csf/csf.ignore. This will prevent malicious
blocking from denying you access to the server

5. To confirm successful logins to SSH, use the "last" utility from the root
shell, e.g.:

last -da

6. Regularly check the server and user data for exploits, old vulnerable
applications and out of date OS applications

7. Consider carefully any application that you use that centralises actions and
syslog/rsyslog logs and the implications of spoofed log lines

8. Consider the implications of this overall issue on applications and scripts
other than csf/lfd that use the affected log files

9. Do not enable syslog/rsyslog reception via UDP/TCP ports

10.  For CloudLinux clients utilizing CageFS this can be prevented by limiting
access to /dev/log inside CageFS. 
For that remove file: /etc/rsyslog.d/schroot.conf
Or remove this line from that file:
$AddUnixListenSocket /usr/share/cagefs-skeleton/dev/log

That will prevent end user's access to /dev/log, preventing them from spoofing.
However, this does also break cron job logging.


25. Exim SMTP AUTH Restriction
##############################

The option SMTPAUTH_RESTRICT will only allow SMTP AUTH to be advertised to the
IP addresses listed in /etc/csf/csf.smtpauth plus the localhost IP addresses.

The additional option CC_ALLOW_SMTPAUTH can be used with this option to
additionally restrict access to specific countries.

This is to help limit attempts at distributed attacks against SMTP AUTH which
are difficult to achive since port 25 needs to be open to relay email.

The reason why this works is that if EXIM does not advertise SMTP AUTH on a
connection, then SMTP AUTH will not accept logins, defeating the attacks
without restricting mail relaying.

Note: csf and lfd must be restarted if /etc/csf/csf.smtpauth is modified so
that the lookup file in /etc/exim.smtpauth is regenerated from the information
from /etc/csf/csf.smtpauth, the localhost IP addresses, plus any countries
listed in CC_ALLOW_SMTPAUTH

To make this option work you MUST make the following modifications to your
exim.conf:


On cPanel servers you can do this by:
=====================================

1. Navigate to WHM > Exim Configuration Manager > Advanced Editor

2. Search within the window and ensure that "auth_advertise_hosts" has not been
   set

3. Scroll down and click "Add additional configuration setting"

4. From the drop-down box select "auth_advertise_hosts"

5. In the input box after the = sign add the following on one line:

${if match_ip{$sender_host_address}{iplsearch;/etc/exim.smtpauth}{*}{}}

6. Scroll to the bottom and click "Save"

7. That should be all that is required after having made any necessary changes
   within csf.conf and restarting csf and then lfd
   
8. Be sure to test extensively to ensure the option works as expected

To reverse this change:

1. Navigate to WHM > Exim Configuration Manager > Advanced Editor

2. Search within the window for "auth_advertise_hosts"

3. Click the wastebasket icon next to the option (if there is no wastebasket
   you should be able to change the setting to * to advertise to all IP's)

4. Scroll to the bottom and click "Save"

5. Disable SMTPAUTH_RESTRICT and CC_ALLOW_SMTPAUTH in csf.conf and then restart
   csf and then lfd


Alternatively, on cPanel:
=========================

1. Edit /etc/exim.conf.local and add the following line to an @CONFIG@ section
   all on one line:

auth_advertise_hosts = ${if match_ip{$sender_host_address}{iplsearch;/etc/exim.smtpauth}{*}{}}

2. Rebuild the exim configuration:

/scripts/buildeximconf
service exim restart

3. Be sure to test extensively to ensure the option works as expected


On non-cPanel platforms:
========================

1. Modify your active exim.conf and add the following as a single line near the
   top all on one line:

auth_advertise_hosts = ${if match_ip{$sender_host_address}{iplsearch;/etc/exim.smtpauth}{*}{}}

2. Restart exim

3. Be sure to test extensively to ensure the option works as expected


26. UI Skinning and Mobile View
###############################

The csf UI provided through cPanel, DirectAdmin, Webmin and the integrated UI
via lfd, all user the Bootstrap and jQuery frameworks. Additional styling is
added to complement the frameworks and the UI flow.

If you want to make changes to the styling or add jQuery or JavaScript code you
can create:

1. A text file /etc/csf/csf.header which will be included in each of
the UI pages before the closing </head> tag

2. A text file /etc/csf/csf.body which will be included in each of the UI
pages after the opening <body> tag[*]

3. A text file /etc/csf/csf.footer which will be included in each of the UI
pages before the closing </body> tag

The html tag will also have a data-post field containing the internal action
being performed by the UI.

You can also make additions to the <html> and <body> tags by creating
/etc/csf/csf.htmltag and /etc/csf/csf.bodytag respectively[*]. Additions made
in these files MUST all be on a single line at the top of the file, anything
else will be ignored. The text will then be placed within the respective tag,
e.g. if you want <body data-name='result'> you would put the following on a
single line in /etc/csf/csf.bodytag:
data-name='result'

[*] This functionality is ONLY available on webmin servers

The Mobile View feature has a breakpoint of 600px which will initiate the full
browser subset of UI features. This may mean breaking out of framesets in some
control panels, so a return to the main control panel window is included. Also
switching back to the Desktop view will remain in the full browser display.

If you switch to the Mobile View and then switch to main control panel window
further accesses to the UI will always default to the Mobile View. If you
switch back after returning to the Desktop View, subsequent access will default
to that view. This reverts back to the default breakpoint behaviour in new
browser sessions as the system uses session cookies to keep track of the chosen
view which are reset one browser shutdown.

There are options in csf.conf that control the behaviour of these options under
STYLE_*. Any styling changes MUST respect these options.

Note: We do NOT recommend reformatting the UI output as any changes in the core
code may not be reflected in the user experience and can break the product.
Only style changes should be made.


27. CloudFlare
##############

This features provides interaction with the CloudFlare Firewall.

As CloudFlare is a reverse proxy, any attacking IP addresses (so far as 
iptables is concerned) come from the CloudFlare IP's. To counter this, an
Apache module (mod_cloudflare) is available that obtains the true attackers
IP from a custom HTTP header record (similar functionality is available
for other HTTP daemons.

However, despite now knowing the true attacking IP address, iptables cannot
be used to block that IP as the traffic is still coming from the CloudFlare
servers.

CloudFlare have provided a Firewall feature within the user account where
rules can be added to block, challenge or whitelist IP addresses.

Using the CloudFlare API, this feature adds and removes attacking IPs from that
firewall and provides CLI (and via the UI) additional commands.

There are several restrictions to using this feature:

1.  All lfd blocks will be temporary blocks so that csf/lfd can keep blocks in
    sync with CloudFlare

2.  Automatic blocks via lfd are limited to LF_MODSEC and LF_CXS triggers as
    only through these can the domain name be determined. Any users that own
    domains that are involved in the trigger will get a block in their
    CloudFlare Firewall. Additionally, any users with the special case "any"
    will also get blocks

3.  The temporary/permanent config of the lfd settings are ignored and CF_TEMP
    is used instead

4.  LF_TRIGGER must not be used, the feature will not work with it enabled

5.  mod_cloudflare or similar must be used to report real IP in the Apache logs

6.  URLGET must be set to 2 (i.e. LWP) must be used

7.  If PERMBLOCK is used, the last tempblock will remain and never be cleared.
    So any CloudFlare Firewall entries must be manually cleared in CloudFlare
    or via CLI

8.  There are restrictions imposed by CloudFlare to the number of rules that
    can be created depending on the type of account used. See 
    https://goo.gl/ssGu7v for more information

9.  When restarting csf, any old temporary blocks will still be created for lfd
    to clear when it restarts

10. All interaction with CloudFlare is at User-level, not Zone-level

11. If using the CloudFlare cPanel user plugin, it must be v7+

CF_TEMP should be configured taking into account the maximum number of rules
that the CloudFlare account allows: https://goo.gl/ssGu7v

All CloudFlare users for the domains that are involved in LF_MODSEC and
LF_CXS triggers will have a CloudFlare rule added. Any CloudFlare account
configured to use the special case "any" field value in csf.cloudflare will
have a CloudFlare rule added regardless of domain.

NOTE: You should always list the CloudFlare IP addresses in /etc/csf/csf.ignore
to prevent them from being blocked by lfd from https://www.cloudflare.com/ips/


CLI commands
============

There are also accompanying csf CLI commands available (see man) to interact
with the Cloudflare firewall.

Enabling CF_ENABLE enables two CloudFlare buttons in the UI in the "Other"
section that mirror the CLI commands.

1. Using the CLI commands all, block, challenge or whitelist rules in the
provided users CloudFlare firewall can be listed, e.g.:

csf --cloudflare list all [user1,user2,...]

2. Block, challenge and whitelist rules can be added for IPs to the provided
users CloudFlare firewall, e.g.:

csf --cloudflare add challenge 11.22.33.44 [user1,user2,...]

Note: These rules are NOT cleared by lfd and do NOT create an equivalent
iptables rule in csf)

3. Rules can be deleted for IPs to the provided users CloudFlare firewall,
e.g.:

csf --cloudflare del 11.22.33.44 [domain,domain2,...]

Note: These rules are NOT cleared in csf if they exist

4. Domains can also be used instead of users, or a mixture of both e.g.:

csf --cloudflare list all [user,user2,domain,...]

5. IPs can be added both the users CloudFlare firewall and to csf as temporary
allow or deny, e.g.:

csf --cloudflare tempadd deny 11.22.33.44 [user1,user2,...]

Note: This applies the allow/deny for the IP address in csf for CF_TEMP seconds
as well as the users CloudFlare Firewall. Once the temporary entry expires lfd
removes the IP address from both csf (as normal) as well as the users
CloudFlare Firewall.

Note: Any CloudFlare account configured to use the special case "any" field
value in csf.cloudflare will also have a CloudFlare rule added.

Note: In the above IP addresses are used as the target for each rule. However,
the target can be one of:
  . An IP address
  . 2 letter Country Code
  . IP range CIDR
Only Enterprise customers can "block" a Country Code, but all can "allow" and
"challenge". IP range CIDR is limited to /16 and /24.

6. To manually remove an IP block that was blocked via CF_ENABLE in lfd or by
using "tempadd" use the normal csf temp CLI commands. This will remove the
rules from both iptables and the users CloudFlare firewall, e.g.:

csf --tr 44.33.22.11


28. InterWorx
#############

InterWorx integration is available for csf. The installation makes changes to
the underlying InterWorx installation due to its current dependence on APF. To
cater for this, installing csf will replace /etc/apf/apf with a stub script
that redirects commands to csf. The script is then chattr +ia to prevent it
being overwritten.

Note: None of the apf conf files are used and are ignored by csf.

The Firewall UI option in NodeWorx should now not be used and any changes made
there will not be reflected in iptables.

There is a UI option under "ConfigServer Services" for "ConfigServer Firewall &
Security" that should now be used.

The installation will also replace the Firewall page in NodeWorx with a dummy
page stating that csf should be used instead. lfd will replace the page upon
restart incase of upgrades to InterWorx. If you want to disable this behaviour,
create an empty file as follows:

touch /etc/cxs/interworx.firewall

The InterWorx plugin for csf is auto-enabled. Enabling or Disabling the
InterWorx plugin has no effect on csf itself, only the UI plugin presence.

NOTE: Unless you have configured a root forwarder, you should edit the csf
configuration settings in /etc/csf/csf.conf or via the UI and set LF_ALERT_TO
to a suitable email address. After making any changes, restart csf and then
lfd.


28. CentOS Web Panel (CWP)
##########################

CWP integration is available for csf. Since CWP already has some custom
modifications, these have been taken into account. To access the now inbuilt UI
in CWP, there is a new menu option in CWP > ConfigServer Scripts > ConfigServer
Firewall.

There is now an option in /etc/csf/csf.conf for LF_CWP for login failure
detection. However, this WILL NOT work with the default CWP installation as
there is a custom entry in /etc/csf/regex.custom.pm. The now official detection
will be ignored while this is in place.

If you want to use the now inbuilt detection you must edit
/etc/csf/regex.custom.pm and remove the 3 lines that comprise the custom entry
and then restart lfd.
