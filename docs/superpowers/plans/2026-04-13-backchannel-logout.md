# Backchannel Logout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Configure backchannel logout across all SAML clients (ILIAS, Moodle, BBB) and add static logout confirmation/result pages served by the existing static files infrastructure.

**Architecture:** Keycloak sends SAML SOAP logout requests to Shibboleth SP endpoints on ILIAS and Moodle (Tier 2). BBB gets a best-effort adminUrl with frontchannel kept as fallback (Tier 3). Two static HTML pages (logout-confirm, logged-out) are served by the existing `opendesk-static-files` nginx deployment under the `static.{{ domain }}` host.

**Tech Stack:** Helmfile, Kubernetes YAML, Gotemplate, SAML 2.0 SOAP, Shibboleth SP XML config

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` | Modify (lines 797-972) | Keycloak SAML client configs for ILIAS, Moodle, BBB |
| `helmfile/apps/ilias/templates/shibboleth-config.yaml` | Modify (line 34) | Add SOAP logout handler to ILIAS Shibboleth SP |
| `helmfile/environments/default/global.yaml.gotmpl` | Modify (after line 105) | Moodle backchannel feature flag |
| `helmfile/apps/opendesk-services/values-opendesk-static-files.yaml.gotmpl` | Modify (after line 98) | Static logout pages as nginx-served assets |

No new files are created. All changes modify existing files.

### Dependencies

```
Task 1 (ILIAS Keycloak) ─────────┐
Task 2 (Moodle Keycloak) ─────────┼── No interdependencies, can run in any order
Task 3 (BBB Keycloak) ────────────┘
Task 4 (ILIAS Shibboleth SP) ───── Depends on Task 1 (adminUrl must match)
Task 5 (Moodle feature flag) ───── Depends on Task 2 (Keycloak client must be ready)
Task 6 (Static logout pages) ───── Independent
Task 7 (Verify & commit) ───────── Depends on all above
```

---

### Task 1: ILIAS SAML Keycloak Client Configuration

**Files:**
- Modify: `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` (lines 797-853)

The ILIAS SAML client needs three changes: flip `frontchannelLogout` to false, replace the `adminUrl` with the SOAP endpoint, and swap `frontchannel.logout.url` for `logout.service.url.binding.soap.post`. Note: ILIAS uses subdomain `lms` not `ilias`.

- [x] **Step 1: Update ILIAS SAML client in Keycloak bootstrap**

Open `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`.

At line 805, change:
```yaml
        adminUrl: "https://lms.opendesk.example.com"
```
to:
```yaml
        adminUrl: "https://lms.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
```

At line 807, change:
```yaml
        frontchannelLogout: true
```
to:
```yaml
        frontchannelLogout: false
```

At line 820, change:
```yaml
          frontchannel.logout.url: "https://lms.opendesk.example.com/Shibboleth.sso/Logout"
```
to:
```yaml
          logout.service.url.binding.soap.post: "https://lms.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
```

Also update `redirectUris` and `rootUrl` at lines 802-804 to use templated domains:
```yaml
        redirectUris:
          - "https://lms.{{ .Values.global.domain }}/*"
        rootUrl: "https://lms.{{ .Values.global.domain }}"
```

- [x] **Step 2: Verify with helmfile template**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "ilias-saml" -Context 5`
Expected: The rendered YAML shows `frontchannelLogout: false`, the SOAP adminUrl, and `logout.service.url.binding.soap.post` attribute.

- [x] **Step 3: Commit**

```bash
git add helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl
git commit -m "feat(keycloak): configure ILIAS SAML client for backchannel logout

Set frontchannelLogout to false, point adminUrl to Shibboleth SOAP
endpoint, replace frontchannel.logout.url with SOAP binding attribute."
```

---

### Task 2: Moodle SAML Keycloak Client Configuration

**Files:**
- Modify: `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` (lines 856-912)

Same pattern as ILIAS: flip to backchannel, update adminUrl, swap the attribute. Moodle uses subdomain `moodle`.

- [x] **Step 1: Update Moodle SAML client in Keycloak bootstrap**

Open `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`.

At line 864, change:
```yaml
        adminUrl: "https://moodle.opendesk.example.com"
```
to:
```yaml
        adminUrl: "https://moodle.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
```

