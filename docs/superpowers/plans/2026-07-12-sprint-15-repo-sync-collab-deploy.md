# Sprint 15: Main Repo Sync + Edu Collab Services Deploy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sync the edu repo with Codeberg's main (322 commits behind), then deploy missing Phase 1 collab services (BookStack, OpenWebUI, RStudio, TTYD, Collab Dashboard, Self-Service Password).

**Architecture:** Two sequential workstreams:
1. **Repo sync**: Rebase local `main` onto `codeberg/main` to pick up 322 commits of upstream work (articles, landing page, presentation slides, issue templates). Then merge `feat/ics-test-system` test infrastructure on top.
2. **Edu collab deploy**: Deploy the 6 remaining Phase 1 services that have charts but aren't running on the cluster. Each is standalone with no interdependencies.

**Tech Stack:** Git (rebase), Helmfile, Kubernetes, Helm charts

---

## Workstream 1: Repo Sync

### Task 1: Sync local main with Codeberg main

**Context:** Codeberg's `main` is 322 commits ahead of local `main`. Local `main` has 1 commit not on Codeberg (`ci: add GitLab CI pipeline on opencode.de`). Need to sync.

**Files:** None (git operations only)

- [ ] **Step 1: Check what the local-only commit contains**

```bash
git log main --not codeberg/main --oneline
git show HEAD --stat
```

If the local-only commit (`b721b5ad ci: add GitLab CI pipeline on opencode.de`) is valuable, save it as a patch:

```bash
git format-patch -1 HEAD --stdout > /tmp/gitlab-ci-pipeline.patch
```

If it's not relevant (Codeberg uses Forgejo Actions, not GitLab CI), skip it.

- [ ] **Step 2: Fast-forward local main to Codeberg main**

```bash
git checkout main
git merge --ff-only codeberg/main
```

- [ ] **Step 3: Verify sync**

```bash
git log --oneline -5
git log codeberg/main --not main --oneline  # Should be empty
```

- [ ] **Step 4: Push to all remotes**

```bash
git push codeberg main
git push github main
git push origin main
```

### Task 2: Merge feat/ics-test-system onto synced main

**Context:** The ICS test system (`feat/ics-test-system` branch) has 2 commits cherry-picked from the old `feat/v1.1-release-prep`. Need to merge onto the now-synced main.

- [ ] **Step 1: Rebase feat/ics-test-system onto updated main**

```bash
git checkout feat/ics-test-system
git rebase main
```

If conflicts arise (likely in `.gitignore` if main updated it), resolve them by keeping both changes.

- [ ] **Step 2: Push updated branch**

```bash
git push codeberg feat/ics-test-system --force-with-lease
git push github feat/ics-test-system --force-with-lease
```

- [ ] **Step 3: Create PR on Codeberg**

Navigate to: `https://codeberg.org/opendesk-edu/opendesk-edu/compare/main...feat/ics-test-system`

Or via CLI:
```bash
tea pr create --title "test(ics): ICS test spec system — generator, schema validation, CI" \
  --head feat/ics-test-system --base main \
  --description "Adds complete ICS integration test infrastructure:
- YAML declarative test specs for 5 services (OC, SOGo, ILIAS, Nextcloud, XWiki)
- YAML→Playwright generator (generate-playwright-specs.py)
- JSON Schema validation (run-specs.py --validate)
- Forgejo Actions CI workflow (.forgejo/workflows/test-specs.yml)
- Shibboleth-compatible auth handling (soft_fail headers)
- Sprint plan documents"
```

### Task 3: Verify CI fires on the PR

**Context:** The Forgejo Actions workflow in `.forgejo/workflows/test-specs.yml` triggers on `pull_request` events for paths matching `tests/specs/**`, `tests/run-specs.py`, `tests/generate-playwright-specs.py`. After creating the PR, verify it runs.

- [ ] **Step 1: Check Codeberg Actions page**

Navigate to Codeberg → opendesk-edu → Actions → test-specs

Or check via API:
```bash
tea actions list --repo opendesk-edu/opendesk-edu
```

- [ ] **Step 2: Verify validate-specs job passes**

The job should run `python3 tests/run-specs.py --validate` — all 3 specs should pass.

- [ ] **Step 3: Verify generate-playwright job passes**

The job should generate `.spec.js` files and run `node --check` on each.

---

## Workstream 2: Deploy Missing Edu Collab Services

### Task 4: Deploy BookStack

**Context:** BookStack chart exists at `opendesk-edu/helmfile/apps/bookstack/values.yaml.gotmpl`. It uses embedded MariaDB. Currently listed as `bookstack.enabled: true` in test values but pod is not running on cluster.

**Files:**
- Reference: `opendesk-edu/helmfile/apps/bookstack/values.yaml.gotmpl`
- Reference: `opendesk-edu/helmfile/apps/bookstack/helmfile.yaml.gotmpl`

- [ ] **Step 1: Read BookStack helmfile to understand deployment structure**

```bash
cat opendesk-edu/helmfile/apps/bookstack/helmfile.yaml.gotmpl
```

- [ ] **Step 2: Check BookStack values for required config (DB password, domain, etc.)**

Read `opendesk-edu/helmfile/apps/bookstack/values.yaml.gotmpl` — check for environment-specific values that need setting.

- [ ] **Step 3: Check if BookStack has dependencies not running**

BookStack uses embedded MariaDB. Check if it needs PostgreSQL or other shared services.

- [ ] **Step 4: Deploy via helmfile**

```bash
helmfile -e test -f apps/bookstack/helmfile.yaml.gotmpl sync
```

