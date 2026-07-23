# CE Upstream Integration — Git Submodule Architecture

**Spec v1.0** · 2026-07-23
**openDesk Edu v1.1**

---

## 1. Problem

The `opendesk-edu` repo is a full fork of the openDesk CE deployment repo. It contains all CE files plus edu-specific additions in a flat tree. Every upstream release (v1.16.0→v1.17.0) forces a merge of ~50 upstream commits across ~56 shared files. Conflicts arise because both repos modify the same files (environments, CI, docs, values, helmfile configs). The `--theirs` merge strategy used to resolve this discards edu customizations. Proper resolution is labor-intensive and error-prone.

## 2. Goal

Receive upstream CE updates without merge conflicts. CE and edu files must live in separate paths so git never sees them as the same file. Updating CE must be a one-line operation (`git checkout v1.18.0`).

## 3. Architecture

### 3.1 Repo Structure

```
opendesk-edu/
├── helmfile/
│   ├── ce/                          ← CE repo as git submodule (never modified)
│   │   ├── helmfile.yaml.gotmpl
│   │   ├── helmfile-defaults.yaml.gotmpl
│   │   ├── apps/                    ← CE apps (nubus, nextcloud, openproject, ...)
│   │   ├── charts/                  ← CE charts
│   │   ├── environments/default/    ← CE environment configs
│   │   └── files/gpg-pubkeys/       ← CE GPG keyring
│   │
│   ├── environments/edu/            ← Edu overrides for CE values
│   │   ├── ce-overrides.yaml        ← apps.open-xchange.enabled: false, etc.
│   │   ├── secrets.yaml             ← Edu-specific secret templates
│   │   └── images.yaml              ← Overridden image registries/tags
│   │
│   ├── apps/edu/                    ← Edu-specific apps
│   │   ├── etherpad/
│   │   │   ├── helmfile-child.yaml.gotmpl   (chart path: ../../charts/etherpad)
│   │   │   └── values.yaml.gotmpl
│   │   ├── ilias/
│   │   ├── moodle/
│   │   ├── bigbluebutton/
│   │   ├── collab-dashboard/
│   │   ├── rstudio/
│   │   ├── code-server/
│   │   ├── ttyd/
│   │   ├── open-webui/
│   │   ├── ollama/
│   │   ├── bookstack/
│   │   ├── planka/
│   │   ├── typo3/
│   │   ├── seaweedfs/
│   │   ├── self-service-password/
│   │   ├── sogo/
│   │   └── snipr/
│   │
│   ├── charts/                      ← Edu-specific Helm charts
│   │   ├── etherpad/
│   │   ├── collab-dashboard/
│   │   ├── ... (other edu charts)
│   │   └── portal-entries/
│   │
│   ├── portal-entries/              ← Portal entry LDIFs (edu services)
│   │   ├── entries/
│   │   │   ├── etherpad.ldif
│   │   │   └── ...
│   │   └── helmfile-child.yaml.gotmpl
│   │
│   ├── files/                       ← Copied CE assets (stable, small)
│   │   └── gpg-pubkeys/
│   │       ├── univention-de.gpg     ← copied from CE (small, stable)
│   │       └── openproject-de.gpg
│   │
│   ├── theme/                       ← Edu custom theme
│   │   └── edu_services/
│   │
│   └── edu-helmfile.yaml.gotmpl     ← Orchestrates edu-specific apps
│
├── deploy.sh                        ← Wrapper: runs CE + edu helmfile
├── .gitlab-ci.yml                   ← Edu-specific CI/CD
├── .gitmodules                      ← CE submodule definition
├── tests/                           ← Edu-specific tests
│   ├── integration/
│   └── config.yaml
├── docs/
│   ├── assets/
│   ├── local-customizations.md
│   └── superpowers/
└── README.md
```

### 3.2 Files Deleted from Edu Repo (now come from CE submodule)

**CE apps** — entire directories under `helmfile/apps/` that belong to CE:
- `nubus/`, `services-external/`, `opendesk-migrations-pre/`, `opendesk-migrations-post/`, `opendesk-services/`, `opendesk-openproject-bootstrap/`, `opendesk-keycloak-realm/`, `collabora/`, `cryptpad/`, `jitsi/`, `element/`, `nextcloud/`, `openproject/`, `xwiki/`, `open-xchange/`, `notes/`, `sliding-sync/`

