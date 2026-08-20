# Zot Registry Docker Image - Technical Specification

**SPDX-License-Identifier: Apache-2.0**
**Maintainer: openDesk Edu Team <team@opendesk-edu.org>**
**Version: 2.0.0-rc5**
**Build Date: 2026-08-03T12:00:00Z**
**Registry: registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5**

---

## 📋 TABLE OF CONTENTS

1. [OVERVIEW](#1-overview)
2. [ARCHITECTURE](#2-architecture)
3. [DOCKER IMAGE SPECIFICATION](#3-docker-image-specification)
4. [CONFIGURATION](#4-configuration)
5. [ENTRYPOINT & HEALTHCHECKS](#5-entrypoint--healthchecks)
6. [SECURITY HARDENING](#6-security-hardening)
7. [KUBERNETES DEPLOYMENT](#7-kubernetes-deployment)
8. [PERFORMANCE & CACHING](#8-performance--caching)
9. [FILE SYSTEM LAYOUT](#9-file-system-layout)
10. [BUILD PROCESS](#10-build-process)
11. [APPENDICES](#11-appendices)

---

## 1. OVERVIEW

### 1.1 Purpose

The **openDesk Hardened Zot Registry** provides a **pull-through caching registry** for container images with:
- Multi-upstream mirroring
- Authentication support
- SBOM generation integration
- Cosign signature verification
- Rate limiting
- Hardened security profile

### 1.2 Use Cases

- **Local K3s caching** - Cache images from ghcr.io, GitLab, Docker Hub
- **Air-gapped environments** - Pre-cache required images
- **SBOM verification** - Validate container SBOMs before allowing pulls
- **Signature enforcement** - Require cosign signatures for all images
- **Multi-tenant registry** - Support multiple namespaces with RBAC

### 1.3 Supported Registries

| Registry | Pull-Through | Push | Authentication | SBOM |
|----------|--------------|------|----------------|------|
| docker.io | ✅ | ❌ | ✅ | ✅ |
| ghcr.io | ✅ | ❌ | ✅ | ✅ |
| registry.gitlab.com | ✅ | ❌ | ✅ | ✅ |
| registry.gitlab.opencode.de | ✅ | ❌ | ✅ | ✅ |
| quay.io | ✅ | ❌ | ✅ | ✅ |
| gcr.io | ✅ | ❌ | ✅ | ✅ |
| Local | ❌ | ✅ | ✅ | ✅ |

---

## 2. ARCHITECTURE

### 2.1 Pull-Through Caching Flow

```
+------------------------------------------------------------------+
|                              Cluster                                |
+------------------------------------------------------------------+
|                                                                  |
|  +---------------+                                               |
|  |   Developer   |                                               |
|  |   Pod         |                                               |
|  +-------+-------+                                               |
|          |                                                           |
|          v                                                           |
|  +-------+-------+                                               |
|  | Custom Image  |------+                                        |
|  |   Request     |      |                                        |
|  +---------------+      |                                        |
|                        v                                        |
|                +--------+--------+                                |
|                | Zot Registry   |                                |
|                | (Pull-Through) |                                |
|                +--------+--------+                                |
|                         |                                         |
|                    +----+----+                                   |
|                    v         v                                   |
|             +----------+  +----------+                           |
|             |   Cache   |  | Upstream |                           |
|             |   Hit     |  | Fetch    |                           |
|             +----------+  +----------+                           |
|                    |         |                                   |
|                    +----+----+                                   |
|                         |                                         |
|                    +----v----+                                   |
|                    | Response |                                   |
|                    |   to     |                                   |
|                    | Developer|                                   |
|                    +----------+                                   |
|                                                                  |
+------------------------------------------------------------------+
|                              Upstream                               |
+------------------------------------------------------------------+
|                                                                  |
|  +---------------+    +---------------+    +---------------+     |
|  |  ghcr.io      |    |  GitLab Reg   |    | docker.io     |     |
|  | (GitHub)      |    | (opencode.de) |    | (Docker Hub)  |     |
|  +---------------+    +---------------+    +---------------+     |
+------------------------------------------------------------------+
```

### 2.2 Caching Architecture

```
+---------------------------------------------------------------+
|                    Zot Registry Container                       |
+---------------------------------------------------------------+
|                                                               |
|  +---------------------------------------------------------+  |
|  |                      Storage                             |  |
|  |  +------------------+  +------------------+               |  |
|  |  |   Blob Storage    |  |  Index Storage   |               |  |
|  |  |   - OCI blobs     |  |  - Image index   |               |  |
|  |  |   - Layers        |  |  - Manifests     |               |  |
|  |  +------------------+  +------------------+               |  |
|  +---------------------------------------------------------+  |
|                                                               |
|  +---------------------------------------------------------+  |
|  |                      Cache                              |  |
|  |  +------------------+  +------------------+               |  |
|  |  |   Pull Cache      |  |   SBOM Cache     |               |  |
|  |  |   - Pushed images |  |   - Generated    |               |  |
|  |  |   - Pulled images |  |     SBOMs        |               |  |
|  |  +------------------+  +------------------+               |  |
|  +---------------------------------------------------------+  |
|                                                               |
|  +---------------------------------------------------------+  |
|  |                   Configuration                          |  |
|  |  +------------------+  +------------------+               |  |
|  |  |   config.yml     |  |   passwd         |               |  |
|  |  |   (Main config)   |  |   (Auth users)   |               |  |
|  |  +------------------+  +------------------+               |  |
|  +---------------------------------------------------------+  |
|                                                               |
|  +---------------------------------------------------------+  |
|  |                    Processes                             |  |
|  |  +------------------+  +------------------+               |  |
|  |  |     zotd          |  |   HealthServer   |               |  |
|  |  |   (Registry)      |  |   (8081)         |               |  |
|  |  +------------------+  +------------------+               |  |
|  +---------------------------------------------------------+  |
|                                                               |
+---------------------------------------------------------------+
```

---

## 3. DOCKER IMAGE SPECIFICATION

### 3.1 OCI Labels

```yaml
# Standard OCI Labels
org.opencontainers.image.title: openDesk Zot Registry
org.opencontainers.image.description: "Hardened Zot Registry 2.0.0-rc5 with pull-through caching, SBOM generation, cosign verification for openDesk Edu"
org.opencontainers.image.vendor: openDesk Edu
org.opencontainers.image.license: Apache-2.0
org.opencontainers.image.version: 2.0.0-rc5
org.opencontainers.image.source: https://github.com/opendesk-edu/opendesk-nix/tree/main/docker/zot-registry
org.opencontainers.image.documentation: https://opendesk-edu.org/docs/zot-registry
org.opencontainers.image.architectures: amd64
org.opencontainers.image.os: linux

# openDesk Labels
opendesk.org.component: registry
opendesk.org.purpose: container-registry-cache
opendesk.org.version: 2.0.0-rc5
opendesk.org.registry: registry.gitlab.opencode.de/umr
opendesk.org.hardened: "true"
opendesk.org.non-root: "true"

# ZKI IT-Grundschutz
de.zki.it-grundschutz.module: SW.1.1Registry,BA.3.4Docker
de.zki.it-grundschutz.layer: Platform
de.zki.it-grundschutz.classification: internal

# container.gov.de
de.container.gov.component: zot-registry
de.container.gov.component-type: registry
de.container.gov.security-level: enhanced
de.container.gov.sbom-format: CycloneDX-1.5,SPDX-2.3
de.container.gov.storage-type: oci
```

### 3.2 Image Variants

| Variant | Base | Size | Purpose |
|---------|------|------|---------|
| default | distroless-static | ~150MB | Production, minimal |
| alpine | alpine:3.18 | ~200MB | Debugging, full tools |

### 3.3 Build Arguments

| ARG | Default | Description |
|-----|---------|-------------|
| ZOT_VERSION | 2.0.0-rc5 | Zot version |
| BUILD_DATE | 2026-08-03T12:00:00Z | Build timestamp |
| BASE_IMAGE | distroless-static | Base image |

### 3.4 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| ZOT_HTTP_PORT | 8080 | HTTP port |
| ZOT_HTTPS_PORT | 8443 | HTTPS port (disabled by default) |
| ZOT_STORAGE_ROOT | /var/lib/zot/storage | Storage directory |
| ZOT_LOG_LEVEL | info | Log level (debug, info, warn, error) |
| ZOT_CONFIG_PATH | /etc/zot/config.yml | Config file path |

### 3.5 Exposed Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | TCP | HTTP (Registry API) |
| 8443 | TCP | HTTPS (if configured) |
| 8081 | TCP | Health check endpoint |

### 3.6 Volumes

| Mount | Path | Purpose | Required |
|-------|------|---------|----------|
| zot-storage | /var/lib/zot/storage | Blob & index storage | ✅ |
| zot-cache | /var/lib/zot/cache | Cache storage | ✅ |
| zot-config | /etc/zot | Configuration | ✅ |
| zot-tmp | /tmp/zot | Temporary files | ✅ |
| zot-logs | /var/log/zot | Log files | ✅ |

---

## 4. CONFIGURATION

### 4.1 Main Configuration (config.yml)

```yaml
# Server Configuration
http:
  port: 8080
  address: 0.0.0.0
  # tls:
  #   cert: /etc/zot/tls/tls.crt
  #   key: /etc/zot/tls/tls.key

# Logging
log:
  level: info
  format: json
  access: true

# Storage Configuration
storage:
  rootDirectory: /var/lib/zot/storage
  gc:
    enabled: true
    interval: 24h
    deleteUntagged: true
  dedupe: true
  rotation:
    enabled: true
    schedule: "0 0 * * *"

# Pull-Through Caching (Cable)
cable:
  enabled: true
  tmpDir: /tmp/zot
  port: 8080
  registries:
    - name: ghcr.io
      urls:
        - https://ghcr.io
      insecure: false
      strippedPrefixes:
        - "docker.io/library"
      tlsVerify: true
      
    - name: registry.gitlab.opencode.de
      urls:
        - https://registry.gitlab.opencode.de
      insecure: false
      
    - name: docker.io
      urls:
        - https://registry-1.docker.io
      insecure: false
      strippedPrefixes:
        - "docker.io/library"
      
    - name: gcr.io
      urls:
        - https://gcr.io
        - https://us.gcr.io
        - https://eu.gcr.io
        - https://asia.gcr.io
      insecure: false

# Authentication
auth:
  # HTTP Basic Auth
  htdpasswd:
    enabled: true
    path: /etc/zot/htpasswd
    
  # Bearer token auth
  bearer:
    enabled: true
    
  # Anonymous access
  anonymous:
    enabled: true
    read: true
    pull: true
    push: false
    delete: false

# Rate Limiting
rateLimit:
  enabled: true
  requestsPerSecond: 100
  burst: 200

# SBOM Configuration
sbom:
  enabled: true
  generator: "syft:latest"
  scanOnPush: true
  scanOnPull: false
  requiredForPush: false
  requiredForPull: false

# Cosign Configuration
cosign:
  enabled: true
  verificationKey: /etc/zot/cosign/cosign.pub
  requireSignatures: false

# Notifications (optional)
notifications:
  endpoint: ""
  enabled: false
```

### 4.2 Auth Configuration (passwd)

Basic authentication users (bcrypt hashed):

```bash
# Format: username:$2y$... (bcrypt hash)
# Generated with: htpasswd -Bc passwd username
zot:$2y$10$x/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 4.3 TLS Configuration

Place certificates in `/etc/zot/tls/`:
- `tls.crt` - Server certificate
- `tls.key` - Server private key

Enable in config.yml:
```yaml
http:
  tls:
    cert: /etc/zot/tls/tls.crt
    key: /etc/zot/tls/tls.key
  address: 0.0.0.0
  port: 8443
```

---

## 5. ENTRYPOINT & HEALTHCHECKS

### 5.1 Entrypoint (/entrypoint.sh)

**Purpose:** Manage Zot registry startup with validation and signal handling.

**Features:**
- Pre-flight configuration validation
- Directory permissions check
- Storage initialization
- Signal trapping (TERM, INT, QUIT)
- Graceful shutdown
- Health server startup

**Flow:**
```
Validate config.yml exists
├── Check storage directories
├── Check config permissions
└── Check network
    
Start Zot registry (zotd)
├── Load configuration
├── Initialize storage
└── Start HTTP server on port 8080

Start Health Server
└── HTTP endpoint on port 8081

Signal Handling
├── TERM: Graceful shutdown (30s timeout)
├── INT: Same as TERM
└── QUIT: Immediate shutdown
```

### 5.2 Healthcheck (/healthcheck.sh)

**Probes:**

| Probe | Endpoint | Check | Interval | Timeout |
|-------|----------|-------|----------|---------|
| Liveness | /healthz | Process running + storage accessible | 30s | 5s |
| Readiness | /ready | Registry responding on port 8080 | 15s | 10s |
| Startup | N/A | Process started | 10s | 5s |
| Deep | /health | Full connectivity + upstream reachable | 60s | 15s |

**Checks:**
- Zot process PID check
- Port 8080 TCP check
- Storage directory exists and writable
- Configuration file readable
- Upstream registries reachable
- Cache statistics

---

## 6. SECURITY HARDENING

### 6.1 User & Permissions

- **User:** `zot` (UID 1000)
- **All processes run as non-root**
- **Dir permissions:** 750 for configs, 700 for sensitive data

### 6.2 Security Context (K8s)

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true  # App writes to volumes only
  capabilities:
    drop: [ALL]
    # No additional capabilities needed
```

### 6.3 Distroless Base Image

The **default** image uses **gcr.io/distroless/static-debian12** which:
- Contains only the Zot binary and minimal OS
- No shell (`/bin/sh` does not exist)
- No package manager
- No intriguing binaries
- Minimal attack surface

### 6.4 Network Security

- **Rate limiting:** 100 req/s + 200 burst
- **Upstream TLS verification:** Always enabled
- **No direct internet access** from registry (pull-through only)
- **Anonymous read-only** by default (configurable)

### 6.5 Storage Security

- **Blob integrity:** SHA256 verified
- **Index validation:** OCI-compliant
- **Garbage collection:** Automatic, weekly
- **Deduplication:** Enabled

---

## 7. KUBERNETES DEPLOYMENT

### 7.1 Complete Deployment

```yaml
# zot-registry-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: zot-registry
  labels:
    name: zot-registry
    opendesk.org/component: registry
    de.zki.it-grundschutz.module: SW.1.1Registry

# zot-registry-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: zot-config
  namespace: zot-registry
  labels:
    app: zot-registry
    opendesk.org/config: "zot"
    de.container.gov.sbom: "cyclonedx+spdx"
data:
  config.yml: |
    # [Full config.yml from section 4.1]
    http:
      port: 8080
      address: 0.0.0.0
    log:
      level: info
      format: json
    storage:
      rootDirectory: /var/lib/zot/storage
    cable:
      enabled: true
      registries:
        - name: ghcr.io
          urls: ["https://ghcr.io"]
        - name: registry.gitlab.opencode.de
          urls: ["https://registry.gitlab.opencode.de"]
        - name: docker.io
          urls: ["https://registry-1.docker.io"]
    auth:
      htdpasswd:
        enabled: true
        path: /etc/zot/htpasswd
      anonymous:
        enabled: true
        read: true
        pull: true
    rateLimit:
      enabled: true
      requestsPerSecond: 100

# zot-registry-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: zot-secret
  namespace: zot-registry
  labels:
    app: zot-registry
    opendesk.org/secret: "zot-auth"
    de.container.gov.security: "sensitive"
stringData:
  passwd: |
    zot:$2y$10$x/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  htpasswd: |
    zot:$2y$10$x/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

type: Opaque

# zot-registry-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: zot-storage
  namespace: zot-registry
  labels:
    app: zot-registry
    opendesk.org/volume: "storage"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: ceph-rbd-ssd
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: zot-cache
  namespace: zot-registry
  labels:
    app: zot-registry
    opendesk.org/volume: "cache"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: ceph-rbd-ssd

# zot-registry-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: zot-registry
  namespace: zot-registry
  labels:
    app: zot-registry
    opendesk.org/sa: "zot"

# zot-registry-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zot-registry
  namespace: zot-registry
  labels:
    app: zot-registry
    version: 2.0.0-rc5
    opendesk.org/component: registry
    de.container.gov.component: zot-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zot-registry
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: zot-registry
        version: 2.0.0-rc5
        opendesk.org/pod: "zot"
        de.zki.it-grundschutz.layer: "Platform"
      annotations:
        de.container.gov.sbom: "sha256:..."
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      serviceAccountName: zot-registry
      containers:
      - name: zot
        image: registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5
        imagePullPolicy: IfNotPresent
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: [ALL]
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        env:
        - name: ZOT_HTTP_PORT
          value: "8080"
        - name: ZOT_LOG_LEVEL
          value: "info"
        - name: ZOT_STORAGE_ROOT
          value: "/var/lib/zot/storage"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 15
          timeoutSeconds: 10
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /healthz
            port: 8081
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 2000m
            memory: 4Gi
        volumeMounts:
        - name: zot-storage
          mountPath: /var/lib/zot/storage
        - name: zot-cache
          mountPath: /var/lib/zot/cache
        - name: zot-config
          mountPath: /etc/zot/config.yml
          subPath: config.yml
        - name: zot-secret
          mountPath: /etc/zot/htpasswd
          subPath: htpasswd
        - name: zot-tmp
          mountPath: /tmp/zot
        - name: zot-logs
          mountPath: /var/log/zot
      volumes:
      - name: zot-storage
        persistentVolumeClaim:
          claimName: zot-storage
      - name: zot-cache
        persistentVolumeClaim:
          claimName: zot-cache
      - name: zot-config
        configMap:
          name: zot-config
      - name: zot-secret
        secret:
          secretName: zot-secret
      - name: zot-tmp
        emptyDir:
          sizeLimit: 1Gi
      - name: zot-logs
        emptyDir:
          sizeLimit: 1Gi

# zot-registry-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: zot-registry
  namespace: zot-registry
  labels:
    app: zot-registry
    opendesk.org/service: "registry"
    de.container.gov.service-type: "oci-registry"
spec:
  type: ClusterIP
  selector:
    app: zot-registry
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
---
  selector:
    app: zot-registry
  ports:
  - name: registry
    port: 8080
    targetPort: 8080
    protocol: TCP

# zot-registry-ingress.yaml (optional, if external access needed)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: zot-registry-ingress
  namespace: zot-registry
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - zot-registry.example.com
    secretName: zot-registry-tls
  rules:
  - host: zot-registry.example.com
    http:
      paths:
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: zot-registry
            port:
              name: registry
```

### 7.2 NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: zot-registry-ingress
  namespace: zot-registry
spec:
  podSelector:
    matchLabels:
      app: zot-registry
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: opendesk
      podSelector:
        matchLabels:
          app.kubernetes.io/component: workspace
    ports:
    - protocol: TCP
      port: 8080
```

---

## 8. PERFORMANCE & CACHING

### 8.1 Caching Strategy

| Cache Type | Purpose | Location | Size |
|------------|---------|----------|------|
| Blob Cache | Layer caching | /var/lib/zot/cache | 50Gi |
| Manifets Cache | Manifest indexing | In storage | part of storage |
| SBOM Cache | SBOM storage | In storage | config |

### 8.2 Performance Tuning

```yaml
# config.yml optimizations
storage:
  gc:
    # More frequent GC for busy registries
    interval: 12h
    deleteUntagged: true
    
cable:
  # Cache configuration
  tmpDir: /tmp/zot
  
rateLimit:
  # For high-traffic
  requestsPerSecond: 1000
  burst: 2000

# For low-memory systems
# storage:
#   gc:
#     interval: 1h
```

### 8.3 Storage Recommendations

| Environment | Storage | Cache | Requests/day |
|-------------|---------|-------|--------------|
| Dev | 10Gi | 5Gi | <100 |
| Small | 100Gi | 50Gi | <10000 |
| Medium | 500Gi | 200Gi | <100000 |
| Large | 1Ti+ | 500Gi+ | >100000 |

---

## 9. FILE SYSTEM LAYOUT

```
/__unused__
└── [Distroless: minimal root filesystem]
    
/etc/
└── zot/
    ├── config.yml          (Registry configuration)
    ├── passwd              (Basic auth passwords)
    └── tls/                (TLS certificates)
        ├── tls.crt
        └── tls.key

/var/
├── lib/
│   └── zot/
│       ├── storage/        (PERSISTENT - OCI blobs, manifests)
│       │   ├── oci-repo/
│       │   │   └── registry/
│       │   │       └── v2/
│       │   │           ├── blob/
│       │   │           │   └── sha256/
│       │   │           └── manifests/
│       │   └── cache/
│       │       └── oci-repo/
│       └── cache/           (PERSISTENT - pull-through cache)
│
└── log/
    └── zot/                (PERSISTENT - registry logs)
        ├── access.log
        └── zot.log

/tmp/
└── zot/                   (EMPTY DIR - temp files)

/usr/
└── local/
    └── bin/
        └── zotd            (Zot registry binary)

/home/
└── zot/                   (Home for zot user)

/healthcheck.sh            (Health check script)
/entrypoint.sh             (Entrypoint script)
```

---

## 10. BUILD PROCESS

### 10.1 Multi-Stage Dockerfile

The Dockerfile uses multiple stages for security and size optimization:

1. **builder**: Compile Zot from source (Go 1.21)
2. **static**: Create static binary
3. **runtime**: Minimal image with only the binary

### 10.2 Building with Docker

```bash
# Build from source
docker build \
  --build-arg ZOT_VERSION=2.0.0-rc5 \
  -t registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5 \
  -t registry.gitlab.opencode.de/umr/zot-registry:latest \
  -f docker/zot-registry/Dockerfile \
  .

# Push
docker push registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5
docker push registry.gitlab.opencode.de/umr/zot-registry:latest
```

### 10.3 Building with Nix

```bash
nix build .#zot-registry-image
docker load < result
docker tag zot-registry:latest registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5
docker push registry.gitlab.opencode.de/umr/zot-registry:2.0.0-rc5
```

---

## 11. APPENDICES

### 11.1 API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /v2/ | Registry API v2 | Optional |
| GET | /v2/_catalog | List repositories | Optional |
| GET | /v2/<name>/tags/list | List image tags | Optional |
| GET | /v2/<name>/manifests/<ref> | Get manifest | Optional |
| GET | /v2/<name>/blobs/<sha> | Get blob | Optional |
| HEAD | /v2/<name>/blobs/<sha> | Check blob exists | Optional |
| POST | /v2/<name>/blobs/uploads/ | Start upload | Required |
| PATCH | /v2/<name>/blobs/uploads/<uuid> | Continue upload | Required |
| PUT | /v2/<name>/blobs/uploads/<uuid>?digest=<sha> | Complete upload | Required |
| PUT | /v2/<name>/manifests/<sha> | Upload manifest | Required |
| DELETE | /v2/<name>/manifests/<sha> | Delete manifest | Required |

### 11.2 Extension Endpoints (Zot-specific)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /v2/zot/config | Get Zot configuration |
| GET | /v2/zot/health | Deep health check |
| GET | /v2/zot/stats | Cache statistics |
| GET | /v2/zot/sbom/<image> | Get SBOM for image |

### 11.3 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| zot | 2.0.0-rc5 | Main registry |
| static-debian12 | latest | Base image |
| Go | 1.21 | Build dependency |

### 11.4 Compliance Checklist

- [x] Runs as non-root user (UID 1000)
- [x] Read-only root filesystem
- [x] All capabilities dropped
- [x] No privilege escalation allowed
- [x] Minimal base image (distroless)
- [x] All dependencies staticically linked
- [x] SBOM generation integrated
- [x] Rate limiting configured
- [x] Upstream TLS verification
- [x] Garbage collection enabled
- [x] OCI-compliant
- [x] ZKI IT-Grundschutz aligned
- [x] container.gov.de ready

---

## 📄 DOCUMENTATION LINKS

- [Zot Registry Official Site](https://zotregistry.io)
- [Zot GitHub](https://github.com/project-zot/zot)
- [OCI Distribution Spec](https://github.com/opencontainers/distribution-spec)
- [openDesk Documentation](https://opendesk-edu.org/docs)
- [container.gov.de](https://container.gov.de)

---

**Document Version:** 1.0.0  
**Last Updated:** 2026-08-03  
**Author:** openDesk Edu Team  
**License:** Apache-2.0
