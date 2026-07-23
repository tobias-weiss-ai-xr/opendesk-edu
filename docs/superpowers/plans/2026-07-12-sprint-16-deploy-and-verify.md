# Sprint 16: Deploy Collab Services + Verify ICS Integration

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge pending PRs, deploy 8 missing edu collab services to the cluster, verify they're running and accessible, then test ICS routing for newly deployed services.

**Architecture:** All 8 services are already defined in `helmfile_generic.yaml.gotmpl` and enabled in `helmfile/environments/test/values.yaml.gotmpl`. The root helmfile orchestrates everything — a single `helmfile -e test sync` will deploy all enabled services. The portal entries PR needs to be created and merged first so the portal shows the new services.

**Tech Stack:** Helmfile, K3s, kubectl, curl (for verification), Codeberg API (for PR management)

---

## Task 1: Create PR for portal entries branch

**Context:** Branch `feat/portal-entries-collab-services` has 1 commit (7648804c) with 6 new portal entries in nubus. No PR exists yet.

**Files:**
- Branch: `feat/portal-entries-collab-services`
- Modified: `helmfile/apps/nubus/values-nubus.yaml.gotmpl`

- [ ] **Step 1: Create PR on Codeberg via API**

```bash
curl -s -X POST "https://codeberg.org/api/v1/repos/opendesk-edu/opendesk-edu/pulls" \
  -H "Authorization: token fb02f607905a7b477f39931e9f61eec1e69f75e6" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "feat(portal): add entries for collab-dashboard, open-webui, ollama, rstudio, ttyd, code-server",
    "head": "feat/portal-entries-collab-services",
    "base": "main",
    "body": "## Summary\n\nAdds 6 portal entries (16-21) to nubus bootstrap data for edu collab services:\n\n| # | Service | Hostname |\n|---|---------|----------|\n| 16 | Collab Dashboard | collab.opendesk.hrz... |\n| 17 | Open WebUI | ai.opendesk.hrz... |\n| 18 | RStudio | r.opendesk.hrz... |\n| 19 | TTYD | term.opendesk.hrz... |\n| 20 | Code Server | code.opendesk.hrz... |\n| 21 | Ollama | ai.opendesk.hrz... |\n\nAll follow existing portal entry pattern: activated=true, anonymous=false, linkTarget=newwindow, bilingual de_DE/en_US."
  }'
```

Expected: `{"number": 3, "html_url": "https://codeberg.org/opendesk-edu/opendesk-edu/pulls/3"}`

- [ ] **Step 2: Merge both PRs**

Since these are our own PRs in our own repo:

```bash
git checkout main
git merge feat/ics-test-system --no-ff -m "Merge pull request #2 from opendesk-edu/feat/ics-test-system"
git merge feat/portal-entries-collab-services --no-ff -m "Merge pull request #3 from opendesk-edu/feat/portal-entries-collab-services"
git push codeberg main
git push github main
```

---

## Task 2: Pre-deploy check — verify helmfile can render

**Context:** Before deploying, verify helmfile can template all releases without errors. This catches missing values, chart dependency issues, or template errors.

**Files:**
- `helmfile.yaml.gotmpl`
- `helmfile_generic.yaml.gotmpl`
- `helmfile/environments/test/values.yaml.gotmpl`

- [ ] **Step 1: Run helmfile template (dry-run)**

```bash
helmfile -e test template 2>&1 | tail -20
```

Expected: Rendered YAML for all enabled releases. If errors, fix them before proceeding.

- [ ] **Step 2: Note which releases are installed vs skipped**

```bash
helmfile -e test template 2>&1 | grep -c "Adding release"
helmfile -e test template 2>&1 | grep "Skipping.*installed: false"
```

This shows exactly which services will be deployed. We expect bookstack, self-service-password, collab-dashboard, open-webui, ollama, rstudio, ttyd, code-server to be added (installed: true) and sogo, ilias, moodle, etc. to be skipped (installed: false).

---

## Task 3: Deploy all services via helmfile sync

