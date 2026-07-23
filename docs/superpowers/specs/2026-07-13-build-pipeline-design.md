# Build Pipeline — Own Container Images

**Spec v1.0** · 2026-07-13
**openDesk Edu v1.1**

---

## 1. Goal

Establish a fully automated CI pipeline that builds custom container images from upstream source,
pushes them to the Codeberg Container Registry, tracks base-image updates via Renovate, and signs
images with SBOM attestation.

## 2. Architecture

```
┌─────────────────────┐     ┌──────────────────────────────┐     ┌──────────────────┐
│  Woodpecker CI       │     │  Codeberg Container Registry │     │  K3s Cluster      │
│                      │     │                              │     │                   │
│  .woodpecker/build.yaml──►│  codeberg.org/opendesk-edu/   │◄────│  containerd pull  │
│                      │     │  ├─ moodle:latest            │     │                   │
│  9 Dockerfiles:      │     │  ├─ sogo:v1.1.0-a3f2c1d     │     │  Zot (Fallback)   │
│  ├─ moodle           │     │  ├─ typo3:sha-xxxxx         │     │                   │
│  ├─ sogo             │     │  ├─ ilias-shibboleth         │     │                   │
│  ├─ typo3            │     │  ├─ bigbluebutton            │     │                   │
│  ├─ ilias-shibboleth │     │  ├─ opencloud                │     │                   │
│  ├─ bigbluebutton    │     │  ├─ user-import              │     │                   │
│  ├─ opencloud        │     │  ├─ semester-provisioning    │     │                   │
│  ├─ user-import      │     │  └─ collab-dashboard         │     │                   │
│  └─ semester-prov.   │     └──────────────────────────────┘     └──────────────────┘
└─────────────────────┘
```

## 3. Components

### 3.1 Woodpecker Build Pipeline

**File:** `.woodpecker/build.yaml`

- **Trigger:** push to `main` when `**/Dockerfile*` or `.woodpecker/build.yaml` changes; manual via workflow dispatch
- **Matrix:** all 9 Dockerfiles built in parallel
- **Steps per image:**
  1. `docker build` — build from Dockerfile context
  2. `docker tag` — tag with `${VERSION}-${GIT_SHA}` and `latest`
  3. `docker push` — push both tags to Codeberg Registry
  4. `trivy image` — scan for CVEs (non-blocking, advisory)
  5. `cosign sign` — keyless signing via OIDC (Codeberg identity)
  6. `cosign attest` — attach SBOM attestation
- **Secrets:** `CI_REGISTRY_TOKEN` (built-in Codeberg CI token with write access)

**Image definitions:**

| Dockerfile | Image Name | Build Context |
|---|---|---|
| `helmfile/charts/sogo/Dockerfile` | `sogo` | `helmfile/charts/sogo/` |
| `helmfile/charts/moodle/Dockerfile` | `moodle` | `helmfile/charts/moodle/` |
| `helmfile/charts/bigbluebutton/Dockerfile` | `bigbluebutton` | `helmfile/charts/bigbluebutton/` |
| `helmfile/charts/opencloud/Dockerfile` | `opencloud` | `helmfile/charts/opencloud/` |
| `helmfile/apps/typo3/Dockerfile` | `typo3` | `helmfile/apps/typo3/` |
| `helmfile/apps/ilias/Dockerfile.shibboleth-source` | `ilias-shibboleth` | `helmfile/apps/ilias/` |
| `scripts/user_import/Dockerfile` | `user-import` | `scripts/user_import/` |
| `scripts/semester-provisioning/Dockerfile` | `semester-provisioning` | `scripts/semester-provisioning/` |
| `collab-dashboard/Dockerfile` | `collab-dashboard` | `collab-dashboard/` |

### 3.2 Tagging Strategy

```
<image>:v<VERSION>-<GIT_SHA>    # e.g., sogo:v1.1.0-a3f2c1d
<image>:latest                   # always points to latest main build

VERSION = softwareVersion from publiccode.yml (e.g., "1.1.0-edu")
GIT_SHA = first 7 chars of commit hash
```

### 3.3 Codeberg Container Registry

- **Registry URL:** `codeberg.org/opendesk-edu/`
- **Auth:** CI registry token (`CI_REGISTRY_TOKEN`) — automatically available in Forgejo CI
- **Pull secret:** created in K3s namespace for containerd to pull from Codeberg
- **Fallback:** Zot registry remains available for air-gapped/offline scenarios

### 3.4 Helm Chart Integration

After pipeline push, update Helm chart `values.yaml` to reference the built image:

```yaml
# Before (upstream)
image: srsolutions/ilias:9-php8.2-apache

# After (self-built)
image: codeberg.org/opendesk-edu/ilias-shibboleth:v1.1.0-a3f2c1d
```

This is **not** automated in v1 — manual update after verifying the image works.

### 3.5 Renovate — Base Image Updates

**Changes to `.renovate/config.yaml`:**

1. `platform: "github"` → `platform: "gitlab"` (Forgejo-compatible mode)
2. Add Dockerfile scanning:
   ```yaml
   - customType: "regex"
     fileMatch: ["**/Dockerfile*"]
     datasourceTemplate: "docker"
     matchStrings: ["FROM\\s+(?<depName>\\S+):(?<currentValue>\\S+)"]
   ```
3. Keep existing `images.yaml.gotmpl` tracking
4. Renovate opens PRs when base images (e.g., `debian:bookworm-slim`, `php:8.4-apache`) get updated
5. Images in this repo: `debian:bookworm-slim`, `ubuntu:22.04`, `ruby:3.3-slim`, `php:8.4-apache`, `srsolutions/ilias:9-php8.2-apache`

**Note:** Codeberg does not host Renovate natively. Options:
- Self-hosted Renovate (Docker container on a schedule)
- Or accept manual PRs triggered by Renovate via GitHub mirror (existing `.forgejo/workflows/github-sync.yml` mirrors to GitHub, where Renovate can run)

### 3.6 Signing & SBOM — "Nice to Have"

- **SBOM:** Trivy already in `.woodpecker/security.yaml` — add inline scan after build, output SPDX JSON as artifact
- **Signing:** `cosign` keyless signing via Codeberg OIDC (`cosign sign --oidc-issuer https://codeberg.org`)
- **Attestation:** `cosign attest --predicate sbom.spdx.json`
- **Status:** Deferred to iterative improvement — not blocking initial pipeline

## 4. Non-Goals

- Automated Helm chart updates when new images are built (out of scope for v1)
- Multi-architecture builds (amd64 only initially)
- Image promotion between environments (dev → staging → prod)
- Full CD pipeline (this is CI for images, not continuous deployment)

## 5. Success Criteria

1. Woodpecker pipeline builds all 9 images and pushes them to Codeberg Registry
2. K3s cluster can pull and deploy images from Codeberg Registry
3. Renovate opens PRs for base image updates
4. SBOM generated and attached per image
5. All existing CI checks (lint, test, security) continue passing

## 6. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Codeberg Registry rate limits | Slow/failed pushes | Use Zot as local mirror; batch builds with backoff |
| Docker build OOM in Woodpecker | Build failure | Limit parallel builds; add `--memory` flags |
| Renovate doesn't work well with Forgejo | Renovate useless | Fallback: manual base-image checks via Trivy |
| cosign OIDC not supported on Codeberg | Signing fails | Skip cosign; sign manually pre-release |
