---
title: About CSF
tags:
  - info
---

# About ConfigServer Firewall

**ConfigServer Firewall**, also known as _CSF_, is a **Stateful Packet Inspection** (_SPI_) firewall, Login/Intrusion Detection and Security application for Linux servers. CSF provides better security for your server while giving you an advanced, easy to use interface for managing firewall settings. CSF configures your server’s firewall to lock down public access to services and only allow certain connections, such as logging in to FTP, checking email, or loading websites.

ConfigServer Firewall also comes with a service called **Login Failure Daemon**, or _LFD_. LFD watches your user activity for excessive login failures which are commonly seen during brute force attacks. If a large number of login failures are seen coming from the same IP address, that IP will immediately be temporarily blocked from all services on your server. These IP blocks will automatically expire, however they can be removed manually through the ConfigServer interface in WebHost Manager. In addition to removing IPs, CSF also allows you to manually whitelist or blacklist IPs in your firewall, as well as real-time monitoring for automatic IP blocks in LFD. Configuration details are covered in Managing Your CSF Firewall.

<br />

When installing CSF; you will be provided with two services:

| Service | Description |
| --- | --- |
| `csf` | **ConfigServer Firewall** (csf): SPI iptables firewall which allows you to restrict what is allowed to communicate with your server. |
| `lfd` |  **Login Failure Daemon** (lfd): Process that runs all the time and periodically (every X seconds) scans the latest log file entries for login attempts against your server that continually fail within a short period of time. |

<br />

<br />

A partial list of ConfigServer Firewall features are outlined below.

<br />

- Straight-forward SPI iptables firewall script
- Daemon process that checks for login authentication failures for:
    - Courier imap, Dovecot, uw-imap, Kerio
    - openSSH
    - cPanel, WHM, Webmail (cPanel servers only)
    - Pure-ftpd, vsftpd, Proftpd
    - Password protected web pages (htpasswd)
    - Mod_security failures (v1 and v2)
    - Suhosin failures
    - Exim SMTP AUTH
    - Custom login failures with separate log file and regular expression matching
- POP3/IMAP login tracking to enforce logins per hour
- SSH login notification
- SU login notification
- Excessive connection blocking
- UI Integration for cPanel, DirectAdmin, InterWorx, CentOS Web Panel (CWP), VestaCP, CyberPanel - and Webmin
- Easy upgrade between versions from within the control panel
- Easy upgrade between versions from shell
- Pre-configured to work on a cPanel server with all the standard cPanel ports open
- Pre-configured to work on a DirectAdmin server with all the standard DirectAdmin ports open
- Auto-configures the SSH port if it’s non-standard on installation
- Block traffic on unused server IP addresses – helps reduce the risk to your server
- Alert when end-user scripts sending excessive emails per hour – for identifying spamming scripts
- Suspicious process reporting – reports potential exploits running on the server
- Excessive user processes reporting
- Excessive user process usage reporting and optional termination
- Suspicious file reporting – reports potential exploit files in /tmp and similar directories
- Directory and file watching – reports if a watched directory or a file changes
- Block traffic on a variety of Block Lists including DShield Block List and Spamhaus DROP List
- BOGON packet protection
- Pre-configured settings for Low, Medium or High firewall security (cPanel servers only)
- Works with multiple ethernet devices
- Server Security Check – Performs a basic security and settings check on the server (via cPanel/- DirectAdmin/Webmin UI)
- Allow Dynamic DNS IP addresses – always allow your IP address even if it changes whenever you connect to the internet
- Alert sent if server load average remains high for a specified length of time
- mod_security log reporting (if installed)
- Email relay tracking – tracks all email sent through the server and issues alerts for excessive usage (cPanel servers only)
- IDS (Intrusion Detection System) – the last line of detection alerts you to changes to system and application binaries
- SYN Flood protection
- Ping of death protection
- Port Scan tracking and blocking
- Permanent and Temporary (with TTL) IP blocking
- Exploit checks
- Account modification tracking – sends alerts if an account entry is modified, e.g. if the password is changed or the login shell
- Shared syslog aware
- Messenger Service – Allows you to redirect connection requests from blocked IP addresses to preconfigured text and html pages to inform the visitor that they have been blocked in the firewall. This can be particularly useful for those with a large user base and help process support requests more efficiently
- Country Code blocking – Allows you to deny or allow access by ISO Country Code
- Port Flooding Detection – Per IP, per Port connection flooding detection and mitigation to help block DOS attacks
- WHM root access notification (cPanel servers only)
- lfd Clustering – allows IP address blocks to be automatically propagated around a group of servers running lfd. It allows allows cluster-wide allows, removals and configuration changes
- Quick start csf – deferred startup by lfd for servers with large block and/or allow lists
- Distributed Login Failure Attack detection
- Temporary IP allows (with TTL)
- IPv6 Support with ip6tables
- Integrated UI – no need for a separate Control Panel or Apache to use the csf configuration
- Integrated support for cse within the Integrated UI
- cPanel Reseller access to per reseller configurable options Unblock, Deny, Allow and Search IP address blocks
- System Statistics – Basic graphs showing the performance of the server, e.g. Load Averages, CPU Usage, Memory Usage, etc
- ipset support for large IP lists
- Integrated with the CloudFlare Firewall
- …lots more!

<br />

---

<br />
