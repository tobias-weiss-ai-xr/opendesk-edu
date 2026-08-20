# openDesk Platform Upgrade 1.12.2 → 1.13.2

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the HRZ openDesk deployment from v1.12.2 to v1.13.2, integrating 5 upstream commits while preserving security hardening customizations.

**Architecture:** Merge upstream/develop into the local security-hardening branch, resolve conflicts (keep hardened security contexts), update chart/image versions, then deploy via helmfile sync.

**Tech Stack:** Helmfile, Helm, K3s v1.32.3, openDesk platform

---

## Pre-flight Assessment

### Current State
- **Cluster**: K3s v1.32.3, 9 nodes, all Ready
- **Namespace**: `opendesk` — 37 Helm releases deployed
- **Git branch**: `security-hardening` in `/home/weissto_local/git/opendesk_git/opendesk/`
- **Upstream**: `upstream/develop` at `f241ecc5` (v1.13.2)
- **Behind**: 5 commits (small diff — 13 files)

### Diff Summary (security-hardening → upstream/develop)

| File | Change Type | Conflict Risk |
|---|---|---|
| `helmfile/apps/jitsi/values.yaml.gotmpl` | Security: `capabilities: drop ALL` → `capabilities: {}` | 🔴 **CONFLICT** — keep hardened |
| `helmfile/apps/nubus/values-nubus.yaml.gotmpl` | Security: SSSD caps relaxed, Keycloak readOnlyRootFilesystem | 🔴 **CONFLICT** — keep hardened |
| `helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl` | New: `pauseBeforeScriptStart: 180` | 🟢 Clean merge |
| `helmfile/apps/open-xchange/values-openxchange-contact-picker.yaml.gotmpl` | Feature: contact picker restructure + distribution lists | 🟡 Review needed |
| `helmfile/apps/open-xchange/values-postfix.yaml.gotmpl` | Security: caps/user relaxed | 🔴 **CONFLICT** — keep hardened |
| `helmfile/apps/services-external/values-dkimpy.yaml.gotmpl` | Security: caps relaxed | 🔴 **CONFLICT** — keep hardened |
| `helmfile/apps/services-external/values-postfix.yaml.gotmpl` | Security: caps/user relaxed | 🔴 **CONFLICT** — keep hardened |
| `helmfile/environments/default/charts.yaml.gotmpl` | Chart: Nextcloud 4.9.1 → 4.9.3 | 🟢 Clean merge |
| `helmfile/environments/default/images.yaml.gotmpl` | Image: Nextcloud mgmt 2.14.0 → 2.14.7 | 🟢 Clean merge |
| `helmfile/environments/default/global.generated.yaml.gotmpl` | Version: 1.13.1 → 1.13.2 | 🟢 Clean merge |
| `helmfile/environments/default-enterprise-overrides/images.yaml.gotmpl` | Image: Nextcloud EE 1.8.5 → 1.8.11 | 🟢 Clean merge |
| `CHANGELOG.md` | Docs: changelog entries | 🟢 Clean merge |
| `publiccode.yml` | Docs: metadata | 🟢 Clean merge |

### Upstream Migration Requirements (from migrations.md)

**Pre-upgrade to v1.13.0:**
1. ~~Remove legacy Ingress object~~ — Already on HAProxy, not applicable
2. **Nubus/OX Ingress annotation changes** — Check if custom annotations exist

**Pre-upgrade to v1.12.0 (already done, verify):**
1. ~~Keycloak user import~~ — Already at 1.12.1+
2. ~~Jitsi 2.x uninstall~~ — Already on Jitsi 3.6.1
3. ~~StorageClassName templating~~ — Check PVC status
4. ~~Postfix SASL TLS security options~~ — Verify mail delivery works

**Post-upgrade to v1.12.0:**
1. **XWiki user merge** — Run script if uppercase usernames exist
2. **External mail routing** — Check if needed

---

## Tasks

### Task 1: Pre-upgrade Verification

- [ ] **Step 1: Verify current cluster health**

Run: `kubectl get pods -n opendesk --no-headers | grep -vE 'Running.*0|Completed' | wc -l`
Expected: 0 (all pods healthy after previous fixes)

- [ ] **Step 2: Verify current backup status**

Run: `kubectl get jobs -n opendesk --no-headers | grep backup | tail -5`
Expected: Recent completed backup jobs

- [ ] **Step 3: Take git snapshot**

Run:
```bash
cd /home/weissto_local/git/opendesk_git/opendesk
git stash
git checkout security-hardening
git tag pre-upgrade-1.13.2 security-hardening
```

- [ ] **Step 4: Check for uppercase XWiki usernames**

