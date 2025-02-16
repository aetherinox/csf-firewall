---
title: Install CSF
tags:
  - install
---

# Install CSF <!-- omit from toc -->
These steps explain how to install ConfigServer Firewall on your system. There are two possible ways to install CSF which are listed below: 

- [Install: Using Patch](#install-using-patch)
- [Install: Manually](#install-manually)

<br />

The [Patch](#install-using-patch) method attempts to take much of the work out of installing CSF. It installs all prerequisites automatically, and sets CSF to start with `TESTING MODE` disabled. After CSF is installed using the patcher; then the Docker and OpenVPN patches will automatically be installed next.

The [Manual](#install-manually) method requires you to manually install all prerequisites using your OS package manager, and then manually downloading the latest copy of CSF and extracting / installing it on your system. You will have to run the patcher after you have installed CSF.

<br />

---

<br />

## Install: Using Patch

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

  Patch installer will now start ...
```

<br />

After the patcher has installed CSF; it will then automatically install the Docker and OpenVPN patches. All you will need to do after; is ensure CSF is up and running.

Please proceed to the section [Configure & Start CSF](../../configure/start/)

<br />

---

<br />

## Install: Manually

### Prerequisites <!-- omit from toc -->
- A Linux server running CentOS, Debian, Ubuntu, or any other compatible Linux distribution. 
- Root access or a user account with sudo privileges.
- Perl installed on your server. If Perl is not installed, you can install it by running the following commands:
  - For **CentOS/RHEL**:
    ```shell
    sudo yum install perl ipset
    ```

  - For **Debian/Ubuntu**:

    ```shell
    sudo apt-get update 
    sudo apt-get install perl ipset
    ```

<br />

### Download and Install CSF <!-- omit from toc -->
To download and install CSF, follow these steps:

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

## Next Steps <!-- omit from toc -->

```embed
url:            ../configure
name:           Next: How to Configure & Start CSF
desc:           Instructions for editing the CSF config file and starting CSF for the first time
image:          https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon:        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon_size:   25
target:         same
accent:         a40547E0
```

<br />

---

<br />
