<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Federation with external identity provider (IdP)</h1>

* [Context](#context)
* [Prerequisites](#prerequisites)
  * [User accounts](#user-accounts)
  * [External IdP with OIDC](#external-idp-with-oidc)
* [Example configuration](#example-configuration)
  * [Versions](#versions)
  * [Example values](#example-values)
  * [Keycloak admin console access](#keycloak-admin-console-access)
  * [Your organizations IdP](#your-organizations-idp)
    * [Separate realm](#separate-realm)
    * [OIDC Client](#oidc-client)
  * [openDesk IdP](#opendesk-idp)

# Context

Most organizations already have an Identity and Access Management (IAM) of their own that includes an identity provider (IdP) for single-sign-on to internal or external web applications.

This document shows how to configure your organizations IdP as well as the openDesk IdP to allow account federation to support single-sign-on to openDesk based on your organization's login.

# Prerequisites

## User accounts

Beside the configuration it is required that the user accounts with the same name exist within openDesk. This prerequisite is outside the scope of this document.

We will provide additional documents regarding user provisioning in the future, so here's just an overview regarding potential scenarios:

- Manual user management
  - That is a lightweight way for testing your IdP federation setup or in case you just have a small amount of users to manage.
  - Just create and maintain you user(s) in openDesk and ensure the username in your IAM and openDesk is identical.
- User import
  - If you need to create more than just a couple of test accounts you can use the [openDesk User Importer](https://gitlab.opencode.de/bmi/opendesk/tooling/user-import) that utilizes the UDM REST API for user account creation.
  - Downsides: Managing groups and deleting accounts needs to be done manually.
- Automated Pre-provisioning:
  - Pre-provisioning users and groups including de-provisioning (deleting) accounts is the best practice as it ensures that openDesk is in sync with your organization's IAM.
  - There are at least two ways of implementing the pre-provisioning:
  - UDM REST API:
    - Build a provisioning solution by yourself using the [UDM REST API](https://docs.software-univention.de/developer-reference/5.0/en/udm/rest-api.html).
    - The API gives you full control over the contents of the IAM in order to create, update or delete users and groups.
  - Directory Connector:
    - It is based on a Python one-way directory synchronization for users and groups.
    - We will provide more details on this approach soon one the tool is made publicly available.
- Ad-hoc provisioning (AHP)
  - This feature is currently not available in the openDesk Keycloak, but there are plans by the Supplier Univention to make it available.
  - Ad-hoc provisioning creates an user account on the fly during a users first login.
  - While AHP this is a nice approach for a quick start with openDesk it has various downsides:
    - Users are just created after their first login, so you cannot find your colleagues in the openDesk apps unless they already logged in.
    - A user account would never be deactivated or deleted in openDesk.
    - Group memberships are not transferred.

## External IdP with OIDC

This document focusses on the OIDC federation between an external IdP and the openDesk IdP. It makes use of the OpenID Connect (OIDC) protocol, so your external IdP must support OIDC.

# Example configuration

## Versions

The example was tested with openDesk v0.7.0 using its integrated Keycloak v24.0.3, as external IdP we also used an openDesk deployment of the same version but created a separate realm for proper separation of the configuration.

## Example values

The following values are used in this example documentation. Please ensure when you come across such a value even if it is part of a URL hostname or path that you adapt it where needed to your setup:

- `idp.organization.tld`: hostname for your organization's IdP
- `id.opendesk.tld`: hostname for the openDesk IdP, so openDesk is obviously deployed at `opendesk.tld`
- `fed-test-idp-realm`: realm name for your organizations IdP
- `opendesk-federation-client`: OIDC client for the openDesk federation that is defined in your organizations IdP
- `auto-federate-idp`: Identifier of your organizations IdP's configuration within the openDesk Keycloak.
- `auto-federate-flow`: Identifier of the required additional login flow to be created and referenced in the openDesk Keycloak.

## Keycloak admin console access

To access the admin console of Keycloak in an openDesk deployment you need to add a route for `/admin` to the Keycloak's ingress. This is done automatically if you deploy openDesk with `debug.enabled: true` but beware that this will also cause a lot of log output across all openDesk pods.

The admin console will be available at:
- Organization's IdP: https://idp.organization.tld/admin/master/console/
- openDesk IdP: https://id.opendesk.tld/admin/master/console/

For the following configuration steps login with user `kcadmin` and grab the password from the `ums-keycloak` pod's `KEYCLOAK_ADMIN_PASSWORD` variable.

## Your organizations IdP

As we use the Keycloak of another openDesk instance to simulate your organization's IdP in this example, especially URL paths within the Keycloak might differ if you use different products.

Please let us know about your experiences or differences you came across.

### Separate realm

To not interfere with an existing configuration for our test scenario we create a separate realm:

- `Create realm` (from realm selection drop down menu in the left upper corner)
- *Realm name*: `fed-test-idp-realm`
- `Create`

### OIDC Client

If you just created the `fed-test-idp-realm` your are already in the admin screen for the realm, if not use the realm selection drop down menu in the left upper corner to switch to the realm.

- *Clients* > *Create Client*
  - Client create wizard page 1:
    - *Client type*: `OpenID Connect`
    - *Client-ID*: `opendesk-federation-client`
    - *Name*: `openDesk @ your organization` (is the descriptive text of the client that might show up in you IdP's UI and therefore should explain what the client is used for)
  - Client create wizard page 2:
    - *Client authentication*: `On`
    - *Authorization*: `Off` (default)
    - *Authentication flow*: leave defaults
	    - `Standard flow`
	    - `Direct access grants`
  - Client create wizard page 3:
    - *Valid Redirect URLs*: `https://id.opendesk.tld/realms/opendesk/broker/auto-federate-idp/endpoint`
  - When completed with *Save* you get to the detailed client configured that also needs some updates:
    - Tab *Settings* > Section *Logout settings*
      - *Front channel logout*: `Off`
      - *Back channel logout URL*: `https://id.opendesk.tld/realms/opendesk/protocol/openid-connect/logout/backchannel-logout`
    - Tab *Credentials*
      - Copy the *Client Secret* as we need it for the configuration of the openDesk IdP to be used in the openDesk IdP, as well as the *Client-ID*.

## openDesk IdP

The following configuration is taking place in the Keycloak realm `opendesk`.

- *Authentication* > *Create flow*
  - *Name*: `auto-federate-flow`
  - *Flow type*: `Basic flow`
  - *Create*
  - *Add execution*: Add `Detect existing broker user` and set it to `Required`
  - *Add step*: `Automatically set existing user` and set it to `Required`

- *Identity providers* > *User-defined* > *OpenID Connect 1.0*
  - *Alias*: `auto-federate-idp` (used in our example)
  - *Display Name*: Descriptive Name in case you do not forcefully redirect the user to the IdP that name is shown in the login screen for manual selection.
  - *Use discovery endpoint*: `On` (default)
  - *Discovery endpoint*: `https://idp.organization.tld/realms/fed-test-idp-realm/.well-known/openid-configuration` - this URL may look different if you do not use Keycloak or a different Keycloak version as IdP in your organization
    - In case the IdP metadata could not be auto-discovered you will get an error.
    - If everything is fine you can review the discovered metadata for your IdP by clicking on *Show metadata*.
  - *Client authentication*: `Client secret sent as post` (default)
  - *Client ID*: Use the client ID you took form your organization's IdP config (`opendesk-federation-client` in this example)
  - *Client Secret*: Use the secret you took form your organization's IdP config
  - When completed with *Add* you get to the detailed IdP configured that also needs some updates (you may need to open the *Advanced* section to access some settings)
    - *Back-channel logout*: `On`
    - *Disable user info*: `On`
    - *First login flow override*: `auto-federate-flow`

- In case you want to forcefully redirect all users to your organizations IdP (disabling login with local openDesk accounts):
  - *Authentication* > `2fa-browser`
    - Click on the cogwheel next to the *Identity Provider Re-director*
      - *Alias*: `auto-federate-idp`
      - *Default Identity Provider*: `auto-federate-idp`
