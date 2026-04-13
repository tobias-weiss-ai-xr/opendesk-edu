<!--
SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Backchannel Logout Design Spec

> **Created:** 2026-04-13
> **Status:** Draft

## Purpose

Design a comprehensive backchannel logout system for openDesk Edu that terminates user sessions across all connected services when a user logs out from the portal. The design uses a tiered approach, honest about which services support true backchannel logout and which rely on session timeout fallback.

## Overview

Backchannel logout is a server-to-server mechanism where Keycloak notifies registered clients that a user's session has ended, without requiring the user's browser to visit each service. This is stronger than frontchannel logout (which depends on iframes and redirects) and prevents orphaned sessions.

openDesk Edu runs a mix of OIDC and SAML clients. Upstream openDesk already configures OIDC backchannel logout for its core services. The edu stack adds SAML-only services (ILIAS, Moodle, BBB) and a long tail of applications that lack native backchannel support. This spec covers the full picture.

### Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Logout UX | Confirmation page before propagation | Prevents accidental logouts, gives users control |
| Scope | All services, tiered coverage | Honest documentation beats pretending everything works |
| Static pages | ConfigMap + ingress volume mount | Simpler than a Keycloak theme, no rebuild needed |
| SAML backchannel | Keycloak SOAP to Shibboleth SP | Built-in Keycloak feature, no SPI needed |

## Architecture

### Logout Flow

```
  User clicks "Logout"
         │
         ▼
  ┌──────────────────────┐
  │  /logout-confirm.html │  Static page served by ingress
  │  "Log out of all      │
  │   services?"          │
  │  [Log Out All]        │
  └──────────┬───────────┘
             │ User clicks [Log Out All]
             │ POST to Keycloak
             ▼
  ┌──────────────────────┐
  │     Keycloak IdP      │
  │  /realms/opendesk/    │
  │  protocol/openid-     │
  │  connect/logout       │
  └──────────┬───────────┘
             │ Keycloak propagates backchannel
             │ (parallel, async to all clients)
             │
    ┌────────┼────────┬────────────┬──────────────┐
    │        │        │            │              │
    ▼        ▼        ▼            ▼              ▼
 Tier 1    Tier 2   Tier 2     Tier 3        Tier 5
 OIDC      SAML     SAML       SAML          OIDC
 back-     SOAP     SOAP       best-effort   front-
 channel   ILIAS    Moodle     BBB           channel
 (6 svc)                        + redirect
                                        TYPO3
             │
             ▼
  ┌──────────────────────┐
  │  /logged-out.html     │  Static page with disclaimer
  │  "You have been       │
  │   logged out"         │
  │  + coverage note      │
  └──────────────────────┘

  Tier 4 services (Planka, SOGo, etc.)
  are NOT contacted. Sessions expire
  via normal timeout.
```

### Tiered Service Coverage

| Tier | Services | Method | Status |
|------|----------|--------|--------|
| **1** | Intercom, OpenCloud, Nextcloud, OX, Matrix, OpenProject, Notes, Dovecot | OIDC backchannel (`backchannel.logout.url`) | Already configured upstream |
| **2** | ILIAS, Moodle | SAML backchannel (SOAP to Shibboleth SP) | Needs config changes |
| **3** | BigBlueButton (Greenlight) | SAML backchannel via `adminUrl` | Best-effort, may not work |
| **4** | Planka, SOGo, Grommunio, Etherpad, BookStack, Zammad, LimeSurvey, F13, DrawIO, Excalidraw | None. Session timeout only | Documented as unsupported |
| **5** | TYPO3 CMS portal | OIDC frontchannel + redirect | Works today, no changes |

## Per-Service Changes

### Tier 1: OIDC Backchannel (Already Done)

No changes needed. Upstream openDesk configures these clients in the Keycloak bootstrap:

**File:** `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`

Clients with `backchannel.logout.url` already set:
- Intercom, OpenCloud, Nextcloud, OX, Matrix, OpenProject, Notes, Dovecot

Keycloak POSTs a signed `logout_token` JWT to each client's backchannel URL when the user session ends.

### Tier 2: ILIAS (SAML Backchannel)

ILIAS uses a Shibboleth SP with a SOAP endpoint already defined in its SAML metadata. The missing piece is Keycloak client configuration and the Shibboleth SP logout handler.

**What changes:**

