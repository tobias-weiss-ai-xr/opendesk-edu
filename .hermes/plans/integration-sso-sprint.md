# Integration & SSO Sprint

## Phases

### Phase 1: Helmfile consolidation
- Enable moodle (uncomment in helmfile_generic.yaml.gotmpl, fix child yaml)
- Add n8n (create helmfile/apps/n8n/ from existing chart)
- Add ilias (referenced in helmfile, verify it's connected)
- Add portal-entries, open-webui etc. that are running but not referenced
- Fix broken seaweedfs reference (missing helmfile-child.yaml.gotmpl)
- Fix stale snipr reference (commented but broken YAML)
- Convert kubectl infra (mariadb-standalone, openldap, postgresql) → Helm charts

### Phase 2: SSO Audit & Per-Service Configuration
For each edu service, document and implement SSO:

| Service | SSO Protocol | Keycloak Client | Status |
|---------|-------------|----------------|--------|
| Keycloak (existing) | — | `id.opendesk.hrz.uni-marburg.de` | ✅ |
| OpenProject | OIDC | `opendesk-openproject` | Client exists, needs config |
| OpenWebUI | OIDC | `opendesk-open-webui` / `opendesk-openwebui` | Client exists |
| Code Server | OIDC | `opendesk-codeserver` | Client exists |
| RStudio | OIDC | `opendesk-rstudio` | Client exists |
| Slidev | OIDC | `opendesk-slidev` | Client exists |
| TTYD | OIDC | `opendesk-ttyd` | Client exists |
| JupyterHub | OIDC | `opendesk-jupyterhub` | Client exists |
| Moodle | SAML | `https://moodle.opendesk.../shibboleth` | Client exists, chart needs Shibboleth re-added |
| ILIAS | SAML | `ilias-saml` | Client exists |
| Zammad | OIDC | — | Needs client + env config |
| SOGo | SAML | — | Needs config |
| Bookstack | OIDC | — | Needs client + env config |
| Planka | OIDC | — | Needs client + env config |
| n8n | OIDC | — | Needs client + env config |
| LimeSurvey | SAML/OIDC | — | Needs investigation |

### Phase 3: Clean implementation
- Write/modify chart templates to accept SSO config
- Create portal entries for all services
- Create helmfile integration test

### Phase 4: Documentation
- `opendesk-edu/docs/helmfile-integration.md`
- `opendesk-edu/docs/sso-configuration.md`
- Update `AGENTS.md`
