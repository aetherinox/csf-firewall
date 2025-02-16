---
title: "Configure: Basics"
tags:
  - configure
---

# Configure: csf.conf <!-- omit from toc -->
Two versions of the config file have been provided below. A **full version** which contains comments, and a **clean version** which contains no comments and only the config settings. 

You may copy the contents, and place it within your server under the path `/etc/csf/csf.conf`.

<br />

- [Full Version](#full-version)
- [Clean Version](#clean-version)

<br />

After you have set your config file to its desired values; you must restart the CSF service to apply the configurations. Open Terminal and run:

```shell
sudo csf -r
```

You can also restart both CSF and LFD services with `-ra, --restartall`
```shell
sudo csf -ra
```

<br />

---

<br />

## Full Version
```ini
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/configs/etc/csf/csf.conf"
```

<br />

---

<br />

## Clean Version
```ini
--8<-- "https://raw.githubusercontent.com/Aetherinox/csf-firewall/main/configs/etc/csf/csf.conf.clean"
```


<br />

---

<br />
