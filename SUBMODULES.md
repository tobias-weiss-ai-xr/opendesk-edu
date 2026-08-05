# OpenDesk Git - Submodule Overview

> **Note:** This file is auto-generated from `.gitmodules`. See `scripts/submodule-overview.sh` for live status.

This repository uses git submodules to manage its component repositories. All submodules are now properly tracked via `.gitmodules`.

## 📊 Submodule Summary

| # | Submodule | Source | Current Branch | Commit | Status |
|---|-----------|--------|----------------|--------|--------|
| 1 | `addon-nextcloud_integration` | OpenCode.de | heads/stable-8.44 | 068ac0ea | OK |
| 2 | `argocd-opendesk` | HRZ GitLab | heads/feature/minimal-edu-stalwart-sogo-opencloud | 8f43fa7c | OK |
| 3 | `charts-upgrade-v1.20.1` | GitHub (t-ai-xr) | heads/main | ffd95995 | OK |
| 4 | `erprobungskonzept` | HRZ GitLab | 24.03-38-gcc1084b | cc1084bf | OK |
| 5 | `k8s-mc-mirror` | HRZ GitLab | heads/main | 214e7a5f | OK |
| 6 | `k8up` | HRZ GitLab | k8up-4.8.6-13-g22bdc84f | 22bdc84f | OK |
| 7 | `monitoring` | HRZ GitLab | heads/main | 4adefe1e | OK |
| 8 | `opencode-de-analysis` | External | heads/master | ad0c7945 | OK |
| 9 | **`opendesk`** | HRZ GitLab | v1.17.0-12-g73efc6a7 | 73efc6a7 | OK |
| 10 | `opendesk-collab-dashboard` | GitHub (t-ai-xr) | heads/master | 8403931a | OK |
| 11 | `opendesk-cop` | GitHub (edu) | heads/main | 98a51cb0 | OK |
| 12 | `opendesk-dev-agent` | GitHub (t-ai-xr) | heads/main | f21422a9 | OK |
| 13 | `opendesk-dev-agent-operator` | GitHub (t-ai-xr) | heads/main | 4b9709e1 | OK |
| 14 | **`opendesk-edu`** | GitHub (t-ai-xr) | edu-v0.1.0-190-g818170e5 | +818170e | **+ NEW** |
| 15 | `opendesk-edu-landscape` | GitHub (t-ai-xr) | heads/main | c4d025fd | OK |
| 16 | `opendesk-edu-spec` | GitHub (edu) | heads/master | bf4eb991 | OK |
| 17 | `opendesk-edu-website` | GitHub (edu) | heads/main | 887ea1a9 | OK |
| 18 | `opendesk-helm-charts` | GitHub (t-ai-xr) | heads/master | a0f9df29 | OK |
| 19 | `opendesk-knowledge` | GitHub (t-ai-xr) | heads/master | 98032bb3 | OK |
| 20 | `opendesk-kubectl` | GitHub (t-ai-xr) | heads/master | 5203a37f | OK |
| 21 | `opendesk-sogo-image` | GitHub (t-ai-xr) | heads/master | 4e6f9bae | OK |
| 22 | `registry` | HRZ GitLab | heads/master | af5bb211 | OK |
| 23 | `user_import` | HRZ GitLab | v3.3.1-16-gc4573a1 | c4573a19 | OK |

**Status:** 23 submodules total, 22 OK, 1 with new commits (`opendesk-edu`)

---

## 🏢 Grouped by Source

### 🏛️ HRZ GitLab (Internal Deployment)

These repositories are hosted on the HRZ GitLab instance and are used for internal Kubernetes deployments.

| Submodule | Branch | Commit |
|-----------|--------|--------|
| `argocd-opendesk` | feature/minimal-edu-stalwart-sogo-opencloud | 8f43fa7c |
| `erprobungskonzept` | 24.03-38-gcc1084b | cc1084bf |
| `k8s-mc-mirror` | main | 214e7a5f |
| `k8up` | k8up-4.8.6-13-g22bdc84f | 22bdc84f |
| **`opendesk`** | v1.17.0-12-g73efc6a7 | **73efc6a7** |
| `monitoring` | main | 4adefe1e |
| `registry` | master | af5bb211 |
| `user_import` | v3.3.1-16-gc4573a1 | c4573a19 |

**Count:** 8 submodules

---

### 🌍 GitHub - tobias-weiss-ai-xr (Source of Truth ✅)

These are **YOUR GitHub forks** - designated as the source of truth for OpenDesk Edu development.

| Submodule | Branch | Commit |
|-----------|--------|--------|
| `charts-upgrade-v1.20.1` | main | ffd95995 |
| `opendesk-collab-dashboard` | master | 8403931a |
| `opendesk-dev-agent` | main | f21422a9 |
| `opendesk-dev-agent-operator` | main | 4b9709e1 |
| **`opendesk-edu`** | edu-v0.1.0-190-g818170e5 | **+818170e** |
| `opendesk-edu-landscape` | main | c4d025fd |
| `opendesk-helm-charts` | master | a0f9df29 |
| `opendesk-knowledge` | main | 98032bb3 |
| `opendesk-kubectl` | main | 5203a37f |
| `opendesk-sogo-image` | main | 4e6f9bae |