At line 866, change:
```yaml
        frontchannelLogout: true
```
to:
```yaml
        frontchannelLogout: false
```

At line 879, change:
```yaml
          frontchannel.logout.url: "https://moodle.opendesk.example.com/Shibboleth.sso/Logout"
```
to:
```yaml
          logout.service.url.binding.soap.post: "https://moodle.{{ .Values.global.domain }}/Shibboleth.sso/SLO/SOAP"
```

Also update `redirectUris` and `rootUrl` at lines 861-863 to use templated domains:
```yaml
        redirectUris:
          - "https://moodle.{{ .Values.global.domain }}/*"
        rootUrl: "https://moodle.{{ .Values.global.domain }}"
```

- [x] **Step 2: Verify with helmfile template**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "moodle-saml" -Context 5`
Expected: The rendered YAML shows `frontchannelLogout: false`, the SOAP adminUrl, and `logout.service.url.binding.soap.post` attribute.

- [x] **Step 3: Commit**

```bash
git add helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl
git commit -m "feat(keycloak): configure Moodle SAML client for backchannel logout

Set frontchannelLogout to false, point adminUrl to Shibboleth SOAP
endpoint, replace frontchannel.logout.url with SOAP binding attribute."
```

---

### Task 3: BBB SAML Keycloak Client Configuration

**Files:**
- Modify: `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` (lines 915-972)

BBB's Greenlight does not run a Shibboleth SP. Keep `frontchannelLogout: true` as fallback, update `adminUrl` to point to Greenlight's SAML logout endpoint, and fix the wrong `frontchannel.logout.url` that currently points at a nonexistent Shibboleth endpoint.

- [x] **Step 1: Update BBB SAML client in Keycloak bootstrap**

Open `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`.

At line 924, change:
```yaml
        adminUrl: "https://bbb.opendesk.example.com"
```
to:
```yaml
        adminUrl: "https://bbb.{{ .Values.global.domain }}/saml/logout"
```

At line 939, change:
```yaml
          frontchannel.logout.url: "https://bbb.opendesk.example.com/Shibboleth.sso/Logout"
```
to:
```yaml
          frontchannel.logout.url: "https://bbb.{{ .Values.global.domain }}/saml/logout"
```

Keep `frontchannelLogout: true` at line 926 unchanged.

Also update `redirectUris` and `rootUrl` at lines 920-923 to use templated domains:
```yaml
        redirectUris:
          - "https://bbb.{{ .Values.global.domain }}/*"
          - "https://bbb.{{ .Values.global.domain }}/auth/saml2/callback"
        rootUrl: "https://bbb.{{ .Values.global.domain }}"
```

- [x] **Step 2: Verify with helmfile template**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "bbb-saml" -Context 5`
Expected: The rendered YAML shows `frontchannelLogout: true` (unchanged), adminUrl pointing to `/saml/logout`, and `frontchannel.logout.url` also pointing to `/saml/logout`.

- [x] **Step 3: Commit**

```bash
git add helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl
git commit -m "feat(keycloak): update BBB SAML client adminUrl for best-effort backchannel

Point adminUrl and frontchannel.logout.url to Greenlight SAML logout.
Keep frontchannelLogout true as fallback since Greenlight may not
handle SOAP backchannel requests."
```

---

### Task 4: ILIAS Shibboleth SP Logout Handler

**Files:**
- Modify: `helmfile/apps/ilias/templates/shibboleth-config.yaml` (line 34, inside `<Sessions>` block)

The ILIAS Shibboleth SP has the SOAP binding defined in `protocols.xml` (line 149: `/SLO/SOAP`) but no `<Handler>` to process incoming SOAP logout requests. Add one inside the `<Sessions>` element.

- [x] **Step 1: Add SOAP logout handler to ILIAS Shibboleth SP config**

Open `helmfile/apps/ilias/templates/shibboleth-config.yaml`.

After line 34 (`<Handler type="DiscoveryFeed" Location="/DiscoFeed"/>`), before the closing `</Sessions>` tag on line 35, insert:

```xml
          <Handler type="Logout" Location="/SLO/SOAP"
                   Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"/>
```

The full `<Sessions>` block should now read:

