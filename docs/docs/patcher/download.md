---
title: "Patcher: Download"
tags:
  - install
  - patch
---

# Download Patches <!-- omit from toc -->
After you have installed CSF, [ConfigServer WebUI](../../webui/), and enabled both lfd and csf services; it's now time to run the patcher. The patcher will check your current configuration, and add a series of iptable rules so that apps like Docker and OpenVPN can communicate with the outside world and users can access your services.

<br />

## About
The patcher includes several patches:

`Docker`

:   Allows for you to restart CSF without having to restart your docker containers.
    Scans every container you have set up in docker and adds a whitelist firewall rule.
    Automatically enables CSF **Docker Mode**.

`OpenVPN`

:   Allows VPN clients to connect to your OpenVPN server without being blocked by
    the CSF firewall.

<br />

---

<br />

## Download
Within your server, change to whatever directory where you want to download the patcher:

```shell
cd $HOME/Documents
```

<br />

Next, ensure you have the package `git` installed so that we can use it to fetch the patch:

```shell
sudo apt-get install git
```

<br />

Clone the patch repo:

```shell
git clone https://github.com/Aetherinox/csf-firewall.git
```

<br />

Finally, set new permissions on the patcher's `install.sh` file by running the command:

```shell
sudo chmod +x /patch/install.sh
```

<br />

The patcher is now on your system and ready to run. However, before we run the patcher; there are a few things that need to be configured. **Do not run the patch yet**. 

Proceed to the [Configure](../configure/) section.

<br />

---

<br />

## Next Steps <!-- omit from toc -->

```embed
url:            ../configure/
name:           Next: How to configure the patcher
desc:           Instructions for configuring the patches included
image:          https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon:        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon_size:   25
target:         same
accent:         a40547E0
```

<br />

---

<br />

