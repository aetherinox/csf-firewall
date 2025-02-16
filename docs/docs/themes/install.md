---
title: "Themes: Install"
tags:
  - install
  - themes
---

# Themes: Install <!-- omit from toc -->
This section outlines how to install custom themes that are included in the Github repository. These themes will override your existing ConfigServer Firewall theme, so be aware that you will be unable to utilize the default light theme unless you back up the original files and add them back.

<br />

## Available Themes
We offer the following custom themes:

<br />

<div markdown="1" align="center">

[![View](https://img.shields.io/badge/%20-%20Dark%20Theme-%20%23de2343?style=for-the-badge&logo=github&logoColor=FFFFFF)](https://github.com/Aetherinox/csf-firewall/releases)

</div>

<figure markdown="span">
  ![Dark theme login page](https://github.com/user-attachments/assets/df9085af-788e-4a55-ad0e-17815f95741c){ width="80%" }
  <figcaption>Dark theme preview</figcaption>
</figure>

<br />

---

<br />

## Install

Head over to the [Releases](https://github.com/Aetherinox/csf-firewall/releases) page and download the theme zip file:

- `*-theme-dark.zip`

<br />

<figure markdown="span">
  ![Dark theme login page](https://github.com/user-attachments/assets/954722fc-91e5-4087-9aa8-2ed60750752a){ width="80%" }
  <figcaption>List of Github repository files available for download</figcaption>
</figure>

<br />

Extract the files from the zip to the same paths as they are shown in the zip. You should have the following files:

!!! info inline end "Backup Data"

    It is recommended that you back up your
    current copy of ConfigServer Firewall
    before overwriting the files with the
    custom theme files.

- `/etc/csf/ui/images/*.css`
- `/usr/local/csf/lib/ConfigServer/*.pm`
- `/usr/sbin/lfd`

<br />
<br />

After you have copied over the new files from the zip, give ConfigServer Firewall a restart using the command:

```shell
sudo csf -ra
```

<br />

Once ConfigServer Firewall is restarted, you should be able to open your browser and navigate to your firewall's normal URL address and see the new theme.

<br />

<figure markdown="span">
  ![Dark theme login page](https://github.com/user-attachments/assets/aa837e8c-ef39-4e94-b446-0dfad69a3a74){ width="80%" }
  <figcaption>Dark theme login page</figcaption>
</figure>

<br />

---

<br />

## Uninstall

Currently, there is no uninstaller available for custom themes. In order to remove your custom theme, you must restore the original ConfigServer Firewall theme files that come with the official version. These are located in the following paths:

- `/etc/csf/ui/images/*.css`
- `/usr/local/csf/lib/ConfigServer/*.pm`
- `/usr/sbin/lfd`

<br />

---

<br />