```xml
        <Sessions lifetime="28800" timeout="3600" relayState="ss:mem"
                  checkAddress="false" handlerSSL="true" cookieProps="; path=/; HttpOnly; Secure">

          <SSO entityID="https://id.opendesk.example.com/realms/opendesk" ECP="true" authnRequestsSigned="true">
            SAML2
          </SSO>

          <Logout>SAML2</Logout>
          <Handler type="MetadataGenerator" Location="/Metadata" signing="true"/>
          <Handler type="Status" Location="/Status" acl="127.0.0.1"/>
          <Handler type="Session" Location="/Session" showAttributeValues="false"/>
          <Handler type="DiscoveryFeed" Location="/DiscoFeed"/>
          <Handler type="Logout" Location="/SLO/SOAP"
                   Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"/>
        </Sessions>
```

- [x] **Step 2: Verify with helmfile template**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "SLO/SOAP" -Context 2`
Expected: The rendered ILIAS Shibboleth ConfigMap contains the new `<Handler type="Logout">` element with SOAP binding inside the `<Sessions>` block.

- [x] **Step 3: Commit**

```bash
git add helmfile/apps/ilias/templates/shibboleth-config.yaml
git commit -m "feat(ilias): add SAML SOAP logout handler to Shibboleth SP

Add Handler element for /SLO/SOAP with SAML 2.0 SOAP binding so
Keycloak can send backchannel logout requests to the ILIAS SP."
```

---

### Task 5: Moodle Backchannel Feature Flag

**Files:**
- Modify: `helmfile/environments/default/global.yaml.gotmpl` (after line 105, before `...`)

The Moodle backchannel templates (`helmfile/charts/moodle/values-backchannel.yaml`, `helmfile/apps/moodle/templates/shibboleth-sp-config.yaml`, `helmfile/apps/moodle/templates/apache-backchannel-configmap.yaml`) already exist and are gated on `.Values.backchannelLogout.saml.moodle.enabled`. This task activates them.

- [x] **Step 1: Add backchannel logout feature flag to global config**

Open `helmfile/environments/default/global.yaml.gotmpl`.

After the `grommunio` block (after line 104, before the final `...` on line 105), add:

```yaml

  ## =============================================================================
  ## BACKCHANNEL LOGOUT CONFIGURATION
  ## Enable SAML backchannel logout for specific services
  ## =============================================================================
  backchannelLogout:
    saml:
      moodle:
        enabled: true
```

The file should end like:

```yaml
      limits:
        memory: "8Gi"
        cpu: "2000m"

  ## =============================================================================
  ## BACKCHANNEL LOGOUT CONFIGURATION
  ## Enable SAML backchannel logout for specific services
  ## =============================================================================
  backchannelLogout:
    saml:
      moodle:
        enabled: true
...
```

- [x] **Step 2: Verify with helmfile template**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "backchannel" -Context 2`
Expected: Moodle templates render with backchannel logout enabled. The Apache backchannel ConfigMap contains the SOAP handler location. The Shibboleth SP config includes the backchannel logout SessionInitiator.

- [x] **Step 3: Commit**

```bash
git add helmfile/environments/default/global.yaml.gotmpl
git commit -m "feat(moodle): enable SAML backchannel logout feature flag

Set backchannelLogout.saml.moodle.enabled to true in global config.
This activates the existing gated backchannel templates in Moodle's
Shibboleth SP and Apache configuration."
```

---

### Task 6: Static Logout Pages

**Files:**
- Modify: `helmfile/apps/opendesk-services/values-opendesk-static-files.yaml.gotmpl` (after line 98, inside the `assets` block)

The existing `opendesk-static-files` chart serves static assets via nginx on `static.{{ .Values.global.domain }}`. The chart takes a list of assets with `subdomain`, `path`, and `data` fields. We add two new HTML pages under the portal subdomain so they are accessible at `https://portal.{{ domain }}/logout-confirm.html` and `https://portal.{{ domain }}/logged-out.html`.

The portal subdomain is the right choice because users clicking "Logout" are already on the portal, and the portal is the natural place for these pages.

- [x] **Step 1: Add logout-confirm.html and logged-out.html assets**

Open `helmfile/apps/opendesk-services/values-opendesk-static-files.yaml.gotmpl`.

