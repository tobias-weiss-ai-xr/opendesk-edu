# ArgoCD Helmfile Plugin Setup

## Overview

ArgoCD manages deployments via Helmfile using a Config Management Plugin (CMP).
This document explains how the plugin works and how to set it up from scratch.

## Architecture

```
ArgoCD Repo Server Pod
├── Container: repo-server (main)
│   - Reads git repo, generates manifests
├── Container: sops (sidecar)
│   - Decrypts SOPS-encrypted files
└── Container: helmfile (sidecar) ← WE NEED THIS
    - Runs helmfile to render manifests
```

All sidecars share volumes:
- `/home/argocd/cmp-server/plugins/` — Plugin configs (from ConfigMaps)
- `/home/argocd/cmp-server/config/` — CMP server config
- `/custom-tools/` — Extra binaries (installed by init containers)
- `/var/run/argocd/` — Argocd binaries + sockets
- `/tmp/` — Shared temp space

## Current State

The `sops` plugin is already installed using this pattern:
1. **Init container** `install-sops`: Downloads `sops` binary to `/tools/`
2. **Shared volume** `extra-tools` (emptyDir): Mounted at `/custom-tools/`
3. **Sidecar container** `sops`: Runs `argocd-cmp-server`, uses `/custom-tools/sops`

The helmfile plugin is registered in `argocd-cm` but the helmfile sidecar
failed because the helmfile plugin image wasn't available on quay.io.

## Setup Instructions

### Prerequisites
```bash
# Access to the cluster with kubectl
export KUBECONFIG=/path/to/kubeconfig
export NAMESPACE=argocd
```

### Step 1: Register the Plugin in argocd-cm

```bash
# Get current config
kubectl get configmap argocd-cm -n argocd -o yaml > /tmp/argocd-cm.yaml

# Edit to add helmfile plugin under configManagementPlugins
# Append after the sops plugin:
# ---
# name: helmfile
# sidecar: true
# discover:
#   find:
#     glob: "**/helmfile*.yaml*"
```

Expected config in `argocd-cm`:
```yaml
data:
  configManagementPlugins: |
    ---
    name: sops
    sidecar: true
    discover:
      find:
        glob: "**/*.enc.yaml"
    ---
    name: helmfile
    sidecar: true
    discover:
      find:
        glob: "**/helmfile*.yaml*"
```

### Step 2: Create the Plugin ConfigMap

```yaml
# argocd-cmp-helmfile-plugin.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmp-helmfile-plugin
  namespace: argocd
data:
  plugin.yaml: |
    apiVersion: argoproj.io/v1alpha1
    kind: ConfigManagementPlugin
    metadata:
      name: helmfile
    spec:
      sidecar: true
      discover:
        find:
          glob: "**/helmfile*.yaml*"
      generate:
        command:
          - /usr/local/bin/argocd-cmp-server
```

### Step 3: Add Init Container to Install Helmfile

Add to `argocd-repo-server` deployment:

```yaml
spec:
  template:
    spec:
      initContainers:
        - name: install-helmfile
          image: curlimages/curl:latest
          command:
            - /bin/sh
            - -c
            - |
              # Install helm
              curl -sL https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz | tar xz -C /tools/ linux-amd64/helm
              # Install helmfile
              curl -sL https://github.com/helmfile/helmfile/releases/download/v0.171.0/helmfile_0.171.0_linux_amd64.tar.gz | tar xz -C /tools/ helmfile
              # Install helm-diff plugin
              /tools/helm plugin install https://github.com/databus23/helm-diff --version v3.9.14
              chmod +x /tools/helm /tools/helmfile
          volumeMounts:
            - mountPath: /tools
              name: extra-tools
```

### Step 4: Add Helmfile Sidecar

Add to `argocd-repo-server` deployment:

