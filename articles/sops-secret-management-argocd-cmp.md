---
title: "GitOps-Native Secret Management with SOPS and ArgoCD CMP Sidecar"
description: "How openDesk Edu encrypts 126 secrets in Git using SOPS with age encryption and decrypts them at deploy time via an ArgoCD Config Management Plugin sidecar — no Vault, no External Secrets Operator, no proprietary infrastructure required."
date: 2026-07-10
tags: [sops, secret-management, argocd, gitops, kubernetes, security, devops, age-encryption]
author: "Tobias Weiß and openDesk Edu Contributors"
---

# GitOps-Native Secret Management with SOPS and ArgoCD CMP Sidecar

> **The challenge:** How do you manage database passwords, API tokens, and OIDC client secrets in a GitOps workflow where *everything* — including the deployment configuration — lives in a public Git repository?
>
> **The answer:** Encrypt secrets with SOPS using age keys, commit them as `.enc.yaml` files alongside your plaintext values, and decrypt them at deploy time with an ArgoCD Config Management Plugin sidecar. No Vault cluster. No External Secrets Operator. No proprietary infrastructure — just `sops`, `age`, and a 10-line shell script.

## The Problem: Secrets in GitOps

At openDesk Edu, we deploy 25+ integrated services across multiple Kubernetes clusters using a GitOps workflow with ArgoCD and Helmfile. Every piece of configuration — Helm values, environment overrides, service definitions — lives in a Git repository and is automatically synced to the cluster.

This is great for everything *except secrets*.

A standard openDesk Edu deployment requires ~126 distinct secret values:

- **P0 (Critical):** Keycloak admin credentials, database root passwords, mail relay authentication
- **P1 (High):** OIDC client secrets, LDAP bind credentials, SMTP passwords
- **P2 (Medium):** Redis authentication tokens, MariaDB replica passwords
- **P3 (Low):** Ceph storage keys, service API tokens

With GitOps, you can't just `kubectl create secret` — that violates the principle of Git as single source of truth. But you also can't commit plaintext secrets to a Git repository.

The open-source ecosystem offers several solutions. Here's why we chose our approach.

## Why SOPS (+ age) Over the Alternatives

### Option Rejected: Sealed Secrets

[Bitnami Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) encrypts secrets with a cluster-local key. The problem: the SealedSecret CRD is cluster-scoped. If your cluster dies, you lose your sealing key unless you've backed it up separately. For a multi-cluster deployment (dev, staging, prod), you'd need separate sealed secrets per cluster, which duplicates effort and creates drift risk.

### Option Rejected: External Secrets Operator

