<div align="center">

🕙 `Last Sync: 04/10/2025 10:06 UTC`

</div>

<div align="center">
<h6>Unofficial dark theme, Docker, Traefik, and OpenVPN support. Includes "bad actor" blocklists / ipsets, and numerous helper patches.</h6>
<h1>♾️ ConfigServer Firewall & Blocklist ♾️</h1>
</div>

<br />

<p>

ConfigServer Firewall (CSF) is a popular and powerful firewall solution for Linux servers. This repo contains complete installation guides, a new dark theme, and also numerous patches for `Docker` and `OpenVPN` firewall support so that you can allow traffic between these services without interruption.

<br />

This repository also contains a list of ipsets / blocklists which are updated every few hours. These sets contain various lists of IP addresses which block connections known for [SSH brute-force](https://www.cmu.edu/iso/aware/be-aware/brute-force_ssh_attack.html) attempts, [port knocking](https://en.wikipedia.org/wiki/Port_knocking) / [scanning](https://www.paloaltonetworks.com/cyberpedia/what-is-a-port-scan), research, [IoT](https://en.wikipedia.org/wiki/Internet_of_things), data collection, etc. These ipsets are compatible with ConfigServer Firewall, and also any other application which supports one IP per line (Windows Hosts file, etc).

<br />

Ipsets include lists from [AbuseIPDB](https://abuseipdb.com/) and [IPThreat](https://ipthreat.net/). For information on how to use these sets, read the section [IP Rulesets & Blocklists](#ip-sets--blocklist).

</p>

<br />

<div align="center">

<img src="https://malware.expert/wp-content/uploads/2018/09/csf_firewall.png" height="230">

<br />
<br />

</div>

<div align="center">

<!-- prettier-ignore-start -->
[![Version][github-version-img]][github-version-uri]
[![Downloads][github-downloads-img]][github-downloads-uri]
[![Size][github-size-img]][github-size-img]
[![Last Commit][github-commit-img]][github-commit-img]
[![Contributors][contribs-all-img]](#contributors-)

[![Built with Material for MkDocs](https://img.shields.io/badge/Powered_by_Material_for_MkDocs-526CFE?style=for-the-badge&logo=MaterialForMkDocs&logoColor=white)](https://aetherinox.github.io/csf-firewall/)
<!-- prettier-ignore-end -->

<br />

<p float="left">
  <img style="padding-right:15px;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/1.png" width="300" />
  <img src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/2.png" width="300" /> 
</p>

<p float="left">
  <img style="padding-right:15px;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/3.png" width="300" />
  <img src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/4.png" width="300" /> 
</p>

<p float="left">
  <img style="padding-right:15px;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/5.png" width="300" />
  <img src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/6.png" width="300" /> 
</p>

</div>

<br />

---

<br />

- [Summary](#summary)
- [ConfigServer Firewall Features](#configserver-firewall-features)
- [How The Patcher Works](#how-the-patcher-works)
- [Install ConfigServer Firewall](#install-configserver-firewall)
  - [Install Using Patcher](#install-using-patcher)
  - [Install Manually](#install-manually)
    - [Step 1: Prerequisites](#step-1-prerequisites)
    - [Step 2: Download and Install CSF](#step-2-download-and-install-csf)
- [Testing the Firewall](#testing-the-firewall)
- [Configuring CSF](#configuring-csf)
- [Enabling CSF Firewall](#enabling-csf-firewall)
- [Managing the Firewall](#managing-the-firewall)
  - [Enable CSF \& LFD](#enable-csf--lfd)
  - [Disable CSF \& LFD](#disable-csf--lfd)
  - [Start Firewall](#start-firewall)
  - [Stop Firewall](#stop-firewall)
  - [Restart CSF](#restart-csf)
  - [Restart CSF \& LFD](#restart-csf--lfd)
  - [List Firewall Rules](#list-firewall-rules)
  - [Add IP to Allow List](#add-ip-to-allow-list)
  - [Remove IP to Allow List](#remove-ip-to-allow-list)
  - [Add IP to Deny List](#add-ip-to-deny-list)
  - [Remove IP from Deny List](#remove-ip-from-deny-list)
  - [Add Temp Block IP](#add-temp-block-ip)
  - [Remove Temp Block IP](#remove-temp-block-ip)
- [Uninstalling CSF](#uninstalling-csf)
- [Enable CSF Firewall Web UI](#enable-csf-firewall-web-ui)
  - [Step 1: Install Required Perl Modules:](#step-1-install-required-perl-modules)
  - [Step 2: Enable CSF Firewall Web UI:](#step-2-enable-csf-firewall-web-ui)
  - [Step 3: Access and Use Web UI:](#step-3-access-and-use-web-ui)
- [Install Docker Patch](#install-docker-patch)
  - [Clone](#clone)
  - [Configure](#configure)
  - [Run Patch](#run-patch)
  - [Manual Run](#manual-run)
  - [Advanced Logs](#advanced-logs)
- [Install OpenVPN Patch](#install-openvpn-patch)
  - [Clone](#clone-1)
  - [Configure](#configure-1)
  - [Run Patch](#run-patch-1)
  - [Manual Run](#manual-run-1)
  - [Advanced Logs](#advanced-logs-1)
- [Install Dark Theme](#install-dark-theme)
- [Traefik Integration with CSF WebUI](#traefik-integration-with-csf-webui)
  - [Adding Authentik Provider](#adding-authentik-provider)
- [IP Sets / Blocklist](#ip-sets--blocklist)
  - [Main Lists](#main-lists)
  - [Privacy Lists](#privacy-lists)
  - [Spam Lists](#spam-lists)
  - [Geographical (Continents \& Countries)](#geographical-continents--countries)
  - [Transmission (BitTorrent Client)](#transmission-bittorrent-client)
- [Download ConfigServer Firewall](#download-configserver-firewall)
- [Notes](#notes)
  - [CSF to Iptable Commands](#csf-to-iptable-commands)
    - [Default Policy](#default-policy)
    - [Clear Iptables / Open Firewall](#clear-iptables--open-firewall)
    - [List Rules](#list-rules)
    - [List Chains](#list-chains)
    - [Unblock Port](#unblock-port)
    - [Allow OpenVPN](#allow-openvpn)
- [References for More Help](#references-for-more-help)
- [Contributors ✨](#contributors-)

<br />

---

<br />

## Summary

This repository contains several folders:
- 📁 `configs`
  - Ready-to-use CSF config files
    - `configs/etc/csf/csf.conf` (full version)
    - `configs/etc/csf/csf.conf.clean` (clean version)
    - `configs/etc/GeoIP.conf` GeoIP Config File for [MaxMind geo-blocking](https://www.maxmind.com/en/home)
- 📁 `theme`
  - Dark theme for ConfigServer Firewall
- 📁 `patches`
  - Docker patch which allows CSF and Docker to work together
  - OpenVPN integration patch
- 📁 `blocklists` 
  - List of IP addresses which have been reported for ssh brute-force attempts, port scanning, etc.
  - 100% Confidence, powered by services such as [AbuseIPDB](https://abuseipdb.com/)
  - IPs are no older than 90 days old _(updated daily)_, and also contain blocks to protect your privacy from certain online services
  - Add to `csf.blocklists`

<br />
<br />

Each release posted on the [Releases Page](https://github.com/Aetherinox/csf-firewall/releases) contains several `.zip` files and a `.tgz`:
- `csf-firewall-vxx.xx.tgz`
  - Latest official version of ConfigServer Firewall. You do not need this if you already have CSF installed on your system.
- `csf-firewall-vx.x.x-theme-dark.zip`
  - Custom dark theme
- `csf-firewall-vx.x.x-patches.zip`
  - The patches contained in this repository, which include the files:
    - 📄 csfpost.sh
    - 📄 csfpre.sh
    - 📄 docker.sh
    - 📄 install.sh
    - 📄 openvpn.sh
    - 📄 README.md
    - 📄 LICENSE

<br />
<br />

This guide will help you with the following:

- Install CSF (ConfigServer Firewall)
- Install CSF WebUI interface
- Install patches
  - Docker Integration
  - OpenVPN Integration
- Install Dark Theme
- Traefik + CSF WebUI
  - Access CSF WebUI via domain
  - Secure domain with Authentik
  - IP Whitelist access to CSF WebUI

<br />

---

<br />

## ConfigServer Firewall Features

- Straight-forward SPI iptables firewall script
- Daemon process that checks for login authentication failures for:
    - Courier imap, Dovecot, uw-imap, Kerio
    - OpenSSH
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
- Messenger Service – Allows you to redirect connection requests from blocked IP addresses to pre-configured text and html pages to inform the visitor that they have been blocked in the firewall. This can be particularly useful for those with a large user base and help process support requests more efficiently
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

## How The Patcher Works

You can read this if you want, or skip it. It outlines exactly how the patches work:
  - Download all the files in the `/patch` folder to your system.
  - Set the `install.sh` file to be executable.
    - `sudo chmod +x install.sh`
  - Run the `install.sh` script
    - `sudo ./install.sh`
    - The script will first check to see if you have ConfigServer Firewall and all of its prerequisites installed. It will install them if they are not installed. This includes:
      - ConfigServer Firewall
      - ipset package
      - iptables / ip6tables package
    - Two new files will be added:
      - `/usr/local/csf/bin/csfpre.sh`
      - `/usr/local/csf/bin/csfpost.sh`
    - The patches will then be moved onto your system in the locations:
      - `/usr/local/include/csf/post.d/docker.sh`
      - `/usr/local/include/csf/post.d/openvpn.sh`
    - The `Docker` patch will first check to ensure you have the following:
      - **Must** have Docker installed
        - This script will **NOT** install docker. You must do that.
      - **Must** have a valid docker network adapter named `docker*` or `br-*`
    - The `OpenVPN` patch will first check to ensure you have the following:
      - **Must** have OpenVPN Server installed
      - **Must** have a valid network tunnel named `tun*` (tun0, tun1, etc)
      - **Must** have an outside network adapter named either `eth*` or `enp*`
      - If any of the checks above are not true, OpenVPN patcher will skip
        - You can check your list of network adapters using any of the commands below:
          - `ip link show`
          - `ifconfig`
        - You can check if OpenVPN server is installed by using the commmand:
          - `openvpn --version`
  
<br />

  - If you attempt to run the `install.sh` any time after the initial setup:
    - The script will check if ConfigServer Firewall and all prerequisites are installed.
      - **If they are not installed**; they will be installed.
      - **If they are already installed**; nothing will happen. The script does **NOT** update your packages. It installs the latest version of each package from the time that you run the script and do not already have ConfigServer Firewall installed.
    - The script will look at all of the files it added the first time and check the MD5 hash.
      - If the `csfpre`, `csfpost`, or patch files do not exist; they will be re-added to your system.
      - **If the patch files are different** from the one the patcher comes with, you will be prompted / asked if you wish to overwrite your already installed copy
      - **If the patch files are the same** as the ones which comes with the patcher; nothing will be done and it will skip that step.

<br />

When you start up the CSF service, the `csfpost.sh` file will loop through every patch / file added to the `post.d` folder, and run the code inside of those files. The code inside each patch contains iptable / firewall rules which allow that app to communicate between your system and the outside world.

<br />

Even if you were to completely wipe your iptable rules, as soon as you restart the CSF service; those rules will be added right back.

<br />

---

<br />

## Install ConfigServer Firewall

You can install ConfigServer Firewall and all prerequisites one of two ways:

1. [Install Using Patcher](#install-using-patcher)
2. [Install Manually](#install-manually)

<br />

### Install Using Patcher

If you would like to install ConfigServer Firewall using this repo's patcher; download the patch:
```shell
git clone https://github.com/aetherinox/csf-firewall.git .
```

<br />

Set the permissions for the `install.sh` file:

```shell
sudo chmod +x ./patch/install.sh
```

<br />

Run the script:

```shell
sudo ./patch/install.sh
```

<br />

If ConfigServer Firewall is not already installed on your system; you should see:

```
  Installing package iptables
  Installing package ipset
  Installing package ConfigServer Firewall

  Docker patch will now start ...
```
<br />

### Install Manually

These steps explain how to install ConfigServer Firewall manually.

<br />

#### Step 1: Prerequisites

- A Linux server running CentOS, Debian, Ubuntu, or any other compatible Linux distribution. 
- Root access or a user account with sudo privileges.
- Perl installed on your server. If Perl is not installed, you can install it by running the following commands:
  - For CentOS/RHEL:
    ```shell
    sudo yum install perl ipset
    ```

  - For Debian/Ubuntu:

    ```shell
    sudo apt-get update 
    sudo apt-get install perl ipset
    ```

<br />
<br />

#### Step 2: Download and Install CSF

To download and install CSF, follow these steps:

<br />

- Log in to your server via SSH. 
- Download the latest version of CSF using the wget command:
    ```shell
    wget https://download.configserver.com/csf.tgz
    ```
- Extract the downloaded archive:
    ```shell
    tar -xzf csf.tgz
    ```
- Navigate to the extracted directory:
    ```shell
    cd csf
    ```
- Run the installation script:
    ```shell
    sudo sh install.sh
    ```

<br />

CSF will now be installed on your server, along with its Web UI (ConfigServer Firewall & Security) if you have a control panel like cPanel or DirectAdmin installed.

<br />

---

<br />

## Testing the Firewall

Before enabling and configuring CSF, it is crucial to test whether it is compatible with your server. Run the following command to initiate the test:

```shell
sudo perl /usr/local/csf/bin/csftest.pl
```

The test will check for any potential issues or conflicts. If the test completes successfully, you will see the message “RESULT: csf should function on this server.” If there are any problems, the test will provide information on how to resolve them.

<br />

---

<br />

## Configuring CSF

Now that CSF is installed, you can start configuring it to suit your server’s requirements. The main configuration file for CSF is located at /etc/csf/csf.conf. You can use your preferred text editor to modify the file, such as nano or vim:

```shell
sudo nano /etc/csf/csf.conf
```

<br />

Some essential settings you may want to modify include:

> [!NOTE]
> When you run the patcher `install.sh`; **TESTING MODE** will automatically be disabled after everything as successfully completed.

<br />

- `TESTING`: Set this value to 0 to disable testing mode and activate the firewall.
- `TCP_IN` and `TCP_OUT`: These settings define the allowed incoming and outgoing TCP ports, respectively. Add or remove ports as required, separated by commas.
- `UDP_IN` and `UDP_OUT`: These settings define the allowed incoming and outgoing UDP ports, respectively. Add or remove ports as required, separated by commas.
- `DENY_IP_LIMIT`: This setting defines the maximum number of IP addresses that can be listed in the /etc/csf/csf.deny file. Adjust this limit as needed.
- `CT_LIMIT`: This setting controls the number of connections from a single IP address that are allowed before the IP is temporarily blocked. Adjust this value according to your server’s requirements.

<br />

These are just a few of the numerous configuration options available in CSF. Make sure to review the configuration file and adjust the settings to suit your server’s needs. After making changes to the configuration file, save and exit the text editor.

<br />

---

<br />

## Enabling CSF Firewall

Once you have configured the CSF firewall, it is time to enable it. To do so, run the following command:

```shell
sudo csf -e
```

<br />

This command will restart the CSF and LFD (Login Failure Daemon) services, applying your configuration changes and activating the firewall.

<br />

---

<br />

## Managing the Firewall

CSF provides several commands to manage the firewall, such as:

<br />

### Enable CSF & LFD

```shell
sudo csf -e
```

<br />

### Disable CSF & LFD

```shell
sudo csf -x
```

<br />

### Start Firewall

```shell
sudo csf -s
```

<br />

### Stop Firewall

```shell
sudo csf -f
```

<br />

### Restart CSF

```shell
sudo csf -r
```

<br />

### Restart CSF & LFD

```shell
sudo csf -ra
```

<br />

### List Firewall Rules

```shell
# show IPv4 rules
sudo csf -l

# Show IPv6 rules
sudo csf -l6
```

<br />

### Add IP to Allow List

```shell
sudo csf -a IP_ADDRESS
```

<br />

### Remove IP to Allow List

```shell
sudo csf -ar IP_ADDRESS
```

<br />

### Add IP to Deny List

```shell
sudo csf -d IP_ADDRESS
```

<br />

### Remove IP from Deny List

```shell
sudo csf -dr IP_ADDRESS
```

<br />

### Add Temp Block IP

```shell
sudo csf -td IP_ADDRESS
```

<br />

### Remove Temp Block IP

```shell
sudo csf -tr IP_ADDRESS
```

<br />

These commands can help you manage your server’s security and monitor incoming and outgoing traffic.

<br />

---

<br />

## Uninstalling CSF

If you decide to uninstall CSF for any reason, follow these steps:

<br />

1. Navigate to the CSF directory:
    ```shell
    cd /etc/csf
    ```

<br />

2. Run the uninstallation script:
    ```shell
    sudo sh uninstall.sh
    ```

<br />

The script will remove CSF and its associated files from your server.

<br />

---

<br />

## Enable CSF Firewall Web UI

ConfigServer Firewall offers a WebUI for the managing firewall from the web interface. This section explains how to install the WebUI.

<br />

### Step 1: Install Required Perl Modules:

CSF UI required some of Perl modules to be installed on your system. Use the following commands to install required modules as per your operating system.

<br />

**Debian based systems:**

```shell
sudo apt-get install libio-socket-ssl-perl libcrypt-ssleay-perl \
                    libnet-libidn-perl libio-socket-inet6-perl libsocket6-perl
```

<br />

**Redhat based systems:**

```shell
sudo yum install perl-IO-Socket-SSL.noarch perl-Net-SSLeay perl-Net-LibIDN \
               perl-IO-Socket-INET6 perl-Socket6
```

<br />
<br />

### Step 2: Enable CSF Firewall Web UI:

To enable CSF web UI edit /etc/csf/csf.conf file in your favorite text editor and update the following values.

```shell
sudo vim /etc/csf/csf.conf
```

```conf
# 1 to enable, 0 to disable web ui 
UI = "1"

# Set port for web UI. The default port is 6666, but
# I change this to 1025 to easy access. Default port create some issue
# with popular chrome and firefox browser (in my case) 

UI_PORT = "1025"

# Leave blank to bind to all IP addresses on the server 
UI_IP = ""

# Set username for authetnication 
UI_USER = "admin"

# Set a strong password for authetnication 
UI_PASS = "admin"
```

<br />

Change the following values to your own:
- `UI_PORT`
- `UI_USER`
- `UI_PASS`

<br />

After making changes, edit `/etc/csf/ui/ui.allow` configuration file and add your public IP to allow access to CSF UI. Change `YOUR_PUBLIC_IP_ADDRESS` with your public IP address.

```shell
sudo echo "YOUR_PUBLIC_IP_ADDRESS" >>  /etc/csf/ui/ui.allow
```

<br />

Web UI works under lfd daemon. So restart the lfd daemon on your system using the following command.

```shell
sudo service lfd restart
```

<br />

In order to gain access to the online admin panel; you must ensure lfd and csf are running. You can check by running the commands:

```shell ignore
sudo service lfd status
```

<br />

You should see the `lfd` service running:

```
● lfd.service - ConfigServer Firewall & Security - lfd
     Loaded: loaded (/lib/systemd/system/lfd.service; enabled; preset: enabled)
     Active: active (running) since Mon 2024-08-05 11:59:38 MST; 1s ago
    Process: 46393 ExecStart=/usr/sbin/lfd (code=exited, status=0/SUCCESS)
   Main PID: 46407 (lfd - sleeping)
      Tasks: 8 (limit: 4613)
     Memory: 121.7M
        CPU: 2.180s
     CGroup: /system.slice/lfd.service
```

<br />

Next, confirm `csf` service is also running:

```shell ignore
sudo service csf status
```

<br />

Check the output for errors on service `csf`. You should see no errors:

```shell
● csf.service - ConfigServer Firewall & Security - csf
     Loaded: loaded (/lib/systemd/system/csf.service; enabled; preset: enabled)
     Active: active (exited) since Mon 2024-08-05 12:04:09 MST; 1s ago
    Process: 46916 ExecStart=/usr/sbin/csf --initup (code=exited, status=0/SUCCESS)
   Main PID: 46916 (code=exited, status=0/SUCCESS)
        CPU: 12.692s
```

<br />

If you see the following error when running `csf status`:

```
csf[46313]: open3: exec of /sbin/ipset flush failed: No such file or directory at /usr/sbin/csf line 5650.
```

<br />

You must install `ipset`:

```shell ignore
sudo apt-get update 
sudo apt-get install ipset
```

<br />
<br />

### Step 3: Access and Use Web UI:

Now, access CSF UI on your browser with the specified port. For this tutorial; we used 1025 port and accessed the CSF admin panel by opening our browser and going to:

```
https://127.0.0.1:1025
```

<br />

When prompted for the username and password; the default is:

| Field | Value |
| --- | --- |
| Username | `admin` |
| Password | `admin` |

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/c23e9de8-69a9-4a92-810b-791c72f5793a"></p>

<br />

After successful login, you will find the screen like below.

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/2b1a0c5b-d21d-456b-a07d-69c2acdf3888"></p>

<br />

**Allow IP Address**: You can use below option to allow any IP quickly. This action adds the entry to the `/etc/csf/csf.allow` file.

<p align="center"><img style="width: 80%;text-align: center;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/docs/images/csf-quick-allow.png"></p>

<br />

**Deny IP Address**: You can use below option to deny any IP quickly. This action adds the entry to the `/etc/csf/csf.deny` file.

<p align="center"><img style="width: 80%;text-align: center;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/docs/images/csf-quick-deny.png"></p>

<br />

**Unblock IP Address**: You can use below option to quickly unblocked any IP which is already blocked by CSF.

<p align="center"><img style="width: 80%;text-align: center;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/docs/images/csf-unblock-ip.png"></p>

<br />

---

<br />

## Install Docker Patch

After you have installed CSF, the WebUI, and enabled both `lfd` and `csf` services; it's now time to run the docker patcher. The docker patch will check your docker configuration, and add a series of iptable rules so that docker can communicate with the outside world and users can access your containers.

<br />

The docker patch does several things:

- Allows for you to restart CSF without having to restart your docker containers.
- Scans every container you have set up in docker and adds a whitelist firewall rule

<br />

### Clone

Within your server, change to whatever directory where you want to download everything (including patch):

```shell
cd $HOME/Documents
```

<br />

Clone the repo

```shell
git clone https://github.com/aetherinox/csf-firewall.git .
```

<br />
<br />

### Configure

The `/patch/docker.sh` file has a few configs you can adjust. Open it in a text editor and change the values to your preference.

```bash
docker0_eth="docker0"
file_csf_allow="/etc/csf/csf.allow"
csf_comment="Docker container whitelist"
containers_ip_cidr=(
    '172.17.0.0/16'
)
```

<br />

Each setting is defined below:

| Setting | Default | Description |
| --- | --- | --- |
| `docker0_eth` | `docker0` | <br>main docker network interface <br><br> |
| `file_csf_allow` | `/etc/csf/csf.allow` | <br>Path to your `csf.allow` file <br><br> |
| `csf_comment` | `Docker container whitelist` | <br>comment added to each new whitelisted docker ip in the file `/etc/csf/csf.allow` <br><br> |
| `containers_ip_cidr` | `172.17.0.0/16` | <br>list of ip address blocks you will be using for your docker setup. these blocks will be whitelisted through ConfigServer Firewall <br><br> |
| `cfg_dev_enabled` | `false` | <br>debug mode <br><br> |

<br />
<br />

### Run Patch

Set the permissions (if needed)

```shell
sudo chmod +x /patch/install.sh
```

<br />

Run the script:

```shell
cd /patch/
sudo ./install.sh
```

<br />

On certain distros of Linux, you may need to use the following instead to run the patcher:

```shell
sudo sh install.sh
```

<br />

The `docker.sh` file will be installed to `/usr/local/include/csf/post.d`

<br />
<br />

### Manual Run

You can manually run the `docker.sh` script. It will also allow you to specify arguments such as `--dev` to get more detailed logging as the firewall is set up. This should only be done if you know what you're doing.

```shell ignore
sudo chmod +x /patch/docker.sh
sudo /patch/docker.sh
```

<br />

You can call arguments by running the file using:

```shell ignore
sudo /patch/docker.sh --dev
```

<br />

You can also find out what version you are running by appending `--version` to either the `install.sh` or `docker.sh` file:

```shell ignore
./patch/install.sh --version
```

<br />

```shell ignore
  ┌────────────────────────────────────────────────────────────────────────────────────────┐

     ConfigServer Firewall - Installer Script (v14.24.0)

     Installs Docker and OpenVPN patches into your existing CSF setup.
     This script requires that you have iptables installed on your system. 
     The required packages will be installed if you do not have them.

     @repo        https://github.com/Aetherinox/csf-firewall
     @system      Ubuntu | 24.04
     @notice      Before running this script, open /path/to/dock.sh
                  and edit the settings at the top of the file.

  └────────────────────────────────────────────────────────────────────────────────────────┘
```

<br />

```shell ignore
sudo /patch/docker.sh --version
```

<br />

```shell ignore
  ┌────────────────────────────────────────────────────────────────────────────────────────┐

     ConfigServer Firewall - Docker Patch (v14.24.0)

     Sets up your firewall rules to work with Docker and Traefik. 
     This script requires that you have iptables installed on your system. 
     The required packages will be installed if you do not have them.

     @repo        https://github.com/Aetherinox/csf-firewall
     @system      Ubuntu | 24.04
     @notice      Before running this script, open /path/to/dock.sh
                  and edit the settings at the top of the file.

  └────────────────────────────────────────────────────────────────────────────────────────┘
```

<br />
<br />

### Advanced Logs

This script includes debugging prints / logs. To view these, restart `csf.service` by running the following command in terminal:

```shell ignore
sudo csf -r
```

<br />

All steps performed by the script will be displayed in terminal:

```shell ignore
  + POSTROUTING   Adding IPs from primary IP list
                  + 172.17.0.0/16
                  + RULE:                  -t nat -A POSTROUTING ! -o docker0 -s 172.17.0.0/16 -j MASQUERADE
                  + RULE:                  -t nat -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE

 ---------------------------------------------------------------------------------------------------

  + BRIDGES       Configuring network bridges

                  BRIDGE                   e8a57188323a                          
                  DOCKER INTERFACE         docker0                               
                  SUBNET                   172.17.0.0/16                         
                  + RULE:                  -t nat -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
                  + RULE:                  -t nat -A DOCKER -i docker0 -j RETURN
                  + RULE:                  -A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
                  + RULE:                  -A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
```

<br />

---

<br />

## Install OpenVPN Patch

This repo includes an OpenVPN patch which automatically sets up ConfigServer Firewall to accept connections from your OpenVPN server; while still restricting other incoming and outgoing connections you may not want going through.

<br />

### Clone

Within your server, change to whatever directory where you want to download everything (including patch):

```shell
cd $HOME/Documents
```

<br />

Clone the repo

```shell
git clone https://github.com/aetherinox/csf-firewall.git .
```

<br />
<br />

### Configure

The `/patch/openvpn.sh` file has a few configs you can adjust. Open it in a text editor and change the values to your preference.

```bash
ETH_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
TUN_ADAPTER=$(ip -br l | awk '$1 ~ "^tun[0-9]" { print $1}')
IP_PUBLIC=$(curl ipinfo.io/ip)
DEBUG_ENABLED="false"
IP_POOL=(
    '10.8.0.0/24'
)
```

<br />

Each setting is defined below:

| Setting | Description |
| --- | --- |
| `ETH_ADAPTER` | <br>primary network adapter on host machine <br><br> |
| `TUN_ADAPTER` | <br>openvpn tunnel adapter, usually `tun0` <br><br> |
| `IP_PUBLIC` | <br>server's public ip address <br><br> |
| `DEBUG_ENABLED` | <br>debugging / better logs <br><br> |
| `IP_POOL` | <br>openvpn ip pool <br><br> |

<br />

The script tries to automatically detect the values specified above, however, you can manually specify your own values. 

<br />

As an example, instead of automatically detecting your server's public IP address or ethernet adapters, you can specify your own by changing the following:

```bash
# old code
ETH_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
TUN_ADAPTER=$(ip -br l | awk '$1 ~ "^tun[0-9]" { print $1}')
IP_PUBLIC=$(curl ipinfo.io/ip)

# manually specified ip
ETH_ADAPTER="eth0"
TUN_ADAPTER="tun0"
IP_PUBLIC="216.55.100.5"
```

<br />
<br />

### Run Patch

Set the permissions:

```shell
sudo chmod +x /patch/install.sh
```

<br />

Run the script:

```shell
cd /patch/
sudo ./install.sh
```

<br />

On certain distros of Linux, you may need to use the following instead to run the patcher:

```shell
sudo sh install.sh
```

<br />

The `openvpn.sh` file will be installed to `/usr/local/include/csf/post.d`

<br />
<br />

### Manual Run

You can manually run the `openvpn.sh` script. It will also allow you to specify arguments such as `--dev` to get more detailed logging as the firewall is set up. This should only be done if you know what you're doing.

```shell ignore
sudo chmod +x /patch/openvpn.sh
sudo /patch/openvpn.sh
```

<br />

You can call arguments by running the file using:

```shell ignore
sudo /patch/openvpn.sh --dev
```

<br />

You can also find out what version you are running by appending `--version` to either the `install.sh` or `openvpn.sh` file:

```shell ignore
./patch/install.sh --version
```

<br />

```shell ignore
ConfigServer Firewall Configuration - v2.0.0.0
https://github.com/Aetherinox/csf-firewall
Ubuntu | 24.04
```

<br />

```shell ignore
sudo /patch/openvpn.sh --version
```

<br />

```shell ignore
ConfigServer Firewall OpenVPN Patch - v2.0.0.0
https://github.com/Aetherinox/csf-firewall
Ubuntu | 24.04
```

<br />
<br />

### Advanced Logs

This script includes debugging prints / logs. To view these, restart `csf.service` by running the following command in terminal:
```shell ignore
sudo csf -ra
```

<br />

All steps performed by the script will be displayed in terminal:
```shell ignore
  + OPENVPN       Adding OpenVPN Rules

                  + RULE                   -A INPUT -i tun+ -j ACCEPT            
                  + RULE                   -A FORWARD -i tun+ -j ACCEPT          
                  + RULE                   -A FORWARD -o tun0 -j ACCEPT
                  + RULE                   -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
                  + RULE                   -A FORWARD -i tun+ -o enp0s3 -m state --state RELATED,ESTABLISHED -j ACCEPT
                  + RULE                   -A FORWARD -i enp0s3 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
                  + RULE                   -t nat -A POSTROUTING -j SNAT --to-source XX.XXX.XXX.XXX
                  + RULE                   -t nat -A POSTROUTING -s 10.8.0.0/24 -o enp0s3 -j MASQUERADE
```

<br />

---

<br />

## Install Dark Theme
The dark theme is an unofficial theme not available in the official install of ConfigServer firewall. You may use the files provided in this repository to switch your copy of CSF over to the dark theme.

<br />

<p align="center">
  <img style="padding-right:15px;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/7.gif" width="400" />
  <img src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/8.gif" width="400" /> 
</p>

<p align="center"><img style="width: 80%;text-align: center;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/refs/heads/main/docs/images/readme/9.png"></p>

<br />

Head over to the [Releases](https://github.com/Aetherinox/csf-firewall/releases) page and download the dark theme zip file:

- `*-theme-dark.zip`

<br />

Extract the files from the zip to the same paths as they are shown in the zip. You should have the following files:

- `/etc/csf/ui/images/*.css`
- `/usr/local/csf/lib/ConfigServer/*.pm`
- `/usr/sbin/lfd`

<br />

---

<br />

## Traefik Integration with CSF WebUI

To integrate the CSF WebUI into Docker and Traefik so that you can access it via a domain and secure it:

<br />

Open `/etc/csf/csf.conf` and change the `UI_IP`. This specifies the IP address that the CSF WebUI will bind to. By default, the value is empty and binds CSF's WebUI to all IPs on your server.

Find:

```shell ignore
UI_IP = ""
```

<br />

Change the IP to your Docker network subnet. You MUST use the format below, which is 
`::IPv6:IPv4`

```shell ignore
UI_IP = "::ffff:172.17.0.1"
```

<br />

The above change will ensure that your CSF WebUI is **not** accessible via your public IP address. We're going to allow access to it via your domain name, but add some Traefik middleware so that you must authenticate before you can access the WebUI.

<br />

Next, we can add CSF through Docker and Traefik so that it's accessible via `csf.domain.com`. Open up your Traefik's `dynamic.yml` and add the following:

```yml
http:
    routers:
        csf-http:
            service: "csf"
            rule: "Host(`csf.domain.com`)"
            entryPoints:
                - "http"
            middlewares:
                - https-redirect@file

        csf-https:
            service: "csf"
            rule: "Host(`csf.domain.com`)"
            entryPoints:
                - "https"
            middlewares:
                - authentik@file
                - whitelist@file
                - geoblock@file
            tls:
              certResolver: cloudflare
              domains:
                  - main: "domain.com"
                    sans:
                        - "*.domain.com"
```

<br />

A full example of the Traefik routers and middleware can be found at:

- https://aetherinox.github.io/csf-firewall/csf/tutorials/traefik/

<br />

At the bottom of the same file, we must now add a new **loadBalancer** rule under `http` -> `services`. Change the `ip` and `port` if you have different values:

```yml
http:
    routers:
        [CODE FROM ABOVE]
    services:
        csf:
            loadBalancer:
                servers:
                    - url: "https://172.17.0.1:8546/"
```

<br />

With the example above, we are also going to add a few middlewares:
- [Authentik](https://goauthentik.io/)
- [IP Whitelist](https://doc.traefik.io/traefik/middlewares/http/ipwhitelist/)
- [Geographical Location Blocking](https://plugins.traefik.io/plugins/62947302108ecc83915d7781/LICENSE)

<br />

By applying the above middlewares, we can restrict what IP addresses can access your CSF WebUI, as well as add Authentik's authentication system so that you must authenticate first before getting into the CSF WebUI. These are all optional, and you can apply whatever middlewares you deem fit.

<br />

You must configure the above middleware if you have not added it to Traefik yet. This guide does not go into how to add middleware to Traefik, that information can be found at:
- https://doc.traefik.io/traefik/middlewares/overview/

<br />

Once you configure these changes in Traefik, you can restart your Traefik docker container. The command for that depends on how you set up the container. If you used `docker-compose.yml`, you can `cd` into the folder with the `docker-compose.yml` file and then execute:
```shell
docker compose down && docker compose up -d
```

<br />
<br />

### Adding Authentik Provider

If you are adding [Authentik](https://goauthentik.io/) as middleware in the steps above; the last thing you must do is log in to your Authentik admin panel and add a new **Provider** so that we can access the CSF WebUI via your domain.

<br />

Once you sign into the Authentik admin panel, go to the left-side navigation, select **Applications** -> **Providers**. Then at the top of the new page, click **Create**.

<br />

<p align="center"><img style="width: 40%;text-align: center;" src="https://github.com/user-attachments/assets/8fe1dfc8-bbdc-4c8c-bc5a-be5b103e7404"></p>

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/82e3f027-b058-4b3c-86db-bdc4505a4e4e"></p>

<br />

For the **provider**, select `Proxy Provider`.

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/086ae998-964f-45e3-8606-ae8a36ecf82c"></p>

<br />

Add the following provider values:
- Name: `CSF ForwardAuth`
- Authentication Flow: `default-source-authentication (Welcome to authentik!)`
- Authorization Flow: `default-provider-authorization-implicit-consent (Authorize Application)`

<br />

Select **Forward Auth (single application)**:
- External Host: `https://csf.domain.com`

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/b1d6258a-f53e-4225-a4e9-9f9b5b69b191"></p>

<br />

Once finished, click **Create**. Then on the left-side menu, select **Applications** -> **Applications**. Then at the top of the new page, click **Create**.

<br />

<p align="center"><img style="width: 40%;text-align: center;" src="https://github.com/user-attachments/assets/405fb566-0384-4345-8f07-ad52b9af9358"></p>

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/82e3f027-b058-4b3c-86db-bdc4505a4e4e"></p>

<br />

Add the following parameters:
- Name: `CSF (ConfigServer Firewall)`
- Slug: `csf`
- Group: `Administrative`
- Provider: `CSF ForwardAuth`
- Backchannel Providers: `None`
- Policy Engine Mode: `any`

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/11425a7a-f049-4434-a232-3ea2847145d7"></p>

<br />

Save, and then on the left-side menu, select **Applications** -> **Outposts**:

<br />

<p align="center"><img style="width: 40%;text-align: center;" src="https://github.com/user-attachments/assets/cb975af4-d167-44c5-8587-b366aa591716"></p>

<br />

Find your **Outpost** and edit it.

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/a349423f-6db5-431d-888e-8ba658053b2c"></p>

<br />

Move `CSF (ConfigServer Firewall)` to the right side **Selected Applications** box.

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/b4b882d4-8f41-4af9-b788-cef649a48d24"></p>

<br />

You should be able to access `csf.domain.com` and be prompted now to authenticate with Authentik.

<br />

---

<br />

## IP Sets / Blocklist

This repository contains a set of ipsets which are automatically updated every `6 hours`. You may add these sets to your ConfigServer Firewall `/etc/csf/csf.blocklists` with the following new line:

```
CSF_MASTER|43200|400000|https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/master.ipset
CSF_HIGHRISK|43200|0|https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/highrisk.ipset
```

<br />

The format for the above lines are `NAME|INTERVAL|MAX_IPS|URL`

- **NAME**: List name with all uppercase alphabetic characters with no spaces and a maximum of 25 characters - this will be used as the iptables chain name
- **INTERVAL**: Refresh interval to download the list, must be a minimum of 3600 seconds (an hour).
  - `43200`: 12 hours
  - `86400`: 24 hours
- **MAX_IPS**: This is the maximum number of IP addresses to use from the list, a value of 0 means all IPs _(see note below)_. 
  - If you add an ipset with 50,000 IPs, and you set this value to 20,000; then you will only block the first 20,000.
- **URL**: The URL to download the ipset from

<br />

> [!NOTE]
> If you have not modified the settings of ConfigServer Firewall; the `MAX_IPS` value is limited by the setting `LF_IPSET_MAXELEM` which has a maximum value of loading `65536` IPs; even if you set the value in your lists above to 0, or anything above 65536.
>
> To allow for higher numbers of blocked IPs in an ipset to be loaded; you must edit your CSF config file in `/etc/csf/csf.conf` and change the setting `LF_IPSET_MAXELEM` to something higher than `65536`
> 
> ```ini
> # old value
> # LF_IPSET_MAXELEM = "65536"
> 
> # new value
> LF_IPSET_MAXELEM = "4000000"
> ```
>
> This setting can also be modified through the ConfigServer Firewall Admin WebUI if you have it installed.

<br />

Once you have added the line(s) above; you will need to give ConfigServer Firewall and LFD a restart.

```shell
sudo csf -ra
```

<br />

You can confirm that the ipset is installed by running the command:

```shell
sudo ipset --list -n
```

<br />

The above command will list all existing ipsets running on your firewall:

```console
chain_DENY
chain_6_DENY
chain_ALLOW
chain_6_ALLOW
bl_CSF_HIGHRISK
bl_6_CSF_HIGHRISK
bl_CSF_MASTER
bl_6_CSF_MASTER
```

<br />

As you can see in the list above; we have the following ipsets loaded from this repository:

- `bl_CSF_HIGHRISK`
- `bl_6_CSF_HIGHRISK`
- `bl_CSF_MASTER`
- `bl_6_CSF_MASTER`

<br />

To view all of the IPs in a specified ipset / list, run:

```shell
$ sudo ipset --list bl_CSF_HIGHRISK

Name: bl_CSF_HIGHRISK
Type: hash:net
Revision: 7
Header: family inet hashsize 1024 maxelem 4000000 bucketsize 12 initval 0x5f263e28
Size in memory: 24024
References: 1
Number of entries: 630
Members:
XX.XX.XX.XXX
XX.XX.XX.XXX
[ ... ]
```

<br />

If you modified the ConfigServer Firewall setting `LF_IPSET_MAXELEM` _(explained in the note above)_, you will see the new max limit value listed next to `maxelem`.

```shell
Header: family inet hashsize 1024 maxelem 4000000 
```

<br />

> [!NOTE]
> If you decide to use the blocklist `master.ipset`, you must ensure you increase the value of the setting `LF_IPSET_MAXELEM` in the file `/etc/csf/csf.conf` to at least `400000`.
> 
> On average, the `master.ipset` list normally contains `392,000` blocked IP addresses.

<br />
<br />

### Main Lists

These are the primary lists that most people will be interested in. They contain a large list of IP addresses which have been reported recently for abusive behavior. These statistics are gathered from numerous websites such as [AbuseIPDB](https://www.abuseipdb.com/) and [IPThreat](https://ipthreat.net/). IPs on this list have a 100% confidene level, which means you should get no false-positives from any of the IPs in these lists. IP addresses in these lists have been flagged for engaging in the following:

- SSH Bruteforcing
- Port Scanning
- DDoS Attacks
- IoT Targeting
- Phishing

<br />

For the majority of people, using the blocklists `master.ipset` and `highrisk.ipset` will be all you need. It is a massive collection, all with a 100% confidence level, which means you should get none or minimal false positives. 

<br />

| Set Name | Description | Severity | View |
| --- | --- | --- | --- |
| `master.ipset` | <sub>Abusive IP addresses which have been reported for port scanning and SSH brute-forcing. HIGHLY recommended. <br> Includes [AbuseIPDB](https://www.abuseipdb.com/), [IPThreat](https://ipthreat.net/), [CinsScore](https://cinsscore.com), [GreensNow](https://blocklist.greensnow.co/greensnow.txt)</sub> | ★★★★★ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/master.ipset) |
| `highrisk.ipset` | <sub>IPs with highest risk to your network and have a possibility that the activity which comes from them are going to be fraudulent.</sub> | ★★★★★ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/highrisk.ipset) |

<br />
<br />

### Privacy Lists

These blocklists give you more control over what 3rd party services can access your server, and allows you to remove bad actors or services hosting such services.

<br />

| Set | Description | Severity | View |
| --- | --- | --- | --- |
| `privacy_general.ipset` | <sub>Servers which scan ports for data collection and research purposes. List includes [Censys](https://censys.io), [Shodan](https://www.shodan.io/), [Project25499](https://blogproject25499.wordpress.com/), [InternetArchive](https://archive.org/), [Cyber Resilience](https://cyberresilience.io), [Internet Measurement](https://internet-measurement.com), [probe.onyphe.net](https://onyphe.net), [Security Trails](https://securitytrails.com) </sub> | ★★★★⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_general.ipset) |
| `privacy_ahrefs.ipset` | <sub>Ahrefs SEO and services</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_ahrefs.ipset) |
| `privacy_amazon_aws.ipset` | <sub>Amazon AWS</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_amazon_aws.ipset) |
| `privacy_amazon_ec2.ipset` | <sub>Amazon EC2</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_amazon_ec2.ipset) |
| `privacy_applebot.ipset` | <sub>Apple Bots</sub> | ★★★⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_applebot.ipset) |
| `privacy_bing.ipset` | <sub>Microsoft Bind and Bing Crawlers / Bots</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_bing.ipset) |
| `privacy_bunnycdn.ipset` | <sub>Bunny CDN</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_bunnycdn.ipset) |
| `privacy_cloudflarecdn.ipset` | <sub>Cloudflare CDN</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_cloudflarecdn.ipset) |
| `privacy_cloudfront.ipset` | <sub>Cloudfront DNS</sub> | ★⚝⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_cloudfront.ipset) |
| `privacy_duckduckgo.ipset` | <sub>DuckDuckGo Web Crawlers / Bots</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_duckduckgo.ipset) |
| `privacy_facebook.ipset` | <sub>Facebook Bots & Trackers</sub> | ★★★⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_facebook.ipset) |
| `privacy_fastly.ipset` | <sub>Fastly CDN</sub> | ★⚝⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_fastly.ipset) |
| `privacy_google.ipset` | <sub>Google Crawlers</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_google.ipset) |
| `privacy_pingdom.ipset` | <sub>Pingdom Monitoring Service</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_pingdom.ipset) |
| `privacy_rssapi.ipset` | <sub>RSS API Reader</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_rssapi.ipset) |
| `privacy_stripe_api.ipset` | <sub>Stripe Payment Gateway API</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_stripe_api.ipset) |
| `privacy_stripe_armada_gator.ipset` | <sub>Stripe Armada Gator</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_stripe_armada_gator.ipset) |
| `privacy_stripe_webhooks.ipset` | <sub>Stripe Webhook Service</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_stripe_webhooks.ipset) |
| `privacy_telegram.ipset` | <sub>Telegram Trackers and Crawlers</sub> | ★★★⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_telegram.ipset) |
| `privacy_uptimerobot.ipset` | <sub>Uptime Robot Monitoring Service</sub> | ★⚝⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_uptimerobot.ipset) |
| `privacy_webpagetest.ipset` | <sub>Webpage Test Services</sub> | ★★⚝⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/privacy/privacy_webpagetest.ipset) |

<br />
<br />

### Spam Lists

These blocklists allow you to remove the possibility of spam sources accessing your server.

<br />

| Set | Description | Severity | View |
| --- | --- | --- | --- |
| `spam_forums.ipset` | <sub>List of known forum / blog spammers and bots</sub> | ★★★⚝⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/spam/spam_forums.ipset) |
| `spam_spamhaus.ipset` | <sub>Bad actor IP addresses registered with Spamhaus</sub> | ★★★★⚝ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/spam/spam_spamhaus.ipset) |

<br />
<br />

### Geographical (Continents & Countries)
These blocklists allow you to determine what geographical locations can access your server. These can be used as either a whitelist or a blacklist. Includes both **continents** and **countries**.

<br />

| Set | Description | Severity | View |
| --- | --- | --- | --- |
| `GeoLite2 Database` | <sub>Lists IPs by continent and country from GeoLite2 database. Contains both IPv4 and IPv6 subnets</sub> | ★★★★★ | [view](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data/) |
| `Ip2Location Database` | <sub>Coming soon</sub> | ★★★★★ | [view](https://lite.ip2location.com/database-download) |

<br />
<br />

### Transmission (BitTorrent Client)

This section includes blocklists which you can import into the [bittorrent client Transmission](https://transmissionbt.com/).

<br />

- In this repo, copy the direct URL to the Transmission blocklist, provided below:
  - https://github.com/Aetherinox/csf-firewall/raw/main/blocklists/transmission/blocklist.gz
- Open your Transmission application; depending on the version you run, do ONE of the follow two choices:
  - Paste the link to Transmission > Settings > Peers > Blocklist
  - Paste the link to Transmission > Edit > Preferences > Privacy > Enable Blocklist

<br />

| Set | Description | Severity | View | Website |
| --- | --- | --- | --- | --- |
| `bt-transmission` | <sub>A large blocklist for the BitTorrent client [Transmission](https://transmissionbt.com/)</sub> | ★★★★★ | [view](https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/blocklists/transmission/blocklist.ipset) | [view](https://transmissionbt.com/) |


<br />

---

<br />

## Download ConfigServer Firewall

The latest version of csf can be downloaded from:
- https://download.configserver.com/csf.tgz

<br />

---

<br />

## Notes

This section simply outlines notes about ConfigServer Firewall

<br />

### CSF to Iptable Commands

ConfigServer Firewall is a way to manage your existing firewall rules. In order for ConfigServer Firewall to work, your server must have the library `iptables` installed. ConfigServer Firewall is basically a wrapper for iptables, and has the additional option of adding a web UI so that you can visually manage your firewall instead of using commands. Without `iptables`, ConfigServer Firewall is useless.

<br />

If you were to uninstall ConfigServer Firewall from your server; you would still have the ability to do everything CSF can, but you would have to manually run commands on the package iptables. 

<br />

This section gives you the commands that ConfigServer Firewall uses to manage your firewall, and gives you the iptables alternative command if you do not wish to use CSF.

<br />
<br />

#### Default Policy

ConfigServer Firewall and iptables come with three main CHAINS. ConfigServer Firewall will set these three main chains to have the policy `DROP`. 

This `DROP` policy means that no connections are allowed to access any of these chains on your server, meaning nobody can connect to your server; unless you have added rules to allow access by an IP address or port. 

To set the policy of these chains; run:

```shell
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP 
sudo iptables -P OUTPUT DROP
```

<br />

You can select from the list of available policies. 

- `ACCEPT` Accepts packets into or out of your server.
- `DROP` Denies access to a port or server, but makes the connection appear to be to an unoccupied IP address. Scanners may choose not to continue scanning addresses which appear unoccupied.
- `REJECT` Denies access to a port or server, but tells the connecting party that the server and port are really there, but they've been denied access to transmit data or connect.

<br />

As a general rule:
  - Use `ACCEPT` to allow access to a port or IP by a connecting party.
  - Use `DROP` for connections to hosts you don't want people to see.
  - Use `REJECT` when you want the other end to know the port is unreachable.

<br />
<br />

#### Clear Iptables / Open Firewall

To clear every single iptables rule and open your firewall back up, run the following command. Note that this will completely turn off iptables / CSF's blocking abilities. Your server will be open to connections:

```shell
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
```

<br />
<br />

#### List Rules

To list all of your iptable rules, and the rules that CSF has added to your firewall, run:

```shell
sudo iptables --list --line-numbers -n
```

<br />
<br />

#### List Chains

To list all of the chains in iptables, run:

```shell
sudo iptables -L | grep Chain
```

<br />

A list of the available CHAINS are provided below:

> [!NOTE]
> Out of box, ConfigServer Firewall & Iptables makes use of three chains
>   - `INPUT` Packets coming _from_ the network and going _to_ your server 
>   - `OUTPUT` Packets originating _from_ your server and going _to_ the network.
>   - `FORWARD` Packets forwarded by your server, if/when it acts as a router between different networks such as <sup> `DOCKER` </sup>
> 
> **Additional Chains**
>   - `NAT` This table is consulted when a packet that creates a new connection is encountered. It consists of four built-ins:
>     - `PREROUTING` for altering packets as soon as they come in
>     - `INPUT` for altering packets destined for local sockets
>     - `OUTPUT` for altering locally-generated packets before routing
>     - `POSTROUTING` for altering packets as they are about to go out
>   - `MANGLE` Used for specialized packet alteration.
>   - `DOCKER` Rules that determine whether a packet that is not part of an established connection should be accepted, based on the port forwarding configuration of running containers.
>   - `DOCKER-USER` A placeholder for user-defined rules that will be processed before rules in the <sup> `DOCKER-FORWARD` </sup> and <sup> `DOCKER` </sup> chains.
>   - `DOCKER-FORWARD` The first stage of processing for Docker's networks. Rules that pass packets that are not related to established connections to the other Docker chains, as well as rules to accept packets that are part of established connections.
>   - `DOCKER-ISOLATION-STAGE-1` Rules to isolate Docker networks from each other.
>   - `DOCKER-INGRESS` Rules related to Swarm networking.

<br />
<br />

#### Unblock Port

If you make use of the ConfigServer Firewall WebUI; one of the features available is the ability to whitelist / allow access to certain ports. If you do not wish to use the WebUI, you can unblock these ports in your terminal using `iptables`.

To access unblocking ports in CSF, open your WebUI:

<p align="center"><img style="width: 80%;text-align: center;" src="docs/images/readme/20.jpg"></p>

<br />

Select **Firewall Configuration**, and then scroll down until you see the settings:

- `TCP_IN`
- `TCP_OUT`

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="docs/images/readme/21.jpg"></p>

<br />

To unblock a port using Iptables using the command that CSF would use, you can run the following. For this example, we will unblock port `43` which can be used for the `whois` package:

```shell
sudo iptables -I OUTPUT ! -o lo -m conntrack --ctstate NEW -p tcp --dport 43 -j ACCEPT
```

<br />

Remember to change `--dport 43` to the port you wish to unblock, change `-p tcp` to specify either `TCP` or `UDP`, and change `-D OUTPUT` to specify the chain you want the port to allow access through.

<br />

To re-block port `43` and disallow connections, delete the rule in iptables:

```shell
sudo iptables -D OUTPUT ! -o lo -m conntrack --ctstate NEW -p tcp --dport 43 -j ACCEPT
```

<br />

To view the firewall rule in your iptables, run:

```shell
sudo iptables --list --line-numbers -n
```

<br />

Running this command should output all your table rules. Your new rule will appear as:

```
Chain OUTPUT (policy DROP)
num  target     prot opt source               destination         
1    ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:43 ctstate NEW
```

<br />
<br />

#### Allow OpenVPN

To allow OpenVPN through CSF / Iptables, run the following command. Replace `tun0` with your channel adapter name.

```shell
TUN_ADAPTER=$(ip -br l | awk '$1 ~ "^tun[0-9]" { print $1}')
sudo iptables -A FORWARD -o ${TUN_ADAPTER} -j ACCEPT
```

<br />

Next, add a `POSTROUTING` rule. If you do not want to use your default adapter name, replace `${ETH_ADAPTER}` with the name. For ours, we will use `eth0`.

```shell
ETH_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
sudo iptables -t nat -A POSTROUTING -o ${ETH_ADAPTER} -j MASQUERADE
```

<br />

Now we need to add a few rules for the IP block our OpenVPN server will use. In this example, we'll use `10.8.0.0/24`.

```shell
ETH_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
sudo iptables -t nat -A POSTROUTING -s "10.8.0.0/24" -o ${ETH_ADAPTER} -j MASQUERADE
```

<br />

Next, add the iptable rules for your OpenVPN server's port. Replace `1194` with your OpenVPN port if it is different. Replace `${ETH_ADAPTER}` with your desired ethernet adapter name if you do not wish to use the default defined below.

```shell
ETH_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
sudo iptables -A INPUT -i ${ETH_ADAPTER} -m state --state NEW -p udp --dport 1194 -j ACCEPT
sudo iptables -A FORWARD -i tun+ -o ${ETH_ADAPTER} -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i ${ETH_ADAPTER} -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
```

<br />

Finally, set the adapter name `tun+` to have access to the `OUTPUT` chain. 

The `+` symbol is a wildcard rule; which means that if you create multiple OpenVPN tunnels, they'll automatically be allowed through the OUTPUT chain, such as `tun1`, `tun2`, etc. If you only want one specific tunnel to be allowed, change `tun+` to `tun0`, or whatever tunnel you want to allow.

```shell
sudo iptables  -A OUTPUT -o tun+ -j ACCEPT
```

<br />

Your OpenVPN server should now be able to allow connections between CSF / Iptables and OpenVPN.

<br />

---

<br />

## References for More Help

If you need additional help apart from this guide to configure CSF; use the following pages for more help:
- Chapter 1: [How to Install and Configure CSF Firewall on Linux](https://tecadmin.net/install-csf-firewall-on-linux/)
- Chapter 2: [How to Enable CSF Firewall Web UI](https://tecadmin.net/how-to-enable-csf-firewall-web-ui/)

<br />

---

<br />

## Contributors ✨

We are always looking for contributors. If you feel that you can provide something useful to Gistr, then we'd love to review your suggestion. Before submitting your contribution, please review the following resources:

- [Pull Request Procedure](.github/PULL_REQUEST_TEMPLATE.md)
- [Contributor Policy](CONTRIBUTING.md)

<br />

Want to help but can't write code?
- Review [active questions by our community](https://github.com/Aetherinox/csf-firewall/labels/help%20wanted) and answer the ones you know.

<br />

![Alt](https://repobeats.axiom.co/api/embed/a968656a3592fa904ffbcc3abd666aa2d40b8648.svg "Repobeats analytics image")

<br />

The following people have helped get this project going:

<br />

<div align="center">

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![Contributors][contribs-all-img]](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top"><a href="https://gitlab.com/Aetherinox"><img src="https://avatars.githubusercontent.com/u/118329232?v=4?s=40" width="80px;" alt="Aetherinox"/><br /><sub><b>Aetherinox</b></sub></a><br /><a href="https://github.com/Aetherinox/csf-firewall/commits?author=Aetherinox" title="Code">💻</a> <a href="#projectManagement-Aetherinox" title="Project Management">📆</a> <a href="#fundingFinding-Aetherinox" title="Funding Finding">🔍</a></td>
    </tr>
  </tbody>
</table>
</div>
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

<br />
<br />

<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- BADGE > GENERAL -->
  [general-npmjs-uri]: https://npmjs.com
  [general-nodejs-uri]: https://nodejs.org
  [general-npmtrends-uri]: http://npmtrends.com/csf-firewall

<!-- BADGE > VERSION > GITHUB -->
  [github-version-img]: https://img.shields.io/github/v/tag/Aetherinox/csf-firewall?logo=GitHub&label=Version&color=ba5225
  [github-version-uri]: https://github.com/Aetherinox/csf-firewall/releases

<!-- BADGE > VERSION > NPMJS -->
  [npm-version-img]: https://img.shields.io/npm/v/csf-firewall?logo=npm&label=Version&color=ba5225
  [npm-version-uri]: https://npmjs.com/package/csf-firewall

<!-- BADGE > VERSION > PYPI -->
  [pypi-version-img]: https://img.shields.io/pypi/v/csf-firewall-plugin
  [pypi-version-uri]: https://pypi.org/project/csf-firewall-plugin/

<!-- BADGE > LICENSE > MIT -->
  [license-mit-img]: https://img.shields.io/badge/MIT-FFF?logo=creativecommons&logoColor=FFFFFF&label=License&color=9d29a0
  [license-mit-uri]: https://github.com/Aetherinox/csf-firewall/blob/main/LICENSE

<!-- BADGE > GITHUB > DOWNLOAD COUNT -->
  [github-downloads-img]: https://img.shields.io/github/downloads/Aetherinox/csf-firewall/total?logo=github&logoColor=FFFFFF&label=Downloads&color=376892
  [github-downloads-uri]: https://github.com/Aetherinox/csf-firewall/releases

<!-- BADGE > NPMJS > DOWNLOAD COUNT -->
  [npmjs-downloads-img]: https://img.shields.io/npm/dw/%40aetherinox%2Fcsf-firewall?logo=npm&&label=Downloads&color=376892
  [npmjs-downloads-uri]: https://npmjs.com/package/csf-firewall

<!-- BADGE > GITHUB > DOWNLOAD SIZE -->
  [github-size-img]: https://img.shields.io/github/repo-size/Aetherinox/csf-firewall?logo=github&label=Size&color=59702a
  [github-size-uri]: https://github.com/Aetherinox/csf-firewall/releases

<!-- BADGE > NPMJS > DOWNLOAD SIZE -->
  [npmjs-size-img]: https://img.shields.io/npm/unpacked-size/csf-firewall/latest?logo=npm&label=Size&color=59702a
  [npmjs-size-uri]: https://npmjs.com/package/csf-firewall

<!-- BADGE > CODECOV > COVERAGE -->
  [codecov-coverage-img]: https://img.shields.io/codecov/c/github/Aetherinox/csf-firewall?token=MPAVASGIOG&logo=codecov&logoColor=FFFFFF&label=Coverage&color=354b9e
  [codecov-coverage-uri]: https://codecov.io/github/Aetherinox/csf-firewall

<!-- BADGE > ALL CONTRIBUTORS -->
  [contribs-all-img]: https://img.shields.io/github/all-contributors/Aetherinox/csf-firewall?logo=contributorcovenant&color=de1f6f&label=contributors
  [contribs-all-uri]: https://github.com/all-contributors/all-contributors

<!-- BADGE > GITHUB > BUILD > NPM -->
  [github-build-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/csf-firewall/npm-release.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-uri]: https://github.com/Aetherinox/csf-firewall/actions/workflows/npm-release.yml

<!-- BADGE > GITHUB > BUILD > Pypi -->
  [github-build-pypi-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/csf-firewall/release-pypi.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-pypi-uri]: https://github.com/Aetherinox/csf-firewall/actions/workflows/pypi-release.yml

<!-- BADGE > GITHUB > TESTS -->
  [github-tests-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/csf-firewall/npm-tests.yml?logo=github&label=Tests&color=2c6488
  [github-tests-uri]: https://github.com/Aetherinox/csf-firewall/actions/workflows/npm-tests.yml

<!-- BADGE > GITHUB > COMMIT -->
  [github-commit-img]: https://img.shields.io/github/last-commit/Aetherinox/csf-firewall?logo=conventionalcommits&logoColor=FFFFFF&label=Last%20Commit&color=313131
  [github-commit-uri]: https://github.com/Aetherinox/csf-firewall/commits/main/

<!-- prettier-ignore-end -->
<!-- markdownlint-restore -->