```yaml
spec:
  template:
    spec:
      containers:
        - name: helmfile
          image: quay.io/argoproj/argocd:v3.0.12  # Same image as repo-server
          command:
            - /usr/local/bin/argocd-cmp-server
          env:
            - name: HELMFILE_GLOBAL_OPTIONS
              value: "--environment hrz --namespace opendesk --allow-no-matching-release"
          securityContext:
            runAsNonRoot: true
            runAsUser: 999
          volumeMounts:
            - mountPath: /home/argocd/cmp-server/config
              name: cmp-plugin-config
            - mountPath: /home/argocd/cmp-server/plugins
              name: plugins
            - mountPath: /custom-tools
              name: extra-tools
            - mountPath: /var/run/argocd
              name: var-files
            - mountPath: /tmp
              name: tmp
```

### Step 5: Configure CMP Server

Ensure the `cmp-plugin-config` ConfigMap exists:

```yaml
# argocd-cmp-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmp-cm
  namespace: argocd
data:
  cmp.yaml: |
    plugins:
      - name: helmfile
        socketPath: /home/argocd/cmp-server/socks/helmfile.sock
```

### Step 6: Apply and Restart

```bash
# Apply plugin ConfigMap
kubectl apply -f argocd-cmp-helmfile-plugin.yaml

# Patch deployment with init container and sidecar
kubectl patch deployment argocd-repo-server -n argocd --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/initContainers/-", "value": {
    "name": "install-helmfile",
    "image": "curlimages/curl:latest",
    "command": ["/bin/sh", "-c", "curl -sL https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz | tar xz -C /tools/ linux-amd64/helm && curl -sL https://github.com/helmfile/helmfile/releases/download/v0.171.0/helmfile_0.171.0_linux_amd64.tar.gz | tar xz -C /tools/ helmfile && chmod +x /tools/helm /tools/helmfile"],
    "volumeMounts": [{"mountPath": "/tools", "name": "extra-tools"}]
  }}]'

kubectl patch deployment argocd-repo-server -n argocd --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/-", "value": {
    "name": "helmfile",
    "image": "quay.io/argoproj/argocd:v3.0.12",
    "command": ["/usr/local/bin/argocd-cmp-server"],
    "env": [{"name": "HELMFILE_GLOBAL_OPTIONS", "value": "--environment hrz --namespace opendesk --allow-no-matching-release"}],
    "securityContext": {"runAsNonRoot": true, "runAsUser": 999},
    "volumeMounts": [
      {"mountPath": "/home/argocd/cmp-server/config", "name": "cmp-plugin-config"},
      {"mountPath": "/home/argocd/cmp-server/plugins", "name": "plugins"},
      {"mountPath": "/custom-tools", "name": "extra-tools"},
      {"mountPath": "/var/run/argocd", "name": "var-files"},
      {"mountPath": "/tmp", "name": "tmp"}
    ]
  }}]'

# Wait for rollout
kubectl rollout status deploy/argocd-repo-server -n argocd --timeout=120s
```

### Step 7: Verify

```bash
# Check sidecar is running
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-repo-server \
  -o jsonpath='{.items[0].spec.containers[*].name}'

# Force sync an application
kubectl patch application opencloud -n argocd --type='json' \
  -p='[{"op": "replace", "path": "/status", "value": {}}]'

# Check sync status
kubectl get application opencloud -n argocd -o json | jq '.status.sync.status'
```

## Troubleshooting

### ImagePullBackOff
If the sidecar image can't be pulled (common in HRZ cluster):
```bash
# Check the error
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-repo-server | grep -A5 "ImagePullBackOff"

# The cluster uses a proxy - ensure proxy env vars are set
# Add to the sops sidecar (or globally in the deployment):
# env:
#   - name: HTTP_PROXY
#     value: http://www-proxy2.uni-marburg.de:3128
#   - name: HTTPS_PROXY
#     value: http://www-proxy2.uni-marburg.de:3128
```

