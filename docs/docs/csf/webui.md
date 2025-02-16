---
title: Install WebUI
tags:
  - install
---

# Install WebUI <!-- omit from toc -->
ConfigServer Firewall offers a WebUI for the managing firewall from the web interface. This section explains how to install the WebUI.

<br />

### Step 1: Install Required Perl Modules:
The CSF WebUI requires a few Perl modules to be installed on your system. Use the following commands to install the required modules as per your operating system.

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

In order to gain access to the online admin panel; you must ensure lfd and csf are running. You can check by running the command:

```shell
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

```shell
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

```shell
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

<br />

**Deny IP Address**: You can use below option to deny any IP quickly. This action adds the entry to the `/etc/csf/csf.deny` file.

<p align="center"><img style="width: 80%;text-align: center;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/docs/images/csf-quick-deny.png"></p>

<br />

**Unblock IP Address**: You can use below option to quickly unblocked any IP which is already blocked by CSF.

<p align="center"><img style="width: 80%;text-align: center;" src="https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/docs/images/csf-unblock-ip.png"></p>

<br />

---

<br />
