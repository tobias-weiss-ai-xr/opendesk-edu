# Sprint 3: Runtime Stability & Feature Completion

**Date:** 2026-06-03
**State:** plan

---

## Goal

Deliver a fully operational openDesk Edu cluster: fix the remaining blocker (clamav), reconcile helmfile drift, and round off with ingress cleanup, SAML re-enable for moodle, and basic monitoring.

---

## Current State

- **57/58** pods Running. Only `clamav-simple-0` (0/2, running but unhealthy) — blocked by external internet access.
- **Moodle:** 1/1 Running, PostgreSQL backend, OIDC issuer configured, SAML disabled (mod_shib.so ABI mismatch).
- **Helmfile:** `.gotmpl` YAML anchor syntax (`&values`/`*values`) blocks `helmfile sync` on helmfile v2+. Helm CLI used for individual app deploys.
- **Monitoring:** Grafana ingress deployed at `grafana.opendesk.hrz.uni-marburg.de`, PodMonitor + ServiceMonitor created. Dashboards not yet validated.
- **Git:** `ea248e2` on `main`. Leaked secrets present in history (no force-push to purge yet).
- **Certificates:** `opendesk-certificates-tls` (self-signed) used across all ingresses. HTTPS works.

---

## Proposed Approach

1. **Clamav** → inject cluster proxy via chart values (not `helm set`). The `HTTP_PROXY` env vars exist in a reference file but were never applied to a persistent config.
2. **Helmfile drift** → either fix the `.gotmpl` anchor syntax or document the alternative deploy workflow. Low priority since individual helm releases work.
3. **Moodle SAML** → rebuild a Docker image with distro-matched `mod_shib.so` via Dockerfile, or switch permanently to OIDC and document the decision.
4. **Ingress cleanup** → verify all 30+ ingresses have correct TLS + domains. Fix any remaining `opendesk.example.com` references in chart templates.
5. **Monitoring** → import standard moodle/openproject/nginx dashboards to Grafana, verify Prometheus scrapes all targets.
6. **Git hygiene** → simple secret redaction (no force-push unless user requests it).

---

## Step-by-step Plan

### 1. Clamav — proxy injection
- **Files:** `helmfile/apps/clamav-simple/values.yaml.gotmpl` (create if not exists)
- **Action:** Add `HTTP_PROXY`/`HTTPS_PROXY`/`NO_PROXY` env vars to the clamav values template per `/tmp/clamav-proxy.yaml` format.
- **Verification:** `helm upgrade --install clamav-simple ...` — clamav pods go 2/2 Running.
- **Risk:** Low. Proxy values are known-working for other services.

### 2. Helmfile — anchor fix
- **Files:** `helmfile/helmfile_generic.yaml.gotmpl`
- **Issue:** `values: &values` uses YAML anchors in a `.gotmpl` file. Helmfile v2.x's parser doesn't accept this when pre-processed by Go templates.
- **Option A:** Replace anchors with explicit inline values blocks.
- **Option B:** Remove the anchor syntax and use a `default-values.yaml` approach.
- **Verification:** `helmfile --file helmfile/helmfile_generic.yaml.gotmpl sync --dry-run` parses without error.
- **Risk:** Medium. May require restructuring the helmfile to avoid `.gotmpl` + YAML anchor interaction.

### 3. Moodle SAML
- **Option A (recommended):** Document OIDC as the permanent SSO solution. Remove SAML config from moodle values. No Docker rebuild needed.
- **Option B:** Rebuild `docker.io/weissto/moodle-shib` with `apt-get install --reinstall libapache2-mod-shib` offline-baked into the image.
- **Files:** `helmfile/apps/moodle/values.yaml.gotmpl` (remove SAML section if Option A).
- **Verification:** Moodle login page shows "Log in with Keycloak" button.
- **Risk:** Low for Option A. Option B requires Docker build infra + push access.

### 4. Ingress verification
- **Files:** N/A (read-only audit)
- **Action:** For each app in `helm list`, confirm ingress exists with correct TLS, domain, and path rules.
- **Verification:** `kubectl get ingress -n opendesk-edu -o wide` — all hosts under `*.opendesk.hrz.uni-marburg.de`.
- **Risk:** Low.

### 5. Monitoring dashboards
- **Files:** None (import via Grafana API or web UI)
- **Action:** Import moodle, openproject, and general Kubernetes dashboards (dashboard IDs: `14831` for Kubernetes, `14080` for moodle).
- **Verification:** Data populates in Grafana dashboards.
- **Risk:** Low. ServiceMonitor already created; metrics should be flowing.

### 6. Git hygiene
- **Files:** N/A
- **Action:** Replace leaked secrets in git-tracked files with `[REDACTED]`. No force-push — just fix forward.
- **Risk:** Low. Secrets are already in history but fixing files prevents new leaks.

---

## Open Questions

1. **Clamav:** Does the chart support `extraEnvVars`, or does the deployment template need patching?
2. **Helmfile anchor:** Which helmfile version is installed? (`helmfile --version`)
3. **Moodle SAML:** Are existing users depending on Shibboleth-aware features, or can we drop SAML entirely?
4. **Monitoring:** Are there existing Grafana dashboards in the `./monitoring/` directory?
5. **Secret purge:** Any objection to force-pushing to purge secrets from git history?

---

## Acceptance Criteria

- `clamav-simple-0` → 2/2 Running (or blocker documented with path to fix)
- `helmfile sync` succeeds (or documented workaround)
- Moodle offers OIDC login
- Grafana shows metrics for all services
- All ingresses return 200 with valid TLS