**Context:** Single helmfile sync deploys all enabled releases. Some services (BookStack, Ollama, CodeServer) pull images from Docker Hub — may need proxy. The cluster has HAProxy ingress.

**Files:** All releases in `helmfile_generic.yaml.gotmpl`

- [ ] **Step 1: Deploy all enabled services**

```bash
helmfile -e test sync 2>&1 | tee /tmp/helmfile-sync.log
```

Expected: All enabled releases sync'd. Watch for image pull errors or template errors.

- [ ] **Step 2: Check for failures**

```bash
grep -i "error\|failed\|release.*failed" /tmp/helmfile-sync.log
```

If any releases failed, investigate and retry individually.

- [ ] **Step 3: Wait for pods to reach Running state**

```bash
watch -n 5 "kubectl get pods -n opendesk --no-headers -o custom-columns='NAME:.metadata.name,STATUS:.status.phase' | grep -E 'bookstack|self-service|collab|open-webui|ollama|rstudio|ttyd|code-server'"
```

Wait until all pods show `Running`. Some services (BookStack with MariaDB, Ollama with 50Gi PVC) may take several minutes.

---

## Task 4: Verify each service is accessible

**Context:** Each service has an ingress via HAProxy. Verify HTTP responses. Services use `*.opendesk.hrz.uni-marburg.de`.

**Files:** None (kubectl + curl only)

- [ ] **Step 1: Check all service ingresses exist**

```bash
kubectl get ingress -n opendesk --no-headers -o custom-columns='NAME:.metadata.name,HOSTS:.spec.rules[*].host,CLASS:.spec.ingressClassName' | grep -E 'bookstack|ssp|collab|ai|r\.|term\.|code\.|wiki\.'
```

Expected ingresses:
- `bookstack` → `wiki.opendesk.hrz.uni-marburg.de`
- `self-service-password` → `ssp.opendesk.hrz.uni-marburg.de`
- `collab-dashboard` → `collab.opendesk.hrz.uni-marburg.de`
- `open-webui` → `ai.opendesk.hrz.uni-marburg.de`
- `rstudio` → `r.opendesk.hrz.uni-marburg.de`
- `ttyd` → `term.opendesk.hrz.uni-marburg.de`
- `code-server` → `code.opendesk.hrz.uni-marburg.de`

- [ ] **Step 2: Curl each service endpoint**

```bash
for host in wiki ssp collab ai r term code; do
  code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 "https://${host}.opendesk.hrz.uni-marburg.de/" 2>/dev/null)
  echo "${host}: ${code}"
done
```

Expected: All return HTTP 200 or 302 (redirect to login). 502/503 means the service isn't ready yet.

- [ ] **Step 3: Check Ollama status separately (no ingress)**

```bash
kubectl get pods -n opendesk -l app.kubernetes.io/name=ollama -o wide
kubectl logs -n opendesk -l app.kubernetes.io/name=ollama --tail=5
```

Ollama may not have an ingress (uses ClusterIP). Verify it's running and the models are being pulled.

---

## Task 5: Update ICS test specs for newly deployed services

**Context:** Now that services are running, add them to the ICS test specs. Currently `ics-routing.yaml` covers OC, SOGo, ILIAS. Add BookStack, SSP, Collab Dashboard, RStudio, TTYD, CodeServer.

**Files:**
- Modify: `tests/specs/ics-routing.yaml`
- Modify: `tests/specs/ics-services-extended.yaml`

- [ ] **Step 1: Add new routing scenarios to ics-routing.yaml**

Add scenarios for each new service following the existing pattern:

