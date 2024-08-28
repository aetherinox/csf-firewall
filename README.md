<div align="center">
<h6>Adds a new dark theme, and support for Docker, Traefik, and OpenVPN servers</h6>
<h1>♾️ ConfigServer Firewall ♾️</h1>

<br />

<p>

ConfigServer Security & Firewall (CSF) is a popular and powerful firewall solution for Linux servers. This repo contains complete installation guides, a new dark theme, and also numerous patches for `Docker` and `OpenVPN` firewall support so that you can allow traffic between these services without interruption.

</p>

<br />

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

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/f93fcd88-4817-4fc8-b342-56a2375c0b92"></p>

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/98440f33-8947-4409-8ff4-32138ddf4763"></p>

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
  - [Start Firewall](#start-firewall)
  - [Stop Firewall](#stop-firewall)
  - [Restart Firewall](#restart-firewall)
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
  - [Install](#install)
  - [Configure](#configure)
  - [Run Patch](#run-patch)
  - [Manual Run](#manual-run)
  - [Advanced Logs](#advanced-logs)
- [Install OpenVPN Patch](#install-openvpn-patch)
  - [Clone](#clone-1)
  - [Install](#install-1)
  - [Configure](#configure-1)
  - [Run Patch](#run-patch-1)
  - [Manual Run](#manual-run-1)
  - [Advanced Logs](#advanced-logs-1)
- [Install Dark Theme](#install-dark-theme)
- [Traefik Integration with CSF WebUI](#traefik-integration-with-csf-webui)
  - [Adding Authentik Provider](#adding-authentik-provider)
- [Download ConfigServer Firewall](#download-configserver-firewall)
- [References for More Help](#references-for-more-help)
- [Contributors ✨](#contributors-)


<br />

---

<br />

## Summary
This repository contains several folders:
- 📁 `extras`: The official CSF `config.conf`
- 📁 `patches`: Custom patches
  - Docker
  - OpenVPN Server

<br />
<br />

Each release posted on the [Releases Page](https://github.com/Aetherinox/csf-firewall/releases) contains two files:
- `csf-firewall-vxx.xx.tgz`
  - This is the latest version of ConfigServer Firewall. You do not need this if you already have CSF installed on your system.
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
git clone https://github.com/Aetherinox/csf-firewall.git
```

<br />

Set the permissions for the `install.sh` file:
```shell
sudo chmod +x /csf-firewall/patch/install.sh
```

<br />

Run the script:
```shell
sudo ./csf-firewall/patch/install.sh
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

This command will restart the CSF and LFD (Login Failure Daemon) services, applying your configuration changes and activating the firewall.

<br />

---

<br />

## Managing the Firewall
CSF provides several commands to manage the firewall, such as:

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

### Restart Firewall

```shell
sudo csf -r
```

<br />

### List Firewall Rules

```shell
sudo csf -l
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
```
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

**Deny IP Address**: You can use below option to deny any IP quickly. This action adds the entry to the `/etc/csf/csf.deny` file.

<p align="center"><img style="width: 80%;text-align: center;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/docs/images/csf-quick-deny.png"></p>

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
git clone https://github.com/Aetherinox/csf-firewall.git
```

<br />

### Install
The Docker patch will automatically be installed if you run the `/patch/install.sh` script. It is the 2nd step in the process, right after it sets up the `pre` and `post` scripts.

<br />

If you wish to manually install it, you may run the following commands:
```shell ignore
sudo chmod +x /patch/docker.sh

sudo ./patch/docker.sh
```

<br />

### Configure
The `/patch/docker.sh` file has a few configs you can adjust. Open it in a text editor and change the values to your preference.

```bash ignore
DOCKER_INT="docker0"
NETWORK_MANUAL_MODE="false"
NETWORK_ADAPT_NAME="traefik"
CSF_FILE_ALLOW="/etc/csf/csf.allow"
CSF_COMMENT="Docker container whitelist"
DEBUG_ENABLED="false"
IP_CONTAINERS=(
    '172.17.0.0/16'
)
```

<br />

Each setting is defined below:

| Setting | Description |
| --- | --- |
| `DOCKER_INT` | <br>main docker network interface <br><br> |
| `NETWORK_MANUAL_MODE` | <br>set `true` if you are manually assigning the ip address for each docker container <br><br> |
| `NETWORK_ADAPT_NAME` | <br>requires `NETWORK_MANUAL_MODE="true"` <br>name of the adapter you are specifying <br><br> |
| `CSF_FILE_ALLOW` | <br>Path to your `csf.allow` file <br><br> |
| `CSF_COMMENT` | <br>comment added to each new whitelisted docker ip <br><br> |
| `DEBUG_ENABLED` | <br>debugging / better logs <br><br> |
| `IP_CONTAINERS` | <br>list of ip address blocks you will be using for your docker setup. these blocks will be whitelisted through ConfigServer Firewall <br><br> |

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

You can also try:
```shell
sudo sh install.sh
```

<br />

The `docker.sh` file will be installed to `/usr/local/include/csf/post.d`

<br />

### Manual Run
You can manually run the `docker.sh` script. It will also allow you to specify arguments such as `--dev` to get more detailed logging as the firewall is set up. This should only be done if you know what you're doing.

```shell ignore
sudo chmod +x /usr/local/include/csf/post.d/docker.sh
sudo /usr/local/include/csf/post.d/docker.sh
```

<br />

You can call arguments by running the file using:
```shell ignore
sudo /usr/local/include/csf/post.d/docker.sh --dev
```

<br />

You can also find out what version you are running by appending `--version` to either the `install.sh` or `docker.sh` file:

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
sudo /usr/local/include/csf/post.d/docker.sh --version
```

<br />

```shell ignore
ConfigServer Firewall Docker Patch - v2.0.0.0
https://github.com/Aetherinox/csf-firewall
Ubuntu | 24.04
```

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
git clone https://github.com/Aetherinox/csf-firewall.git
```

<br />

### Install
The OpenVPN patch will automatically be installed when you run the `/patch/install.sh` script.

<br />

If you wish to manually install it, you may run the following commands:
```shell ignore
sudo chmod +x /patch/openvpn.sh

sudo ./patch/openvpn.sh
```

<br />

### Configure
The `/patch/openvpn.sh` file has a few configs you can adjust. Open it in a text editor and change the values to your preference.

```bash ignore
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

```bash ignore
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

You can also try:
```shell
sudo sh install.sh
```

<br />

The `openvpn.sh` file will be installed to `/usr/local/include/csf/post.d`

<br />

### Manual Run
You can manually run the `openvpn.sh` script. It will also allow you to specify arguments such as `--dev` to get more detailed logging as the firewall is set up. This should only be done if you know what you're doing.

```shell ignore
sudo chmod +x /usr/local/include/csf/post.d/openvpn.sh
sudo /usr/local/include/csf/post.d/openvpn.sh
```

<br />

You can call arguments by running the file using:
```shell ignore
sudo /usr/local/include/csf/post.d/openvpn.sh --dev
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
sudo /usr/local/include/csf/post.d/openvpn.sh --version
```

<br />

```shell ignore
ConfigServer Firewall OpenVPN Patch - v2.0.0.0
https://github.com/Aetherinox/csf-firewall
Ubuntu | 24.04
```

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

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/f93fcd88-4817-4fc8-b342-56a2375c0b92"></p>

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/98440f33-8947-4409-8ff4-32138ddf4763"></p>

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

Find
```shell ignore
UI_IP = ""
```

<br />

Change the IP to your Docker network subnet. You MUST use the format below, which is `::IPv6:IPv4`
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

## Download ConfigServer Firewall
The latest version of csf can be downloaded from:
- https://download.configserver.com/csf.tgz

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
