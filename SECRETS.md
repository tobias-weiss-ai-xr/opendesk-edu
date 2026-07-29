# Secret Management

## Workflow

```
secrets.yaml (plaintext, local only) ──→ secrets.enc.yaml (committed to git)
                   ↑                              │
                   │ sops decrypt                   │ sops encrypt
                   │                              ↓
              deploy.sh ────────→ helmfile sync
```

## Daily Use

```bash
# Edit secrets (plaintext — NEVER commit this)
vim helmfile/environments/edu/secrets.yaml

# Encrypt for commit
sops encrypt helmfile/environments/edu/secrets.yaml > helmfile/environments/edu/secrets.enc.yaml
git add helmfile/environments/edu/secrets.enc.yaml
git commit -m "fix(secrets): update XYZ"

# Deploy
./scripts/deploy.sh sync   # decrypts → runs helmfile → cleans up
```

## ArgoCD

ArgoCD reads `secrets.yaml` from git (plaintext — accepted tradeoff).
The `secrets.enc.yaml` is the canonical encrypted source.
For full SOPS-in-ArgoCD support, the CMP sidecar would need sops installed.
