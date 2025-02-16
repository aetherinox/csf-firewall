---
title: How this patcher works
tags:
  - info
---

# How Patcher Works

This section is optional to read. It simply outlines what the patcher does from the time of execution to better explain what will be happening on your systen.

<br />

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

---

<br />
