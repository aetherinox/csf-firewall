---
title: "Configure & Startup"
tags:
  - configure
---

# Configure & Startup
After you have installed ConfigServer Firewall in the previous chapter; you can start configuring it to suit your server’s requirements.

<br />

## Configure
The main configuration file for CSF is located at `/etc/csf/csf.conf`. You can use your preferred text editor to modify the file, such as nano or vim:

```shell
sudo nano /etc/csf/csf.conf
```

<br />

The list below outlines just a few of the important settings that you can modify within ConfigServer Firewall.

!!! note annotate "Patcher Note"

    When you run the patcher `install.sh`; **TESTING MODE** will automatically
    be disabled after the script has successfully completed.

- `TESTING`: Set this value to 0 to disable testing mode and activate the firewall.
- `TCP_IN` and `TCP_OUT`: These settings define the allowed incoming and outgoing TCP ports, respectively. Add or remove ports as required, separated by commas.
- `UDP_IN` and `UDP_OUT`: These settings define the allowed incoming and outgoing UDP ports, respectively. Add or remove ports as required, separated by commas.
- `DENY_IP_LIMIT`: This setting defines the maximum number of IP addresses that can be listed in the /etc/csf/csf.deny file. Adjust this limit as needed.
- `CT_LIMIT`: This setting controls the number of connections from a single IP address that are allowed before the IP is temporarily blocked. Adjust this value according to your server’s requirements.

<br />

Make sure to review the configuration file and adjust the settings to suit your server’s needs. After making changes to the configuration file, save and exit the text editor.

Two **csf.conf** configuration files have been provided as examples; a full version, and clean (uncommented) version, and can be viewed on the [csf.conf](../../cheatsheet/conf) page.

<br />

---

<br />

## Start ConfigServer
After you have set your config file to its desired values; you can now start up or restart the CSF service to apply the configurations. Open Terminal and run:

<br />

### Enable
<!-- md:command `-e,  --enable` -->

Enable csf and lfd if previously disabled

```shell
sudo csf -e
```

<br />

### Start
<!-- md:command `-s,  --start` -->

Starts the firewall and applies any rules that have been configured at startup.

```shell
sudo csf -s
```

<br />

### Restart
<!-- md:command `-r,  --restart` -->

Restart firewall rules (csf)

```shell
sudo csf -r
```

<br />

A full list of CSF commands have been provided in our [Cheatsheet: Commands](../../cheatsheet/commands/) section.

<br />

---

<br />

## Next Steps

```embed
url:            ../webui
name:           Next: Installing the Admin WebUI
desc:           Instructions for installing the CSF Admin Web Interface
image:          https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon:        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon_size:   25
target:         same
accent:         a40547E0
```

<br />

---

<br />