1. Keycloak client `ilias-saml`: Set `frontchannelLogout: false`, set `adminUrl` to the ILIAS Shibboleth SP SOAP endpoint
2. Shibboleth SP config: Add a `Logout` handler with SAML2 SOAP binding to `shibboleth2.xml`

**How it works:** When Keycloak processes the logout request, it sends a SAML SOAP logout request to the `adminUrl`. The Shibboleth SP receives it, terminates the local session, and responds.

### Tier 2: Moodle (SAML Backchannel)

Moodle uses a Shibboleth SP with existing gated backchannel templates already in the repository.

**What changes:**

1. Keycloak client `moodle-saml`: Set `frontchannelLogout: false`, set `adminUrl` to Moodle's Shibboleth SP SOAP endpoint
2. Enable the feature flag `backchannelLogout.saml.moodle.enabled=true`

**Existing files (already present, just need activation):**
- `helmfile/charts/moodle/values-backchannel.yaml`
- `helmfile/apps/moodle/templates/shibboleth-sp-config.yaml`

### Tier 3: BigBlueButton (Best-Effort SAML)

BBB's Greenlight is a Rails app using SAML auth. It does not run a Shibboleth SP. Backchannel logout support is uncertain.

**What changes:**

1. Keycloak client `bbb-saml`: Keep `frontchannelLogout: true`, add `adminUrl` pointing to Greenlight's SAML endpoint
2. This is best-effort. If Greenlight doesn't handle the SOAP request, Keycloak logs a warning and continues

**Why best-effort:** Greenlight's SAML implementation may not process backchannel SOAP logout requests. The frontchannel logout stays active as fallback.

### Tier 4: Unsupported Services

These services lack any backchannel logout mechanism:

- **Planka:** No OIDC/SAML backchannel support
- **SOGo:** No backchannel logout API
- **Grommunio:** No backchannel logout API
- **Etherpad:** Session-based, no OIDC backchannel
- **BookStack:** No backchannel logout support
- **Zammad:** No backchannel logout support
- **LimeSurvey:** No backchannel logout support
- **F13:** No backchannel logout support
- **DrawIO:** No backchannel logout support
- **Excalidraw:** No backchannel logout support

**Mitigation:** Sessions expire through normal session timeout (typically 30 minutes). The `/logged-out.html` page includes a disclaimer about this.

### Tier 5: TYPO3 CMS Portal

Already uses OIDC frontchannel logout. Works without changes. The portal redirects through Keycloak's frontchannel logout flow, which triggers iframe-based logout in the TYPO3 OIDC plugin.

## Configuration Reference

### Keycloak Client: ILIAS SAML

**File:** `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`

```yaml
# In the clients list, find ilias-saml and update:
- clientId: ilias-saml
  protocol: saml
  frontchannelLogout: false
  adminUrl: "https://ilias.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
  attributes:
    saml.assertion.consumer.url.post: "https://ilias.{{ .Values.global.domain }}/Shibboleth.sso/SAML2/POST"
    logout.service.url.binding.soap.post: "https://ilias.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
```

### Keycloak Client: Moodle SAML

**File:** `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`

```yaml
- clientId: moodle-saml
  protocol: saml
  frontchannelLogout: false
  adminUrl: "https://moodle.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
  attributes:
    saml.assertion.consumer.url.post: "https://moodle.{{ .Values.global.domain }}/Shibboleth.sso/SAML2/POST"
    logout.service.url.binding.soap.post: "https://moodle.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
```

### Keycloak Client: BBB SAML

**File:** `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`

```yaml
- clientId: bbb-saml
  protocol: saml
  frontchannelLogout: true  # Keep frontchannel as fallback
  adminUrl: "https://bbb.{{ .Values.global.domain }}/saml/logout"  # Best-effort backchannel
```

### Moodle Feature Flag

**File:** `helmfile/environments/default/global.yaml.gotmpl` (or equivalent)

```yaml
backchannelLogout:
  saml:
    moodle:
      enabled: true
```

### ILIAS Shibboleth SP Logout Handler

**File:** ILIAS Shibboleth SP config `shibboleth2.xml`

```xml
<!-- Add inside <Sessions> element -->
<Handler type="Logout" location="/SLO/SOAP"
         Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
         conf:ignoreAttributes="true"/>
```

**Note:** The SOAP endpoint `/SLO/SOAP` is already referenced in the ILIAS Shibboleth SP `protocols.xml`. This adds the handler that processes incoming logout requests at that endpoint.