After the existing `portal` asset block (after line 87, which ends the portal paths), add two new asset entries inside the `assets` block. Insert after line 87 (after the `login/background.jpg` path entry for portal):

```yaml
  portal-logout-confirm:
    subdomain: {{ .Values.global.hosts.nubus | quote }}
    pathType: "exact"
    paths:
      - path: "/logout-confirm.html"
        data: |
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Log out of all services</title>
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                background: #f5f5f5;
                color: #333;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
                padding: 1rem;
              }
              .card {
                background: #fff;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                max-width: 480px;
                width: 100%;
                padding: 2rem;
                text-align: center;
              }
              h1 { font-size: 1.5rem; margin-bottom: 1rem; }
              p { color: #666; margin-bottom: 1.5rem; line-height: 1.5; }
              .btn-primary {
                background: #0066cc;
                color: #fff;
                border: none;
                padding: 0.75rem 2rem;
                border-radius: 4px;
                font-size: 1rem;
                cursor: pointer;
                width: 100%;
                margin-bottom: 0.75rem;
              }
              .btn-primary:hover { background: #0052a3; }
              .btn-cancel {
                color: #666;
                text-decoration: none;
                font-size: 0.9rem;
              }
              .btn-cancel:hover { color: #333; }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>Log out of all services</h1>
              <p>
                Your session will be ended on all connected services.
                Any unsaved work may be lost.
              </p>
              <form method="POST"
                    action="https://{{ .Values.global.hosts.keycloak }}.{{ .Values.global.domain }}/realms/opendesk/protocol/openid-connect/logout">
                <input type="hidden" name="post_logout_redirect_uri"
                       value="https://{{ .Values.global.hosts.nubus }}.{{ .Values.global.domain }}/logged-out.html" />
                <button type="submit" class="btn-primary">Log Out All</button>
              </form>
              <a href="https://{{ .Values.global.hosts.nubus }}.{{ .Values.global.domain }}"
                 class="btn-cancel">Cancel</a>
            </div>
          </body>
          </html>
  portal-logged-out:
    subdomain: {{ .Values.global.hosts.nubus | quote }}
    pathType: "exact"
    paths:
      - path: "/logged-out.html"
        data: |
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>You have been logged out</title>
            <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                background: #f5f5f5;
                color: #333;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
                padding: 1rem;
              }
              .card {
                background: #fff;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                max-width: 520px;
                width: 100%;
                padding: 2rem;
                text-align: center;
              }
              h1 { font-size: 1.5rem; margin-bottom: 1rem; }
              p { color: #666; margin-bottom: 1rem; line-height: 1.5; }
              .disclaimer {
                background: #fff8e1;
                border: 1px solid #ffecb3;
                border-radius: 4px;
                padding: 1rem;
                margin: 1rem 0;
                text-align: left;
                font-size: 0.85rem;
                color: #795548;
                line-height: 1.5;
              }
              .btn-return {
                display: inline-block;
                background: #0066cc;
                color: #fff;
                text-decoration: none;
                padding: 0.75rem 2rem;
                border-radius: 4px;
                font-size: 1rem;
                margin-top: 0.5rem;
              }
              .btn-return:hover { background: #0052a3; }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>You have been logged out</h1>
              <p>Your session has been ended on most connected services.</p>
              <div class="disclaimer">
                Some applications (Planka, SOGo, Grommunio, Etherpad, BookStack, Zammad,
                LimeSurvey, F13, DrawIO, Excalidraw) do not support immediate logout.
                Sessions on these services will expire automatically within 30 minutes.
                Closing your browser helps accelerate this process.
              </div>
              <a href="https://{{ .Values.global.hosts.nubus }}.{{ .Values.global.domain }}"
                 class="btn-return">Return to Portal</a>
            </div>
          </body>
          </html>
```

- [x] **Step 2: Verify with helmfile template**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "logout-confirm" -Context 3`
Expected: The rendered output includes the `portal-logout-confirm` and `portal-logged-out` asset entries with the HTML content.

- [x] **Step 3: Commit**

```bash
git add helmfile/apps/opendesk-services/values-opendesk-static-files.yaml.gotmpl
git commit -m "feat(static-pages): add logout confirmation and result pages