Run: `kubectl exec -n opendesk deploy/opendesk-opencloud -- curl -s http://localhost:8080/rest/wikis/xwiki/query?q=SELECT%20doc.fullName%20FROM%20Document%20doc%20WHERE%20doc.fullName%20LIKE%20'XWiki.%25' | python3 -c "import sys,json; data=json.load(sys.stdin); [print(x) for x in data.get('results',[])]" 2>&1 | grep -P '[A-Z]'`
Expected: If results found, the XWiki user merge script must be run post-upgrade.

- [ ] **Step 5: Verify PVC storage class status**

Run: `kubectl get pvc -n opendesk -o custom-columns='NAME:.metadata.name,CLASS:.spec.storageClassName,STATUS:.status.phase' | grep -v ceph-rbd-ssd`
Expected: No PVCs with missing storageClassName (the 1.12.0 templating fix)

### Task 2: Merge Upstream

- [ ] **Step 1: Fetch latest upstream**

Run:
```bash
cd /home/weissto_local/git/opendesk_git/opendesk
git fetch upstream
```

- [ ] **Step 2: Create merge branch**

Run:
```bash
git checkout security-hardening
git checkout -b merge-1.13.2-upstream
```

- [ ] **Step 3: Attempt merge**

Run:
```bash
git merge upstream/develop --no-commit
```
Expected: Conflicts on security-hardened files (jitsi, nubus, postfix, dkimpy)

### Task 3: Resolve Conflicts (Security Contexts)

> **CRITICAL**: Keep the hardened security contexts from security-hardening branch. Do NOT accept upstream's relaxed versions.

- [ ] **Step 1: List conflicts**

Run: `git diff --name-only --diff-filter=U`
Expected: helmfile/apps/jitsi/values.yaml.gotmpl, helmfile/apps/nubus/values-nubus.yaml.gotmpl, helmfile/apps/open-xchange/values-postfix.yaml.gotmpl, helmfile/apps/services-external/values-postfix.yaml.gotmpl, helmfile/apps/services-external/values-dkimpy.yaml.gotmpl

- [ ] **Step 2: Resolve each conflict — keep hardened (ours) version for security contexts**

For each conflicting file, the resolution strategy is:
- **Security context blocks**: Keep `security-hardening` version (ours) — `capabilities: drop: ALL`, `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`
- **Non-security changes in same file**: Accept upstream's functional changes

Resolution pattern:
```bash
# For files with ONLY security context changes (jitsi, dkimpy):
git checkout --ours helmfile/apps/jitsi/values.yaml.gotmpl
git checkout --ours helmfile/apps/services-external/values-dkimpy.yaml.gotmpl
git add helmfile/apps/jitsi/values.yaml.gotmpl helmfile/apps/services-external/values-dkimpy.yaml.gotmpl

# For files with MIXED changes (nubus, postfix-ox, postfix-ext):
# Manually edit to keep hardened security + accept functional changes
```

- [ ] **Step 3: For nubus/values-nubus.yaml.gotmpl — keep hardened security, accept pauseBeforeScriptStart**

The nubus file has two changes:
1. Keycloak `readOnlyRootFilesystem: true` → `false` → **KEEP true (ours)**
2. SSSD capabilities relaxed → **KEEP hardened (ours)**

Run: `git checkout --ours helmfile/apps/nubus/values-nubus.yaml.gotmpl && git add helmfile/apps/nubus/values-nubus.yaml.gotmpl`

- [ ] **Step 4: For postfix files — keep hardened security, accept any functional changes**

Run:
```bash
git checkout --ours helmfile/apps/open-xchange/values-postfix.yaml.gotmpl
git checkout --ours helmfile/apps/services-external/values-postfix.yaml.gotmpl
git add helmfile/apps/open-xchange/values-postfix.yaml.gotmpl helmfile/apps/services-external/values-postfix.yaml.gotmpl
```

- [ ] **Step 5: Verify keycloak bootstrap pauseBeforeScriptStart is included**

Run: `grep -A3 'pauseBeforeScriptStart' helmfile/apps/nubus/values-opendesk-keycloak-bootstrap.yaml.gotmpl`
Expected: `pauseBeforeScriptStart: 180` is present