- [ ] **Step 5: Verify pod starts and ingress responds**

```bash
kubectl get pods -l app.kubernetes.io/name=bookstack -n opendesk
curl -sk -o /dev/null -w "%{http_code}" https://bookstack.opendesk.hrz.../
```

### Task 5: Deploy Self-Service Password

**Context:** Chart at `opendesk-edu/helmfile/apps/self-service-password/values.yaml.gotmpl`. Simple standalone service.

**Files:**
- Reference: `opendesk-edu/helmfile/apps/self-service-password/values.yaml.gotmpl`

- [ ] **Step 1: Read helmfile and values**

- [ ] **Step 2: Deploy**

```bash
helmfile -e test -f apps/self-service-password/helmfile.yaml.gotmpl sync
```

- [ ] **Step 3: Verify**

```bash
kubectl get pods -l app.kubernetes.io/name=self-service-password -n opendesk
```

### Task 6: Deploy Collab Dashboard

**Context:** Chart at `opendesk-edu/helmfile/apps/collab-dashboard/values.yaml.gotmpl`. Dashboard for collab services.

**Files:**
- Reference: `opendesk-edu/helmfile/apps/collab-dashboard/values.yaml.gotmpl`

- [ ] **Step 1: Read helmfile and values**

- [ ] **Step 2: Deploy**

```bash
helmfile -e test -f apps/collab-dashboard/helmfile.yaml.gotmpl sync
```

- [ ] **Step 3: Verify**

```bash
kubectl get pods -l app.kubernetes.io/name=collab-dashboard -n opendesk
```

### Task 7: Deploy OpenWebUI + Ollama

**Context:** OpenWebUI (ChatGPT-compatible web UI) + Ollama (LLM runner). Charts at `opendesk-edu/helmfile/apps/open-webui/` and `opendesk-edu/helmfile/apps/ollama/`. Both enabled in test values but not running.

**Files:**
- Reference: `opendesk-edu/helmfile/apps/open-webui/values.yaml.gotmpl`
- Reference: `opendesk-edu/helmfile/apps/ollama/values.yaml.gotmpl`

- [ ] **Step 1: Read both helmfiles to understand GPU/node requirements**

Ollama likely needs GPU node affinity. Check if the cluster has GPU nodes.

- [ ] **Step 2: Check if Ollama requires GPU**

If it does and the cluster has no GPU nodes, this task is blocked — skip and document.

- [ ] **Step 3: If no GPU required, deploy both**

```bash
helmfile -e test -f apps/ollama/helmfile.yaml.gotmpl sync
helmfile -e test -f apps/open-webui/helmfile.yaml.gotmpl sync
```

- [ ] **Step 4: Verify**

```bash
kubectl get pods -l 'app.kubernetes.io/name in (ollama,open-webui)' -n opendesk
```

### Task 8: Deploy RStudio + TTYD + CodeServer

**Context:** Developer tools — RStudio (R IDE), TTYD (terminal), CodeServer (VS Code in browser). Charts exist but pods not running.

**Files:**
- Reference: `opendesk-edu/helmfile/apps/rstudio/values.yaml.gotmpl`
- Reference: `opendesk-edu/helmfile/apps/ttyd/values.yaml.gotmpl`
- Reference: `opendesk-edu/helmfile/apps/code-server/values.yaml.gotmpl`

- [ ] **Step 1: Read helmfiles for all three**

Check dependencies, PVC requirements, node selectors.

- [ ] **Step 2: Deploy each**

```bash
helmfile -e test -f apps/rstudio/helmfile.yaml.gotmpl sync
helmfile -e test -f apps/ttyd/helmfile.yaml.gotmpl sync
helmfile -e test -f apps/code-server/helmfile.yaml.gotmpl sync
```

- [ ] **Step 3: Verify all three**

```bash
kubectl get pods -l 'app.kubernetes.io/name in (rstudio,ttyd,code-server)' -n opendesk
```

### Task 9: Add missing portal entries

**Context:** After deploying new services, they need portal entries for visibility. Check which services already have entries in `opendesk-edu/helmfile/apps/nubus/values-nubus.yaml.gotmpl`.

**Files:**
- Reference: `opendesk-edu/helmfile/apps/nubus/values-nubus.yaml.gotmpl` (portal entries 07-17)

- [ ] **Step 1: Audit which deployed services have portal entries**

Check entries 03 (ILIAS), 04 (Moodle — disabled), 07 (Etherpad), 08 (BookStack), 09 (Planka), 12 (DrawIO), 13 (Excalidraw), 14 (SSP), 15 (SOGo).

Missing entries for: Self-Service Password, Collab Dashboard, OpenWebUI, RStudio, TTYD, CodeServer.

- [ ] **Step 2: Add portal entries for services that need them**

For each missing service, follow the pattern from existing entries (e.g., 07-custom-etherpad-portal-entry.yaml):
- Set `activated: true`, `anonymous: false`
- Set `linkTarget: "newwindow"`
- Set appropriate `displayName` and `description` in de_DE and en_US
- Set `link` URL to the service's ingress URL
- Add to `cn=od.applications` category

- [ ] **Step 3: Deploy updated nubus bootstrap**

```bash
helmfile -e test -f apps/nubus/helmfile.yaml.gotmpl sync
```

---

## Out of Scope

- **Moodle** — disabled in test values, needs custom Docker image rebuild for ICS integration
- **JupyterHub** — no Helm chart exists in repo, blocked on chart creation
- **Overleaf** — disabled in test values
- **KasmVNC** — disabled in test values
- **Dask** — disabled in test values