### Helmfile Not Found
If the helmfile binary isn't found:
```bash
# Check if init container ran successfully
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server --container=install-helmfile

# Check if binary exists in the shared volume
kubectl exec -n argocd deploy/argocd-repo-server --container=helmfile -- ls -la /custom-tools/
```

### Plugin Not Detected
If ArgoCD doesn't detect the helmfile plugin:
```bash
# Check the plugin config
kubectl get configmap argocd-cmp-helmfile-plugin -n argocd -o yaml

# Check the argocd-cm plugin list
kubectl get configmap argocd-cm -n argocd -o jsonpath='{.data.configManagementPlugins}'

# Restart the repo-server to pick up new config
kubectl rollout restart deploy/argocd-repo-server -n argocd
```

## Known Issue: CMP Plugin Discovery in ArgoCD v3.0.12

In ArgoCD v3.0.12 (argo-cd chart v8.2.5), dynamically adding CMP sidecar
plugins to an existing deployment does not work reliably. The plugin sidecar
runs and creates the socket, but the repo-server fails with:

```
couldn't find cmp-server plugin with name "helmfile" supporting the given repository
```

CMP sidecar plugin discovery requires the plugin to be configured during
initial deployment via the Helm chart values.

### Workaround: Direct Helmfile Deployments

Services NOT managed by ArgoCD (stalwart, intercom, f13, grommunio,
semester-provisioning) can be deployed directly:

```bash
cd opendesk-edu/helmfile
helmfile --environment edu -l name=stalwart sync
```

For ArgoCD-managed apps (opencloud, sogo, xwiki, openproject), the changes
are committed in the git repos and ready. The helmfile plugin will work once
ArgoCD is upgraded with proper CMP plugin configuration (see below).

### Proper Installation (via Helm Chart Values)

To correctly install the helmfile plugin, add to the argo-cd Helm chart
values during the next upgrade:

```yaml
repoServer:
  extraContainers:
    - name: helmfile
      image: quay.io/argoproj/argocd:v3.0.12
      command: [/var/run/argocd/argocd-cmp-server]
      env:
        - name: HELMFILE_GLOBAL_OPTIONS
          value: "--environment hrz --namespace opendesk --allow-no-matching-release"
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      volumeMounts:
        - mountPath: /home/argocd/cmp-server/config
          name: cmp-plugin-helmfile-config
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /custom-tools
          name: extra-tools
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /tmp
          name: tmp
  volumes:
    - name: cmp-plugin-helmfile-config
      configMap:
        name: argocd-cmp-helmfile-plugin
        defaultMode: 420
  initContainers:
    - name: install-helmfile
      image: curlimages/curl:latest
      env:
        - name: HTTP_PROXY
          value: http://www-proxy2.uni-marburg.de:3128
        - name: HTTPS_PROXY
          value: http://www-proxy2.uni-marburg.de:3128
      command: ["/bin/sh", "-c", "set -ex; curl -sL --proxy http://www-proxy2.uni-marburg.de:3128 https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz | tar xz -C /tools/ linux-amd64/helm; mv /tools/linux-amd64/helm /tools/helm; curl -sL --proxy http://www-proxy2.uni-marburg.de:3128 https://github.com/helmfile/helmfile/releases/download/v0.171.0/helmfile_0.171.0_linux_amd64.tar.gz | tar xz -C /tools/ helmfile; chmod +x /tools/helm /tools/helmfile"]
      volumeMounts:
        - mountPath: /tools
          name: extra-tools

configs:
  cmp:
    plugins:
      - name: helmfile
        socketPath: /home/argocd/cmp-server/plugins/helmfile.sock
  cm:
    configManagementPlugins: |
      ---
      name: sops
      sidecar: true
      discover:
        find:
          glob: "**/*.enc.yaml"
      ---
      name: helmfile
      sidecar: true
      discover:
        find:
          glob: "**/helmfile*"
```

This approach ensures the plugin is registered during deployment and
discovery works correctly.
