---
title: "CSF: Traefik Integration"
tags:
  - configure
  - tutorials
---

# Traefik Integration
This section explains how to integrate ConfigServer Firewall and Traefik so that you can access the CSF WebUI via your domain name, but restrict access to the server IP address and port.

<br />

Open `/etc/csf/csf.conf` and change `UI_IP`. This specifies the IP address that the CSF WebUI will bind to. By default, the value is empty and binds CSF's WebUI to all IPs on your server.

Find
```shell ignore
UI_IP = ""
```

<br />

Change the IP to your Docker network subnet. You MUST use the format below, which is `::IPv6:IPv4`
```shell ignore
UI_IP = "::ffff:172.17.0.1"
```

<br />

The above change will ensure that your CSF WebUI is **not** accessible via your public IP address. We're going to allow access to it via your domain name, but add some Traefik middleware so that you must authenticate before you can access the WebUI.

<br />

Next, we can add CSF through Docker and Traefik so that it's accessible via `csf.domain.com`. Open up your Traefik's `dynamic.yml` and add the following:

```yml
http:
  middlewares:
    csf-http:
      service: "csf"
      rule: "Host(`csf.{{ env "SERVER_DOMAIN" }}`)"
      entryPoints:
        - "http"
      middlewares:
        - https-redirect@file

    csf-https:
      service: "csf"
      rule: "Host(`csf.{{ env "SERVER_DOMAIN" }}`)"
      entryPoints:
        - "https"
      middlewares:
        - authentik@file
        - whitelist@file
        - geoblock@file
      tls:
        certResolver: cloudflare
        domains:
          - main: "{{ env "SERVER_DOMAIN" }}"
            sans:
              - "*.{{ env "SERVER_DOMAIN" }}"
```

<br />

At the bottom of the same file, we must now add a new **loadBalancer** rule under `http` -> `services`. Change the `ip` and `port` if you have different values:

```yml
http:
  middlewares:
    [CODE FROM ABOVE]
  services:
    csf:
      loadBalancer:
        servers:
          - url: "https://172.17.0.1:8546/"
```

<br />

With the example above, we are also going to add a few middlewares:
- [Authentik](https://goauthentik.io/)
- [IP Whitelist](https://doc.traefik.io/traefik/middlewares/http/ipwhitelist/)
- [Geographical Location Blocking](https://plugins.traefik.io/plugins/62947302108ecc83915d7781/LICENSE)

<br />

By applying the above middlewares, we can restrict what IP addresses can access your CSF WebUI, as well as add Authentik's authentication system so that you must authenticate first before getting into the CSF WebUI. These are all optional, and you can apply whatever middlewares you deem fit.

<br />

You must configure the above middleware if you have not added it to Traefik yet. This guide does not go into how to add middleware to Traefik, that information can be found at:
- https://doc.traefik.io/traefik/middlewares/overview/

<br />

Once you configure these changes in Traefik, you can restart your Traefik docker container. The command for that depends on how you set up the container. If you used `docker-compose.yml`, you can `cd` into the folder with the `docker-compose.yml` file and then execute:
```shell
docker compose down && docker compose up -d
```

<br />

---

<br />
