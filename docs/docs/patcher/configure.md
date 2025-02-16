---
title: "Patcher: Configure"
tags:
  - install
  - patch
---

# Configure Patches <!-- omit from toc -->
Before you run the downloaded patcher; there are several files you must open and edit. **Do not run the patcher yet**.

<br />

## Docker
The **Docker** patch has a few settings that must be modified. To change these settings, open the file:

```shell
sudo nano /patch/docker.sh
```

<br />

Find the following settings:

```ini
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/patch/docker.sh:57:71"
```

<br />

The settings are outlined below:

| Setting | Description |
| --- | --- |
| `DOCKER_INT` | main docker network interface |
| `CSF_FILE_ALLOW` | Path to your `csf.allow` file |
| `CSF_COMMENT` | comment added to each new whitelisted docker ip |
| `DEBUG_ENABLED` | debugging / better logs |
| `IP_CONTAINERS` | list of ip address blocks you will be using for your docker setup. these blocks will be whitelisted through ConfigServer Firewall |

<br />

### Settings
Each individual setting with a detailed description

<br />

#### <!-- md:flag setting --> DOCKER_INT 
<!-- md:version stable-2.0.0 --> <!-- md:default `docker0` --> <!-- md:flag required -->

The main docker visual bridge network name; this is usually `docker0`, however, it can be changed. You can find a list of these by running the command

```shell
ip link show
```

=== "Output"

    ```
    4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN mode DEFAULT group default 
        link/ether 01:af:fd:1a:a1:2f ard ff:ff:ff:ff:ff:ff
    ```

<br />
<br />

#### <!-- md:flag setting --> CSF_FILE_ALLOW 
<!-- md:version stable-2.0.0 --> <!-- md:default `/etc/csf/csf.allow` --> <!-- md:flag required -->

The full path to your ConfigServer's `csf.allow` file. Each time an IP from one of your docker containers is detected, the IP will be whitelisted in ConfigServer Firewall.

=== "docker.sh"

    ```bash
    CSF_FILE_ALLOW="/etc/csf/csf.allow"
    ```

<br />
<br />

#### <!-- md:flag setting --> CSF_COMMENT 
<!-- md:version stable-2.0.0 --> <!-- md:default `Docker container whitelist` --> <!-- md:flag required -->

This is the comment that will be appended to each IP that is added to your ConfigServer's `allow.csf` whitelist file.

=== "docker.sh"

    ```bash
    CSF_COMMENT="Docker container whitelist"
    ```

=== "csf.allow"

    ```
    172.18.0.21 # Docker container whitelist - Fri Jun 7 11:43:00 2024
    172.18.0.12 # Docker container whitelist - Fri Jun 7 11:43:01 2024
    172.18.0.11 # Docker container whitelist - Fri Jun 7 11:43:01 2024
    ```

<br />
<br />

#### <!-- md:flag setting --> DEBUG_ENABLED 
<!-- md:version stable-2.0.0 --> <!-- md:default `false` --> <!-- md:flag required -->

If set `true`, additional information will be printed to terminal when the user executes `sudo csf -ra`

=== "docker.sh"

    ```bash
    DEBUG_ENABLED="false"
    ```

<br />
<br />

#### <!-- md:flag setting --> IP_CONTAINERS 
<!-- md:version stable-2.0.0 --> <!-- md:default `172.17.0.0/16` --> <!-- md:flag required -->

A list of IP blocks that you use within docker for container assignment.

=== "docker.sh"

    ```bash
    IP_CONTAINERS=(
        '172.17.0.0/16'
    )
    ```

<br />

---

<br />

## OpenVPN
The **OpenVPN** patch has a few settings that must be modified. To change these settings, open the file:

```shell
sudo nano /patch/openvpn.sh
```

<br />

Find the following settings:

```ini
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/patch/openvpn.sh:37:50"
```

<br />

The settings are outlined below:

| Setting | Description |
| --- | --- |
| `ETH_ADAPTER` | name of primary network adapter |
| `TUN_ADAPTER` | name of OpenVPN tunnel adapter |
| `IP_PUBLIC` | public IP to your server |
| `DEBUG_ENABLED` | debugging / better logs |
| `IP_POOL` | list of subnets assigned to your OpenVPN server |

<br />

### Settings
Each individual setting with a detailed description

<br />

#### <!-- md:flag setting --> ETH_ADAPTER 
<!-- md:version stable-2.0.0 --> <!-- md:default `$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")` --> <!-- md:flag required -->

