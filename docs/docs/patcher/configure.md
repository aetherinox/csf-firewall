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
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/patch/docker.sh:59:75"
```

<br />

The settings are outlined below:

| Setting | Description |
| --- | --- |
| `DOCKER_INT` | main docker network interface |
| `NETWORK_MANUAL_MODE` | set `true` if you are manually assigning the ip address for each docker container |
| `NETWORK_ADAPT_NAME` | requires `NETWORK_MANUAL_MODE="true"` <br>name of the adapter you are specifying |
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

#### <!-- md:flag setting --> NETWORK_MANUAL_MODE 
<!-- md:version stable-2.0.0 --> <!-- md:default `false` --> <!-- md:flag required -->

Set `true` if you are manually assigning `external: true ` for each docker container within your `docker-compose.yml`.

=== "docker-compose.yml"

    ```yml hl_lines="4"
    networks:
      my-docker-network:
        name: my-docker-network
        external: true
    ```

=== "docker-sh"

    ```bash hl_lines="1"
    NETWORK_MANUAL_MODE="true"
    NETWORK_ADAPT_NAME="my-docker-network"
    ```

<br />

If you set `NETWORK_MANUAL_MODE="true"`; ensure you configure the setting [NETWORK_ADAPT_NAME](#network_adapt_name)

<br />
<br />

#### <!-- md:flag setting --> NETWORK_ADAPT_NAME 
<!-- md:version stable-2.0.0 --> <!-- md:default `traefik` --> <!-- md:flag required -->

The name of the adapter you are specifying if you have manually specified a network adapter in your docker container's `docker-compose.yml`. Requires `NETWORK_MANUAL_MODE="true"`

=== "docker-compose.yml"

    ```yml hl_lines="2-3"
    networks:
      my-docker-network:
        name: my-docker-network
        external: true
    ```

=== "docker-sh"

    ```bash hl_lines="2"
    NETWORK_MANUAL_MODE="true"
    NETWORK_ADAPT_NAME="my-docker-network"
    ```

<br />
<br />


<br />

---

<br />

## OpenVPN
The **OpenVPN** patch has a few settings that must be modified. To change these settings, open the file:

```shell
sudo nano /patch/openvpn.sh
```

<br />

---

<br />
