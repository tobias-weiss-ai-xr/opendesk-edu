# Sprint 14: ICS Test Spec System Completion + Edu Phase 2 Prep

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the complete ICS test spec system (commit uncommitted work, push to CI), then prepare the edu branch for Phase 2 service enablement (SOGo, ILIAS, Moodle, JupyterHub).

**Architecture:** Two workstreams:
1. **Ship ICS Specs**: Commit all uncommitted test infrastructure, push to Forgejo + GitHub, verify CI workflow fires, validate end-to-end.
2. **Edu Phase 2 Prep**: Enable SOGo + ILIAS on the test environment, add portal entries, document what's needed for Moodle/JupyterHub ICS integration.

**Tech Stack:** Python (yaml, jsonschema), Playwright, Forgejo Actions, Helmfile, Helm charts

---

## Workstream 1: Ship ICS Test Spec System

### Task 1: Commit and push all uncommitted ICS test work

**Files:**
- Modify: `tests/run-specs.py` (JSON schema validation + soft_fail header support)
- Modify: `tests/specs/ics-routing.yaml` (Shibboleth-aware redirects, soft_fail headers)
- Modify: `tests/specs/ics-backchannel.yaml` (soft_fail headers, auth annotations)
- Create: `tests/generate-playwright-specs.py` (YAML → Playwright generator)
- Create: `tests/specs/ics-services-extended.yaml` (Nextcloud + XWiki)
- Create: `tests/playwright/ics-routing.spec.js` (generated)
- Create: `tests/playwright/ics-backchannel.spec.js` (generated)
- Create: `tests/playwright/ics-services-extended.spec.js` (generated)
- Create: `.forgejo/workflows/test-specs.yml` (CI pipeline)

**Context:** All work from Sprint D/C/B/A (YAML→Playwright generator, JSON schema validation, extended specs, CI workflow) is staged but uncommitted. Branch: `feat/v1.1-release-prep`.

- [ ] **Step 1: Stage and commit the core test infrastructure**

```bash
git add tests/run-specs.py tests/generate-playwright-specs.py
git add tests/specs/ics-routing.yaml tests/specs/ics-backchannel.yaml
git add tests/specs/ics-services-extended.yaml
git add .forgejo/workflows/test-specs.yml
git commit -m "test(ics): complete spec system - generator, schema validation, CI, extended coverage

- YAML→Playwright generator (generate-playwright-specs.py)
- JSON Schema validation (run-specs.py --validate)  
- Extended specs: Nextcloud /fs, XWiki /wiki
- Forgejo Actions CI workflow (.forgejo/workflows/test-specs.yml)
- soft_fail headers for Shibboleth IdP compatibility
- Generic login form handling (Keycloak + Shibboleth + portal)"
```

- [ ] **Step 2: Stage and commit generated Playwright tests**

Do NOT add auto-generated `.spec.js` files to git. Add them to `.gitignore` instead. These are regenerated from YAML specs on every CI run.

Create `.gitignore` entry:
```
tests/playwright/ics-*.spec.js
```

```bash
git add .gitignore  # or update existing
git commit -m "chore: ignore generated Playwright specs (regenerated from YAML)"
```

- [ ] **Step 3: Push to GitHub remote**

```bash
git push github feat/v1.1-release-prep
```

### Task 2: Verify Forgejo Actions CI

**Context:** The CI workflow `.forgejo/workflows/test-specs.yml` fires on push to `tests/specs/**`, `tests/run-specs.py`, `tests/generate-playwright-specs.py`. After push, verify it runs.

- [ ] **Step 1: Check CI workflow runs on Codeberg**

```bash
# Check if workflow was triggered
gh run list --repo graphwiz-ai/opendesk-edu --limit 5
```

Or navigate to Codeberg → Actions in browser.

- [ ] **Step 2: Verify validate-specs job passes**

The job runs `python3 tests/run-specs.py --validate` — should pass for all 3 specs.

- [ ] **Step 3: Verify generate-playwright job passes**

The job generates `.spec.js` files and checks JS syntax with `node --check`.

### Task 3: Merge feat/v1.1-release-prep → develop

**Context:** If all CI passes and review is done, merge the feature branch.

- [ ] **Step 1: Verify all tests pass locally**

```bash
cd opendesk-edu
python3 tests/run-specs.py --validate
python3 tests/run-specs.py
PORTAL_USERNAME=ics-testuser PORTAL_PASSWORD=ics-testuser-2026 npx playwright test tests/playwright/ics-*.spec.js --reporter=list
```

- [ ] **Step 2: Merge and push**

```bash
git checkout develop
git merge feat/v1.1-release-prep
git push github develop
git push hrz develop  # if applicable
```

---

## Workstream 2: Edu Phase 2 Service Enablement

### Task 4: Enable SOGo on test environment

**Files:**
- Modify: `opendesk-edu/helmfile/environments/test/values.yaml.gotmpl` (set `sogo.enabled: true`)
- Reference: `opendesk-edu/helmfile/apps/sogo/values.yaml.gotmpl` (existing SOGo chart)

**Context:** SOGo is disabled in test environment. Enable it and verify it works. SOGo routes through ICS at `/sogo` with SAML auth.

- [ ] **Step 1: Enable SOGo in test values**

In `opendesk-edu/helmfile/environments/test/values.yaml.gotmpl`, change:
```yaml
  sogo:
    enabled: false  # → true
```

- [ ] **Step 2: Check SOGo chart values for test-specific config**

Read `opendesk-edu/helmfile/apps/sogo/values.yaml.gotmpl` to verify no test-specific overrides are missing (LDAP bind DN, domain, etc.).

