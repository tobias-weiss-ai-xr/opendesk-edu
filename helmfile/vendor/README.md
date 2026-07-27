# Vendor Charts

This directory contains vendored (forked) copies of upstream Helm charts used by
openDesk Edu. By vendoring these charts into our repository, we gain full control
over them — we can apply patches, pin specific versions, and develop modifications
without being affected by upstream changes.

## Structure

```
vendor/charts/
├── code-server/          # Forked from coder/coder (https://helm.coder.com)
├── dask/                 # Forked from dask/dask-gateway (https://helm.dask.org)
├── jupyterhub/           # Forked from jupyterhub/jupyterhub (https://hub.jupyter.org/helm-chart)
├── ollama/               # Forked from ollama/ollama (https://ollama.github.io/helm-chart)
├── open-webui/           # Forked from open-webui/open-webui (https://helm.openwebui.com)
├── overleaf/             # OCI chart — download manually (oci://ghcr.io/sharelatex/overleaf-helm-chart/overleaf)
└── kasmvnc/              # OCI chart — download manually (oci://registry.kasmweb.com/kasmweb/charts/kasmvnc)
```

## How to Update a Vendor Chart

### 1. Check current version
```bash
grep "^version:" vendor/charts/<chart-name>/Chart.yaml
```

### 2. Update to new upstream version
```bash
# For regular Helm repos:
helm repo update
helm pull <chart> --version <new-version> --untar --untardir=vendor/charts/<chart-name>-tmp
rm -rf vendor/charts/<chart-name>
mv vendor/charts/<chart-name>-tmp/<chart-name> vendor/charts/<chart-name>

# For OCI repos:
helm pull oci://<registry>/<chart> --version <version> --untar --untardir=vendor/charts/<chart-name>
```

### 3. Verify the update
```bash
grep "^version:" vendor/charts/<chart-name>/Chart.yaml
git diff vendor/charts/<chart-name>/  # Review any upstream changes
```

### 4. Update the pinned version in helmfile-child.yaml
For charts with pinned versions, also update:
```bash
vim helmfile/apps/edu/<app>/helmfile-child.yaml.gotmpl
# Update the version: field
```

## Developing on Forked Charts

Since these are now local copies, you can:

1. **Apply patches directly** — Edit files in `vendor/charts/<chart-name>/`
2. **Track modifications** — Use `git diff vendor/charts/<chart-name>/` to see changes
3. **Add templates** — Create new templates in `vendor/charts/<chart-name>/templates/`
4. **Update values** — Change defaults in `vendor/charts/<chart-name>/values.yaml`

### Best Practices

- Keep a record of upstream version in the chart's `Chart.yaml` annotations:
  ```yaml
  annotations:
    opendesk/upstream-chart: "https://example.com/chart"
    opendesk/upstream-version: "1.2.3"
  ```
- When updating to a new upstream version, re-apply your patches after the update
- Use `git diff` to review what changed vs upstream before committing
