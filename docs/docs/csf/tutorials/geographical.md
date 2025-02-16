---
title: "CSF: Enable Geo Block"
tags:
  - configure
  - tutorials
---

# Enable Geographical Blocks
Geographical blocks allow you to blacklist or whitelist an entire country from accessing your services from within ConfigServer Firewall. 

<br />

## Getting Started
CSF allows you to pick which service you want to use for geographical blocks. By default, CSF uses **db-ip**, but you have the option to pick any of the following:

- [Maxmind](https://maxmind.com/en/account/login)
- [db-ip, ipdeny, iptoasn](https://db-ip.com/db/)

<br />

`Maxmind`

:   This service is free, but it requires you to sign up for an account and 
    generate an API key in order to use the services. Some have reported that
    Maxmind databases are slightly more accurate than db-ip.

    If you choose this provider; you must fill out `MM_LICENSE_KEY` within
    the `csf.conf`.

    **Advantages**: This is a one stop shop for all of the databases required for
    these features. They provide a consistent dataset for blocking and reporting
    purposes

    **Disadvantages**: MaxMind require a license key to download their databases.
    This is free of charge, but requires the user to create an account on their
    website to generate the required key.

`db-ip, ipdeny, iptoasn`

:   **Advantages**: The ipdeny.com databases form CC blocking are better optimised
    and so are quicker to process and create fewer iptables entries. All of these
    databases are free to download without requiring login or key

    **Disadvantages**: Multiple sources mean that any one of the three could
    interrupt the provision of these features. It may also mean that there are
    inconsistences between them

<br />

!!! warning "Performance Impact"

    If using **MaxMind**, be aware of how many countries you allow / deny from accessing your server.
    The more countries you add, the more rules that will be added to CSF. These rules will be loaded
    every time you start or restart CSF; and may cause CSF to take longer-than-normal times to boot.

<br />

To change which database is used for geo blocking; open your CSF's `csf.conf` config file and locate the setting `CC_SRC`. If you have the [ConfigServer WebUI](../../webui/) enabled; you can access these settings from the CSF Admin WebUI.

```ini hl_lines="23"
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/configs/etc/csf/csf.conf:943:965"
```

<br />

---

<br />

## Using MaxMind
To configure MaxMind as your specified geo service; you must go to their website and register an account.

- [Register for MaxMind](https://www.maxmind.com/en/accounts)

<br />

Once you have your account, on the left side; select **Manage License Keys**.

<p align="center"><img src="https://github.com/user-attachments/assets/3695dbfd-738e-4f7c-aee2-e3bd954438fd" width="260"></p>

<br />

In the middle of the page, you should be able to generate a license key:

<p align="center"><img src="https://github.com/user-attachments/assets/1f2cacb6-1c9f-48b1-83b3-456120561871" width="660"></p>

<br />

After the license key is generated, you must go back to your `csf.conf` and add the License key to your config. If you are using the [CSF WebUI](../../webui/):

<p align="center"><img src="https://github.com/user-attachments/assets/66f8ef1a-8a41-4df1-baeb-b44141d00b01" width="660"></p>

<br />

Next, you must install MaxMind's **GeoIpUpdater** utility which is what will download the IP address databases. This tool automatically updates GeoIP2 and GeoLite2 databases. The program connects to the MaxMind GeoIP Update server to check for new databases. If a new database is available, the program will download and install it.

A full set of instructions can also be found at:

- [Setting up GeoIpUpdate](https://dev.maxmind.com/geoip/updating-databases?lang=en)

<br />

!!! warning

    If you are using a firewall, you must have the DNS and HTTPS ports open.

<br />

First, install:

```shell
sudo add-apt-repository ppa:maxmind/ppa
sudo apt update
sudo apt install geoipupdate
```

<br />

Once installed make sure you have a License key generated on the maxmind website, you will then need to create a new file in `/etc/`:

```shell
sudo touch /etc/GeoIP.conf
```

<br />

Add the following code to your newly created `/etc/GeoIP.conf`. After you paste the code below; you must change the following values:

- `AccountID`
- `LicenseKey`

```ini
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/configs/etc/GeoIP.conf"
```

<br />

After you have created the above config; you need to launch the `geoipupdate` app. Multiple commands are provided below depending on if you want to specify where you placed your downloaded databases. A list of arguments are also provided. In our example, we are going to start `geoipupdate` and download the databases to the path `/var/lib/csf/Geo/`.

<br />

| Argument                         | Description                                                                                                                                                                                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `-d`, `--database-directory` | Install databases to a custom directory. This is optional. If provided, it overrides the `DatabaseDirectory` value from the configuration file and the `GEOIPUPDATE_DB_DIR` environment variable.                  |
| `-f`, `--config-file`        | The configuration file to use. See `GeoIP.conf` and its documentation for more information. This is optional. It defaults to the environment variable `GEOIPUPDATE_CONF_FILE` if it is set, or CONFFILE otherwise. |
| `--parallelism`              | Set the number of parallel database downloads.                                                                                                                                                                     |
| `-h`, `--help`               | Display help and exit.                                                                                                                                                                                             |
| `--stack-trace`              | Show a stack trace on any error message. This is primarily useful for debugging.                                                                                                                                   |
| `-V`, `--version`            | Display version information and exit.                                                                                                                                                                              |
| `-v`, `--verbose`            | Enable verbose mode. Prints out the steps that `geoipupdate` takes. If provided, it overrides any `GEOIPUPDATE_VERBOSE` environment variable.                                                                      |
| `-o`, `--output`             | Output download/update results in JSON format.                                                                                                                                                                     |
<br />

=== "Start (Basic)"

    ``` shell
    sudo geoipupdate
    ```

=== "Start (Custom Paths)"

    ``` shell
    sudo geoipupdate --database-directory /var/lib/csf/Geo/ --config-file /etc/GeoIP.conf
    ```

=== "Start (Verbose Logging)"

    ``` shell
    sudo geoipupdate -v --database-directory /var/lib/csf/Geo/ --config-file /etc/GeoIP.conf
    ```

<br />

---

<br />

## Using db-ip, ipdeny, iptoasn
This is the second option you can pick within CSF for Geographical blocking. When initially tried, it worked right out of box. It required no modifications, no packages to be installed, and no license keys.

<br />

---

<br />

## Allow / Deny Countries
After you've completed the steps above; you can now whitelist or blacklist specific countries from accessing your server and will be managed through your ConfigServer Firewall.

Pick your preferred method:

- [Manage countries using csf.conf](#manage-with-csfconf)
- [Manage countries with ConfigServer WebUI](#manage-with-csf-webui)

<br />

### Manage with csf.conf
Open up your `csf.conf` file in a text editor and locate the following settings:

- `CC_DENY`
- `CC_ALLOW`

<br />

```ini hl_lines="28-29"
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/configs/etc/csf/csf.conf:967:995"
```

<br />

In our example, we will blacklist the country **China**, which uses the abbreviation `CN`. To do so; our config will look like the following:

```ini
CC_DENY = "CN"
CC_ALLOW = ""
```

<br />

To specify multiple countries; add a comma `,` delimiter between each country.

```ini
CC_DENY = "CN"
CC_ALLOW = "US,GB,DE"
```

<br />

Our rules above mean:

| Setting | Countries | Description |
| --- | --- | --- |
| `CC_DENY` | `China` | Blacklisted countries: **cannot** access our server | 
| `CC_ALLOW` | `United States` <br> `Great Britain` <br> `Germany` | Whitelisted countries: **can** access our server | 

<br />

### Manage with CSF WebUI
Sign into the [ConfigServer WebUI](../../webui/). 

Select the tab **CSF**, scroll down and select **Firewall Configuration**, and then in the top dropdown box in the middle of the page, select **Country Code Lists and Settings**.

<br />

We will add the following to each setting:

```ini
CC_DENY = "CN"
CC_ALLOW = "US,GB,DE"
```

<br />

Below is an animated gif showing the steps.

<p align="center"><img src="https://github.com/user-attachments/assets/19af3001-5cd5-479f-80e4-dbcbd28de748" width="660"></p>

<br />

Once you have modified your country values; scroll to the very bottom and press the **Change** button.

<br />

---

<br />

## Restart CSF
After you have whitelisted / blacklisted your desired countries; give CSF a restart:

<br />

<!-- md:command `-ra, --restartall` -->

Restart firewall rules (csf) and then restart lfd daemon. Both csf and then lfd should be restarted after making any changes to the configuration files

```shell
sudo csf -ra
```

<br />

---

<br />
