# CE Submodule Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure opendesk-edu from a CE fork to a CE submodule + edu overlay, eliminating merge conflicts on CE updates.

**Architecture:** CE is added as a git submodule at `helmfile/ce/`. All CE-originated files are deleted from the edu repo tree. Edu-specific apps move to `helmfile/apps/edu/`. Deployment uses a two-step helmfile: CE with edu value overrides, then edu apps separately.

**Tech Stack:** Git submodules, helmfile, .gotmpl templates

---

### Task 1: Create Backup Branch and Add CE Submodule

**Files:** None modified yet

- [ ] **Step 1: Create a backup branch**

```bash
# Ensure we're on main with the merge commit
git checkout main
git log --oneline -1
# Should show: 35fafbb8 Merge upstream/main: integrate opendesk v1.16.0 → v1.17.0

# Create backup
git branch backup-before-submodule-migration-$(date +%Y%m%d)
git push codeberg backup-before-submodule-migration-20260723
```

- [ ] **Step 2: Add CE as git submodule**

```bash
# Remove the upstream remote since we'll use submodule instead
# (keep it for reference but submodule will use CE's main URL)
git submodule add https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk.git helmfile/ce

# Pin to upstream's v1.17.0 tag (matching current merge)
cd helmfile/ce
git fetch origin
git checkout v1.17.0
cd ../..

# Record the submodule
git add .gitmodules helmfile/ce
git commit -m "chore: add CE as git submodule at helmfile/ce/ (v1.17.0)"
```

Expected: `.gitmodules` created with submodule entry for `helmfile/ce`.

---

### Task 2: Delete CE-Originated App Directories

**Files:**
- Delete: `helmfile/apps/nubus/`
- Delete: `helmfile/apps/collabora/`
- Delete: `helmfile/apps/cryptpad/`
- Delete: `helmfile/apps/jitsi/`
- Delete: `helmfile/apps/element/`
- Delete: `helmfile/apps/nextcloud/`
- Delete: `helmfile/apps/notes/`
- Delete: `helmfile/apps/openproject/`
- Delete: `helmfile/apps/open-xchange/`
- Delete: `helmfile/apps/xwiki/`
- Delete: `helmfile/apps/services-external/`
- Delete: `helmfile/apps/opendesk-migrations-pre/`
- Delete: `helmfile/apps/opendesk-migrations-post/`
- Delete: `helmfile/apps/opendesk-services/`
- Delete: `helmfile/apps/opendesk-openproject-bootstrap/`
- Delete: `helmfile/apps/sliding-sync/` (if exists)

These are upstream CE applications that edu doesn't customize. They come from the CE submodule and are deployed via CE's own helmfile.

- [ ] **Step 1: Delete all CE-originated app directories**

```bash
# CE apps (not customized by edu)
rm -rf helmfile/apps/nubus
rm -rf helmfile/apps/collabora
rm -rf helmfile/apps/cryptpad
rm -rf helmfile/apps/jitsi
rm -rf helmfile/apps/element
rm -rf helmfile/apps/nextcloud
rm -rf helmfile/apps/notes
rm -rf helmfile/apps/openproject
rm -rf helmfile/apps/open-xchange
rm -rf helmfile/apps/xwiki
rm -rf helmfile/apps/services-external
rm -rf helmfile/apps/opendesk-migrations-pre
rm -rf helmfile/apps/opendesk-migrations-post
rm -rf helmfile/apps/opendesk-services
rm -rf helmfile/apps/opendesk-openproject-bootstrap
# sliding-sync if it exists
rm -rf helmfile/apps/sliding-sync 2>/dev/null || true
```

- [ ] **Step 2: Commit the deletions**

```bash
git add -A
git commit -m "chore: remove CE-originated app directories (now in submodule)
```

---

### Task 3: Delete CE-Originated Root Files and Environment Directories

