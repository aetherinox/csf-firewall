---
title: Changelog
tags:
  - changelog
---

# Changelog

<p align="center" markdown="1">

![Version](https://img.shields.io/github/v/tag/Aetherinox/csf-firewall?logo=GitHub&label=version&color=ba5225)
![Downloads](https://img.shields.io/github/downloads/Aetherinox/csf-firewall/total)
![Repo Size](https://img.shields.io/github/repo-size/Aetherinox/csf-firewall?label=size&color=59702a)
![Last Commit)](https://img.shields.io/github/last-commit/Aetherinox/csf-firewall?color=b43bcc)

</p>

### <!-- md:version stable- --> 2.2.1 <small>Aug 29, 2024</small> { id="2.1.1" }

- `change`: new animated checkbox input for firewall profiles
- `change`: clicking logo in header now re-directs user to home
- `change`: enhanced login screen animations
- `change`: enhanced mobile view
- `build`: update main source release to CSF v14.21
- `build`: dark theme now compatible with CSF v14.21
- `fix`: extended sized buttons with text cutting off

<br />

### <!-- md:version stable- --> 2.2.0 <small>Aug 28, 2024</small> { id="2.1.0" }

- `feat`: added new login page to dark theme
- `change`: optimizations to load order
- `change`: updated toggle switches for various setting pages
- `change`: start migration of in-line style properties over to stylesheet
- `fix`: interface bug which existed in light theme which caused certain divs to break

<br />

### <!-- md:version stable- --> 2.1.0 <small>Aug 27, 2024</small> { id="2.1.0" }

- `feat`: add dark theme
- `feat`: add traefik integration
- `feat`: add authentik integration
- `change`: new ruleset for openvpn integration
- `change`: auto disable csf TESTING mode when patch ran
- `change`: add `-r, --report` to display status of dependencies and setup
- `fix`: openvpn ip detection
- `ci`: dark theme now included with all releases as .zip
- `ci`: auto-update /docs/ on push to repo
- `docs`: update to include traefik and authentic integration

<br />

### <!-- md:version stable- --> 2.0.0 <small>Aug 07, 2024</small> { id="2.0.0" }

- `feat`: add new patch `openvpn`
- `feat`: add new command-line arguments:
    - add `-d, --dev` for advanced logging
    - add `-f, --flush` to completely remove iptable rules
    - add `-r, --report` to display dependency stats, app information, etc.
    - add `-v, --version` to display patcher version
- `enhance`: docker patch now allows for multiple ip blocks to be whitelisted
- `refactor`: re-write of script
- `refactor`: merge all scripts into one
- `bug`: fixed issue with manual mode being disabled - #1
- `bug`: fixed error `"docker network inspect" requires at least 1 argument.` - #1
- `bug`: fixed error `invalid port/service '-j' error`
- `docs`: rewrite documentation to include better instructions
- `ci`: add workflow to automatically grab latest version of ConfigServer Firewall and append to each release

<br />

---

<br />

### <!-- md:version stable- --> 1.0.0 <small>Jun 06, 2024</small> { id="1.0.0" }

- Initial release

<br />

---

<br />