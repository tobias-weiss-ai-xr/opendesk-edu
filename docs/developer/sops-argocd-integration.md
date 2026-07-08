# SOPS / ArgoCD Integration

This document describes how to configure ArgoCD to decrypt SOPS-encrypted
`.enc.yaml` files before applying them.

## Overview

The repository uses [SOPS](https://github.com/getsops/sops) with
[age](https://age-encryption.org/) to encrypt secrets as `.enc.yaml` files.
ArgoCD requires a **Config Management Plugin (CMP)** sidecar to decrypt these
files during sync.

## Architecture

```
ArgoCD Repo Server
  ├── CMP sidecar container
  │   ├── age private key (mounted as secret)
  │   └── sops binary
  └── Main container
```

The CMP sidecar intercepts `.enc.yaml` files, decrypts them with `sops
--decrypt`, and hands the plaintext to ArgoCD's resource detection.

## Prerequisites

1.  `sops` binary in the sidecar image
2.  `age` private key mounted into the sidecar
3.  `.sops.yaml` creation rules in the repository (already present)
4.  Environment variable `SOPS_AGE_KEY_FILE` pointing to the age key

## Sidecar Configuration

### 1. Create the age key Secret

The age private key (`~/.age/opendesk-edu.txt`) must be stored as a Kubernetes
Secret in the `argocd` namespace:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-sops-age-key
  namespace: argocd
type: Opaque
stringData:
  age-key.txt: |
    # age secret key
    AGE-SECRET-KEY-...
```

### 2. Define the CMP sidecar via ConfigMap

ArgoCD 2.4+ supports sidecar plugins declared in the `argocd-cm` ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  configManagementPlugins: |
    - name: sops
      sidecar: true
      command: ["/bin/sh", "-c"]
      args:
        - |
          sops --decrypt --input-type yaml --output-type yaml \
            "${ARGOCD_ENV_SOPS_AGE_KEY_FILE:+-a $ARGOCD_ENV_SOPS_AGE_KEY_FILE}" \
            "$1"
```

### 3. Patch the repo-server Deployment

The CMP sidecar container must be added to the `argocd-repo-server` Deployment:

```yaml
spec:
  template:
    spec:
      containers:
        - name: sops
          image: alpine/sops:latest     # or custom image with sops + age
          command: ["/var/run/argocd/argocd-cmp-server"]
          env:
            - name: SOPS_AGE_KEY_FILE
              value: /home/argocd/cmp-server/keys/age-key.txt
          volumeMounts:
            - name: argocd-sops-age-key
              mountPath: /home/argocd/cmp-server/keys
              readOnly: true
            - name: var-files
              mountPath: /var/run/argocd
            - name: plugins
              mountPath: /home/argocd/cmp-server/plugins
      volumes:
        - name: argocd-sops-age-key
          secret:
            secretName: argocd-sops-age-key
```

### 4. Annotate the Application

Each ArgoCD Application that uses SOPS-encrypted files needs the plugin
annotation:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: opendesk-edu
spec:
  source:
    repoURL: https://github.com/.../opendesk-edu.git
    path: .
  plugin:
    name: sops
```

## Alternative: initContainer approach

If CMP sidecars are not available, use an initContainer to decrypt all
`.enc.yaml` files before the repo-server processes them:

```yaml
initContainers:
  - name: sops-decrypt
    image: alpine/sops
    command:
      - /bin/sh
      - -c
      - |
        find /tmp/repo -name '*.enc.yaml' -exec sh -c '
          sops --decrypt "$1" > "${1%.enc.yaml}.yaml"
        ' _ {} \;
    env:
      - name: SOPS_AGE_KEY_FILE
        value: /keys/age-key.txt
    volumeMounts:
      - name: sops-age-key
        mountPath: /keys
        readOnly: true
```

## Testing

After configuring the CMP:

```bash
# Check plugin registration
kubectl -n argocd logs deployment/argocd-repo-server cmp-sidecar

# Test sync
argocd app sync opendesk-edu --preview

# Verify decrypted secrets (look for raw values, not ENC[...])
argocd app diff opendesk-edu --local
```

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `sops metadata not found` | File not encrypted | Check file extension matches `.enc.yaml$` regex |
| `no matching creation rules` | `.sops.yaml` not in repo root | Verify `.sops.yaml` exists |
| `can't decrypt without age key` | Key not mounted | Check `argocd-sops-age-key` Secret and volume mount |
| ArgoCD sees ENC[...] values | CMP not intercepting | Verify plugin annotations and sidecar registration |