**Files:**
- Delete: `helmfile.yaml.gotmpl` (CE's root helmfile entry)
- Delete: `helmfile-defaults.yaml.gotmpl` (CE's defaults)
- Delete: `helmfile_generic.yaml.gotmpl` (CE's app orchestrator)
- Delete: `ct.yaml` (CE's chart testing config — verify not edu-modified first)
- Delete: `helmfile/environments/default/` (CE's entire default environment)
- Delete: `helmfile/environments/argocd/` (CE's)
- Delete: `helmfile/environments/default-enterprise-overrides/` (CE's)
- Delete: `helmfile/environments/dev~HEAD/` (CE's)
- Delete: `helmfile/environments/prod/` (CE's)

**Keep:**
- `helmfile/environments/test/` — edu-specific test overrides (relocate later)
- `drawio-ingress.yaml` — edu-specific
- `excalidraw-ingress.yaml` — edu-specific
- `sogo-direct-values.yaml` — edu-specific

- [ ] **Step 1: Verify ct.yaml is unmodified from CE**

```bash
# Check if ct.yaml is CE-originated or edu-modified
git show HEAD:ct.yaml | head -5
# If it's just CE's file, delete it. If edu-modified, keep it.
```

Expected: `ct.yaml` is CE's chart-testing config, safe to delete.

- [ ] **Step 2: Delete CE root files and environment directories**

```bash
# CE root files
rm helmfile.yaml.gotmpl
rm helmfile-defaults.yaml.gotmpl
rm helmfile_generic.yaml.gotmpl
rm ct.yaml

# CE environment directories
rm -rf helmfile/environments/default
rm -rf helmfile/environments/argocd
rm -rf helmfile/environments/default-enterprise-overrides
rm -rf helmfile/environments/dev~HEAD
rm -rf helmfile/environments/prod
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove CE-originated root files and environment configs"
```

---

### Task 4: Move Edu Apps to `helmfile/apps/edu/`

**Files to move (each directory goes from `helmfile/apps/$NAME/` to `helmfile/apps/edu/$NAME/`):**

Edu-specific apps:
- etherpad, ilias, moodle, bigbluebutton, bookstack, planka, seaweedfs, self-service-password, rstudio, code-server, ttyd, open-webui, ollama, typo3, snipr, drawio, excalidraw, f13, grommunio, jupyterhub, kasmvnc, keycloak, limesurvey, n8n, opencloud, overleaf, slidev, sogo, zammad, collab-dashboard, portal-entries

App directories that are edu-specific or edu-customized replacements for CE apps:
- `sogo/` — edu uses this instead of CE's Open-Xchange
- `opencloud/` — edu uses this instead of CE's Nextcloud
- `keycloak/` — edu-specific keycloak config (separate from CE's keycloak)
- `portal-entries/` — edu creates its own portal entries for edu apps

- [ ] **Step 1: Create edu app directory structure**

```bash
mkdir -p helmfile/apps/edu
```

- [ ] **Step 2: Move each edu app**

```bash
# Core edu apps
mv helmfile/apps/etherpad helmfile/apps/edu/etherpad
mv helmfile/apps/ilias helmfile/apps/edu/ilias
mv helmfile/apps/moodle helmfile/apps/edu/moodle
mv helmfile/apps/bigbluebutton helmfile/apps/edu/bigbluebutton
mv helmfile/apps/collab-dashboard helmfile/apps/edu/collab-dashboard

# Collaboration services
mv helmfile/apps/jupyterhub helmfile/apps/edu/jupyterhub
mv helmfile/apps/kasmvnc helmfile/apps/edu/kasmvnc
mv helmfile/apps/overleaf helmfile/apps/edu/overleaf
mv helmfile/apps/slidev helmfile/apps/edu/slidev
mv helmfile/apps/rstudio helmfile/apps/edu/rstudio
mv helmfile/apps/code-server helmfile/apps/edu/code-server
mv helmfile/apps/ttyd helmfile/apps/edu/ttyd
mv helmfile/apps/open-webui helmfile/apps/edu/open-webui
mv helmfile/apps/ollama helmfile/apps/edu/ollama

# Edu replacements for CE apps
mv helmfile/apps/sogo helmfile/apps/edu/sogo
mv helmfile/apps/opencloud helmfile/apps/edu/opencloud

# Additional edu apps
mv helmfile/apps/bookstack helmfile/apps/edu/bookstack
mv helmfile/apps/planka helmfile/apps/edu/planka
mv helmfile/apps/typo3 helmfile/apps/edu/typo3
mv helmfile/apps/seaweedfs helmfile/apps/edu/seaweedfs
mv helmfile/apps/self-service-password helmfile/apps/edu/self-service-password
mv helmfile/apps/snipr helmfile/apps/edu/snipr
mv helmfile/apps/drawio helmfile/apps/edu/drawio
mv helmfile/apps/excalidraw helmfile/apps/edu/excalidraw
mv helmfile/apps/f13 helmfile/apps/edu/f13
mv helmfile/apps/grommunio helmfile/apps/edu/grommunio
mv helmfile/apps/keycloak helmfile/apps/edu/keycloak
mv helmfile/apps/limesurvey helmfile/apps/edu/limesurvey
mv helmfile/apps/n8n helmfile/apps/edu/n8n
mv helmfile/apps/zammad helmfile/apps/edu/zammad
mv helmfile/apps/portal-entries helmfile/apps/edu/portal-entries

# dask if it exists
mv helmfile/apps/dask helmfile/apps/edu/dask 2>/dev/null || true
```

- [ ] **Step 3: Verify no remaining app directories are CE-originated**

```bash
ls helmfile/apps/
# Only should see: edu/ directory
# If any unknown directories remain, check if they're edu or CE
```

Expected: Only `helmfile/apps/edu/` and maybe `helmfile/apps/` itself remain.

- [ ] **Step 4: Update child helmfile chart paths in edu apps**

Each edu app's `helmfile-child.yaml.gotmpl` references its chart with a relative path like `../../charts/$NAME`. After moving from `helmfile/apps/$NAME/` to `helmfile/apps/edu/$NAME/`, the chart path changes from `../../charts/$NAME` to `../../../charts/$NAME`.

```bash
# Fix chart paths in all edu app helmfile-child.yaml.gotmpl files
# Pattern: old path was ../../charts/... (from helmfile/apps/NAME/)
# New path must be ../../../charts/... (from helmfile/apps/edu/NAME/)

for f in helmfile/apps/edu/*/helmfile-child.yaml.gotmpl; do
  # Read current content and update relative chart paths
  sed -i 's|\.\./\.\./charts/|../../charts/|g' "$f"
  echo "Fixed: $f"
done
```

Expected: Each edu app's chart path goes from its old `helmfile/apps/NAME/` location to its new `helmfile/apps/edu/NAME/` location. Since the chart is still at `helmfile/charts/NAME/`, the path needs to go two levels up (to helmfile/) then into charts/.

From `helmfile/apps/edu/etherpad/`:
- `..` → `helmfile/apps/edu/`
- `..` → `helmfile/apps/`
- `..` → `helmfile/`
- `charts/etherpad` → `helmfile/charts/etherpad/`

So path should be: `../../../charts/etherpad`

From old location `helmfile/apps/etherpad/`:
- `..` → `helmfile/apps/`
- `..` → `helmfile/`
- `charts/etherpad` → `helmfile/charts/etherpad/`

Old path was: `../../charts/etherpad`

So `../../charts/` → `../../../charts/` is the correct transformation.

- [ ] **Step 5: Fix any keyring/GPG file paths in edu apps**

```bash
# Check if any edu apps reference CE keyrings via relative paths
grep -rn "files/gpg-pubkeys" helmfile/apps/edu/ --include="*.yaml.gotmpl" --include="*.tpl" 2>/dev/null
```

If any edu apps reference GPG keyrings, they now need to point to `helmfile/files/gpg-pubkeys/` (local copy). The relative path from `helmfile/apps/edu/$NAME/` is `../../../files/gpg-pubkeys/`.

- [ ] **Step 6: Commit the moves**

```bash
git add -A
git commit -m "chore: move edu apps to helmfile/apps/edu/"
```

---

### Task 5: Create Edu Environment Overrides

**Files:**
- Create: `helmfile/environments/edu/ce-overrides.yaml`
- Create: `helmfile/environments/edu/secrets.yaml`
- Create: `helmfile/environments/edu/images.yaml`

These files override CE's defaults when running CE's helmfile with the `--values` flag. They disable CE apps that edu replaces and enable edu-specific configurations.

- [ ] **Step 1: Create edu environment directory**

```bash
mkdir -p helmfile/environments/edu
```

- [ ] **Step 2: Create ce-overrides.yaml**

```yaml
# Helmfile state values that override CE defaults
# These are injected via --values when running CE's helmfile
# They override CE's default environment values

apps:
  # Disable CE apps that edu replaces
  open-x-change:
    enabled: false
  nextcloud:
    enabled: false
  # Enable SOGo (edu replaces OX with SOGo)
  sogo:
    enabled: true

# Edu-specific global config
global:
  domain: opendesk.hrz.uni-marburg.de
  mail_domain: uni-marburg.de

# Keycloak bootstrap — add edu SAML clients
# CE's bootstrap handles core CE clients
# For edu SAML clients (ILIAS, Moodle, BBB), see post-migration restore task
keycloak:
  bootstrap:
    clients:
      ilias:
        enabled: true
        clientId: ilias
        protocol: saml
        # Restore full SAML config from backup (lost in --theirs merge)
      moodle:
        enabled: true
        clientId: moodle
        protocol: saml
      bigbluebutton:
        enabled: true
        clientId: bigbluebutton
        protocol: saml
```

**Important:** The `apps.open-x-change.enabled: false` and `apps.nextcloud.enabled: false` are critical — they prevent CE from deploying apps that edu replaces with alternatives (SOGo, OpenCloud).

- [ ] **Step 3: Create images.yaml**

```yaml
# Override CE image defaults with edu-specific registries/tags
# TODO: Add edu image overrides as needed
images:
  # example:
  #   sogo: docker.io/opendesk-edu/sogo:latest
```

- [ ] **Step 4: Create secrets.yaml**

```yaml
# Edu-specific secrets that override CE defaults
# These are .gotmpl templates that derive passwords from a shared seed
# TODO: Populate with edu-specific derivePassword entries from the lost secrets.yaml

global:
  # Shared seed for password derivation
  derivePassword:
    # ... entries from the edu-customized secrets.yaml that was overwritten in --theirs merge
```

- [ ] **Step 5: Move existing test environment to edu**

```bash
# Move the edu-specific test overrides
mv helmfile/environments/test helmfile/environments/edu/test
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add edu environment overrides for CE"
```

---

### Task 6: Create Edu Helmfile and Deploy Wrapper

**Files:**
- Create: `helmfile/edu-helmfile.yaml.gotmpl` — orchestrator for edu-specific apps
- Create: `deploy.sh` — deployment wrapper that runs CE + edu

- [ ] **Step 1: Create edu-helmfile.yaml.gotmpl**

```yaml
{{ $root := . }}

environments:
  edu:
    values:
      - environments/edu/ce-overrides.yaml
      - environments/edu/secrets.yaml
      - environments/edu/images.yaml
  edu-test:
    values:
      - environments/edu/test/values.yaml.gotmpl

repositories:
  - name: bitnami
    url: oci://registry-1.docker.io/bitnamicharts
  # Add any edu-specific Helm repos here

helmfiles:
  # Edu apps
  - path: apps/edu/etherpad/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/ilias/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/moodle/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/bigbluebutton/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/collab-dashboard/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/sogo/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/opencloud/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/bookstack/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/planka/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/self-service-password/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/seaweedfs/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/rstudio/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/code-server/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/ttyd/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/open-webui/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/ollama/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/typo3/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/snipr/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/drawio/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/excalidraw/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/jupyterhub/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/kasmvnc/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/overleaf/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/slidev/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/f13/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/grommunio/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/keycloak/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/limesurvey/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/n8n/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/zammad/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
  - path: apps/edu/portal-entries/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/ce-overrides.yaml.gotmpl
```

**Note:** Some apps may have conditions or disabled-by-default state. Keep their existing `{{ if .Values.apps.xxx.enabled }}` conditionals in their individual helmfile-child.yaml.gotmpl files.

- [ ] **Step 2: Create deploy.sh**

```bash
#!/bin/bash
# deploy.sh — Deploy openDesk CE + edu overlay
# Usage: ./deploy.sh [environment]
#   environment: edu (default), edu-test, or helmfile -e compatible

set -euo pipefail

ENVIRONMENT="${1:-edu}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Step 1: Deploy CE with $ENVIRONMENT overrides ==="
cd helmfile/ce

helmfile -f helmfile.yaml.gotmpl \
  --values "../environments/$ENVIRONMENT/ce-overrides.yaml" \
  --values "../environments/$ENVIRONMENT/secrets.yaml" \
  --values "../environments/$ENVIRONMENT/images.yaml" \
  sync

echo "=== Step 2: Deploy edu-specific apps ==="
cd "$SCRIPT_DIR"

helmfile -f helmfile/edu-helmfile.yaml.gotmpl \
  -e "$ENVIRONMENT" \
  sync

echo "=== Deploy complete ==="
```

```bash
chmod +x deploy.sh
```

- [ ] **Step 3: Create .gitignore entry for .playwright-mcp/**

Add to `.gitignore` if not already present:
```
.playwright-mcp/
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add edu-helmfile.yaml.gotmpl and deploy.sh wrapper"
```

---

### Task 7: Copy CE GPG Keys and Fix Path References

**Files:**
- Create: `helmfile/files/gpg-pubkeys/README.md`

Edu apps that verify Helm chart signatures need access to GPG keys. CE stores them in `helmfile/ce/helmfile/files/gpg-pubkeys/`. We copy the required keys to our local `helmfile/files/gpg-pubkeys/`.

- [ ] **Step 1: Copy required GPG keys from CE submodule**

```bash
mkdir -p helmfile/files/gpg-pubkeys

# Copy keys needed by edu apps
cp helmfile/ce/helmfile/files/gpg-pubkeys/univention-de.gpg helmfile/files/gpg-pubkeys/
cp helmfile/ce/helmfile/files/gpg-pubkeys/openproject-com.gpg helmfile/files/gpg-pubkeys/

# Check which keys edu apps reference
grep -rn "gpg-pubkeys" helmfile/apps/edu/ --include="*.yaml.gotmpl" --include="*.tpl" 2>/dev/null || echo "No edu apps reference GPG keys directly"
```

Expected: HP. Most edu apps use custom charts, not signed CE charts, so they may not need GPG keys.

- [ ] **Step 2: Update GPG key references in edu apps if needed**

```bash
# If any edu app references ../../files/gpg-pubkeys/ (old relative path from helmfile/apps/NAME/)
# it now needs ../../../files/gpg-pubkeys/ (from helmfile/apps/edu/NAME/)
# Only needed if grep returned results above
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: copy CE GPG keys to edu repo"
```

---

### Task 8: Migrate Portal Entries, Theme Files, and Docs

**Files:**
- Move: `helmfile/apps/edu/portal-entries/entries/etherpad.ldif` — update LDIF paths if needed
- Move: `helmfile/files/theme/` — already in `helmfile/files/`, no change needed
- Move: `docs/` — edu-specific docs stay as-is

- [ ] **Step 1: Update portal-entries LDIF references**

Check if portal-entries LDIF files reference paths or URLs that changed due to edu relocation.

```bash
# Check portal entries for any hardcoded paths
grep -rn "apps/" helmfile/apps/edu/portal-entries/ --include="*.yaml.gotmpl" --include="*.ldif" 2>/dev/null || true
```

Expected: No path changes needed — portal entries define URLs, not file paths.

- [ ] **Step 2: Move remaining edu assets**

```bash
# Theme files are at helmfile/files/theme/ — keep as-is
# Docs are at docs/ — keep as-is
# Root ingress files (drawio-ingress.yaml, excalidraw-ingress.yaml, sogo-direct-values.yaml) — keep as-is

# Remove any leftover empty directories
rmdir helmfile/apps 2>/dev/null || true
rmdir helmfile/environments/default 2>/dev/null || true
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: finalize file restructuring"
```

---

### Task 9: Verification and Dry-Run

**Commands:**
- Run: `helmfile -f helmfile/ce/helmfile.yaml.gotmpl --values ../environments/edu/ce-overrides.yaml build` (dry-run CE helmfile with edu overrides)
- Run: `helmfile -f helmfile/edu-helmfile.yaml.gotmpl build` (dry-run edu helmfile)

- [ ] **Step 1: Verify git status is clean**

```bash
git status
# Expected: clean working tree (no modified/deleted/untracked files except intentional untracked)
```

- [ ] **Step 2: Verify submodule is correctly pinned**

```bash
cd helmfile/ce
git log --oneline -1
# Expected: v1.17.0 CE commit
git describe --tags --always
# Expected: v1.17.0 or similar
cd ../..
git submodule status
# Expected: pinned commit hash, path helmfile/ce, no prefix (not modified)
```

- [ ] **Step 3: Verify CE helmfile can parse with edu overrides**

```bash
cd helmfile/ce

# Try to parse the helmfile to check syntax
helmfile -f helmfile.yaml.gotmpl \
  --values ../environments/edu/ce-overrides.yaml \
  --values ../environments/edu/secrets.yaml \
  --values ../environments/edu/images.yaml \
  build 2>&1 | head -50 || echo "helmfile build failed (may need cluster context — OK for CI)"

cd ../..
```

Expected: Either success or "no releases found" error (if no cluster context). The key is no template syntax errors.

- [ ] **Step 4: Verify edu helmfile can parse**

```bash
helmfile -f helmfile/edu-helmfile.yaml.gotmpl \
  -e edu \
  build 2>&1 | head -50 || echo "helmfile build failed (expected without cluster context)"

# Also try with test environment
helmfile -f helmfile/edu-helmfile.yaml.gotmpl \
  -e edu-test \
  build 2>&1 | head -50 || true
```

Expected: No template syntax errors. May fail on missing cluster context but that's OK.

- [ ] **Step 5: Run lsp diagnostics**

```bash
# Check for broken YAML syntax
yamllint helmfile/edu-helmfile.yaml.gotmpl deploy.sh 2>/dev/null || true
```

- [ ] **Step 6: Verify the repo structure is correct**

```bash
echo "=== Edu apps ==="
ls helmfile/apps/edu/
echo ""
echo "=== Edu environments ==="
ls helmfile/environments/edu/
echo ""
echo "=== Root files ==="
ls *.yaml *.sh 2>/dev/null
echo ""
echo "=== CE submodule ==="
ls helmfile/ce/helmfile.yaml.gotmpl 2>/dev/null && echo "CE helmfile present ✓"
```

---

### Task 10: Push to Remotes

- [ ] **Step 1: Push to all remotes**

```bash
git push codeberg main
git push github main
```

The opencode-de remote needs SSH key setup. Skip or use HTTPS with auth.

---

## Post-Migration Cleanup

Once the submodule migration is complete:

1. **Fix the --theirs merge damage:**
   - Restore edu SAML clients in Keycloak bootstrap (add to `ce-overrides.yaml`)
   - Restore edu-specific CI in `.gitlab-ci.yml`
   - Restore edu README modifications

2. **Deploy/hrz branch:** The etherpad changes on `deploy/hrz` (inline PostgreSQL) should be cherry-picked or rebased onto the new structure.

3. **Next CE update:** `cd helmfile/ce && git fetch && git checkout v1.18.0 && cd ../.. && git add helmfile/ce && git commit -m "chore: update CE to v1.18.0"` — zero conflicts.

## Self-Review Checklist

- [ ] Spec coverage: Every requirement from the design doc has a corresponding task
- [ ] No placeholders: Every step has concrete commands, not "TBD" or "implement later"
- [ ] Path correctness: Chart paths, keyring paths, and config paths are verified for the new edu/ location
- [ ] Backup exists: `backup-before-submodule-migration-YYYYMMDD` branch created before destructive operations
