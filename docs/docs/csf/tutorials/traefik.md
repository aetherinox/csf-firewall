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

Find:

```shell
UI_IP = ""
```

<br />

Change the IP to your Docker network subnet. You MUST use the format below, which is `::IPv6:IPv4`

```shell
UI_IP = "::ffff:172.17.0.1"
```

<br />

The above change will ensure that your CSF WebUI is **not** accessible via your public IP address. We're going to allow access to it via your domain name, but add some Traefik middleware so that you must authenticate before you can access the WebUI.

<br />

Next, we can add CSF through Docker and Traefik so that it's accessible via `csf.domain.com`. Open up your Traefik's `dynamic.yml` and add the following:

=== "dynamic.yml (routers)"

    ```
    http:
      routers:
        csf-http:
          service: "csf"
          rule: "Host(`csf.domain.com`)"
          entryPoints:
            - "http"
          middlewares:
            - https-redirect@file

        csf-https:
          service: "csf"
          rule: "Host(`csf.domain.com`)"
          entryPoints:
            - "https"
          middlewares:
            - authentik@file
            - whitelist@file
            - geoblock@file
          tls:
            certResolver: cloudflare
            domains:
              - main: "domain.com"
                sans:
                  - "*.domain.com"
    ```

=== "dynamic.yml (middleware)"

    ```
    http:
      middlewares:
        authentik:
          forwardauth:
            address: http://authentik-server:9000/outpost.goauthentik.io/auth/traefik
            trustForwardHeader: true
            authResponseHeaders:
              - X-authentik-username
              - X-authentik-groups
              - X-authentik-email
              - X-authentik-name
              - X-authentik-uid
              - X-authentik-jwt
              - X-authentik-meta-jwks
              - X-authentik-meta-outpost
              - X-authentik-meta-provider
              - X-authentik-meta-app
              - X-authentik-meta-version

        geoblock:
          plugin:
            GeoBlock:
              allowLocalRequests: "true"
              allowUnknownCountries: "false"
              blackListMode: "false"
              api: https://get.geojs.io/v1/ip/country/{ip}
              ipGeolocationHttpHeaderField: "Cf-Ipcountry"
              xForwardedFor: "X-Forwarded-For"
              apiTimeoutMs: "150"
              cacheSize: "15"
              addCountryHeader: "true"
              forceMonthlyUpdate: "true"
              logAllowedRequests: "true"
              logApiRequests: "true"
              logLocalRequests: "true"
              silentStartUp: "false"
              unknownCountryApiResponse: nil
              countries:
                - US

        whitelist:
          ipAllowList:
            sourceRange:
              - "127.0.0.0/8"
            ipStrategy:
              excludedIPs:
                # Cloudflare IP List
                # These will be ignored and the next IP in line will be checked
                - 173.245.48.0/20
                - 103.21.244.0/22
                - 103.22.200.0/22
                - 103.31.4.0/22
                - 141.101.64.0/18
                - 108.162.192.0/18
                - 190.93.240.0/20
                - 188.114.96.0/20
                - 197.234.240.0/22
                - 198.41.128.0/17
                - 162.158.0.0/15
                - 104.16.0.0/13
                - 104.24.0.0/14
                - 172.64.0.0/13
                - 131.0.72.0/22
                - 2400:cb00::/32
                - 2606:4700::/32
                - 2803:f800::/32
                - 2405:b500::/32
                - 2405:8100::/32
                - 2a06:98c0::/29
                - 2c0f:f248::/32
    ```

<br />

At the bottom of the same file, we must now add a new **loadBalancer** rule under `http` -> `services`. Change the `ip` and `port` if you have different values:

```yml
http:
  routers:
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

## Next Steps

```embed
url:            ../authentik
name:           Next: Integrating Authentik
desc:           Instructions for adding Authentik middleware to ConfigServer via Traefik
image:          https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon:        https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjXOa4WN-mW3gXnIo_hEY6uAwoi2v_e02eG3TCHxSwIY70Y_OzErdaeaepXFoRa2sYx8M&usqp=CAU
favicon_size:   25
target:         same
accent:         a40547E0
```

<br />

---

<br />
