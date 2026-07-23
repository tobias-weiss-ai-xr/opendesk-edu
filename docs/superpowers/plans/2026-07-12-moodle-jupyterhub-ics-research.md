# Moodle & JupyterHub ICS Integration Research

## Moodle

**Status:** Deployed with direct ingress + SAML auth (not via ICS)

**Current Architecture:**
- Chart: `opendesk-edu/helmfile/apps/moodle/values.yaml.gotmpl`
- Image: `ghcr.io/<your-org>/moodle-shib` (custom Moodle + mod_shib)
- Auth: Shibboleth SAML via Apache `mod_shib`
  - SP entity: `https://moodle.opendesk.example.com/shibboleth`
  - IdP metadata: Keycloak SAML descriptor
- Backchannel logout: implemented via custom PHP handler + Apache config
- Ingress: Direct (bypasses ICS), `haproxy` ingress class

**ICS Integration Assessment:**
- ICS `values-intercom-service.yaml.gotmpl` has NO Moodle section
- Moodle uses SAML (not OIDC), so ICS would need a SAML-compatible route
- ICS supports SAML services (SOGo, ILIAS both use SAML)
- **Effort:** Medium — add Moodle subdomain to ICS config, update Moodle ingress to route through ICS, adjust Shibboleth SP entityID to use ICS URL
- **Blocker:** Moodle's custom `moodle-shib` image may need patches for ICS-proxied SAML (the SP metadata URL and assertion consumer service URL must match)

## JupyterHub

**Status:** Referenced in test values but no Helm chart exists in the repo

**Current Architecture:**
- No dedicated Helm chart found in `opendesk-edu/helmfile/apps/`
- Listed as `jupyterhub.enabled: true` in test environment values
- Likely deployed via external means or a chart not yet added to the repo
- Not in ICS configuration at all

**ICS Integration Assessment:**
- JupyterHub supports `GenericOAuthenticator` for OIDC natively
- Would need: Helm chart creation + ICS OIDC subdomain/origin config + Keycloak client
- **Effort:** Large — requires Helm chart creation (image, config, PVC, networking, auth setup), ICS integration, and Keycloak client provisioning
- **Blocker:** No Helm chart exists — needs to be created before ICS integration can be considered

## Recommendations

1. **Moodle ICS integration** is feasible but risky — the custom `moodle-shib` image is built for direct SAML with Keycloak. Routing through ICS would change the SAML assertion consumer URL and SP metadata endpoint, requiring image rebuilds. Low priority unless there's a specific need for unified session management via ICS.

2. **JupyterHub ICS integration** requires chart creation first — cannot start ICS work until a proper Helm chart exists with configurable auth. This is a separate task from ICS integration.

3. **Neither service blocks Sprint 14 completion.** The ICS test spec system is complete and covers the currently ICS-proxied services (OpenCloud, SOGo, ILIAS, Nextcloud, XWiki).