Add logout-confirm.html and logged-out.html served via the existing
opendesk-static-files infrastructure on the portal subdomain.
Includes disclaimer about services without backchannel logout support."
```

---

### Task 7: Verification

After all six tasks are complete, run a full verification.

- [x] **Step 1: Full helmfile template render**

Run: `helmfile -e default template`
Expected: Clean render with no errors. All modified files produce valid YAML.

- [x] **Step 2: Spot-check ILIAS SAML client**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "ilias-saml" -Context 10`
Verify:
- `frontchannelLogout: false`
- `adminUrl` contains `/Shibboleth.sso/SLO/SOAP`
- `logout.service.url.binding.soap.post` attribute present
- No `frontchannel.logout.url` attribute remains

- [x] **Step 3: Spot-check Moodle SAML client**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "moodle-saml" -Context 10`
Verify:
- `frontchannelLogout: false`
- `adminUrl` contains `/Shibboleth.sso/SLO/SOAP`
- `logout.service.url.binding.soap.post` attribute present

- [x] **Step 4: Spot-check BBB SAML client**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "bbb-saml" -Context 10`
Verify:
- `frontchannelLogout: true`
- `adminUrl` contains `/saml/logout`
- `frontchannel.logout.url` contains `/saml/logout` (not Shibboleth.sso)

- [x] **Step 5: Spot-check ILIAS Shibboleth SP**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "SLO/SOAP" -Context 2`
Verify: The ILIAS ConfigMap contains `<Handler type="Logout" Location="/SLO/SOAP"` with SOAP binding.

- [x] **Step 6: Spot-check Moodle backchannel activation**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "BACKCHANNEL_LOGOUT_ENABLED" -Context 2`
Verify: The Moodle Apache backchannel ConfigMap renders with `BACKCHANNEL_LOGOUT_ENABLED "true"`.

- [x] **Step 7: Spot-check static pages**

Run: `helmfile -e default template 2>&1 | Select-String -Pattern "logged-out.html" -Context 3`
Verify: The static files values contain both page entries with full HTML content.

---

## Rollback

If backchannel logout causes issues, revert each change in reverse order. No custom code is involved, only configuration.

### Rollback Step 1: Disable Moodle Feature Flag

Open `helmfile/environments/default/global.yaml.gotmpl` and remove the `backchannelLogout` block (or set `enabled: false`).

### Rollback Step 2: Remove ILIAS Logout Handler

Open `helmfile/apps/ilias/templates/shibboleth-config.yaml` and remove the `<Handler type="Logout" Location="/SLO/SOAP".../>` line added in Task 4.

### Rollback Step 3: Revert Keycloak Clients

Open `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` and revert the three SAML clients:

**ILIAS (lines ~797-853):**
```yaml
frontchannelLogout: true
adminUrl: "https://lms.opendesk.example.com"
# Remove logout.service.url.binding.soap.post
# Restore: frontchannel.logout.url: "https://lms.opendesk.example.com/Shibboleth.sso/Logout"
```

**Moodle (lines ~856-912):**
```yaml
frontchannelLogout: true
adminUrl: "https://moodle.opendesk.example.com"
# Remove logout.service.url.binding.soap.post
# Restore: frontchannel.logout.url: "https://moodle.opendesk.example.com/Shibboleth.sso/Logout"
```

**BBB (lines ~915-972):**
```yaml
# Restore: adminUrl: "https://bbb.opendesk.example.com"
# Restore: frontchannel.logout.url: "https://bbb.opendesk.example.com/Shibboleth.sso/Logout"
```

### Rollback Step 4: Remove Static Pages (Optional)

The static pages are harmless HTML that renders even if left in place. To remove them, delete the `portal-logout-confirm` and `portal-logged-out` asset blocks from `helmfile/apps/opendesk-services/values-opendesk-static-files.yaml.gotmpl`.

### Rollback Step 5: Redeploy

```bash
helmfile apply
```

The Keycloak bootstrap job re-runs and updates client configurations. Services reconnect on next login.

### What Stays After Rollback

- Tier 1 OIDC backchannel is upstream openDesk config, untouched by these changes.
- The static HTML pages are inert. No risk if left in place.
- Session timeouts on Tier 4 services are unaffected by any of these changes.
