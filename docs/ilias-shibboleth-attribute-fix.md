<!--
SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
SPDX-License-Identifier: Apache-2.0
-->

# ILIAS Shibboleth SAML Attribute Mapping Fix

> **Date:** 2026-05-27
> **Applies to:** openDesk HRZ (`opendesk/`) and openDesk Edu (`opendesk-edu/`)

## Problem

After creating a user account (via Keycloak/openDesk portal) and logging into ILIAS via
Shibboleth SAML SSO for the first time, ILIAS showed:

```
Sorry, an error occurred. A logfile has been created which can be identified via the code "86071_9642".
```

The user was created in Keycloak but ILIAS failed during auto-provisioning.

## Root Cause

A **mismatch between SAML attribute names** in Keycloak's `ilias-saml` client and
Shibboleth's `attribute-map.xml`:

| Component | Expects | Sends |
|-----------|---------|-------|
| Keycloak SAML client | — | `firstname`, `lastname` |
| Shibboleth `attribute-map.xml` | `givenname`, `surname` | — |
| ILIAS (via HTTP headers) | `HTTP_FIRSTNAME`, `HTTP_LASTNAME` | — |

The Shibboleth `attribute-map.xml` mapped `givenname` → `FIRSTNAME` and `surname` → `LASTNAME`,
but Keycloak's SAML assertion contained attributes named `firstname` and `lastname`. Because
the attribute names didn't match:

- `HTTP_FIRSTNAME` and `HTTP_LASTNAME` were **never populated** in the Shibboleth-to-Apache
  header passthrough
- ILIAS received empty name fields during auto-provisioning
- ILIAS generated an internal error (reference code `86071_9642`)

An additional secondary issue: the ILIAS `http_path` in `ilias.ini.php` was set to `http://`
while the ingress terminates HTTPS, causing potential redirect and URL generation issues.

## Fix

### Fix 1: Correct SAML attribute names in `attribute-map.xml`

**Changed:** `opendesk-edu/helmfile/apps/ilias/templates/shibboleth-config.yaml`

```diff
- <Attribute name="givenname" ... id="FIRSTNAME"/>
- <Attribute name="surname" ... id="LASTNAME"/>
+ <Attribute name="firstname" ... id="FIRSTNAME"/>
+ <Attribute name="lastname" ... id="LASTNAME"/>
```

This makes Shibboleth look for `firstname` and `lastname` in the SAML assertion, which
matches what Keycloak's `ilias-saml` client sends (configured in
`helmfile/environments/default/functional.yaml.gotmpl`):

```yaml
protocolMappers:
  - name: "firstname"
    config:
      attribute.name: "firstname"
      user.attribute: "firstName"
  - name: "lastname"
    config:
      attribute.name: "lastname"
      user.attribute: "lastName"
```

### Fix 2: Correct `http_path` scheme

**Changed:** `opendesk-edu/helmfile/charts/ilias/values.yaml`

```diff
- http_path = http://{{ .Values.ilias.hostName }}
+ http_path = https://{{ .Values.ilias.hostName }}
```

Also fixed in the setup JSON:

```diff
- "path" : "http://{{ .Values.ilias.hostName }}"
+ "path" : "https://{{ .Values.ilias.hostName }}"
```

## Attribute Flow (After Fix)

```
Keycloak SAML Assertion
  ├── email       → Shibboleth: USERNAME   → HTTP_USERNAME   → ILIAS login/email
  ├── firstname   → Shibboleth: FIRSTNAME  → HTTP_FIRSTNAME  → ILIAS first name
  └── lastname    → Shibboleth: LASTNAME   → HTTP_LASTNAME   → ILIAS last name
```

## Files Changed

### opendesk-edu/ (and opendesk/ HRZ)

| File | Change |
|------|--------|
| `helmfile/apps/ilias/templates/shibboleth-config.yaml` | SAML attribute names in `attribute-map.xml` |
| `helmfile/charts/ilias/values.yaml` | `http_path` and `setupJson` scheme |

## Deployment

After applying these changes, redeploy the ILIAS Helm release. The Shibboleth
`attribute-map.xml` is mounted via ConfigMap and requires a pod restart to take effect.

```bash
helmfile -e default apply --selector name=ilias
# or, for a targeted restart:
kubectl -n opendesk-edu rollout restart deployment/ilias-ilias
```