**Count:** 10 submodules  
**⚠️ Note:** `opendesk-edu` has new commits not yet committed in parent repo

---

### 🌍 GitHub - opendesk-edu organization

These are from the opendesk-edu organization on GitHub.

| Submodule | Branch | Commit |
|-----------|--------|--------|
| `opendesk-cop` | main | 98a51cb0 |
| `opendesk-edu-spec` | master | bf4eb991 |
| `opendesk-edu-website` | main | 887ea1a9 |

**Count:** 3 submodules

---

### 🔗 External Upstream

External dependencies not hosted on HRZ or your GitHub.

| Submodule | Branch | Commit | URL |
|-----------|--------|--------|-----|
| `addon-nextcloud_integration` | stable-8.44 | 068ac0ea | gitlab.opencode.de |
| `opencode-de-analysis` | master | ad0c7945 | github.com |

**Count:** 2 submodules

---

## 📁 Directory Layout

```
opendesk_git/
├── .gitmodules                    # ← Submodule configuration (NEW!)
├── SUBMODULES.md                  # ← This file
├── scripts/
│   └── submodule-overview.sh      # ← Status script
├── addon-nextcloud_integration/   # OpenCode.de
├── argocd-opendesk/               # HRZ GitLab
├── charts-upgrade-v1.20.1/        # GitHub (t-ai-xr)
├── erprobungskonzept/             # HRZ GitLab
├── k8s-mc-mirror/                 # HRZ GitLab
├── k8up/                          # HRZ GitLab
├── monitoring/                    # HRZ GitLab
├── opencode-de-analysis/          # GitHub
├── opendesk/                      # HRZ GitLab (CORE)
├── opendesk-collab-dashboard/     # GitHub (t-ai-xr)
├── opendesk-cop/                  # GitHub (edu)
├── opendesk-dev-agent/            # GitHub (t-ai-xr)
├── opendesk-dev-agent-operator/   # GitHub (t-ai-xr)
├── opendesk-edu/                  # GitHub (t-ai-xr) - EDU CORE
├── opendesk-edu-landscape/        # GitHub (t-ai-xr)
├── opendesk-edu-spec/             # GitHub (edu)
├── opendesk-edu-website/          # GitHub (edu)
├── opendesk-helm-charts/          # GitHub (t-ai-xr)
├── opendesk-knowledge/            # GitHub (t-ai-xr)
├── opendesk-kubectl/              # GitHub (t-ai-xr)
├── opendesk-sogo-image/           # GitHub (t-ai-xr)
├── registry/                      # HRZ GitLab
└── user_import/                   # HRZ GitLab
```

---

## 🔧 Quick Commands

### Clone with all submodules

```bash
# Clone and initialize all submodules in one step
git clone --recurse-submodules <repository-url> opendesk_git
cd opendesk_git
```

### Initialize submodules (existing clone)

```bash
# Initialize and update all submodules
git submodule update --init --recursive
```

### Update to latest remote

```bash
# Update to latest commits from their origin repos
git submodule update --remote --recursive
```

### Update and checkout default branches

```bash
# Update to latest and checkout each submodule's default branch
git submodule update --remote --recursive --checkout
```

### Check status

```bash
# See which submodules have new commits
.git submodule status

# Or use the overview script
bash scripts/submodule-overview.sh
```

### Pull with submodules

```bash
# Pull parent repo and update submodules
git pull
git submodule update --recursive
```

---

## 📝 Notes

1. **Source of Truth**: Your GitHub forks (`tobias-weiss-ai-xr`) are designated as the primary source foredu components
2. **HRZ GitLab**: Internal deployment repositories remain on HRZ infrastructure
3. **Mixed Origins**: Some repos (like `opendesk-edu-spec`) are from opendesk-edu organization
4. **External**: Upstream dependencies are tracked but not modified

---

## 🎯 Priority Submodules

| Priority | Submodule | Purpose |
|----------|-----------|---------|
| ⭐⭐⭐ | `opendesk` | Core OpenDesk deployment |
| ⭐⭐⭐ | `opendesk-edu` | Education-specific components |
| ⭐⭐⭐ | `opendesk-sogo-image` | SOGo container image |
| ⭐⭐ | `opendesk-helm-charts` | Helm charts |
| ⭐⭐ | `monitoring` | Monitoring infrastructure |
| ⭐ | All others | Supporting components |

---

*Generated: $(date)*
*Last updated: .gitmodules commit $(git log -1 --format="%H" -- .gitmodules 2>/dev/null || echo "unknown")*