[External Secrets Operator](https://external-secrets.io/) pulls secrets from an external vault (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault). This is a great pattern for cloud-native deployments, but it introduces an external dependency and a second source of truth. For an on-premise deployment at German universities where you want to minimize infrastructure dependencies, adding a HashiCorp Vault cluster just to manage secrets felt like replacing one problem with another.

### Option Rejected: Helm Secrets / Helm S3

These require the decryption tooling on every developer's machine and don't integrate cleanly with ArgoCD's declarative sync model.

### Chosen: SOPS with age and ArgoCD CMP Sidecar

[SOPS (Secrets OPerationS)](https://github.com/getsops/sops) is a mature, battle-tested tool for encrypting individual values or entire files. We chose it because:

- **Stateless encryption** — decryption only requires the age private key, not a running service
- **Git-native** — encrypted files sit next to their plaintext counterparts in the repo
- **ArgoCD-native** — the Config Management Plugin sidecar pattern integrates seamlessly
- **No cluster dependency** — the decryption key is a single file, backed up independently of any cluster
- **Audit trail** — every secret change is a Git commit with author, timestamp, and diff

## The Architecture

Our secret management architecture consists of four components:

```
┌─────────────────────────────────────────────────────────┐
│                    Git Repository                         │
│                                                          │
│  .sops.yaml          helmfile/environments/default/       │
│  ──────────          ───────────────────────             │
│  creation_rules:     secrets.enc.yaml (P0 critical)      │
│    age: <public_key> secrets.prod.enc.yaml (P1-P3)       │
│                                                          │
└──────────────────────┬──────────────────────────────────┘
                       │ git push
                       ▼
┌─────────────────────────────────────────────────────────┐
│                    ArgoCD                                 │
│                                                          │
│  ┌─────────────────┐    ┌────────────────────────────┐  │
│  │  repo-server     │    │  CMP sidecar (sops)        │  │
│  │  (main)          │◄───│                            │  │
│  │                  │    │  sops --decrypt *.enc.yaml │  │
│  │  Receives        │    │  age key: /sops-age-key/   │  │
│  │  decrypted YAML  │    └────────────────────────────┘  │
│  └─────────────────┘                                     │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  Kubernetes Cluster  │
                    │  Secrets + ConfigMaps│
                    └─────────────────────┘
```

### 1. SOPS Configuration (`.sops.yaml`)

The repository root contains a `.sops.yaml` file that defines the encryption rules:

```yaml
creation_rules:
  - path_regex: \.enc\.yaml$
    age: <age-public-key>
```

This tells SOPS: *any file ending in `.enc.yaml` should be encrypted with this age public key.* The magic is that SOPS generates a unique data encryption key per file, which is then wrapped with the age public key. This means you can rotate the age key without re-encrypting every file — just re-wrap the data encryption keys.

### 2. Encrypted Secrets Files

We organize secrets by environment and criticality:

| File | Contents | Priority |
|------|----------|----------|
| `helmfile/environments/default/secrets.enc.yaml` | P0 critical secrets (97 values) | 🔴 Critical |
| `helmfile/environments/default/secrets.prod.enc.yaml` | P1-P3 secrets per environment (29 values) | 🟠 High |

The `.enc.yaml` extension is our signal to both SOPS and ArgoCD that the file needs decryption. When you open one of these files, you see:

```yaml
keycloak_admin_password: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
mariadb_root_password: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
sops:
    kms: null
    gcp_kms: null
    azure_kv: null
    hc_vault: null
    age:
        - recipient: age1...
          enc: |
            ---
            ...
    lastmodified: '2026-07-09T12:00:00Z'
```

Each value is individually encrypted with AES-256-GCM, and the file carries metadata about the encryption keys, version, and last modification time.

### 3. ArgoCD CMP Sidecar

The key integration point is the ArgoCD Config Management Plugin (CMP) sidecar. This sidecar runs alongside the main ArgoCD repo-server container and intercepts `.enc.yaml` files before they reach resource detection.

**The sidecar configuration is a single ConfigMap:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmp-sops-plugin
  namespace: argocd
data:
  plugin.yaml: |
    apiVersion: argoproj.io/v1alpha1
    kind: ConfigManagementPlugin
    metadata:
      name: sops
    spec:
      sidecar: true
      generate:
        command:
          - /bin/sh
          - -c
          - |
            for f in $(find . -name '*.enc.yaml' -type f); do
              /custom-tools/sops --decrypt \
                --input-type yaml --output-type yaml "$f" 2>/dev/null
            done
      discover:
        find:
          glob: "**/*.enc.yaml"
```

When ArgoCD detects a file matching `*.enc.yaml`, it invokes the sidecar's generate command, which runs `sops --decrypt` on each encrypted file. The decrypted YAML is then handed to ArgoCD's standard resource detection.

**The sidecar needs two things to function:**
1. The `sops` binary in the sidecar container
2. The age private key mounted as a Kubernetes Secret

Both are injected via a strategic merge patch to the ArgoCD repo-server Deployment:

```yaml
# Strategic merge patch (abbreviated)
spec:
  template:
    spec:
      initContainers:
        - name: install-sops
          image: alpine:3.20
          command: ["/bin/sh", "-c"]
          args:
            - |
              wget -q https://github.com/getsops/sops/releases/...
              mv sops /custom-tools/sops
          volumeMounts:
            - name: extra-tools
              mountPath: /custom-tools
      containers:
        - name: sops
          image: alpine:3.20
          command: [/var/run/argocd/argocd-cmp-server]
          volumeMounts:
            - name: extra-tools
              mountPath: /custom-tools
            - name: argocd-sops-age-key
              mountPath: /sops-age-key
              readOnly: true
      volumes:
        - name: extra-tools
          emptyDir: {}
        - name: argocd-sops-age-key
          secret:
            secretName: argocd-sops-age-key
```

### 4. Annotating ArgoCD Applications

Each ArgoCD Application that uses SOPS-encrypted files must declare the plugin:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: opendesk-edu
spec:
  source:
    repoURL: https://github.com/opendesk-edu/opendesk-edu.git
    path: .
  plugin:
    name: sops
```

That's it. The Application now transparently decrypts secrets during sync.

## Verified End-to-End

The CMP sidecar was deployed and tested on the production HRZ cluster (K3s v1.32.3, ArgoCD v3.0.12) in July 2026. We verified:

1. **Encrypted secret committed** — A `test-secret.enc.yaml` was committed to the repository
2. **ArgoCD detected the change** — The Application's sync status showed a diff
3. **Sidecar decrypted the secret** — `kubectl -n argocd logs deployment/argocd-repo-server sops` confirmed decryption
4. **Resource was applied** — The plaintext Secret was created in the target namespace
5. **No plaintext leaked** — Verified the encrypted file remained encrypted in Git

The entire setup — from repository configuration to working deployment — took approximately 4 hours, including debugging the sidecar volume mounts.

## What This Means for Operators

### Day-to-Day Operations

For most operators, the SOPS integration is invisible. They:

1. Edit Helm values in the usual `.yaml` and `.gotmpl` files
2. Commit and push to Git
3. ArgoCD syncs automatically

The only difference is that secrets are stored as encrypted files. When an operator needs to add or update a secret:

```bash
# Decrypt the secrets file
sops helmfile/environments/default/secrets.enc.yaml

# Edit the file (opens in $EDITOR)
# When saved, SOPS automatically re-encrypts

# Commit
git add helmfile/environments/default/secrets.enc.yaml
git commit -m "feat(secrets): update Keycloak admin password"
git push
```

The `sops` CLI handles decryption and re-encryption transparently. Operators never see or handle plaintext secrets unless they have the age private key.

### Secret Rotation

Rotating a secret is as simple as:

```bash
sops helmfile/environments/default/secrets.enc.yaml
# Edit the value in-place
# Save → auto-encrypted

# Or rotate all data encryption keys:
sops --rotate helmfile/environments/default/secrets.enc.yaml
```

### Disaster Recovery

The most important operational concern: **back up the age private key.** This single file (`~/.age/opendesk-edu.txt`) controls access to all encrypted secrets. Without it, you cannot decrypt any `.enc.yaml` file.

Our disaster recovery guide now includes SOPS key recovery as the first step in the recovery order (P0 priority, before storage and databases).

## The 126 Encrypted Secrets: By the Numbers

| Priority | Count | Categories |
|----------|-------|------------|
| P0 (Critical) | 97 | Keycloak admin, DB roots, mail relay auth, LDAP admin |
| P1 (High) | 16 | OIDC client secrets, SMTP credentials, API tokens |
| P2 (Medium) | 8 | Redis auth, replica DB passwords, cache keys |
| P3 (Low) | 5 | Ceph keys, service tokens, monitoring credentials |
| **Total** | **126** | |

Each value is individually encrypted with AES-256-GCM. No two values share a nonce. The file-level data encryption key is unique per file, wrapped with the age public key.

## Why This Matters for GitOps

This approach preserves the core GitOps principles:

- **Git is the single source of truth** — every secret value has a Git commit
- **Declarative deployment** — ArgoCD handles everything autonomously
- **No infrastructure dependencies** — no Vault, no cloud provider, no external service
- **Audit trail** — `git log` shows exactly who changed which secret and when
- **Reproducible** — a fresh cluster can be bootstrapped from Git alone (with the age key)

## Lessons Learned

1. **Volume mounts are the trickiest part** — The CMP sidecar needs access to the same repo checkout as the main repo-server. The shared `tmp` volume mount is essential.

2. **Proxy configuration matters** — On the HRZ cluster, the `install-sops` initContainer needed `HTTP_PROXY` and `HTTPS_PROXY` environment variables to download the sops binary.

3. **Plugin caching can cause stale secrets** — If a previous sync is cached in Redis, ArgoCD may not re-run the plugin after a secret update. Forcing a cache flush (`redis-cli FLUSHALL`) or bumping the commit hash resolves this.

4. **Test with a dummy secret first** — We committed a harmless `test-secret.enc.yaml` and verified end-to-end before encrypting real production credentials.

5. **Back up the age key in multiple locations** — This single file is the root of trust for all secrets. Losing it means losing access to every encrypted value.

## What's Next

The SOPS integration is foundational for our v1.1 release. With secrets management solved, we're now able to:

- **Define secret requirements for every service** — each Helm chart declares exactly what secrets it needs
- **Audit secret coverage** — automated checks ensure no service references an undefined secret
- **Rotate secrets on schedule** — using SOPS's metadata (encryption timestamp) to track rotation windows
- **Extend to CI/CD pipelines** — GitLab CI jobs can decrypt secrets for integration tests

The complete integration guide is available in our repository at [`docs/developer/sops-argocd-integration.md`](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/developer/sops-argocd-integration.md), and the encrypted secrets live in `helmfile/environments/*/secrets*.enc.yaml`.

---

*SOPS-based secret management is part of the openDesk Edu v1.1 release. For the full v1.1 roadmap, see our [release plan](https://github.com/opendesk-edu/opendesk-edu/blob/main/docs/v1.1-release-checklist.md).*

**openDesk Edu: Sovereign, integrated, production-ready open-source education technology.**