If missing (because we kept ours and it didn't have this change), manually add it:
```yaml
  debug:
    enabled: {{ .Values.debug.enabled }}
    pauseBeforeScriptStart: 180
```

### Task 4: Review Non-conflicting Changes

- [ ] **Step 1: Review contact picker changes**

Run: `git diff --cached helmfile/apps/open-xchange/values-openxchange-contact-picker.yaml.gotmpl`
The contact picker restructure adds distribution lists and renames `functional` → `sharedMailboxes`, `other` → `noOrganization`. These are functional improvements — accept as-is.

- [ ] **Step 2: Review chart/image version bumps**

Run:
```bash
git diff --cached helmfile/environments/default/charts.yaml.gotmpl
git diff --cached helmfile/environments/default/images.yaml.gotmpl
```
Expected: Nextcloud charts 4.9.1 → 4.9.3, Nextcloud mgmt image 2.14.0 → 2.14.7, release version 1.13.2

### Task 5: Commit Merge

- [ ] **Step 1: Stage all resolved files**

Run: `git add -A`

- [ ] **Step 2: Verify staged changes**

Run: `git diff --cached --stat`
Expected: 13 files changed, security contexts preserved from security-hardening

- [ ] **Step 3: Commit**

Run:
```bash
git commit -m "merge upstream develop: v1.13.2 (preserving security hardening)

- Nextcloud charts 4.9.1 → 4.9.3, mgmt image 2.14.0 → 2.14.7
- OX contact picker: distribution lists, renamed sharedMailboxes/noOrganization
- Keycloak bootstrap: 180s pause to avoid parallel Nubus bootstrap
- Release version 1.13.2

Security hardening preserved: capabilities drop ALL, runAsNonRoot, readOnlyRootFilesystem
for jitsi, nubus/sssd, postfix-ox, postfix-ext, dkimpy"
```

### Task 6: Pre-deploy Checks

- [ ] **Step 1: Verify helmfile renders cleanly**

Run:
```bash
cd /home/weissto_local/git/opendesk_git/opendesk
helmfile -e <ENVIRONMENT> -n opendesk template 2>&1 | head -100
```
Replace `<ENVIRONMENT>` with the HRZ environment name (likely `default` or a custom env dir).
Expected: No YAML parse errors

- [ ] **Step 2: Run helmfile diff to preview changes**

Run:
```bash
helmfile -e <ENVIRONMENT> -n opendesk diff 2>&1 | tail -50
```
Expected: Shows which releases will be upgraded and what changes

- [ ] **Step 3: Verify image pullability**

Run:
```bash
# Test pull of new images
kubectl create job image-pull-test --image=registry.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-nextcloud:2.14.7@sha256:add34242164ee9e595015a3f98c75d54fb087a99865e0bbcef08470a3ecb49ac -n opendesk --dry-run=client -o yaml | kubectl apply -f -
```

### Task 7: Deploy

- [ ] **Step 1: Run helmfile sync**

Run:
```bash
helmfile -e <ENVIRONMENT> -n opendesk sync 2>&1
```
Expected: All releases synced successfully

- [ ] **Step 2: Monitor rollout**

Run:
```bash
kubectl get pods -n opendesk -w --no-headers
```
Wait until all pods reach Running state.

- [ ] **Step 3: Check for restarts**

Run: `kubectl get pods -n opendesk --no-headers | awk '$4+0 > 2'`
Expected: No pods with >2 restarts (except known benign ones like nextcloud-aio backup)

### Task 8: Post-deploy Verification

- [ ] **Step 1: Verify Nextcloud**

Run: `kubectl exec -n opendesk deploy/opendesk-nextcloud-aio -- curl -s http://localhost/status.php | python3 -m json.tool 2>&1 | grep -E 'version|status'`
Expected: status=ok, version shows PHP 8.x

- [ ] **Step 2: Verify OpenProject**

Run: `kubectl exec -n opendesk deploy/openproject -- curl -s http://localhost:8080/api/v3/status 2>&1 | head -5`
Expected: OpenProject 17.2.3 responding

- [ ] **Step 3: Verify OX contact picker**

Run: `kubectl logs -n opendesk deploy/open-xchange --tail=20 2>&1 | grep -iE 'error|contact|picker'`
Expected: No errors related to contact picker

- [ ] **Step 4: Run XWiki user merge script if needed**

Only if Step 1.4 found uppercase usernames. See migrations.md section "Wiki bug fix: User account merge for uppercase usernames".

### Task 9: Cleanup and Documentation

- [ ] **Step 1: Push merge branch to origin**

Run:
```bash
git push origin merge-1.13.2-upstream
```

- [ ] **Step 2: Tag release**

Run:
```bash
git tag hrz-v1.13.2
git push origin hrz-v1.13.2
```

- [ ] **Step 3: Delete old completed jobs**

Run:
```bash
kubectl delete jobs -n opendesk --field-selector=status.successful=true --ignore-not-found
```

---

## Rollback Plan

If the deployment fails:
1. `helmfile -e <ENVIRONMENT> -n opendesk sync --skip-deps` with previous release
2. Or: `git checkout pre-upgrade-1.13.2 && helmfile -e <ENVIRONMENT> -n opendesk sync`
3. Worst case: `kubectl rollout undo deployment/<release> -n opendesk` per component

## Risk Assessment

| Risk | Likelihood | Mitigation |
|---|---|---|
| Security context conflicts break pods | Medium | Test in non-prod first; pod may fail to start if upstream requires relaxed context |
| Contact picker restructure breaks OX | Low | Functional change, new feature addition |
| Nextcloud PHP 8.4 incompatibility | Low | Already running Nextcloud 32.x in 1.12.2 |
| Keycloak bootstrap timing issue | Low | 180s pause added by upstream |
| PVC migration issues | None | Already at 1.12.2, migrations done |