```yaml
  # BookStack (wiki.opendesk.hrz)
  - service: bookstack
    method: GET
    path: /
    status: 200
    headers:
      x-forwarded-user: { value: present, soft_fail: true }
      x-forwarded-host: { value: "wiki.opendesk.hrz.uni-marburg.de" }

  # Self-Service Password (ssp.opendesk.hrz)
  - service: self-service-password
    method: GET
    path: /
    status: 200
    headers:
      x-forwarded-user: { value: present, soft_fail: true }
      x-forwarded-host: { value: "ssp.opendesk.hrz.uni-marburg.de" }

  # Collab Dashboard (collab.opendesk.hrz)
  - service: collab-dashboard
    method: GET
    path: /
    status: 200
    headers:
      x-forwarded-user: { value: present, soft_fail: true }
      x-forwarded-host: { value: "collab.opendesk.hrz.uni-marburg.de" }

  # RStudio (r.opendesk.hrz)
  - service: rstudio
    method: GET
    path: /
    status: 200
    headers:
      x-forwarded-user: { value: present, soft_fail: true }
      x-forwarded-host: { value: "r.opendesk.hrz.uni-marburg.de" }

  # TTYD (term.opendesk.hrz)
  - service: ttyd
    method: GET
    path: /
    status: 200
    headers:
      x-forwarded-user: { value: present, soft_fail: true }
      x-forwarded-host: { value: "term.opendesk.hrz.uni-marburg.de" }

  # Code Server (code.opendesk.hrz)
  - service: code-server
    method: GET
    path: /
    status: 200
    headers:
      x-forwarded-user: { value: present, soft_fail: true }
      x-forwarded-host: { value: "code.opendesk.hrz.uni-marburg.de" }
```

- [ ] **Step 2: Validate specs**

```bash
cd opendesk-edu && python3 tests/run-specs.py --validate
```

Expected: All specs pass validation.

- [ ] **Step 3: Run CLI specs against live services**

```bash
ICS_BASE_URL="https://intercom.opendesk.hrz.uni-marburg.de" python3 tests/run-specs.py 2>&1 | tee /tmp/ics-test-results.log
```

- [ ] **Step 4: Commit and push spec updates**

```bash
git add tests/specs/ics-routing.yaml
git commit -m "test(ics): add routing specs for bookstack, ssp, collab-dashboard, rstudio, ttyd, code-server"
git push codeberg feat/ics-test-system
```

---

## Task 6: Generate and run Playwright specs for new services

**Context:** The YAML→Playwright generator should now produce additional test cases for the newly added services.

**Files:**
- Modify: `tests/specs/ics-routing.yaml` (already updated in Task 5)
- Run: `tests/generate-playwright-specs.py`

- [ ] **Step 1: Regenerate Playwright specs**

```bash
cd opendesk-edu && python3 tests/generate-playwright-specs.py
```

Expected: Generator creates updated `ics-routing.spec.js` with new service tests.

- [ ] **Step 2: Syntax check generated files**

```bash
for f in tests/playwright/ics-*.spec.js; do node --check "$f" && echo "OK: $f" || echo "FAIL: $f"; done
```

- [ ] **Step 3: Run Playwright tests (if npx available)**

```bash
cd opendesk-edu/tests/playwright && npx playwright test --config playwright.config.ts 2>&1 | tail -30
```

---

## Task 7: Document deployment state and create PR for spec updates

**Context:** After deploying and verifying, push the spec updates and create a follow-up PR.

**Files:**
- Branch: `feat/ics-test-system` (or new branch if PR #2 was merged)
- Modified: `tests/specs/ics-routing.yaml`

- [ ] **Step 1: Push all changes**

```bash
git push codeberg HEAD  # push current branch
git push github HEAD
```

- [ ] **Step 2: If PR #2 was already merged, create new PR for spec updates**

```bash
git checkout -b feat/ics-specs-collab-services
git push codeberg feat/ics-specs-collab-services
# Create PR via API
```

---

## Out of Scope

- **Moodle ICS integration** — blocked on custom Docker image rebuild
- **JupyterHub ICS** — blocked on Helm chart creation
- **Overleaf, KasmVNC, Dask** — disabled in test values
- **Ollama GPU optimization** — cluster has no GPU nodes, CPU-only is fine for small models
- **Real Shibboleth auth testing** — requires university IdP test account from HRZ

---

## Rollback Plan

If any deployment fails or causes issues:

```bash
# Rollback specific release
helmfile -e test -l name=SERVICE_NAME sync --force

# Or rollback all to previous state
helm rollback RELEASE_NAME REVISION
```
