---
title: "CSF: Authentik Integration"
tags:
  - configure
  - tutorials
---

# Authentik Integration
This section explains how to add Authentik as a **middleware** through [Traefik](./traefik/) so that you can secure the ConfigServer WebUI behind an authentication server.

<br />

If you are adding [Authentik](https://goauthentik.io/) as middleware in the steps above; the last thing you must do is log in to your Authentik admin panel and add a new **Provider** so that we can access the CSF WebUI via your domain.

<br />

Once you sign into the Authentik admin panel, go to the left-side navigation, select **Applications** -> **Providers**. Then at the top of the new page, click **Create**.

<br />

<p align="center"><img style="width: 40%;text-align: center;" src="https://github.com/user-attachments/assets/8fe1dfc8-bbdc-4c8c-bc5a-be5b103e7404"></p>

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/82e3f027-b058-4b3c-86db-bdc4505a4e4e"></p>

<br />

For the **provider**, select `Proxy Provider`.

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/086ae998-964f-45e3-8606-ae8a36ecf82c"></p>

<br />

Add the following provider values:

- Name: `CSF ForwardAuth`
- Authentication Flow: `default-source-authentication (Welcome to authentik!)`
- Authorization Flow: `default-provider-authorization-implicit-consent (Authorize Application)`

<br />

Select **Forward Auth (single application)**:

- External Host: `https://csf.domain.com`

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/b1d6258a-f53e-4225-a4e9-9f9b5b69b191"></p>

<br />

Once finished, click **Create**. Then on the left-side menu, select **Applications** -> **Applications**. Then at the top of the new page, click **Create**.

<br />

<p align="center"><img style="width: 40%;text-align: center;" src="https://github.com/user-attachments/assets/405fb566-0384-4345-8f07-ad52b9af9358"></p>

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/82e3f027-b058-4b3c-86db-bdc4505a4e4e"></p>

<br />

Add the following parameters:
- Name: `CSF (ConfigServer Firewall)`
- Slug: `csf`
- Group: `Administrative`
- Provider: `CSF ForwardAuth`
- Backchannel Providers: `None`
- Policy Engine Mode: `any`

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/11425a7a-f049-4434-a232-3ea2847145d7"></p>

<br />

Save, and then on the left-side menu, select **Applications** -> **Outposts**:

<br />

<p align="center"><img style="width: 40%;text-align: center;" src="https://github.com/user-attachments/assets/cb975af4-d167-44c5-8587-b366aa591716"></p>

<br />

Find your **Outpost** and edit it.

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/a349423f-6db5-431d-888e-8ba658053b2c"></p>

<br />

Move `CSF (ConfigServer Firewall)` to the right side **Selected Applications** box.

<br />

<p align="center"><img style="width: 80%;text-align: center;" src="https://github.com/user-attachments/assets/b4b882d4-8f41-4af9-b788-cef649a48d24"></p>

<br />

You should be able to access `csf.domain.com` and be prompted now to authenticate with Authentik.

<br />

---

<br />
