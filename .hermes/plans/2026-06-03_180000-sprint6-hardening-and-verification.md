# Sprint 6 — Hardening & Verification

**Cluster:** 57/57 Running | 33 ingresses on `.hrz.uni-marburg.de` | 0 on `.opendesk-edu.org`

## Priority

### 1. Planka — DB migration & app verification
- Planka returns HTTP 200 externally but internal pod-to-pod connection to planka-planka:1337 fails (Connection refused from n8n pod). Need to check:
  - Whether DB migration completed successfully
  - Whether the app is actually serving (maybe only listens on 127.0.0.1)
  - Check pod logs for startup errors beyond "Custom terms not found"
  - Create first admin user if needed

### 2. Helmfile .gotmpl workaround
- Upstream helmfile bug blocks `helmfile sync` for `.gotmpl` child resolution
- Options: upgrade helmfile version, bypass .gotmpl by pre-rendering, or use helm directly with chart paths

### 3. Monitoring stack
- Grafana dashboards exist in `./monitoring/` — deploy them
- Check Prometheus/Grafana are scraping opendesk-edu namespace
- Alert on any non-Running pods

### 4. Edu service smoke tests
- Verify Moodle (login page loads, OIDC redirect works)
- Verify ILIAS (login page loads)
- Verify JupyterHub (landing page)
- Verify OpenProject (login page — already confirmed)
- Verify BookStack (already confirmed)
- Each should return non-error HTTP status on `/` or `/login`

### 5. External DNS handover
- `scripts/generate-dns-records.sh` committed — ready for HRZ DNS admin
- Confirm HTTPS/TLS works on each service's hostname after DNS is active

### 6. Testing logins
- SSP: full OIDC login flow (currently returns 403 without auth, sign-in page at /oauth2/sign_in)
- Planka: login via OIDC after DB setup
- Etherpad: login via oauth2-proxy (was returning 200 with sign-in)
