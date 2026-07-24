# Deployment Guide

## Architecture

openDesk Edu deploys in two layers:

1. **CE** (`helmfile/ce/` — git submodule, v1.17.0) — core services (Keycloak, Nubus, Collabora, Jitsi, Element, OpenProject, XWiki, Open-Xchange, etc.)
2. **Edu** (`helmfile/apps/edu/`) — 32 edu-specific apps (ILIAS, Moodle, Etherpad, SOGo, BigBlueButton, etc.)

Edu overrides CE via `ce-overrides.yaml` (disables CE's OX and Nextcloud, enables edu replacements).

## Prerequisites

- `helmfile` v1.x
- `kubectl` with cluster context configured
- Cluster access (Kubeconfig)

### SOPS-encrypted Secrets

edu secrets (`secrets.yaml`) are encrypted with [SOPS](https://github.com/getsops/sops) using an Age key.

**Before deploying**, you need:

- **SOPS CLI** installed (`pip install sops` or `brew install sops` or `go install github.com/getsops/sops/v3/cmd/sops@latest`)
- **Age key** (`~/.config/sops/age/keys.txt`) corresponding to the public key in `.sops.yaml`
- The public key (`age13zw40j4ax88ljk032zyd7yjr707ejce5ps5nlxmgld6ynwswnc2qcat04y`) is at `.sops-age.pub`

To edit encrypted secrets:

```bash
sops helmfile/environments/edu/secrets.yaml
```

To re-encrypt after key rotation:

```bash
sops updatekeys helmfile/environments/edu/secrets.yaml
```

See `docs/developer/sops-argocd-integration.md` for ArgoCD CMP setup.

## Deploy

```bash
./deploy.sh                    # Deploy edu (production) — default
./deploy.sh edu-test           # Deploy edu-test (staging)
./deploy.sh --diff             # Dry-run: show changes without applying
./deploy.sh --diff edu-test    # Dry-run for test environment
./deploy.sh --verbose          # Enable helmfile debug output
```

This runs:
1. **Step 1**: CE helmfile with `--values` pointing to your environment's overrides
2. **Step 2**: Edu helmfile with the same environment

## Environments

Each environment is a directory under `helmfile/environments/`:

| Directory | Purpose |
|-----------|---------|
| `edu/` | Production (default) |
| `edu/test/` | Staging/test overrides |

Each environment directory contains:
- `ce-overrides.yaml` — Overrides injected into CE (disables CE services, enables edu ones)
- `secrets.yaml` — Derived passwords (derivePassword)
- `images.yaml` — Image tag overrides
- `test/*.yaml.gotmpl` — Test-specific overrides (ingress, persistence, replicas, annotations)

## Adding a New Edu App

1. Create `helmfile/apps/edu/<app>/helmfile-child.yaml.gotmpl` following existing patterns
2. Update `helmfile/environments/edu/ce-overrides.yaml`:
   - Add `<app>.enabled: true` under `apps:`
   - Add `<app>: enabled: true` under `functional.authentication.oidc.clients` (if SAML/OIDC client needed)
3. Add `helmfile/apps/edu/<app>/values.yaml.gotmpl` (or reference chart defaults)
4. Add secrets to `secrets.yaml` if needed

The edu-helmfile uses a glob (`apps/edu/*/helmfile-child.yaml.gotmpl`) so new app directories are picked up automatically.

## Updating CE Submodule

```bash
# List upstream tags
cd helmfile/ce
git fetch --tags upstream
git tag -l 'v*' | tail -5
cd ../..

# Update to new version
./scripts/update-ce.sh v1.18.0
```

This updates the submodule reference, stages the change, and prints the commit command.

## Troubleshooting

**CE fails with "environments/default/ not found"**
→ Verify you're running from the repo root. `deploy.sh` handles this automatically.

**Submodule not checked out**
```bash
git submodule update --init helmfile/ce
```

**Secrets missing**
→ Add `global.derivePassword.<app>` entries to `helmfile/environments/edu/secrets.yaml`.

**Portal entries conflict with CE**
→ Edu only manages entries for edu apps (ILIAS, Moodle, BigBlueButton, etc.).
  CE manages entries for CE apps (OpenProject, Nextcloud, etc.) via its own portal-entries chart.
  Overlap is intentional — CE entries are maintained by CE, edu entries by edu.