- [ ] **Step 3: Deploy and verify**

```bash
helmfile -e test -f apps/sogo/helmfile.yaml.gotmpl sync
# Verify SOGo pods start
kubectl get pods -l app.kubernetes.io/name=sogo -n opendesk
# Verify ICS proxy: curl -sk https://ics.opendesk.hrz.../sogo/SOGo/ → 302
```

### Task 5: Enable ILIAS on test environment

**Files:**
- Modify: `opendesk-edu/helmfile/environments/test/values.yaml.gotmpl` (set `ilias.enabled: true`)
- Reference: `opendesk-edu/helmfile/apps/ilias/values.yaml.gotmpl` (existing ILIAS chart)
- Reference: `opendesk-edu/helmfile/apps/ilias/values-backchannel.yaml.gotmpl` (backchannel logout)

**Context:** ILIAS is disabled in test environment. Enable it and verify. ILIAS routes through ICS at `/ilias` with SAML auth. Has backchannel logout support.

- [ ] **Step 1: Enable ILIAS in test values**

```yaml
  ilias:
    enabled: false  # → true
```

- [ ] **Step 2: Check ILIAS chart values for test-specific config**

Read `opendesk-edu/helmfile/apps/ilias/values.yaml.gotmpl` — verify LDAP, DB, and backchannel config.

- [ ] **Step 3: Deploy and verify**

```bash
helmfile -e test -f apps/ilias/helmfile.yaml.gotmpl sync
kubectl get pods -l app.kubernetes.io/name=ilias -n opendesk
curl -sk https://ics.opendesk.hrz.../ilias/ → 302
```

### Task 6: Add portal entries for SOGo + ILIAS

**Files:**
- Modify: `opendesk-edu/helmfile/apps/portal-entries/values.yaml.gotmpl` (add SOGo + ILIAS entries)

**Context:** Portal entries make services visible in the Nubus portal. Check existing entries for DrawIO, Etherpad, etc. as templates.

- [ ] **Step 1: Check existing portal entry patterns**

Read `opendesk-edu/helmfile/apps/portal-entries/values.yaml.gotmpl` to understand the entry format (name, icon, link, description, group).

- [ ] **Step 2: Add SOGo portal entry**

Add SOGo entry with:
- Name: "SOGo E-Mail"
- Link: `https://ics.opendesk.hrz.../sogo/`
- Icon: email/mail icon
- Group: appropriate edu group

- [ ] **Step 3: Add ILIAS portal entry**

Add ILIAS entry with:
- Name: "ILIAS LMS"
- Link: `https://ics.opendesk.hrz.../ilias/`
- Icon: learning/LMS icon
- Group: appropriate edu group

### Task 7: Moodle research — ICS integration feasibility

**Files:**
- Reference: `opendesk-edu/helmfile/apps/moodle/values.yaml.gotmpl` (existing Moodle chart)
- Reference: `opendesk-edu/helmfile/apps/nubus/values-intercom-service.yaml.gotmpl` (ICS config)

**Context:** Moodle is listed as "coming later" in test values. Research what's needed to route Moodle through ICS (OIDC auth). Moodle supports OIDC natively via plugins.

- [ ] **Step 1: Check Moodle chart for OIDC configuration**

Read `opendesk-edu/helmfile/apps/moodle/values.yaml.gotmpl` — look for auth, OIDC, SAML, Keycloak settings.

- [ ] **Step 2: Check ICS values for Moodle support**

Read `opendesk-edu/helmfile/apps/nubus/values-intercom-service.yaml.gotmpl` — check if there's a Moodle/moodle section (similar to nextcloud, xwiki).

- [ ] **Step 3: Document findings**

Write findings to `docs/superpowers/plans/moodle-ics-integration.md`:
- Does ICS natively support Moodle proxying?
- What Moodle auth plugin is needed (auth_oidc, auth_saml2)?
- What changes to ICS values.yaml.gotmpl are needed?
- Estimated effort: small (config only) vs medium (new chart overrides)

### Task 8: JupyterHub research — ICS integration feasibility

**Files:**
- Reference: `opendesk-edu/helmfile/apps/jupyterhub/values.yaml.gotmpl`
- Reference: `opendesk-edu/helmfile/apps/nubus/values-intercom-service.yaml.gotmpl`

**Context:** JupyterHub is enabled in test environment. Research ICS integration. JupyterHub supports OAuthenticator for OIDC.

- [ ] **Step 1: Check JupyterHub chart for OIDC configuration**

Read `opendesk-edu/helmfile/apps/jupyterhub/values.yaml.gotmpl` — look for auth, OAuthenticator, GenericOAuthenticator settings.

- [ ] **Step 2: Check ICS values for JupyterHub support**

Check if `values-intercom-service.yaml.gotmpl` has a jupyter/jupyterhub section.

- [ ] **Step 3: Document findings**

Add to `docs/superpowers/plans/moodle-ics-integration.md` (or create separate file) with JupyterHub section.

---

## Out of Scope (Future Sprints)

These are NOT part of this sprint but listed for planning visibility:

- **Moodle + JupyterHub ICS integration** (implementation — after research in Tasks 7-8)
- **Real Shibboleth test account** — Need HRZ-assigned test account for full authenticated ICS testing (currently blocked)
- **OpenProject ICS routing** — `/webmail` route returns 404, not yet configured
- **End-to-end Playwright CI** — Browser tests can't run in CI without headless browser + real credentials
- **Backchannel logout integration tests** — Full round-trip logout testing requires real Shibboleth session