**CE charts** (deleted, come from submodule):
- `nubus/`, `nextcloud/`, `openproject/`, `collabora/`, `cryptpad/`, `jitsi/`, `element/`, `postfix/`, `open-xchange/`, `xwiki/`, `univention-keycloak-bootstrap/`, `opendesk-services/`, `notes/`, `semester-provisioning/`

**Edu charts** (kept in edu repo — includes edu-customized versions of charts CE also has):
- `etherpad/`, `collab-dashboard/`, `sogo/` (edu-customized), `ilias/`, `moodle/`, `bigbluebutton/`, `bookstack/`, `planka/`, `typo3/`, `self-service-password/`, `rstudio/`, `code-server/`, `ttyd/`, `open-webui/`, `ollama/`, `portainer/`, `seaweedfs/`, `kasmvnc/`, `dask/`, `slidev/`, `jupyterhub/`, `snipr/`, `portal-entries/`, `overleaf/`

**CE root files (deleted):**
- `helmfile.yaml.gotmpl`, `helmfile-defaults.yaml.gotmpl` (CE expects these in its own directory)

**CE environment files (deleted):**
- `helmfile/environments/default/*` (CE environment configs)

**CE CI/metadata (deleted):**
- `.gitlab-ci.yml` (CE's pipeline), `CHANGELOG.md`, `publiccode.yml`

### 3.3 Deployment Flow

#### Step 1: Deploy CE with edu overrides

```bash
cd helmfile/ce

helmfile -f helmfile.yaml.gotmpl \
  -e default \
  --values ../environments/edu/ce-overrides.yaml \
  --values ../environments/edu/secrets.yaml \
  sync
```

This runs CE's helmfile with the `default` environment, but our edu values override CE defaults. The `--values` flag injects files globally, so all CE releases see our overrides.

#### Step 2: Deploy edu apps

```bash
cd ../..  # back to repo root

helmfile -f helmfile/edu-helmfile.yaml.gotmpl \
  sync
```

This runs only edu-specific apps from `helmfile/apps/edu/`.

### 3.4 Values Layering

Values are resolved in this order (last wins):

```
CE chart defaults
  → CE environment values (environments/default/)
    → CE environment specific (e.g., environments/prod/)
      → edu ce-overrides.yaml (--values flag)
        → edu secrets.yaml (--values flag)
```

Key edu overrides:

| CE Default | Edu Override | Mechanism |
|-----------|-------------|-----------|
| `apps.open-x-change.enabled: true` | `false` | ce-overrides.yaml |
| `apps.nextcloud.enabled: true` | `false` (using OpenCloud) | ce-overrides.yaml |
| `apps.sogo.enabled: false` | `true` | ce-overrides.yaml (or just runs as edu app) |
| Keycloak bootstrap SAML clients | Add ILIAS, Moodle, BBB clients | ce-overrides.yaml or separate edu bootstrap |
| Image registries/tags | Custom edu registry | images.yaml |

### 3.5 Path Resolution

Helmfile resolves relative paths in included child helmfiles relative to the including file's directory. This means:

| Reference | In File | Resolves To |
|-----------|---------|-------------|
| `../../files/gpg-pubkeys/...` | `helmfile/ce/helmfile/apps/nubus/helmfile-child.yaml.gotmpl` | `helmfile/ce/helmfile/files/gpg-pubkeys/...` ✅ |
| `../../charts/etherpad` | `helmfile/apps/edu/etherpad/helmfile-child.yaml.gotmpl` | `helmfile/charts/etherpad/` ✅ |
| `../../files/gpg-pubkeys/...` | `helmfile/apps/edu/etherpad/helmfile-child.yaml.gotmpl` | `helmfile/files/gpg-pubkeys/...` ✅ |

Edu apps that need CE GPG keys reference our local copy at `helmfile/files/gpg-pubkeys/`. We copy the required CE keys there (univention-de.gpg, openproject-de.gpg).

### 3.6 Updating CE

```bash
# Fetch latest upstream
cd helmfile/ce
git fetch origin

# Pin to a specific tag
git checkout v1.18.0

# Record the update in the edu repo
cd ../..
git add helmfile/ce
git commit -m "chore: update CE to v1.18.0"
```

**No merge conflicts.** CE is a submodule pointer — its files don't exist in the edu repo's tree. Edu files in `helmfile/apps/edu/`, `helmfile/environments/edu/`, etc. are in completely separate paths and are never touched by this operation.

### 3.7 Edu Helmfile Structure

The edu helmfile (`helmfile/edu-helmfile.yaml.gotmpl`) follows the same pattern as CE's helmfile but only includes edu apps:

```yaml
{{ $root := . }}
environments:
  edu:

repositories:
  - name: bitnami
    url: oci://registry-1.docker.io/bitnamicharts

releases:
  {{ range $app, $config := .Values.apps }}
  {{ if $config.enabled }}
  {{ if eq $app "etherpad" }}
  - name: etherpad
    namespace: edu
    chart: ./charts/etherpad
    values:
      - ./apps/edu/etherpad/values.yaml.gotmpl
    ...
  {{ end }}
  {{ end }}
  {{ end }}
```

Simpler approach: use helmfile `needs` and individual child helmfiles per app, matching CE's pattern:

```yaml
helmfiles:
  - path: apps/edu/etherpad/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/values.yaml.gotmpl
  - path: apps/edu/ilias/helmfile-child.yaml.gotmpl
    values:
      - environments/edu/values.yaml.gotmpl
  ...
```

### 3.8 CI/CD

The edu repo maintains its own `.gitlab-ci.yml`. It does not inherit CE's CI. The pipeline:

1. Checkout edu repo + init CE submodule
2. Run helmfile (CE + edu) against the target cluster
3. Run edu-specific tests

### 3.9 Keycloak Bootstrap (SAML Clients)

The most critical loss from the `--theirs` merge was the edu Keycloak bootstrap config. In the new architecture:

- CE's `univention-keycloak-bootstrap` handles core CE SAML clients (OX, Nextcloud, etc.) — untouched in submodule
- Edu's own keycloak bootstrap config (in `helmfile/environments/edu/ce-overrides.yaml` or a dedicated edu bootstrap app) adds edu SAML clients (ILIAS, Moodle, BBB)

This separation means CE can change its bootstrap format without affecting edu, and vice versa.

## 4. Migration Plan

### Phase 1: Preparation

1. Create backup branch of current state
2. Add CE as submodule at `helmfile/ce/` pinned to v1.17.0
3. Create `helmfile/apps/edu/` directory structure
4. Create `helmfile/environments/edu/` with initial overrides
5. Copy required GPG keys from CE submodule to `helmfile/files/gpg-pubkeys/`
6. Create `helmfile/edu-helmfile.yaml.gotmpl` orchestrator
7. Create `deploy.sh` wrapper

### Phase 2: File Migration

8. Move edu apps from `helmfile/apps/xxx/` to `helmfile/apps/edu/xxx/`
9. Move edu charts from `helmfile/charts/xxx/` to `helmfile/charts/xxx/` (keep location, CE charts already deleted)
10. Update child helmfile chart paths (one level deeper now)
11. Update portal-entries references for relocated apps

### Phase 3: CE File Removal

12. Delete CE app directories from edu repo
13. Delete CE chart directories from edu repo
14. Delete CE environment configs
15. Delete CE root helmfile files
16. Delete CE CI/metadata files

### Phase 4: Verification

17. Verify `helmfile -f helmfile/ce/helmfile.yaml.gotmpl --values ../environments/edu/ce-overrides.yaml` works
18. Verify `helmfile -f helmfile/edu-helmfile.yaml.gotmpl` works
19. Run lsp diagnostics on changed files
20. Push to remotes

## 5. Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Broken relative paths in edu apps after move | Verify each child helmfile's chart and keyring paths resolve correctly |
| CE submodule version drift | Pin to explicit tags, not branches |
| Submodule checkout complexity for new devs | Document in README, add `--recurse-submodules` to clone instructions |
| Edu overrides become outdated when CE changes | Review override compatibility on each CE update |
| `--values` flag behavior differs from helmfile environments | Test with dry-run before applying to production |
| Existing deployed state on cluster | Ensure helmfile release names don't conflict between CE and edu |

## 6. Future Considerations

- **CE adding edu features**: If upstream ever adds edu-specific features, we can optionally move parts of our overrides upstream, reducing maintenance burden.
- **Multiple environments**: Our `helmfile/environments/edu/` can be extended with `ce-overrides-dev.yaml`, `ce-overrides-prod.yaml` if needed.
- **Automated CE update PRs**: With submodule, a Renovate or Dependabot bot could auto-create PRs bumping CE tag with dry-run results.
