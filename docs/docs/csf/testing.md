---
title: Install CSF > Testing
tags:
  - install
---

# Install CSF: Testing
Before enabling and configuring CSF, it is crucial to test whether it is compatible with your server. Run the following command to initiate the test:

```shell
sudo perl /usr/local/csf/bin/csftest.pl
```

<br />

The test will check for any potential issues or conflicts. If the test completes successfully, you will see the message:

```console title="Console"
“RESULT: csf should function on this server.”
```

<br />

If there are any problems, the test will provide information on how to resolve them.

<br />

---

<br />
