---
title: "Cheatsheet: Troubleshooting"
tags:
  - cheatsheet
  - configure
---

# Cheatsheet: Troubleshooting
The information below is a list of errors you may receive within CSF, and steps on how to correct each issue.

<br />

## Can't locate object method "new" via package "Crypt::CBC" at /usr/sbin/csf line ***
This error occurs when **Crypt::CBC** cannot be found. It is sometimes seen when executing commands such as `sudo csf -cp`.

<br />

To correct the issue, open the file `/usr/sbin/csf` in a text editor.

Locate the lines:
```conf
use ConfigServer::Sendmail;
use ConfigServer::LookUpIP qw(iplookup);
```

Add a new line with `use Crypt::CBC` as shown below:
```hl_lines="3"
use ConfigServer::Sendmail;
use ConfigServer::LookUpIP qw(iplookup);
use Crypt::CBC
```

<br />

Save the file, and re-execute your previous command which caused the error.

<br />

---

<br />

## csf[46313]: open3: exec of /sbin/ipset flush failed: No such file or directory at /usr/sbin/csf line ****.
This error occurs when you are missing the package `ipset`. Install it with the following commands:

<br />

**Debian based systems:**

```shell
sudo apt update
sudo apt-get install ipset
```

**Redhat based systems:**
```shell
sudo yum check-update
sudo yum install ipset
```

<br />

---

<br />