The name of your primary server network adapter. This is usually `eth*`, `enp*`, etc.

=== "openvpn.sh"

    ```bash
    ETH_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
    ```

<br />

The default value attempts to auto-detect your network adapter name, however, you can specify the name manually:

=== "openvpn.sh"

    ```bash
    ETH_ADAPTER="eth0"
    ```

<br />

You can usually find your main network adapter with the command:

=== "Terminal"

    ```bash
    ifconfig
    ```

=== "Output"

    ```
    eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
            inet XX.XX.XX.XX  netmask 255.255.248.0  broadcast XX.XX.XX.XX
            inet6 ea24::a1bd:ef15:15a5:aae  prefixlen 64  scopeid 0x20<link>
            ether 01:15:72:15:2a:ab  txqueuelen 1000  (Ethernet)
            RX packets 101924006  bytes 383095603887 (383.0 GB)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 100519601  bytes 134852355384 (134.8 GB)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

    lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
            inet 127.0.0.1  netmask 255.0.0.0
            inet6 ::1  prefixlen 128  scopeid 0x10<host>
            loop  txqueuelen 1000  (Local Loopback)
            RX packets 7741770  bytes 2099091655 (2.0 GB)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 7741770  bytes 2099091655 (2.0 GB)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
    ```

<br />
<br />

#### <!-- md:flag setting --> TUN_ADAPTER 
<!-- md:version stable-2.0.0 --> <!-- md:default `$(ip -br l | awk '$1 ~ "^tun[0-9]" { print $1}')` --> <!-- md:flag required -->

The name of the primary OpenVPN tunnel adapter name. This is usually `tun*`.

=== "openvpn.sh"

    ```bash
    TUN_ADAPTER=$(ip -br l | awk '$1 ~ "^tun[0-9]" { print $1}')
    ```

<br />

The default value attempts to auto-detect your tunnel adapter name, however, you can specify the tunnel name manually:

=== "openvpn.sh"

    ```bash
    TUN_ADAPTER="tun0"
    ```

<br />

You can usually find your main network adapter with the command:

=== "Terminal"

    ```
    ifconfig
    ```

=== "Output"

    ```
    tun0: flags=4305<UP,POINTOPOINT,RUNNING,NOARP,MULTICAST>  mtu 1500
            inet 10.8.0.1  netmask 255.255.255.0  destination 10.8.0.1
            inet6 fe80::d70f:d8a8:32ab:1292  prefixlen 64  scopeid 0x20<link>
            unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 500  (UNSPEC)
            RX packets 620722  bytes 134501334 (134.5 MB)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 1449168  bytes 1756905789 (1.7 GB)
            TX errors 0  dropped 37128 overruns 0  carrier 0  collisions 0
    ```

<br />
<br />

#### <!-- md:flag setting --> IP_PUBLIC 
<!-- md:version stable-2.0.0 --> <!-- md:default `$(curl -s ipinfo.io/ip)` --> <!-- md:flag required -->

The public IP address of your server.

=== "openvpn.sh"

    ```bash
    IP_PUBLIC=$(curl -s ipinfo.io/ip)
    ```

<br />

The default value attempts to auto-detect your public IP address, however, you can specify the ip manually:

=== "openvpn.sh"

    ```bash
    IP_PUBLIC="204.22.36.22"
    ```

<br />

There are a few ways that you can obtain your server's public IP address:

=== "Method 1"

    ```shell
    wget -q -O - ipinfo.io/ip

    # 204.22.36.22
    ```

=== "Method 2"

    ```shell
    sudo apt-get install lynx -y
    lynx -source ipinfo.io/ip

    # 204.22.36.22
    ```

=== "Method 3"

    ```shell
    curl ipinfo.io/ip

    # 204.22.36.22
    ```

<br />
<br />

#### <!-- md:flag setting --> DEBUG_ENABLED 
<!-- md:version stable-2.0.0 --> <!-- md:default `false` --> <!-- md:flag required -->

If set `true`, additional information will be printed to terminal when the patch is ran.

=== "docker.sh"

    ```bash
    DEBUG_ENABLED="false"
    ```

<br />
<br />

#### <!-- md:flag setting --> IP_POOL 
<!-- md:version stable-2.0.0 --> <!-- md:default `10.8.0.0/24` --> <!-- md:flag required -->

A list of subnets assigned to your OpenVPN server.

=== "docker.sh"

    ```bash
    IP_POOL=(
        '10.8.0.0/24'
    )
    ```

<br />
<br />

---

<br />
