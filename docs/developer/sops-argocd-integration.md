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

## Sidecar Configuration (Actual Deployment)

This section describes the exact configuration applied to the HRZ cluster.

### 1. Create the age key Secret

The age private key (`~/.age/opendesk-edu.txt`) is stored as a Kubernetes
Secret in the `argocd` namespace. This was created using:

```bash
kubectl -n argocd create secret generic argocd-sops-age-key \\
  --from-file=age-key.txt=$HOME/.age/opendesk-edu.txt
```

### 2. Define the CMP sidecar plugin ConfigMap

A ConfigMap named `argocd-cmp-sops-plugin` defines the SOPS Config Management
Plugin. This tells ArgoCD how to invoke the sidecar and what files it
should discover.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmp-sops-plugin
  namespace: argocd
data:
  plugin.yaml: |-
    ---
    apiVersion: argoproj.io/v1alpha1
    kind: ConfigManagementPlugin
    metadata:
      name: sops
    spec:
      sidecar: true
      version: v1.0
      generate:
        command:
          - /bin/sh
          - -c
          - |
            if echo "$ARGOCD_ENV_FILE_PATH" | grep -q "\\.enc\\.yaml$"; then
              /custom-tools/sops --decrypt --input-type yaml --output-type yaml "$ARGOCD_ENV_FILE_PATH"
            else
              cat "$ARGOCD_ENV_FILE_PATH"
            fi
      discover:
        find:
          glob: "**/*.enc.yaml"
```

This ConfigMap was created using:

```bash
kubectl -n argocd create configmap argocd-cmp-sops-plugin \\
  --from-literal=plugin.yaml='<YAML above>'
```

### 3. Patch the `argocd-repo-server` Deployment

The `argocd-repo-server` Deployment needs to be patched to:

1.  Add an `install-sops` initContainer to download the `sops` binary.
2.  Add a `sops` sidecar container for the CMP, mounting necessary volumes
    and setting proxy environment variables.
3.  Add `extra-tools` and `argocd-sops-age-key` volumes.

The patch applied was:

```yaml
spec:
  template:
    spec:
      initContainers:
        - name: install-sops
          image: curlimages/curl:latest
          command:
            - /bin/sh
            - -c
            - "curl -sL -o /tools/sops https://github.com/getsops/sops/releases/download/v3.9.4/sops-v3.9.4.linux.amd64 && chmod +x /tools/sops"
          env:
            - name: HTTP_PROXY
              value: http://www-proxy1.uni-marburg.de:3128
            - name: HTTPS_PROXY
              value: http://www-proxy1.uni-marburg.de:3128
            - name: no_proxy
              value: argocd-repo-server,argocd-application-controller,argocd-metrics,argocd-server,argocd-server-metrics,argocd-redis,*.domain.local,127.0.0.0/8,10.0.0.0/8,172.16.0.0/16,172.17.0.0/16,192.168.0.0/16,gitlab.hrz.uni-marburg.de,registry.hrz.uni-marburg.de,weblogin.uni-marburg.de
          volumeMounts:
            - name: extra-tools
              mountPath: /tools
        - name: copyutil # Existing initContainer (do not remove)
          # ... (existing definition)
      containers:
        - name: sops
          image: quay.io/argoproj/argocd:v3.0.12 # Base ArgoCD repo-server image
          command: ["/var/run/argocd/argocd-cmp-server"]
          env:
            - name: SOPS_AGE_KEY_FILE
              value: /sops-age-key/age-key.txt
            - name: HTTP_PROXY # Added for proxy access in the CMP sidecar
              value: http://www-proxy1.uni-marburg.de:3128
            - name: HTTPS_PROXY # Added for proxy access in the CMP sidecar
              value: http://www-proxy1.uni-marburg.de:3128
            - name: no_proxy # Added for proxy access in the CMP sidecar
              value: argocd-repo-server,argocd-application-controller,argocd-metrics,argocd-server,argocd-server-metrics,argocd-redis,*.domain.local,127.0.0.0/8,10.0.0.0/8,172.16.0.0/16,172.17.0.0/16,192.168.0.0/16,gitlab.hrz.uni-marburg.de,registry.hrz.uni-marburg.de,weblogin.uni-marburg.de
          volumeMounts:
            - name: extra-tools
              mountPath: /custom-tools # Where sops binary is installed
            - name: argocd-sops-age-key
              mountPath: /sops-age-key
              readOnly: true
            - name: cmp-plugin-config
              mountPath: /home/argocd/cmp-server/config # Plugin config.yaml
            - name: var-files # Required existing mounts
              mountPath: /var/run/argocd
            - name: plugins # Required existing mounts
              mountPath: /home/argocd/cmp-server/plugins
        - name: repo-server # Existing main container (do not remove)
          # ... (existing definition)
      volumes:
        - name: extra-tools
          emptyDir: {}
        - name: argocd-sops-age-key
          secret:
            secretName: argocd-sops-age-key
        - name: cmp-plugin-config
          configMap:
            name: argocd-cmp-sops-plugin
        # ... (existing volumes)
```

The patch was applied using `kubectl -n argocd patch deployment argocd-repo-server --type strategic -p '<JSON_PATCH>'`. This caused a rollout.

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

---

## Testing

After configuring the CMP:

```bash
# Check plugin registration - should see "sops" listed
kubectl -n argocd logs deployment/argocd-repo-server sops

# Test sync - ensure it detects changes correctly and decrypts secrets
argocd app sync opendesk-edu --preview

# Verify decrypted secrets (look for raw values, not ENC[...])
argocd app diff opendesk-edu --local
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|\
| `sops metadata not found` | File not encrypted | Check file extension matches `.enc.yaml$` regex |\
| `no matching creation rules` | `.sops.yaml` not in repo root | Verify `.sops.yaml` exists |\
| `can\'t decrypt without age key` | Key not mounted | Check `argocd-sops-age-key` Secret and volume mount |\
| `invalid plugin configuration file. spec.generate command should be non-empty` | `plugin.yaml` syntax error | Ensure `generate.command` is an array of strings |\
| `curl: (28) Connection timed out` | Proxy not configured for `install-sops` | Add `HTTP_PROXY`, `HTTPS_PROXY`, `no_proxy` to `install-sops` initContainer environment variables |\
| ArgoCD sees ENC[...] values | CMP not intercepting | Verify plugin annotations, sidecar registration, and `discover.find.glob` in `plugin.yaml` |