### Static Pages: ConfigMap

**File:** New file `helmfile/apps/ingress/templates/backchannel-logout-pages-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backchannel-logout-pages
  namespace: {{ .Values.global.namespace }}
data:
  logout-confirm.html: |
    <!-- See Static Pages section below -->
  logged-out.html: |
    <!-- See Static Pages section below -->
```

### Static Pages: Ingress Volume Mount

**File:** Update the portal ingress or shared ingress to mount the ConfigMap

```yaml
# In ingress controller or portal deployment
volumes:
  - name: logout-pages
    configMap:
      name: backchannel-logout-pages
volumeMounts:
  - name: logout-pages
    mountPath: /usr/share/nginx/html/logout
```

The ingress then serves `/logout-confirm.html` and `/logged-out.html` from this volume.

## Static Pages

### logout-confirm.html

Served at `/logout-confirm.html`. This is the first page users see when they click "Logout" anywhere in the portal.

**Purpose:** Prevent accidental logouts. Show which services will be affected. Provide a clear "Log Out All" button.

**Content requirements:**
- Heading: "Log out of all services"
- Brief text explaining what happens (sessions terminated across connected services)
- A "Log Out All" button that POSTs to Keycloak's logout endpoint
- A "Cancel" link that returns to the portal
- Branding consistent with the portal theme

**Keycloak POST target:**
```html
<form method="POST" action="https://keycloak.{{ domain }}/realms/opendesk/protocol/openid-connect/logout">
  <button type="submit">Log Out All</button>
</form>
```

The `id_token_hint` and `post_logout_redirect_uri` parameters should be included to redirect back to `/logged-out.html` after logout completes.

### logged-out.html

Served at `/logged-out.html`. This is the final page after logout propagation.

**Purpose:** Confirm logout and set expectations about coverage.

**Content requirements:**
- Heading: "You have been logged out"
- Confirmation text
- A disclaimer covering edge cases:

> "Your session has been ended on most services. Some applications (Planka, SOGo, Grommunio, Etherpad, BookStudio, Zammad, LimeSurvey, F13, DrawIO, Excalidraw) do not support immediate logout. Sessions on these services will expire automatically within 30 minutes. Closing your browser helps accelerate this process."

- A "Return to Portal" link

## Edge Cases

### Backchannel Timeout

Keycloak sends backchannel logout requests to all configured clients in parallel. If a client doesn't respond within Keycloak's internal timeout (configurable, default varies by version), Keycloak logs a warning and moves on.

**Impact:** The user's Keycloak session is still terminated. The timed-out service may retain a stale session until its own session expires.

**Mitigation:** The disclaimer on `/logged-out.html` covers this.

### Partial Logout

Some clients succeed, some fail. This is the normal case for Tier 3 (BBB) and Tier 4 services.

**Impact:** User is logged out of Keycloak and most services, but a few may retain sessions.

**Mitigation:** The disclaimer on `/logged-out.html` tells users to close their browser. Session timeouts (typically 30 minutes) handle the rest.

### Service Down During Logout

If a Tier 1 or Tier 2 service is unreachable when the user logs out, Keycloak's backchannel request fails silently (logged as warning).

**Impact:** That service retains a session. When the service comes back online, the session is still valid until timeout.

**Mitigation:** Same disclaimer. No retry mechanism is planned because the user is already gone.

### No Mobile App Concern

openDesk Edu is a browser-only platform. There are no mobile apps with their own token lifecycle. This simplifies the logout flow significantly.

### Concurrent Logouts

If a user has multiple browser tabs open and triggers logout from two tabs simultaneously, Keycloak handles this idempotently. The second logout request finds the session already terminated and returns success. No race condition.

## Limitations

### Tier 4 Services: No Backchannel Logout

The following services cannot be logged out via backchannel. Their sessions persist until natural timeout or the user explicitly logs out from each one:

| Service | Auth Method | Session Timeout |
|---------|------------|-----------------|
| Planka | OIDC | ~30 min |
| SOGo | OIDC | ~30 min |
| Grommunio | OIDC | ~30 min |
| Etherpad | API key / session | ~1 hour |
| BookStack | OIDC | ~30 min |
| Zammad | OIDC | ~30 min |
| LimeSurvey | OIDC | ~30 min |
| F13 | OIDC | ~30 min |
| DrawIO | OIDC | ~30 min |
| Excalidraw | OIDC | ~30 min |

