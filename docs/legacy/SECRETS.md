# Secret Management

## Current approach

Secrets are stored in `helmfile/environments/edu/secrets.yaml` in plaintext.
This works for the current single-cluster deployment but is not suitable for
shared or public repositories.

## Recommended approach: SOPS + age

The `feat/sops-age-encryption` branch has a working SOPS setup.

### Setup

```bash
# Install sops
wget https://github.com/getsops/sops/releases/download/v3.9.4/sops-v3.9.4.linux.amd64
sudo mv sops-v3.9.4.linux.amd64 /usr/local/bin/sops

# Generate age key
age-keygen -o ~/.config/sops/age/keys.txt

# Encrypt secrets
sops encrypt helmfile/environments/edu/secrets.yaml \
  > helmfile/environments/edu/secrets.enc.yaml

# Decrypt at deploy time
sops decrypt helmfile/environments/edu/secrets.enc.yaml
```

### ArgoCD Integration

For ArgoCD, use `external-secrets` or `sealed-secrets` to decrypt at sync time.
The SOPS-encrypted file can be committed to git safely.
