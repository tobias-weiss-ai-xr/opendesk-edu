<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Federation with external identity provider (IdP)

<!-- TOC -->
* [Federation with external identity provider (IdP)](#federation-with-external-identity-provider-idp)
  * [Prerequisites](#prerequisites)
    * [User accounts](#user-accounts)
    * [Manual user management](#manual-user-management)
    * [User import](#user-import)
    * [Ad-hoc provisioning](#ad-hoc-provisioning)
    * [(Automated) Pre-provisioning](#automated-pre-provisioning)
      * [Nubus Directory Importer](#nubus-directory-importer)
      * [UDM REST API](#udm-rest-api)
  * [Example configuration](#example-configuration)
    * [Example values](#example-values)
    * [Keycloak admin console access](#keycloak-admin-console-access)
    * [Upstream IdP](#upstream-idp)
      * [Separate realm](#separate-realm)
      * [OIDC Client for openDesk](#oidc-client-for-opendesk)
    * [openDesk IdP](#opendesk-idp)
    * [Manual configuration](#manual-configuration)
    * [Automated bootstrapping](#automated-bootstrapping)
<!-- TOC -->

Most organizations already have an Identity and Access Management (IAM) system with an identity provider (IdP) for single sign-on (SSO) to internal or external web applications.

This document helps in setting up your organization's IdP ("upstream IdP") and the "openDesk IdP" to enable OIDC based IdP SSO federation.

## Prerequisites

### User accounts

In addition to the configuration of the IdP SSO federation itself, it is a preprequisite for successful user login, that openDesk knows about the users performing the login. While this prerequisite is outside the scope of this document, please find various options on how to make user identities available for openDesk in the below section.

User accounts are matched between the upstream IdP and openDesk based on their username, so you have to use the same username in openDesk as in your upstream IdP.

If your upstream IdP is sending a different attribute as username or you are facing limitation in openDesk when creating a user, e.g. because your upstream IdP utilizes email addresses for usernames which is not supported by openDesk, you can update the openDesk Keycloak configuration as follows to lookup a different attribute than the username to match a logging in user. The example uses the also mandatory and unique openDesk user attribute `mailPrimaryAddress`.

The following configuration is taking place in the Keycloak realm `opendesk`.

- *Configure* > *User federation* > *ldap-provider*
  - *Username LDAP attribute*: `mailPrimaryAddress`
  - *User LDAP filter *: `(mailPrimaryAddress=*)`
  - *Save* changes

A scriptable version of the above change looks like this:

```shell
export NAMESPACE=<YOUR_NAMESPACE>
export CLUSTER_YAML=<PATH_TO_THE_FILE_CONTAINTING_YOUR_cluster.yaml.gotmpl_VALUES>

export TEMP_WORK_DIR="$(mktemp -d)"
export CLUSTER_NETWORKING_DOMAIN=$(yq '.cluster.networking.domain' ${CLUSTER_YAML})
kubectl -n ${NAMESPACE} exec ums-keycloak-0 -- /opt/keycloak/bin/kcadm.sh config credentials --server http://ums-keycloak.${NAMESPACE}.svc.${CLUSTER_NETWORKING_DOMAIN}:8080 --realm master --user kcadmin --password ${KEYCLOAK_ADMIN_PASSWORD}
export LDAP_PROVIDER_ID=$(kubectl -n ${NAMESPACE} exec ums-keycloak-0 -- /opt/keycloak/bin/kcadm.sh get components -r opendesk -q parentId=opendesk -q type=org.keycloak.storage.UserStorageProvider | jq -r '.[0].id')

kubectl -n ${NAMESPACE} exec ums-keycloak-0 -- /opt/keycloak/bin/kcadm.sh get components/${LDAP_PROVIDER_ID} -r opendesk > ${TEMP_WORK_DIR}/ldap-provider.json
cat ${TEMP_WORK_DIR}/ldap-provider.json |
  jq '.config.usernameLDAPAttribute = ["mailPrimaryAddress"]' | \
  jq '.config.customUserSearchFilter = ["(mailPrimaryAddress=*)"]' | \
  kubectl -n ${NAMESPACE} exec -i ums-keycloak-0 -- /opt/keycloak/bin/kcadm.sh update components/${LDAP_PROVIDER_ID} -r opendesk -f -

# You likely want to remove the temporary work dir afterwards
# rm -rf ${TEMP_WORK_DIR}
```

> [!note]
> The configuration change described above is a global one. In case you keep a local login to openDesk beside the SSO federated one the users also have to use their newly configured username attribute for login. But note: On openDesk's local login it is always possible to also make use of the `mailPrimaryAddress` when logging in.

### Manual user management

A lightweight option to test your IdP federation setup or if you have only a small number of users to manage.
Create and maintain your user(s) in openDesk and ensure the username in your IAM and openDesk is identical.

### User import

If you need to create more than just a couple of test accounts, you can use the [openDesk User Importer](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/user-import) that utilizes the UDM REST API for user account creation.

You have to maintain the accounts after creation manually (e.g. deletion, modifying group memberships).

### Ad-hoc provisioning

Ad-hoc provisioning creates user accounts on the fly during a user's first login. The feature is part of Nubus and the details on its configuration can be found in [the upstream documentation](https://docs.software-univention.de/keycloak-app/latest/ad-hoc-provisioning.html#ad-hoc-provisioning-adfs-configuration).

While ad-hoc provisioning is an excellent approach for a quick start with openDesk, it has some downsides:
- Users are created on their first login, so you cannot find your colleagues in the openDesk apps unless they have already logged in once.
- A user account would never be deactivated or deleted in openDesk.
- Group memberships are not transferred/updated at the moment.

### (Automated) Pre-provisioning

Pre-provisioning users and groups, including de-provisioning (deleting) accounts, is the best practice to ensure that openDesk is in sync with your organization's IAM.

#### Nubus Directory Importer

The recommended way is to use the [Nubus Directory Importer](https://github.com/univention/nubus-directory-importer). It is a Python-based one-way (LDAP/Active Directory -> openDesk) synchronization tool for users and groups. Please find more details in the [upstream documentation](https://docs.software-univention.de/nubus-kubernetes-operation/1.x/en/connect-external-iam/directory-importer.html).

> [!note]
> If you are using Microsoft Entra ID, you need Azure AD Domain Services to use the Nubus Directory Importer, because Entra ID does not expose LDAP. There is no supported direct synchronization from Entra ID (via Microsoft Graph) into openDesk’s LDAP-based user backend.

#### UDM REST API

In case the Nubus Directory Importer is not flexible enough for your use cases, you can make direct use of the [UDM REST API](https://docs.software-univention.de/developer-reference/5.0/en/udm/rest-api.html) to build a custom solution. The API gives you full control over the contents of the IAM to create, update, or delete users and groups.

## Example configuration

The following section explains how to configure the IdP federation manually in an example upstream IdP and in openDesk.

With openDesk 1.4.0 IdP federation has to be enabled as part of the deployment using the `functional.authentication.ssoFederation` section, see [`functional.yaml.gotmpl`](../../helmfile/environments/default/functional.yaml.gotmpl) for reference.

You can use the description below to configure and test the federation that can be exported and used as part of the deployment afterwards, e.g. with the following commands from within the Keycloak Pod:

```shell
# Set the variables according to your deployment first, below are just example values.
export FEDERATION_IDP_ALIAS=sso-federation-idp
export NAMESPACE=example_namespace
export CLUSTER_NETWORKING_DOMAIN=svc.cluster.local
# Authenticate with Keycloak
/opt/keycloak/bin/kcadm.sh config credentials --server http://ums-keycloak.${NAMESPACE}.${CLUSTER_NETWORKING_DOMAIN}:8080 --realm master --user ${KEYCLOAK_ADMIN} --password ${KEYCLOAK_ADMIN_PASSWORD}
# Request details of IdP configuration
/opt/keycloak/bin/kcadm.sh get identity-provider/instances/${FEDERATION_IDP_ALIAS} -r opendesk
```

### Example values

The following values are used in this example documentation. Please ensure when you come across such a value, even if it is part of a URL hostname or path, that you adapt it where needed to your setup:

- `idp.organization.tld`: hostname for your organization's IdP.
- `id.opendesk.tld`: hostname for the openDesk IdP, so openDesk is deployed at `opendesk.tld`.
- `fed-test-idp-realm`: realm name for your organization's IdP.
- `opendesk-federation-client`: OIDC client for the openDesk federation defined in your organization's IdP.
- `sso-federation-idp`: Identifier of your organization IdP's configuration within the openDesk Keycloak.
- `sso-federation-flow`: Identifier of the required additional login flow to be created and referenced in the openDesk Keycloak.

### Keycloak admin console access

To access the Keycloak admin console in an openDesk deployment, you must add a route for `/admin` to the Keycloak ingress. This is done automatically if you deploy openDesk with `debug.enabled: true`, but beware that this will also cause a lot of log output across all openDesk pods.

The admin console will be available at:
- Organization's IdP: https://idp.organization.tld/admin/master/console/
- openDesk IdP: https://id.opendesk.tld/admin/master/console/

For the following configuration steps, log in with user `kcadmin` and grab the password from the `ums-keycloak` pod's `KEYCLOAK_ADMIN_PASSWORD` variable.

### Upstream IdP

In this example, we use the Keycloak of another openDesk instance to simulate your organization's IdP. However, URL paths differ if you use another product.

Please let us know about your experiences or any differences you encountered.

#### Separate realm

To not interfere with an existing configuration for our test scenario, we create a separate realm:

- `Create realm` (from the realm selection drop-down menu in the left upper corner)
- *Realm name*: `fed-test-idp-realm`
- `Create`

#### OIDC Client for openDesk

If you just created the `fed-test-idp-realm`, you are already in the admin screen for the realm; if not, use the realm selection drop-down menu in the upper left corner to switch to the realm.

- *Clients* > *Create Client*
  - Client create wizard page 1:
    - *Client type*: `OpenID Connect`
    - *Client-ID*: `opendesk-federation-client`
    - *Name*: `openDesk @ your organization` (this is the descriptive text of the client that might show up in your IdP's UI and therefore should explain what the client is used for)
  - Client create wizard page 2:
    - *Client authentication*: `On`
    - *Authorization*: `Off` (default)
    - *Authentication flow*: leave defaults
      - `Standard flow`
      - `Direct access grants`
  - Client create wizard page 3:
    - *Valid Redirect URLs*: `https://id.opendesk.tld/realms/opendesk/broker/sso-federation-idp/endpoint`
  - When completed with *Save*, you get to the detailed client configuration that also needs some updates:
    - Tab *Settings* > Section *Logout settings*
      - *Front channel logout*: `Off`
      - *Back channel logout URL*: `https://id.opendesk.tld/realms/opendesk/protocol/openid-connect/logout/backchannel-logout`
    - Tab *Credentials*
      - Copy the *Client Secret* and the *Client-ID* as we need them to configure the openDesk IdP.

### openDesk IdP

Configuring the openDesk IdP can be done manually using the Keycloak UI (see "Keycloak admin console access" above), but the preferred way to apply the configuration is using (configuration-as-code).

Both options are described in the following section.

### Manual configuration

Ensure you have changed into the Keycloak realm `opendesk` before following the manual configuration steps described below:

- *Authentication* > *Create flow*
  - *Name*: `sso-federation-flow`
  - *Flow type*: `Basic flow`
  - *Create*
  - *Add execution*: Add `Detect existing broker user` and set it to `Required`
  - *Add step*: `Automatically set existing user` and set it to `Required`

- *Identity providers* > *User-defined* > *OpenID Connect 1.0*
  - *Alias*: `sso-federation-idp` (used in our example)
  - *Display Name*: A descriptive Name, in case you do not forcefully redirect the user to the IdP, that name is shown on the login screen for manual selection.
  - *Use discovery endpoint*: `On` (default)
  - *Discovery endpoint*: `https://idp.organization.tld/realms/fed-test-idp-realm/.well-known/openid-configuration` - this URL may look different if you do not use Keycloak or a different Keycloak version as IdP in your organization
    - You will get an error if the IdP metadata cannot be auto-discovered.
    - If everything is fine, you can review the discovered metadata for your IdP by clicking on *Show metadata*.
  - *Client authentication*: `Client secret sent as post` (default)
  - *Client ID*: Use the client ID you took from your organization's IdP config (`opendesk-federation-client` in this example)
  - *Client Secret*: Use the secret you took from your organization's IdP config
  - When completed with *Add*, you get to the detailed IdP configuration which at least needs the following update:
    - *First login flow override*: `sso-federation-flow`
    - Depending on your organizations IdP and process preferences, additional configuration may be required

- In case you want to forcefully redirect all users to your organization's IdP (disabling login with local openDesk accounts):
  - *Authentication* > `2fa-browser`
    - Click on the cogwheel next to the *Identity Provider Re-director*
      - *Alias*: `sso-federation-idp`
      - *Default Identity Provider*: `sso-federation-idp`

### Automated bootstrapping

Below is an example structure for applying the configuration.

Check `functional.authentication.ssoFederation` section from the `functional.yaml.gotmpl` for details.

```
functional:
  authentication:
    ssoFederation:
      enabled: true
      enforceFederatedLogin: false
      name: "Login with my upstream IdP"
      idpDetails:
        providerId: "oidc"
        enabled: true
        updateProfileFirstLoginMode: "on"
        trustEmail: true
        storeToken: true
        addReadTokenRoleOnCreate: false
        authenticateByDefault: false
        linkOnly: false
        config:
          userInfoUrl: "https://id.<domain>/realms/opendesk/protocol/openid-connect/userinfo"
          validateSignature: "true"
          clientId: "my-client-id"
          clientSecret: my-client-secret"
          tokenUrl: "https://id.<domain>/realms/opendesk/protocol/openid-connect/token"
          jwksUrl: "https://id.<domain>/realms/opendesk/protocol/openid-connect/certs"
          issuer: "https://id.<domain>/realms/opendesk"
          useJwksUrl: "true"
          metadataDescriptorUrl: "https://id.<domain>/realms/opendesk/.well-known/openid-configuration"
          pkceEnabled: "false"
          authorizationUrl: "https://id.<domain>/realms/opendesk/protocol/openid-connect/auth"
          clientAuthMethod: "client_secret_post"
          logoutUrl: "https://id.<domain>/realms/opendesk/protocol/openid-connect/logout"
          syncMode: "LEGACY"
          guiOrder: ""
          clientAssertionSigningAlg: ""
          loginHint: "false"
          passMaxAge: "false"
          uiLocales: "false"
          backchannelSupported: "true"
          sendIdTokenOnLogout: "true"
          sendClientIdOnLogout: "false"
          disableUserInfo: "false"
          disableNonce: "false"
          defaultScope: ""
          prompt: ""
          acceptsPromptNoneForwardFromClient: "false"
          allowedClockSkew: 0
          forwardParameters: ""
          isAccessTokenJWT: "false"
          hideOnLoginPage: "false"
          filteredByClaim: "false"
          caseSensitiveOriginalUsername: "true"
        postBrokerLoginFlowAlias: ""
```