**Why not implement custom logout endpoints?** Each of these services would require a custom reverse proxy or sidecar to intercept and propagate logout. The maintenance burden outweighs the benefit given these are secondary tools in the education context. Session timeout is the pragmatic fallback.

### BBB: Uncertain Backchannel Support

Greenlight's SAML implementation may not correctly process SOAP backchannel logout requests from Keycloak. The `adminUrl` is set as a best-effort attempt, with frontchannel logout kept as the fallback.

### Nextcloud SAML: Frontchannel Only

The `nextcloud-saml` client uses frontchannel logout. The `nextcloud` OIDC client (Tier 1) handles backchannel logout for Nextcloud. If the deployment uses the SAML client, backchannel logout won't work for Nextcloud.

## Testing Plan

### Tier 1: OIDC Backchannel Verification

1. Log in to each Tier 1 service (OpenCloud, Nextcloud, OX, Matrix, OpenProject)
2. Trigger logout from the portal
3. Verify the user is logged out of each service by attempting to access it
4. Check Keycloak logs for successful backchannel logout events

**Automation:** Existing E2E tests in `tests/playwright/backchannel-e2e.spec.js`

### Tier 2: SAML Backchannel Verification

**Moodle:**
1. Log in to Moodle via SAML
2. Verify session cookie exists
3. Trigger logout from portal
4. Verify Moodle session cookie is cleared
5. Verify accessing Moodle redirects to login

**ILIAS:**
1. Log in to ILIAS via SAML
2. Verify Shibboleth session is active
3. Trigger logout from portal
4. Verify Shibboleth session is terminated
5. Verify accessing ILIAS redirects to login

**Manual SOAP test (both):**
```bash
# Send a test SAML SOAP logout request to the SP endpoint
curl -X POST \
  -H "Content-Type: application/soap+xml" \
  -d @test-saml-logout-request.xml \
  https://moodle.example.org/Shibboleth.sso/SLO/SOAP
```

### Tier 3: BBB Verification

1. Log in to BBB via SAML
2. Trigger logout from portal
3. Check Keycloak logs: if SOAP request to BBB returns success, verify session is gone
4. If SOAP request fails or BBB ignores it, verify frontchannel logout kicks in

### Tier 5: TYPO3 CMS Portal

1. Log in to TYPO3 CMS portal
2. Trigger logout from portal
3. Verify TYPO3 session is terminated via frontchannel redirect

### Static Pages

1. Navigate to `/logout-confirm.html`, verify it renders correctly
2. Click "Log Out All", verify it POSTs to Keycloak
3. Verify redirect to `/logged-out.html` after logout
4. Verify disclaimer text is present on `/logged-out.html`

## Rollback

If backchannel logout causes issues, the rollback is straightforward since no custom code is involved, only configuration changes.

### Step 1: Revert Keycloak Client Config

For each modified client, revert to frontchannel logout:

```yaml
# Revert ilias-saml
- clientId: ilias-saml
  frontchannelLogout: true
  # Remove adminUrl or leave it, Keycloak ignores it with frontchannelLogout: true

# Revert moodle-saml
- clientId: moodle-saml
  frontchannelLogout: true
  # Remove adminUrl

# Revert bbb-saml (was already frontchannelLogout: true, just remove adminUrl)
- clientId: bbb-saml
  # Remove adminUrl
```

### Step 2: Disable Moodle Feature Flag

```yaml
backchannelLogout:
  saml:
    moodle:
      enabled: false
```

### Step 3: Remove ILIAS Logout Handler

Remove the `<Handler type="Logout">` element from ILIAS `shibboleth2.xml`.

### Step 4: Remove Static Pages (Optional)

The static pages are harmless if left in place. They can be removed by deleting the ConfigMap and updating the ingress volume mount. Leaving them causes no issues.

### Step 5: Redeploy

```bash
helmfile apply
```

The Keycloak bootstrap job updates client configurations. Services reconnect on next login.

### What Stays

- Tier 1 OIDC backchannel is upstream openDesk config. Reverting it requires changes to upstream values.
- The `/logged-out.html` and `/logout-confirm.html` pages are inert HTML. No risk if left in place.
- Session timeouts on Tier 4 services are unaffected by any of these changes.
