<!--
SPDX-FileCopyrightText: 2025-2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# SSO Configuration Guide / SSO-Konfigurationsleitfaden

[English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>

## English

### Overview

OpenDesk Edu uses Keycloak as the central Identity and Access Management (IAM) hub. All services authenticate through Keycloak using either OIDC (OpenID Connect) or SAML 2.0 protocols. This document describes the complete SSO topology and how to configure each service.

#### Keycloak Instance

| Parameter   | Value                                      |
|-------------|--------------------------------------------|
| URL         | `https://id.opendesk.hrz.uni-marburg.de`   |
| Realm       | `opendesk`                                 |
| Admin User  | `kcadmin` (set during bootstrap)           |
| Version     | Keycloak 22+ (via nubus/opendesk-keycloak-bootstrap) |

#### Cluster Context

| Parameter       | Value                                |
|-----------------|--------------------------------------|
| Kubernetes      | K3s v1.32.3                          |
| Ingress Class   | `haproxy`                            |
| Domain          | `*.opendesk.hrz.uni-marburg.de`       |
| Namespace       | `opendesk-edu`                       |
| CA              | Let's Encrypt (via cert-manager)     |

---

### SSO Architecture

```
                               ┌─────────────────────────────┐
                               │       Keycloak              │
                               │   id.opendesk.hrz.uni-      │
                               │   marburg.de/realms/opendesk│
                               │                             │
                               │   OIDC Provider + SAML IdP  │
                               └─────────────────────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
              ┌─────┴──────┐       ┌──────┴──────┐       ┌──────┴──────┐
              │   OIDC     │       │   SAML      │       │  oauth2-    │
              │  Direct    │       │ Shibboleth  │       │  proxy      │
              │            │       │     SP      │       │  sidecar    │
              ├────────────┤       ├─────────────┤       ├─────────────┤
              │XWiki       │       │ILIAS        │       │RStudio      │
              │OpenProject │       │Moodle       │       │ttyd         │
              │Nextcloud   │       │BigBlueButton│       │Slidev       │
              │Jitsi       │       │             │       │code-server  │
              │OpenCloud   │       │             │       │Collab Dash. │
              │Notes       │       │             │       └─────────────┘
              │Matrix      │       └─────────────┘
              │OX AppSuite │
              │SOGo        │
              │Planka      │
              │TYPO3       │
              │JupyterHub  │
              │Portal      │
              │f13         │
              │SNIpR       │
              └────────────┘
```

---

### OIDC Client Templates

#### Confidential Client (server-side apps with client secret)

Used by: Portal, XWiki, OpenProject, Nextcloud, Jitsi, OpenCloud, Notes, Matrix, OX AppSuite, SOGo, Planka, TYPO3, SNIpR, f13

```json
{
  "clientId": "opendesk-{service}",
  "protocol": "openid-connect",
  "publicClient": false,
  "standardFlowEnabled": true,
  "directAccessGrantsEnabled": false,
  "serviceAccountsEnabled": true,
  "redirectUris": ["https://{service}.opendesk.hrz.uni-marburg.de/*"],
  "webOrigins": ["https://{service}.opendesk.hrz.uni-marburg.de"],
  "attributes": {
    "access.token.lifespan": "300",
    "use.refresh.tokens": true
  }
}
```

#### Public Client (oauth2-proxy sidecar)

Used by: RStudio, ttyd, Slidev, code-server, Collab Dashboard

```json
{
  "clientId": "opendesk-{service}",
  "protocol": "openid-connect",
  "publicClient": true,
  "standardFlowEnabled": true,
  "redirectUris": [
    "https://{service}.opendesk.hrz.uni-marburg.de/*",
    "https://{service}.opendesk.hrz.uni-marburg.de/oauth2/callback"
  ]
}
```

#### SAML Client (Shibboleth SP)

Used by: ILIAS, Moodle, BigBlueButton

```xml
<md:EntityDescriptor entityID="https://{service}.opendesk.hrz.uni-marburg.de/shibboleth">
  <md:SPSSODescriptor>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:POST"
                                  Location="https://{service}.opendesk.hrz.uni-marburg.de/Shibboleth.sso/SAML2/POST"/>
  </md:SPSSODescriptor>
</md:EntityDescriptor>
```

---

### OIDC/SAML Client Registry

The following table lists all OIDC and SAML clients currently registered in the `opendesk` realm.

| #  | Client ID                      | Protocol | Type        | Service                | Redirect URI(s)                                                    |
|----|--------------------------------|----------|-------------|------------------------|--------------------------------------------------------------------|
| 1  | `opendesk-portal`              | OIDC     | Confidential| Portal                 | `https://portal.*/`                                               |
| 2  | `opendesk-matrix`              | OIDC     | Confidential| Element/Matrix Chat    | `https://chat.opendesk.hrz.uni-marburg.de/*`                      |
| 3  | `opendesk-jitsi`               | OIDC     | Confidential| Jitsi Videoconference  | `https://video.opendesk.hrz.uni-marburg.de/*`                     |
| 4  | `opendesk-xwiki`               | OIDC     | Confidential| XWiki Knowledge Base   | `https://wiki.opendesk.hrz.uni-marburg.de/*`                      |
| 5  | `opendesk-openproject`         | OIDC     | Confidential| OpenProject PM         | `https://projekte.opendesk.hrz.uni-marburg.de/*`                  |
| 6  | `opendesk-nextcloud`           | OIDC     | Confidential| Nextcloud Files        | `https://files.opendesk.hrz.uni-marburg.de/*`                     |
| 7  | `opendesk-oxappsuite`          | OIDC     | Confidential| OX App Suite Mail      | `https://mail.opendesk.hrz.uni-marburg.de/*`                      |
| 8  | `opendesk-dovecot`             | OIDC     | Confidential| Dovecot IMAP/POP       | (internal, no redirect)                                           |
| 9  | `opendesk-notes`               | OIDC     | Confidential| Notes/Impress          | `https://notes.opendesk.hrz.uni-marburg.de/*`                     |
| 10 | `opendesk-opencloud`           | OIDC     | Confidential| OpenCloud Files        | `https://opencloud.opendesk.hrz.uni-marburg.de/*`                 |
| 11 | `snipr`                        | OIDC     | Confidential| SNIpR Lecture Record.  | `https://snipr.opendesk.hrz.uni-marburg.de/*`                     |
| 12 | `snipr-lti`                    | OIDC     | Confidential| SNIpR LTI Integration  | (LTI 1.3 platform launch)                                         |
| 13 | `sogo`                         | OIDC     | Confidential| SOGo Groupware         | `https://sogo.opendesk.hrz.uni-marburg.de/*`                      |
| 14 | `typo3`                        | OIDC     | Confidential| TYPO3 CMS              | `https://cms.opendesk.hrz.uni-marburg.de/*`                       |
| 15 | `planka`                       | OIDC     | Confidential| Planka Kanban          | `https://planka.opendesk.hrz.uni-marburg.de/*`                    |
| 16 | `f13-api`                      | OIDC     | Confidential| f13 AI Services        | (audience: `f13-api`, no redirect)                                |
| 17 | `opendesk-jupyterhub`          | OIDC     | Confidential| JupyterHub Notebooks   | `https://jupyter.opendesk.hrz.uni-marburg.de/hub/oauth_callback`  |
| 18 | `opendesk-rstudio`             | OIDC     | Public      | RStudio IDE            | `https://r.opendesk.hrz.uni-marburg.de/oauth2/callback`           |
| 19 | `opendesk-ttyd`                | OIDC     | Public      | ttyd Web Terminal      | `https://term.opendesk.hrz.uni-marburg.de/oauth2/callback`        |
| 20 | `opendesk-slidev`              | OIDC     | Public      | Slidev Presentations   | `https://slides.opendesk.hrz.uni-marburg.de/oauth2/callback`      |
| 21 | `opendesk-code-server`         | OIDC     | Public      | code-server (VS Code)  | `https://code.opendesk.hrz.uni-marburg.de/oauth2/callback`        |
| 22 | `opendesk-collab-dashboard`    | OIDC     | Public      | Collab Dashboard       | `https://collab.opendesk.hrz.uni-marburg.de/oauth2/callback`      |
| 23 | `ilias` (SAML SP)              | SAML     | SP Entity   | ILIAS LMS              | `https://lms.opendesk.hrz.uni-marburg.de/Shibboleth.sso/SAML2/POST` |
| 24 | `moodle` (SAML SP)             | SAML     | SP Entity   | Moodle LMS             | `https://moodle.opendesk.hrz.uni-marburg.de/Shibboleth.sso/SAML2/POST` |
| 25 | `opendesk-bigbluebutton`       | SAML     | SP Entity   | BigBlueButton          | `https://bbb.opendesk.hrz.uni-marburg.de/auth/saml2/callback`     |
| 26 | `UMC OIDC`                     | OIDC     | Confidential| Univention Portal      | (nubus UMC integration)                                           |
| 27 | `guardian-management-api`      | OIDC     | Confidential| Guardian IAM API       | (internal, nubus)                                                 |
| 28 | `guardian-scripts`             | OIDC     | Confidential| Guardian Scripts       | (internal, nubus)                                                 |
| 29 | `guardian-ui`                  | OIDC     | Confidential| Guardian UI            | (internal, nubus)                                                 |
| 30 | `admin-cli`                    | OIDC     | Confidential| Keycloak Admin CLI     | (built-in)                                                        |
| 31 | `realm-management`             | OIDC     | Confidential| Realm Management       | (built-in)                                                        |
| 32 | `security-admin-console`       | OIDC     | Confidential| Security Admin Console | (built-in)                                                        |
| 33 | `account`                      | OIDC     | Public      | User Account Console   | (built-in)                                                        |
| 34 | `account-console`              | OIDC     | Public      | Account Console (legacy)| (built-in)                                                       |
| 35 | `opendesk-n8n`                 | OIDC     | Confidential| n8n Workflow Automation | `https://n8n.opendesk.hrz.uni-marburg.de/rest/sso/oidc/callback` |
| 36 | `opendesk-zammad`              | OIDC     | Confidential| Zammad Helpdesk        | `https://helpdesk.opendesk.hrz.uni-marburg.de/auth/openid_connect/callback` |
| 37 | `opendesk-ssp`                 | OIDC     | Confidential| Self-Service-Password  | `https://ssp.opendesk.hrz.uni-marburg.de/oauth2/callback`        |
| 38 | `opendesk-bookstack`           | OIDC     | Confidential| Bookstack Wiki         | `https://bookstack.opendesk.hrz.uni-marburg.de/oidc/callback`    |
| 39 | `opendesk-planka`              | OIDC     | Public      | Planka Kanban          | `https://planka.opendesk.hrz.uni-marburg.de/api/oauth`           |
| 40 | `opendesk-limesurvey`          | OIDC     | Public      | LimeSurvey             | `https://limesurvey.opendesk.hrz.uni-marburg.de/oauth2/callback` |
| 41 | `opendesk-drawio`              | OIDC     | Public      | Draw.io Diagrams       | `https://draw.opendesk.hrz.uni-marburg.de/oauth2/callback`       |
| 42 | `opendesk-excalidraw`          | OIDC     | Public      | Excalidraw Whiteboard  | `https://excalidraw.opendesk.hrz.uni-marburg.de/oauth2/callback` |
| 43 | `opendesk-etherpad`            | OIDC     | Public      | Etherpad Collaborative | `https://etherpad.opendesk.hrz.uni-marburg.de/oauth2/callback`   |
| 44 | `opendesk-typo3`               | OIDC     | Public      | TYPO3 CMS              | `https://typo3.opendesk.hrz.uni-marburg.de/oauth2/callback`      |

**Total: 44 registered clients** (38 custom service clients + 6 built-in Keycloak clients)

---

### Per-Service SSO Configuration Reference

#### 1. Portal

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-portal`                                            |
| Client Type       | Confidential (client-secret)                                |
| Redirect URI      | `https://portal.opendesk.hrz.uni-marburg.de/*`              |
| Auth Flow         | Authorization Code + Service Account                        |

**Chart values:**
```yaml
global:
  domain: opendesk.hrz.uni-marburg.de
  hosts:
    portal: portal
# Portal OIDC client is created by Keycloak bootstrap job;
# client secret stored in ums-keycloak-config secret
```

#### 2. Portal Consumer (Object Storage sync)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC (internal, via Keycloak service account)               |
| Client ID         | `opendesk-portal` (shared with portal)                     |
| Auth Method       | Client Credentials Grant (service account)                  |

---

#### 3. XWiki (Knowledge Base)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-xwiki`                                             |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://wiki.opendesk.hrz.uni-marburg.de/*`                |
| Scope             | `openid,opendesk-xwiki-scope`                               |

**Chart values:**
```yaml
# In xwiki.properties (oidc-config.php equivalent)
oidc.clientid: "opendesk-xwiki"
oidc.provider: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk"
oidc.scope: "openid,opendesk-xwiki-scope"
oidc.secret: "<client-secret>"
oidc.endpoint.token.auth_method: "client_secret_basic"
oidc.user.nameFormater: "${oidc.user.opendesk_username._clean._lowerCase}"
```

---

#### 4. OpenProject (Project Management)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-openproject`                                       |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://projekte.opendesk.hrz.uni-marburg.de/*`            |
| Scope             | `[openid,opendesk-openproject-scope]`                       |

**Chart values:**
```yaml
openproject:
  oidc:
    enabled: true
    identifier: "opendesk-openproject"
    provider: "keycloak"
    scope: "[openid,opendesk-openproject-scope]"
    secret: "<client-secret>"
    attribute_map:
      login: "opendesk_username"
      admin: "openproject_admin"
environment:
  OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ISSUER: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk"
  OPENPROJECT_OMNIAUTH__DIRECT__LOGIN__PROVIDER: "keycloak"
```

---

#### 5. Nextcloud (File Sync & Share)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-nextcloud`                                         |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://files.opendesk.hrz.uni-marburg.de/*`               |
| Scope             | `openid,opendesk-nextcloud-scope`                           |

**Chart values:**
```yaml
# Nextcloud OIDC app configuration
oidc:
  provider-url: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk"
  client-id: "opendesk-nextcloud"
  client-secret: "<client-secret>"
  scope: "openid email profile opendesk-nextcloud-scope"
```

---

#### 6. Jitsi (Videoconference)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC + JWT (hybrid)                                        |
| Client ID         | `opendesk-jitsi`                                             |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://video.opendesk.hrz.uni-marburg.de/*`               |

**Chart values:**
```yaml
settings:
  keycloakClientId: "opendesk-jitsi"
  keycloakRealm: "opendesk"
  jwtAppSecret: "<jwt-secret>"
```

---

#### 7. OpenCloud (Next-Gen File Sync)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-opencloud`                                         |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://opencloud.opendesk.hrz.uni-marburg.de/*`           |

**Chart values:**
```yaml
oidc:
  issuer: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk"
  clientId: "opendesk-opencloud"
  clientSecret: "<client-secret>"
  autoProvisionAccounts: "true"
  roleAssignmentDriver: "oidc"
  rewriteWellknown: "true"
  userOidcClaim: "sub"
  userCs3Claim: "sub"
```

---

#### 8. Notes / Impress (Collaborative Notes)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-notes`                                             |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://notes.opendesk.hrz.uni-marburg.de/*`               |
| Scope             | `openid opendesk-notes-scope`                               |

**Chart values:**
```yaml
backend:
  configuration:
    oidc:
      enabled: true
      rpClientId: "opendesk-notes"
      rpClientSecret: "<client-secret>"
      rpScopes: "openid opendesk-notes-scope"
      loginRedirectUrl: "https://notes.opendesk.hrz.uni-marburg.de"
      redirectAllowedHosts: "https://notes.opendesk.hrz.uni-marburg.de/*"
```

---

#### 9. Element / Matrix (Chat)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-matrix`                                            |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://chat.opendesk.hrz.uni-marburg.de/*`                |
| Scope             | `openid,opendesk-matrix-scope`                              |

**Chart values:**
```yaml
# Managed by opendesk-keycloak-bootstrap
# Matrix User Verification Service handles token exchange
```

---

#### 10. OX App Suite (Mail & Groupware)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-oxappsuite`                                        |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://mail.opendesk.hrz.uni-marburg.de/*`                |
| Scope             | `openid,opendesk-oxappsuite-scope`                          |

**Chart values:**
```yaml
# OIDC managed by opendesk-keycloak-bootstrap;
# OX middleware handles token introspection
```

---

#### 11. Dovecot (IMAP/POP3)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `opendesk-dovecot`                                           |
| Client Type       | Confidential                                                |
| Redirect URI      | (internal, no HTTP redirect)                                |
| Scope             | `openid,opendesk-dovecot-scope`                             |

**Chart values:**
```yaml
# Dovecot uses OIDC for SASL/XOAUTH2 authentication
# Managed by opendesk-keycloak-bootstrap
```

---

#### 12. SOGo (Groupware)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `sogo`                                                       |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://sogo.opendesk.hrz.uni-marburg.de/*`                |
| Scope             | `openid profile email`                                      |

**Chart values:**
```yaml
sogo:
  oidc:
    enabled: true
    configUrl: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration"
    clientId: "sogo"
    clientSecret: "<client-secret>"
    scope: "openid profile email"
```

---

#### 13. TYPO3 (CMS)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `typo3`                                                      |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://cms.opendesk.hrz.uni-marburg.de/typo3/index.php?loginProvider=1537648589` |
| Scope             | `openid profile email`                                      |

**Chart values:**
```yaml
# OIDC config is generated as ConfigMap typo3-oidc-config
oidcClientKey: "typo3"
oidcClientSecret: "<client-secret>"
oidcScopes: "openid profile email"
oidcRedirectUri: "https://cms.opendesk.hrz.uni-marburg.de/typo3/index.php?loginProvider=1537648589"
```

---

#### 14. Planka (Kanban Board)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `planka` (default) / `opendesk-planka`                      |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://planka.opendesk.hrz.uni-marburg.de/*`              |
| Scope             | `openid profile email`                                      |

**Chart values:**
```yaml
planka:
  oidc:
    clientId: "planka"
    authEndpoint: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/auth"
    tokenEndpoint: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/token"
    userinfoEndpoint: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/userinfo"
    scope: "openid profile email"
```

---

#### 15. SNIpR (Lecture Recording)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `snipr` (SSO) + `snipr-lti` (LTI 1.3)                      |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://snipr.opendesk.hrz.uni-marburg.de/*`               |

**Chart values:**
```yaml
snipr:
  sso:
    keycloak:
      realm: "opendesk"
      clientId: "snipr"
  lti:
    enabled: true
    keycloak:
      clientId: "snipr-lti"
```

---

#### 16. f13 (AI Services)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC                                                        |
| Client ID         | `f13-api`                                                   |
| Client Type       | Confidential                                                |
| Auth Method       | Client Credentials + JWT Bearer                             |

**Chart values:**
```yaml
authentication:
  keycloakBaseUrl: "https://id.opendesk.hrz.uni-marburg.de"
  keycloakRealm: "opendesk"
  audience: "f13-api"
```

---

#### 17. JupyterHub (Notebooks)

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC (Generic OAuthenticator)                               |
| Client ID         | `opendesk-jupyterhub`                                        |
| Client Type       | Confidential                                                |
| Redirect URI      | `https://jupyter.opendesk.hrz.uni-marburg.de/hub/oauth_callback` |
| Scope             | `openid email profile`                                      |

**Chart values:**
```yaml
hub:
  config:
    GenericOAuthenticator:
      client_id: "opendesk-jupyterhub"
      client_secret: "<client-secret>"
      oauth_callback_url: "https://jupyter.opendesk.hrz.uni-marburg.de/hub/oauth_callback"
      authorize_url: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/auth"
      token_url: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/token"
      userdata_url: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/userinfo"
    JupyterHub:
      authenticator_class: "oauthenticator.generic.GenericOAuthenticator"
```

---

#### 18. Collab Services (oauth2-proxy sidecar)

The following services use the oauth2-proxy sidecar pattern (identical configuration):

- **RStudio** → `https://r.opendesk.hrz.uni-marburg.de`
- **ttyd** → `https://term.opendesk.hrz.uni-marburg.de`
- **Slidev** → `https://slides.opendesk.hrz.uni-marburg.de`
- **code-server** → `https://code.opendesk.hrz.uni-marburg.de`
- **Collab Dashboard** → `https://collab.opendesk.hrz.uni-marburg.de`

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | OIDC (via oauth2-proxy v7.6.0)                             |
| Client ID         | `opendesk-{service}` (public client)                       |
| Client Type       | Public (no client secret needed)                            |
| Redirect URI      | `https://{service}.opendesk.hrz.uni-marburg.de/oauth2/callback` |
| Scope             | `openid email profile`                                      |

**Chart values:**
```yaml
oauth2:
  enabled: true
  provider: "keycloak-oidc"
  clientId: "opendesk-{service}"
  oidcIssuerUrl: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk"
  cookieSecret: "<32-hex-char-stable-secret>"
```

**Internal ports:**
| Service           | Port  |
|-------------------|-------|
| RStudio           | 8787  |
| ttyd              | 7681  |
| Slidev            | 80    |
| code-server       | 8080  |
| Collab Dashboard  | 80    |

---

#### 19. ILIAS (LMS) — SAML

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | SAML 2.0 (via Shibboleth SP)                               |
| SP Entity ID      | `https://lms.opendesk.hrz.uni-marburg.de/shibboleth`        |
| ACS URL           | `https://lms.opendesk.hrz.uni-marburg.de/Shibboleth.sso/SAML2/POST` |
| IdP Metadata      | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/saml/descriptor` |

**Chart values:**
```yaml
# Shibboleth SP configuration (ConfigMap)
shibboleth:
  sp:
    host: "lms.opendesk.hrz.uni-marburg.de"
    entityID: "https://lms.opendesk.hrz.uni-marburg.de/shibboleth"
  idp:
    metadataProvider: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/saml/descriptor"
```

---

#### 20. Moodle (LMS) — SAML

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | SAML 2.0 (via Shibboleth SP)                               |
| SP Entity ID      | `https://moodle.opendesk.hrz.uni-marburg.de/shibboleth`     |
| ACS URL           | `https://moodle.opendesk.hrz.uni-marburg.de/Shibboleth.sso/SAML2/POST` |
| IdP Metadata      | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/saml/descriptor` |

**Chart values:**
```yaml
shibboleth:
  enabled: true
  sp:
    host: "moodle.opendesk.hrz.uni-marburg.de"
    entityID: "https://moodle.opendesk.hrz.uni-marburg.de/shibboleth"
  idp:
    metadataProvider: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/saml/descriptor"
```

---

#### 21. BigBlueButton (Virtual Classroom) — SAML

| Parameter         | Value                                                       |
|-------------------|-------------------------------------------------------------|
| Protocol          | SAML 2.0 (via Greenlight/BoldChat)                         |
| SP Entity ID      | `https://bbb.opendesk.hrz.uni-marburg.de/shibboleth`        |
| ACS URL           | `https://bbb.opendesk.hrz.uni-marburg.de/auth/saml2/callback` |
| IdP SSO URL       | `https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/saml` |

**Chart values:**
```yaml
bigbluebutton:
  greenlight:
    default_registration: "saml"
    saml:
      idp_entityId: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk"
      idp_sso_target_url: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/saml"
      sp_entityId: "https://bbb.opendesk.hrz.uni-marburg.de/shibboleth"
boldchat:
  params:
    assertion_consumer_service_url: "https://bbb.opendesk.hrz.uni-marburg.de/auth/saml2/callback"
    sp_entity_id: "https://bbb.opendesk.hrz.uni-marburg.de/shibboleth"
    idp_metadata_url: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/saml/descriptor"
```

---

### Keycloak Admin CLI Commands

#### Prerequisites

Access to the Keycloak Admin CLI requires authentication. Use the pod-based `kcadm.sh` or direct API:

```bash
# Get admin token
TOKEN=$(curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=kcadmin" \
  -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')
```

#### List All Clients

```bash
# Using API
curl -s -X GET "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.[].clientId'
```

#### Create an OIDC Confidential Client

```bash
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "opendesk-new-service",
    "protocol": "openid-connect",
    "publicClient": false,
    "standardFlowEnabled": true,
    "serviceAccountsEnabled": true,
    "redirectUris": ["https://new-service.opendesk.hrz.uni-marburg.de/*"],
    "webOrigins": ["https://new-service.opendesk.hrz.uni-marburg.de"]
  }'
```

#### Get Client Secret

```bash
# Get client UUID first
CLIENT_UUID=$(curl -s -X GET "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients?clientId=opendesk-new-service" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')

# Regenerate secret
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients/${CLIENT_UUID}/client-secret" \
  -H "Authorization: Bearer ${TOKEN}"
```

#### Create an OIDC Public Client (oauth2-proxy)

```bash
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "opendesk-new-tool",
    "protocol": "openid-connect",
    "publicClient": true,
    "standardFlowEnabled": true,
    "redirectUris": [
      "https://new-tool.opendesk.hrz.uni-marburg.de/*",
      "https://new-tool.opendesk.hrz.uni-marburg.de/oauth2/callback"
    ]
  }'
```

#### Register a SAML Client (SP)

```bash
# Create SAML client
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "https://new-sp.opendesk.hrz.uni-marburg.de/shibboleth",
    "protocol": "saml",
    "attributes": {
      "saml.assertion.signature": "true",
      "saml.authnstatement": "true",
      "saml.client.signature": "true",
      "saml.encrypt": "false",
      "saml.force.post.binding": "true",
      "saml.server.signature": "true",
      "saml.signature.algorithm": "RSA_SHA256"
    }
  }'
```

#### Delete a Client

```bash
CLIENT_UUID=$(curl -s -X GET "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients?clientId=opendesk-stale-service" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')
curl -s -X DELETE "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients/${CLIENT_UUID}" \
  -H "Authorization: Bearer ${TOKEN}"
```

#### Create Client Scope (for access control)

```bash
# Create scope
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/client-scopes" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "opendesk-new-scope",
    "protocol": "openid-connect",
    "attributes": {
      "include.in.token.scope": "true"
    }
  }'

# Add custom protocol mapper to scope
SCOPE_UUID=$(curl -s -X GET "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/client-scopes?name=opendesk-new-scope" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')

curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/client-scopes/${SCOPE_UUID}/protocol-mappers/models" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "opendesk_useruuid",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-usermodel-attribute-mapper",
    "config": {
      "user.attribute": "entryUUID",
      "claim.name": "opendesk_useruuid",
      "id.token.claim": "true",
      "access.token.claim": "true",
      "userinfo.token.claim": "true",
      "jsonType.label": "String"
    }
  }'
```

#### Add Protocol Mapper to Existing Client

```bash
CLIENT_UUID=$(curl -s -X GET "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients?clientId=opendesk-xwiki" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')

curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/clients/${CLIENT_UUID}/protocol-mappers/models" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "opendesk_useruuid",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-usermodel-attribute-mapper",
    "config": {
      "user.attribute": "entryUUID",
      "claim.name": "opendesk_useruuid",
      "id.token.claim": "true",
      "access.token.claim": "true",
      "userinfo.token.claim": "true",
      "jsonType.label": "String"
    }
  }'
```

---

### Standard Protocol Mappers

All OIDC clients use the following standard protocol mappers:

| Mapper Name         | Claim Name           | LDAP Attribute | Description                  |
|---------------------|----------------------|----------------|------------------------------|
| `email`             | `email`              | `mail`         | Email address                |
| `given name`        | `given_name`         | `firstName`    | First name                   |
| `family name`       | `family_name`        | `lastName`     | Last name                    |
| `opendesk_useruuid` | `opendesk_useruuid`  | `entryUUID`    | Persistent user UUID         |
| `opendesk_username` | `opendesk_username`  | `uid`          | LDAP username                |

Services with custom scopes (XWiki, Nextcloud, Matrix, OpenProject, OX AppSuite, Jitsi, Notes, Dovecot, SNIpR, OpenCloud) include additional mappers for their specific needs.

---

### Testing Procedures

#### 1. Quick Connectivity Test

```bash
# Verify Keycloak is reachable and realm exists
curl -s https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/.well-known/openid-configuration \
  | jq '.issuer'
# Expected: "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk"
```

#### 2. Test OIDC Login Flow (any service)

```bash
# 1. Initiate auth request (outputs redirect URL)
AUTH_URL="https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/auth?\
client_id=opendesk-portal&\
redirect_uri=https://portal.opendesk.hrz.uni-marburg.de/&\
response_type=code&\
scope=openid+email+profile&\
state=test123"

echo "Open in browser: $AUTH_URL"
```

#### 3. Test Token Endpoint

```bash
# Exchange auth code for tokens (requires a valid code from step 2)
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=opendesk-portal" \
  -d "client_secret=<portal-client-secret>" \
  -d "code=<auth-code>" \
  -d "redirect_uri=https://portal.opendesk.hrz.uni-marburg.de/"
```

#### 4. Test Service Account (Client Credentials)

```bash
# Get token using client credentials (machine-to-machine)
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=opendesk-portal" \
  -d "client_secret=<portal-client-secret>"
```

#### 5. Introspect Token

```bash
TOKEN="<access-token>"
curl -s -X POST "https://id.opendesk.hrz.uni-marburg.de/realms/opendesk/protocol/openid-connect/token/introspect" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=${TOKEN}" \
  -d "client_id=opendesk-portal" \
  -d "client_secret=<portal-client-secret>"
```

#### 6. Test SAML Login (ILIAS/Moodle/BBB)

Open the following URL in a browser:

```
https://lms.opendesk.hrz.uni-marburg.de/Shibboleth.sso/Login?target=https://lms.opendesk.hrz.uni-marburg.de/
```

This triggers SAML authentication: the Shibboleth SP redirects to Keycloak's SAML IdP endpoint, which performs authentication and returns a SAML assertion.

#### 7. Verify User Attributes After Login

```bash
# Get user UUID from Keycloak
USER_UUID=$(curl -s -X GET "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/users?username=testuser" \
  -H "Authorization: Bearer ${TOKEN}" | jq -r '.[0].id')

# Get user details
curl -s -X GET "https://id.opendesk.hrz.uni-marburg.de/admin/realms/opendesk/users/${USER_UUID}" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.attributes'
```

#### 8. Full Smoke Test

```bash
# Run the repository's smoke test suite
./scripts/smoke-test.sh opendesk.hrz.uni-marburg.de <ingress-ip>

# Expected results:
# - OIDC services → HTTP 302 (redirect to Keycloak)
# - SAML services → HTTP 200 (Shibboleth discovery page or login)
# - Public services → HTTP 200 (landing page)
```

---

### Troubleshooting

| Symptom                          | Likely Cause                                     | Resolution                                              |
|----------------------------------|--------------------------------------------------|---------------------------------------------------------|
| `401 Unauthorized`               | Expired/revoked token                            | Refresh token or re-authenticate                        |
| `redirect_uri_mismatch`          | Redirect URI not registered in Keycloak client   | Check client's `redirectUris` match exactly             |
| `invalid_client`                 | Wrong client ID or secret                        | Verify credentials in chart values vs Keycloak console  |
| `access_denied`                  | User lacks role/scope for service                | Check user's group membership and role assignments      |
| SAML `No authn context`          | SP metadata not matching IdP expectations        | Verify ACS URL, entity ID, and signing certificates     |
| SAML `Signature validation failed`| Key mismatch between SP and IdP                 | Export/import correct SAML signing keys                 |
| oauth2-proxy `502 Bad Gateway`   | Upstream port mismatch                           | Verify `--upstream=http://127.0.0.1:{PORT}` matches app |
| oauth2-proxy login loop          | Cookie secret changed                            | Set stable `--cookie-secret` across restarts            |

---

### Related Documentation

- [eduGAIN Attribute Mapping](./keycloak-edugain-attributes.md)
- [Shibboleth IdP Integration](./shibboleth-idp-integration.md)
- [DFN-AAI Federation Guide](./dfn-aai-federation.md)
- [OAuth2-Proxy Configuration](./oauth2-proxy-config.md)
- [User Provisioning](./user-provisioning.md)
- [Production Deployment](./production-deployment.md)

---

<a name="deutsch"></a>

## Deutsch

### Überblick

OpenDesk Edu verwendet Keycloak als zentrales Identitäts- und Zugriffsmanagement (IAM). Alle Dienste authentifizieren sich über Keycloak mittels OIDC (OpenID Connect) oder SAML 2.0. Dieses Dokument beschreibt die vollständige SSO-Topologie und die Konfiguration jedes Dienstes.

### Keycloak-Instanz

| Parameter   | Wert                                        |
|-------------|---------------------------------------------|
| URL         | `https://id.opendesk.hrz.uni-marburg.de`    |
| Realm       | `opendesk`                                  |
| Admin-Benutzer | `kcadmin`                               |

### Cluster-Kontext

| Parameter       | Wert                                  |
|-----------------|---------------------------------------|
| Kubernetes      | K3s v1.32.3                           |
| Ingress-Klasse  | `haproxy`                             |
| Domain          | `*.opendesk.hrz.uni-marburg.de`       |
| Namespace       | `opendesk-edu`                        |

Die englische Version dieses Dokuments enthält die vollständige Referenz aller registrierten Clients (34 insgesamt), detaillierte Konfigurationswerte pro Dienst, Keycloak Admin CLI-Befehle und Testprozeduren. Bitte konsultieren Sie den englischen Abschnitt für alle technischen Details.
