# ADR-001: SOPS/age Encryption for Helm Secrets

**Date:** 2026-07  
**Status:** Accepted  

## Context

edu secrets (`helmfile/environments/edu/secrets.yaml`) contain passwords, API keys,
and tokens for 32+ apps. Storing them in plaintext in Git is a security risk.

Options considered:
- **Helm secrets** (helm plugin): Encrypts values files with Mozilla SOPS.
  Requires `helm secrets` on all CI/CD runners.
- **Sealed Secrets** (Bitnami): Encrypts per-namespace Secrets at deploy time.
  Adds CRD dependency and cluster-level operator.
- **External Secrets Operator**: Fetches secrets from HashiCorp Vault or AWS.
  Adds cluster-level operator and external dependency.
- **SOPS + Age**: Encrypts files in-repo. Decryption happens at deploy time.
  Zero cluster dependencies, works offline.

## Decision

Use **SOPS with Age key** for secret encryption.

- `.sops.yaml` at repo root configures the Age recipient and `encrypted_regex`
- `.sops-age.pub` contains the public key for CI/CD onboarding
- Encrypted files use `.enc.yaml` suffix and are excluded from `.gitignore`
- Decryption happens in CI via `sops --decrypt` or via ArgoCD CMP

## Consequences

- **Positive:** Secrets are encrypted at rest in Git. No cluster-side operator needed.
- **Positive:** Works with any CI/CD (GitHub Actions, Woodpecker, ArgoCD).
- **Negative:** All deployers must have the Age private key.
- **Negative:** Key rotation requires `sops updatekeys` on every encrypted file.
