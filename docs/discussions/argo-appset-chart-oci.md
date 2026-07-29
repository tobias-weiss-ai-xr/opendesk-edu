# Proposal: OCI Chart Publishing + ArgoCD ApplicationSet

## Context

openDesk Edu at HRZ Marburg uses **helmfile + ArgoCD** for deployment.
openDesk CE uses **helmfile only** (without ArgoCD).

This proposal has two parts: one for the broader community, one ArgoCD-specific.

---

## Part 1: OCI Chart Publishing (for everyone)

### Problem

Four openDesk variants maintain separate chart trees:

```
opendesk/ce/    → helmfile/charts/           (Bitnami-dependent)
opendesk-edu/   → helmfile/charts/           (Bitnami-free, patched)
opendesk-sme/   → helmfile/charts/           (Bitnami-dependent)
opendesk_sec/   → helmfile/charts/           (Bitnami-dependent)
```

A chart fix in Edu (like removing Bitnami) must be manually ported to CE, SME, Sec.
The Bitnami migration has to be done **4 times** independently.

### Solution: Leverage existing oci-pull-mirror infrastructure

Good news: openDesk already has the infrastructure for this.

**`bmi/opendesk/tooling/oci-pull-mirror`** automatically mirrors OCI artifacts
defined in the deployment repo's `images.yaml` and `charts.yaml` to the
opencode.de GitLab container registry.

### What we need to do

Instead of building a new CI workflow, we simply:

1. **Add our custom chart to `charts.yaml`** in the deployment repo:
   ```yaml
   charts:
     mariadb:
       source: ghcr.io/opendesk-edu/charts/mariadb:0.1.0
   ```

2. **Reference the mirrored chart from opencode.de registry:**
   ```yaml
   repositories:
     - name: opendesk
       url: oci://gitlab.opencode.de/bmi/opendesk/components
   
   releases:
     - name: mariadb
       chart: opendesk/charts/mariadb
       version: 0.1.0
   ```

3. **The oci-pull-mirror CI handles the rest** — mirroring, version tracking,
   and availability on the opencode.de registry.

### Benefits

| Before | After |
|--------|-------|
| 4× chart maintenance | 1 chart repo, 4× version pins in `charts.yaml` |
| Fix must be ported to each variant | Fix once → bump version → all variants consume |
| No version tracking | `oci-pull-mirror` handles sync automatically |
| Manual mirroring | Fully automated via existing tooling |

### Works with both helmfile and ArgoCD — no tooling changes needed

- **CE/helmfile users:** `helmfile sync` pulls the chart from OCI, just like any other remote chart
- **Edu/ArgoCD users:** Same — ArgoCD's helmfile plugin pulls from OCI
- **No ArgoCD required** for this part

---

## Part 2: ArgoCD ApplicationSet (HRZ-specific)

### Problem (only for ArgoCD deployments)

Every openDesk app at HRZ has a manually created ArgoCD `Application` resource.
These are defined in a **separate ArgoCD config repo** (`gitlab.hrz.uni-marburg.de/...`).
Adding a new app = 3 files. Changing env vars = update 50+ resources.

### Solution: One ApplicationSet generates all apps

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: edu-apps
spec:
  generators:
    - list:
        elements:
          - app: ilias
          - app: bookstack
          # ... just the app name
  template:
    spec:
      source:
        plugin:
          env:
          - name: HELMFILE_FILE_PATH
            value: "helmfile.yaml.gotmpl"
          - name: HELMFILE_GLOBAL_OPTIONS
            value: "--environment edu --namespace opendesk"
```

### Benefits (ArgoCD deployments only)

| Metric | Before | After |
|--------|--------|-------|
| Resources | 50+ YAML files in ArgoCD repo | 1 ApplicationSet in app repo |
| Add new app | 3 files, 50+ lines | 1 line in list |
| Change env vars | Update 50+ apps | Update 1 template |

### Drawback

- Only relevant for deployments using ArgoCD (HRZ cluster style)
- Requires `argocd-applicationset-controller` (already running at HRZ)

---

## Discussion Questions

1. **OCI Charts:** Should we start with a single shared chart (e.g. `mariadb`) as proof of concept?
2. **Timeline:** The Bitnami migration is urgent (images disappearing from Docker Hub). OCI publishing would let CE consume Edu-migrated charts immediately without redoing the work.
3. **Naming:** Should the OCI org be `opendesk-edu` or `opendesk`? If `opendesk`, who maintains the shared charts?
4. **ApplicationSet:** Is there appetite for this pattern from other ArgoCD-based deployments?

---

*From: openDesk Edu (HRZ Marburg)*
*Status: Draft for discussion*
