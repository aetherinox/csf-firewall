---
title: "Cheatsheet: File & Folder Structure"
tags:
  - cheatsheet
  - configure
---

# Cheatsheet: File & Folder Structure
When installing, configuring, and running CSF; it is helpful to know where files and folders are stored within your system, and what their purpose is. A list of these files and folders used by CSF are provided below:

<br />

## Directory Structure
Directories associated with ConfigServer Filewall which house all of the files used to configure and manage CSF.

| Folder                    | Description                     |
| ------------------------- | ------------------------------- |
| `/etc/csf/`               | configuration files             |
| `/var/lib/csf/`           | temporary data files            |
| `/usr/local/csf/bin/`     | scripts                         |
| `/usr/local/csf/lib/`     | perl modules and static data    |
| `/usr/local/csf/tpl/`     | email alert templates           |

<br />

---

<br />

## File Structure
Files associated with ConfigServer Firewall configuration and management.

| File                      | Description                                                                                                     |
| ------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `/etc/csf/csf.conf`       | The main configuration file.                                                                                    |
| `/etc/csf/csf.allow`      | A list of IP's and CIDR addresses that should always be allowed through the firewall.                           |
| `/etc/csf/csf.deny`       | A list of IP's and CIDR addresses that should never be allowed through the firewall.                            |
| `/etc/csf/csf.ignore`     | A list of IP's and CIDR addresses that the login failure daemon should ignore and not not block if detected.    |
| `/etc/csf/csf.*ignore`    | Various ignore files that list files, users, IP's that the login failure daemon should ignore.                  |
| `/lib/systemd/system/lfd.service`    | Service file for lfd (ConfigServer Firewall)                                                         |
| `/lib/systemd/system/csf.service`    | Service file for csf (Login Failure Daemon)                                                          |

<br />

---

<br />

## Patcher Files
The following files are associated with the ConfigServer Firewall patcher which adds special iptable rules so that CSF can communicate with Docker & OpenVPN.

| File                                    | Description                                                                                                     |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `/usr/local/csf/bin/csfpre.sh`          | Patcher **pre** script. Runs before CSF configures iptables                                                     |
| `/usr/local/csf/bin/csfpost.sh`         | Patcher **post** script. Runs after CSF configures iptables                                                     |
| `/usr/local/include/csf/post.d/docker.sh` | Docker patch for CSF which adds firewall rules for Docker and CSF                                             |
| `/usr/local/include/csf/post.d/openvpn.sh` | OpenVPN patch for CSF which adds firewall rules for OpenVPN and CSF                                          |

<br />

---

<br />
