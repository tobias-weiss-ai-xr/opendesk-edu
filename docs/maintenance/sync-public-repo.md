# Syncing Changes to the Public openDesk Edu Repository

> How to sync changes from the private `opendesk` repo (GitLab HRZ) to the
> public `opendesk-edu` repo (Codeberg).

Last updated: Sprint 13 (June 2026)

## Overview

The private `opendesk` repository contains all HRZ-internal configuration,
security documentation, and production deployment specifics. The public
`opendesk-edu` repository on Codeberg contains only the education-focused
subset suitable for open-source distribution.

## What Gets Synced

| Include | Exclude |
|---------|---------|
| `opendesk/helmfile/` (edu service configs) | `docs/rbac-security-audit.md` |
| `opendesk/helmfile/apps/ilias/` | `docs/pod-security-admission-setup.md` |
| `opendesk/helmfile/apps/sogo/` | `docs/secrets-encryption-setup.md` |
| `opendesk/helmfile/apps/opencloud/` | `opendesk_sec/` (full security variant) |
| `opendesk/helmfile/apps/etherpad/` | Internal HRZ credentials/secrets |
| `opendesk/helmfile/apps/jupyterhub/` | Internal network topology docs |
| `opendesk/helmfile/apps/moodle/` | |
| `tests/` (health checks, etc.) | |
| `monitoring/` (Grafana dashboards) | |

## Manual Sync Procedure

### 1. Prepare the Private Repo

```bash
# Clone fresh copy to avoid polluting your working tree
cd /tmp
git clone git@gitlab.hrz.uni-marburg.de:hrz/kubernetes/opendesk/opendesk.git opendesk-sync
cd opendesk-sync
```

### 2. Strip Internal Content

Use `git filter-repo` (install via `pip install git-filter-repo`):

```bash
# Create a list of allowed paths (only edu-relevant content)
cat > allowed-paths.txt << 'EOF'
opendesk/helmfile/apps/ilias/
opendesk/helmfile/apps/sogo/
opendesk/helmfile/apps/opencloud/
opendesk/helmfile/apps/etherpad/
opendesk/helmfile/apps/jupyterhub/
opendesk/helmfile/apps/moodle/
opendesk/helmfile/apps/monitoring/
tests/
monitoring/
docs/edu-core-services.md
docs/backup-recovery-runbook.md
docs/performance-baseline-analysis.md
AGENTS.md
EOF

git filter-repo --paths-from-file allowed-paths.txt
```

### 3. Add Codeberg Remote

```bash
git remote add codeberg git@codeberg.org:opendesk-edu/opendesk-edu.git
```

### 4. Push to Codeberg

```bash
git push --force codeberg main
```

> **Warning:** `--force` is required because we rewrite history with filter-repo.
> Ensure no one is working directly on the public repo before pushing.

### 5. Verify

```bash
# Clone the public repo and verify
cd /tmp
git clone git@codeberg.org:opendesk-edu/opendesk-edu.git opendesk-edu-verify
cd opendesk-edu-verify

# Check no internal files leaked
test ! -f docs/rbac-security-audit.md || echo "LEAK: rbac-security-audit.md"
test ! -f docs/pod-security-admission-setup.md || echo "LEAK: pod-security doc"
test ! -f docs/secrets-encryption-setup.md || echo "LEAK: secrets-encryption doc"
test ! -d opendesk_sec || echo "LEAK: security directory"
test -d opendesk/helmfile/apps/ilias || echo "MISSING: ilias"

echo "=== Verification complete ==="
```

### 6. Clean Up

```bash
rm -rf /tmp/opendesk-sync /tmp/opendesk-edu-verify
```

## Automated Sync (Future)

For automated sync, consider:

1. **GitLab CI → Codeberg mirror**: Set up a CI job in the private repo that
   runs filter-repo and pushes to Codeberg on each merge to main.
2. **GitHub Actions → Codeberg**: If mirrored to GitHub, use a GitHub Action
   to sync relevant paths to Codeberg.
3. **ArgoCD sync wave**: If both repos are in ArgoCD, the public repo can
   track a subset of the private repo's path.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `filter-repo` not found | `pip install git-filter-repo` |
| Push rejected (non-fast-forward) | `git push --force codeberg main` |
| Large history slow to filter | Use `--refs HEAD~10..HEAD` to only filter recent commits |
| Accidental secret pushed | Use `git filter-repo --force` with `--path-secret` |
