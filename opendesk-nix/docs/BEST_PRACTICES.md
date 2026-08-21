# 🏆 Container Image DevOps Best Practices

**Status:** COMPREHENSIVE GUIDE  
**Version:** 1.0.0  
**Maintainer:** openDesk Edu Team  
**Registry:** registry.gitlab.opencode.de/umr/

---

## 📋 **TABLE OF CONTENTS**

1. [🎯 General Best Practices](#1- General-Best-Practices)
2. [🔒 Security Best Practices](#2- Security-Best-Practices)
3. [🚀 Performance Best Practices](#3- Performance-Best-Practices)
4. [📦 Image Building Best Practices](#4- Image-Building-Best-Practices)
5. [🔄 CI/CD Best Practices](#5- CICD-Best-Practices)
6. [🏛️ Kubernetes Best Practices](#6- Kubernetes-Best-Practices)
7. [📊 Monitoring & Observability](#7- Monitoring--Observability)
8. [🔄 Update & Maintenance](#8- Update--Maintenance)
9. [📁 File Structure](#9- File-Structure)
10. [✅ Checklists](#10- Checklists)

---

## 1️⃣ **🎯 GENERAL BEST PRACTICES**

### **✅ Image Design**

| Practice | Description | Implementation |
|----------|-------------|----------------|
| **Single Concern** | Each image should do one thing well | ✅ SOGo, Dev Agent, Zot Registry separate |
| **Minimal Base** | Use smallest possible base image | ✅ Alpine, Distroless, Scratch |
| **Stateless** | Avoid storing state in images | ✅ Data in PVCs |
| **Config via ENV** | Use environment variables for config | ✅ All containers use ENV |
| **Secrets via K8s** | Never bake secrets into images | ✅ Kubernetes Secrets |
| **Health Checks** | Define liveness/readiness probes | ✅ All deployments have probes |
| **Non-Root User** | Run as non-root user | ✅ `USER 1000` or specific user |

### **📦 Image Naming Convention**

```
registry.gitlab.opencode.de/umr/<component>:<version>-<build>
registry.gitlab.opencode.de/umr/<component>:latest
```

**Examples:**
- `registry.gitlab.opencode.de/umr/sogo5:5.10.0-opendesk-1`
- `registry.gitlab.opencode.de/umr/sogo6:6.0.0 RC-1-opendesk-1`
- `registry.gitlab.opencode.de/umr/dev-agent:1.0.0-opendesk-1`
- `registry.gitlab.opencode.de/umr/zot-registry:2.0.0-hardened-opendesk-1`

### **📊 Image Metadata (LABELs)**

**Every image must have:**

```dockerfile
LABEL maintainer="tobias.weiss@hrz.uni-marburg.de"
LABEL org.opencontainers.image.title="Component Name"
LABEL org.opencontainers.image.description="Description"
LABEL org.opencontainers.image.vendor="openDesk Edu"
LABEL org.opencontainers.image.license="Apache-2.0"
LABEL org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-nix"
LABEL org.opencontainers.image.url="https://opendesk-edu.org"
LABEL org.opencontainers.image.documentation="https://..."
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.revision="git-commit-hash"
```

---

## 2️⃣ **🔒 SECURITY BEST PRACTICES**

### **✅ Image Security**

#### **🛡️ Dockerfile Security**

```dockerfile
# ✅ GOOD
FROM alpine:3.20 as builder
USER nobody
RUN apk add --no-cache package
WORKDIR /app
COPY --chown=nobody:nobody file.txt /app/

# ❌ BAD
FROM ubuntu:latest
USER root
RUN apt-get update && apt-get install -y package
WORKDIR /app
COPY . /app/
RUN chmod -R 777 /app
```

#### **🔐 Security Hardening Checklist**

| Check | Implementation | Status |
|-------|----------------|--------|
| Non-root user | `USER 1000` | ✅ |
| Read-only filesystem | `readOnlyRootFilesystem: true` | ✅ |
| Drop ALL capabilities | `cap_drop: [ALL]` | ✅ |
| No privilege escalation | `allowPrivilegeEscalation: false` | ✅ |
| Seccomp profile | `RuntimeDefault` | ✅ |
| No new privileges | SecurityContext | ✅ |
| Scan for vulnerabilities | Trivy/Grype | ⏳ |
| Sign images | Cosign | ⏳ |
| SBOM generation | Syft | ✅ (via SBOM workflow) |
| Minimal base image | Alpine/Distroless | ✅ |
| Multi-stage builds | Yes | ✅ |
| No secrets in image | Use K8s Secrets | ✅ |
| Verify dependencies | Signed packages | ⏳ |

#### **🎯 Security Context Examples**

**Pod Security Context:**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

**Container Security Context:**
```yaml
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
```

#### **🔍 Vulnerability Scanning**

**Tools:**
- [Trivy](https://github.com/aquasecurity/trivy) - Comprehensive scanning
- [Grype](https://github.com/anchore/grype) - Snyk alternative
- [Snyk](https://snyk.io/) - Commercial option

**Usage:**
```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan image
trivy image registry.gitlab.opencode.de/umr/sogo6:latest

# Scan with severity filter
trivy image --severity CRITICAL,HIGH registry.gitlab.opencode.de/umr/sogo6:latest

# Exit on vulnerabilities
trivy image --exit-code 1 --severity CRITICAL registry.gitlab.opencode.de/umr/sogo6:latest
```

#### **🔏 Image Signing (Cosign)**

**Installation:**
```bash
# Install cosign
curl -LO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign
```

**Key Management:**
```bash
# Generate keypair
cosign generate-key-pair

# Or use KMS (recommended for production)
cosign generate-key-pair-k8s
```

**Sign Images:**
```bash
# Sign an image
COSIGN_PASSWORD=password cosign sign --key cosign.key registry.gitlab.opencode.de/umr/sogo6:latest

# Sign with TUF (Transparent Log)
COSIGN_EXPERIMENTAL=true cosign sign --key cosign.key registry.gitlab.opencode.de/umr/sogo6:latest
```

**Verify Signatures:**
```bash
# Verify an image
cosign verify --key cosign.pub registry.gitlab.opencode.de/umr/sogo6:latest

# Verify with TUF
COSIGN_EXPERIMENTAL=true cosign verify --key cosign.pub registry.gitlab.opencode.de/umr/sogo6:latest
```

#### **📋 SBOM (Software Bill of Materials)**

**Generate SBOM:**
```bash
# With Syft (from Anchore)
syft registry.gitlab.opencode.de/umr/sogo6:latest -o cyclonedx-json > sbom-sogo6.json

# With Trivy
trivy image --format cyclonedx registry.gitlab.opencode.de/umr/sogo6:latest > sbom-sogo6.json

# For Go projects (k8up, operator)
go mod graph | syft stdio -o cyclonedx-json > sbom-go.json
```

**SBOM Standards:**
- CycloneDX (recommended)
- SPDX
- SWID Tags

---

## 3️⃣ **🚀 PERFORMANCE BEST PRACTICES**

### **✅ Image Optimization**

| Practice | Description | Implementation |
|----------|-------------|----------------|
| **Multi-stage builds** | Reduce final image size | ✅ All Dockerfiles |
| **Layer caching** | Reuse build layers | ✅ Ordered Dockerfile |
| **Minimal base** | Use smallest base | ✅ Alpine/Distroless |
| **Clean up** | Remove build deps | ✅ `rm -rf /var/lib/apt/lists/*` |
| **.dockerignore** | Exclude unnecessary files | ✅ All repos |
| **Compress layers** | Smaller image size | ✅ Docker 18.09+ |
| **Single RUN** | Combine commands | ✅ Reduce layers |

#### **📦 Multi-Stage Build Example**

```dockerfile
# Builder stage
FROM golang:1.21 as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/manager

# Final stage
FROM alpine:3.20
WORKDIR /app
COPY --from=builder /app/manager /app/
USER 1000
CMD ["/app/manager"]
```

#### **⚡ Layer Caching Best Practices**

```dockerfile
# ✅ GOOD - Ordered for maximum caching
FROM alpine:3.20

# 1. Install dependencies (cached unless package lists change)
RUN apk update && apk upgrade

# 2. Install packages (cached unless package versions change)
RUN apk add --no-cache package1 package2

# 3. Create directories (cached unless filesystem changes)
RUN mkdir -p /app/data

# 4. Copy files (cached unless files change)
COPY package.json /app/
RUN npm install

# 5. Copy source (changes most frequently, built last)
COPY . /app/

# ❌ BAD - No caching benefits
FROM alpine:3.20
RUN apk update && apk upgrade && apk add --no-cache package1 package2
COPY . /app/
RUN mkdir -p /app/data
COPY package.json /app/
RUN npm install
```

#### **📄 .dockerignore File**

```text
# Git
.git
.gitignore

# Node.js
node_modules/
npm-debug.log
 package-lock.json

# Go
go.mod
go.sum
Godeps/

# Docker
docker/
Dockerfile*
docker-compose*
.dockerignore

# Build artifacts
bin/
out/
dist/
*.log
*.tmp
*.swp

# IDE
.idea/
.vscode/
*.sublime-*

# OS
.DS_Store
Thumbs.db

# Test
coverage/
*.cover

# Docs
docs/
*.md
LICENSE
README.md

# Local development
.env
.env.*
```

### **✅ Runtime Performance**

| Practice | Implementation |
|----------|----------------|
| Resource limits | Set CPU/memory limits |
| Health checks | Liveness/readiness probes |
| Horizontal scaling | HPA configurations |
| Pod anti-affinity | Spread across nodes |
| Node affinity | Run on specific nodes |
| Tolerations | Handle taints |
| Priority classes | Prioritize critical pods |

---

## 4️⃣ **📦 IMAGE BUILDING BEST PRACTICES**

### **✅ Build Process**

#### **Build Arguments**

```dockerfile
# Define build arguments
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG GIT_COMMIT
ARG GIT_BRANCH

# Use build arguments
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.revision=$GIT_COMMIT
LABEL org.opencontainers.image.source=https://github.com/opendesk-edu/opendesk-nix/tree/$GIT_BRANCH
```

**Build Command:**
```bash
docker build \
  --build-arg VERSION=$(git describe --tags --always) \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
  --build-arg GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) \
  -t registry.gitlab.opencode.de/umr/sogo6:latest \
  -f docker/sogo6/Dockerfile .
```

#### **Build Cache Mounts (BuildKit)**

```bash
# Enable BuildKit
DOCKER_BUILDKIT=1 docker build .

# Use cache mounts
DOCKER_BUILDKIT=1 docker build \
  --cache-from type=local,src=path/to/cache •
  --cache-to type=local,dest=path/to/cache/deps,mode=max \
  .
```

#### **Squash Layers (Optional)**

```bash
# Squash all layers into one
docker build --squash -t image:tag .
```

### **✅ Image Tagging Strategy**

| Tag | Usage | Example |
|-----|-------|---------|
| `latest` | Development only | `registry.gitlab.opencode.de/umr/sogo6:latest` |
| `vX.Y.Z` | Production releases | `registry.gitlab.opencode.de/umr/sogo6:v6.0.0` |
| `vX.Y.Z-opendesk-N` | openDesk-specific | `registry.gitlab.opencode.de/umr/sogo6:v6.0.0-opendesk-1` |
| `git-commit` | Immutable | `registry.gitlab.opencode.de/umr/sogo6:abc1234` |
| `vX.Y.Z-rc.N` | Release candidates | `registry.gitlab.opencode.de/umr/sogo6:v6.0.0-rc1` |
| `vX.Y.Z-beta.N` | Beta releases | `registry.gitlab.opencode.de/umr/sogo6:v6.0.0-beta1` |

---

## 5️⃣ **🔄 CI/CD BEST PRACTICES**

### **✅ GitHub Actions Best Practices**

#### **Workflow Structure**

```
.github/workflows/
├── build.yml          # Build images
├── push.yml           # Push to registry
├── test.yml           # Run tests
├── scan.yml           # Security scanning
├── deploy.yml         # Deploy to Kubernetes
└── release.yml        # Release management
```

#### **Build Workflow Example**

```yaml
name: Build Docker Images

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: [self-hosted, linux]
    strategy:
      matrix:
        image: [sogo5, sogo6, dev-agent, zot-registry]
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to GitLab Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v2
        with:
          registry: registry.gitlab.opencode.de
          username: weiss
          password: ${{ secrets.OPENCODE_DE_TOKEN }}
      
      - name: Get image info
        id: image
        run: |
          IMAGE_NAME=${{ matrix.image }}
          if [ "$IMAGE_NAME" = "sogo5" ]; then
            DOCKERFILE="docker/sogo5/Dockerfile"
          elif [ "$IMAGE_NAME" = "sogo6" ]; then
            DOCKERFILE="docker/sogo6/Dockerfile"
          elif [ "$IMAGE_NAME" = "dev-agent" ]; then
            DOCKERFILE="docker/dev-agent/Dockerfile"
          elif [ "$IMAGE_NAME" = "zot-registry" ]; then
            DOCKERFILE="docker/zot-registry/Dockerfile"
          fi
          echo "dockerfile=$DOCKERFILE" >> $GITHUB_OUTPUT
          echo "name=${IMAGE_NAME}.gitlab.opencode.de/umr/${IMAGE_NAME}" >> $GITHUB_OUTPUT
      
      - name: Build and push (PR)
        if: github.event_name == 'pull_request'
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ${{ steps.image.outputs.dockerfile }}
          push: false
          tags: ${{ steps.image.outputs.name }}:pr-${{ github.event.number }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Build and push (main/develop)
        if: github.event_name != 'pull_request'
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ${{ steps.image.outputs.dockerfile }}
          push: true
          tags: |
            ${{ steps.image.outputs.name }}:latest
            ${{ steps.image.outputs.name }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            VERSION=${{ github.ref_name }}
            BUILD_DATE=${{ steps.date.outputs.date }}
            GIT_COMMIT=${{ github.sha }}
            GIT_BRANCH=${{ github.ref_name }}
      
      - name: Build and push (tags)
        if: startsWith(github.ref, 'refs/tags/')
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ${{ steps.image.outputs.dockerfile }}
          push: true
          tags: |
            ${{ steps.image.outputs.name }}:${{ github.ref_name }}
            ${{ steps.image.outputs.name }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

#### **Security Scan Workflow**

```yaml
name: Security Scan

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  trivy-scan:
    runs-on: [self-hosted, linux]
    strategy:
      matrix:
        image: [sogo5, sogo6, dev-agent, zot-registry]
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Build image
        uses: docker/build-push-action@v4
        id: build
        with:
          context: .
          file: docker/${{ matrix.image }}/Dockerfile
          push: false
          tags: local/${{ matrix.image }}:scan
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Run Trivy vulnerability scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: local/${{ matrix.image }}:scan
          format: 'sarif'
          output: 'trivy-results-${{ matrix.image }}.sarif'
          severity: 'CRITICAL,HIGH'
          ignore-unfixed: true
          vuln-type: 'os,library'
          exit-code: 1
      
      - name: Upload Trivy scan results to GitHub Security tab
        if: success() || failure()
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results-${{ matrix.image }}.sarif'
          category: ${{ matrix.image }}
      
      - name: Fail on critical vulnerabilities
        if: failure()
        run: |
          echo "::error::Critical vulnerabilities found in ${{ matrix.image }}"
          exit 1
```

#### **Image Signing Workflow**

```yaml
name: Sign Images

on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:

jobs:
  sign:
    runs-on: [self-hosted, linux]
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Install Cosign
        uses: sigstore/cosign-installer@v3
      
      - name: Login to GitLab Registry
        uses: docker/login-action@v2
        with:
          registry: registry.gitlab.opencode.de
          username: weiss
          password: ${{ secrets.OPENCODE_DE_TOKEN }}
      
      - name: Sign images
        run: |
          IMAGE List=("sogo5" "sogo6" "dev-agent" "zot-registry")
          for IMAGE in "${IMAGE List[@]}"; do
            FULL_IMAGE="registry.gitlab.opencode.de/umr/${IMAGE}:latest"
            echo "Signing ${FULL_IMAGE}..."
            cosign sign --key env://COSIGN_PRIVATE_KEY "${FULL_IMAGE}" •
            cosign sign --key env://COSIGN_PRIVATE_KEY "${FULL_IMAGE}@$(digest)" •
          done
        env:
          COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
          COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
      
      - name: Verify signatures
        run: |
          IMAGE List=("sogo5" "sogo6" "dev-agent" "zot-registry")
          for IMAGE in "${IMAGE List[@]}"; do
            FULL_IMAGE="registry.gitlab.opencode.de/umr/${IMAGE}:latest"
            cosign verify --key env://COSIGN_PUBLIC_KEY "${FULL_IMAGE}"
          done
        env:
          COSIGN_PUBLIC_KEY: ${{ secrets.COSIGN_PUBLIC_KEY }}
```

---

## 6️⃣ **🏛️ KUBERNETES BEST PRACTICES**

### **✅ Deployment Best Practices**

#### **Resource Management**

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
    ephemeral-storage: 10Gi
  limits:
    cpu: 500m
    memory: 512Mi
    ephemeral-storage: 50Gi
```

#### **Pod Disruption Budget**

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: sogo6-pdb
  namespace: opendesk
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: sogo6
```

#### **Horizontal Pod Autoscaler**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sogo6-hpa
  namespace: opendesk
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sogo6
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

#### **Network Policies**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: zot-registry-network-policy
  namespace: opendesk
spec:
  podSelector:
    matchLabels:
      app: zot-registry
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: opendesk
        - podSelector:
            matchLabels:
              app: sogo6
        - podSelector:
            matchLabels:
              app: dev-agent
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 443
        - protocol: TCP
          port: 3128
```

### **✅ Registry Configuration**

#### **Pull-Through Caching**

The Zot Registry is configured as a **pull-through cache** for:
- `ghcr.io/opendesk-edu/*`
- `ghcr.io/tobias-weiss-ai-xr/*`
- `registry.gitlab.opencode.de/umr/*`

This means:
1. First request: Pull from upstream, cache locally
2. Subsequent requests: Serve from local cache
3. Cache invalidation: Automatic based on upstream tags

#### **Storage Configuration**

| Component | StorageClass | Size | Purpose |
|-----------|-------------|------|---------|
| `zot-registry-storage` | ceph-rbd | 50Gi | Registry storage |
| `zot-registry-cache` | ceph-rbd | 20Gi | Cache storage |
| `zot-registry-backup` | ceph-rbd | 100Gi | Backup storage |

---

## 7️⃣ **📊 MONITORING & OBSERVABILITY**

### **✅ Registry Metrics**

Zot Registry exposes metrics on port **8081**:

```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: zot-registry-monitor
  namespace: opendesk
  labels:
    release: kube-prometheus-stack
spec:
  selector:
    matchLabels:
      app: zot-registry
  endpoints:
    - port: metrics
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s
```

### **✅ Key Metrics to Monitor**

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `zot_http_requests_total` | Total HTTP requests | - |
| `zot_http_request_duration_seconds` | Request duration | > 1s |
| `zot_storage_used_bytes` | Storage usage | > 80% |
| `zot_storage_free_bytes` | Free storage | < 20% |
| `zot_cache_hits_total` | Cache hits | - |
| `zot_cache_misses_total` | Cache misses | - |
| `zot_cache_hit_ratio` | Cache hit ratio | < 50% |
| `zot_pull_through_total` | Pull-through requests | - |

### **✅ Alert Rules**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: zot-registry-alerts
  namespace: opendesk
spec:
  groups:
    - name: zot-registry
      rules:
        - alert: ZotRegistryHighLatency
          expr: histogram_quantile(0.95, sum(rate(zot_http_request_duration_seconds_bucket[5m])) by (le)) > 1
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Zot Registry high latency ({{ $value }}s)"
            description: "95th percentile latency is {{ $value }}s for 5 minutes"
        
        - alert: ZotRegistryStorageFull
          expr: (zot_storage_used_bytes / zot_storage_total_bytes * 100) > 80
          for: 10m
          labels:
            severity: critical
          annotations:
            summary: "Zot Registry storage > 80% full"
            description: "Storage usage is {{ $value }}%"
        
        - alert: ZotRegistryLowCacheHitRatio
          expr: rate(zot_cache_hit_ratio[5m]) < 0.5
          for: 15m
          labels:
            severity: warning
          annotations:
            summary: "Zot Registry cache hit ratio < 50%"
            description: "Cache hit ratio is {{ $value }}%"
        
        - alert: ZotRegistryDown
          expr: up{job="zot-registry"} == 0
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: "Zot Registry is down"
            description: "Registry has been down for 1 minute"
```

### **✅ Logging**

**Audit Logging Configuration:**
```yaml
notification:
  audit:
    enabled: true
    file: /var/log/zot/audit.log
    maxSize: 100
    maxBackups: 5
    events:
      - Push
      - Pull
      - Delete
      - AuthenticationFailure
```

**Log Rotation:**
```yaml
# Sidecar container for log rotation
- name: log-rotator
  image: bitnami/logrotate:latest
  args: ["/etc/logrotate.conf"]
  volumeMounts:
    - name: logs
      mountPath: /var/log/zot
    - name: logrotate-config
      mountPath: /etc/logrotate.conf
      subPath: logrotate.conf
```

---

## 8️⃣ **🔄 UPDATE & MAINTENANCE**

### **✅ Image Update Process**

1. **Check for upstream updates**
   ```bash
   # SOGo
   watch -n 86400 docker pull sogo/sogo:5 && docker inspect sogo/sogo:5 | grep Version
   
   # Zot
   watch -n 86400 curl -s https://api.github.com/repos/zotregistry/zot/releases/latest | jq .tag_name
   ```

2. **Update Dockerfiles**
   - Update base image tags
   - Update version labels
   - Test builds locally

3. **Create PR with changes**
   - Update version in `VERSION` file
   - Update CHANGELOG.md
   - Update documentation

4. **Merge and release**
   ```bash
   git tag v2.0.1
   git push origin v2.0.1
   ```

5. **Automated rebuild trigger**
   ```yaml
   on:
     schedule:
       - cron: '0 2 * * 1'  # Every Monday at 2 AM
   ```

### **✅ Garbage Collection**

**Manual GC Trigger:**
```bash
# SSH into Zot pod
kubectl exec -it -n opendesk deploy/zot-registry -- sh

# Trigger garbage collection
curl -X POST http://localhost:8080/v2/internal/gc
```

**Automated GC (via CronJob):**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: zot-registry-gc
  namespace: opendesk
spec:
  schedule: "0 1 * * *"  # Daily at 1 AM
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: gc
              image: curlimages/curl:latest
              command:
                - /bin/sh
                - -c
                - |
                  curl -X POST http://zot-registry.opendesk.svc:8080/v2/internal/gc
                  echo "Zot Registry GC triggered"
```

### **✅ Backup & Restore**

**Backup CronJob:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: zot-registry-backup
  namespace: opendesk
spec:
  schedule: "0 0 * * 0"  # Weekly on Sunday at midnight
  successfulJobsHistoryLimit: 4
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: backup
              image: alpine:3.20
              command:
                - /bin/sh
                - -c
                - |
                  BACKUP_FILE="/backup/zot-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
                  tar -czf "$BACKUP_FILE" -C /var/lib/zot/storage .
                  tar -czf "${BACKUP_FILE%.tar.gz}-cache.tar.gz" -C /var/lib/zot/cache .
                  echo "Backup created: $BACKUP_FILE"
              volumeMounts:
                - name: storage
                  mountPath: /var/lib/zot/storage
                - name: cache
                  mountPath: /var/lib/zot/cache
                - name: backup
                  mountPath: /backup
          volumes:
            - name: storage
              persistentVolumeClaim:
                claimName: zot-registry-storage
            - name: cache
              persistentVolumeClaim:
                claimName: zot-registry-cache
            - name: backup
              persistentVolumeClaim:
                claimName: zot-registry-backup
```

---

## 9️⃣ **📁 FILE STRUCTURE**

```
opendesk-nix/
├── README.md                           # Hauptdokumentation
├── Makefile                            # Build/Push/Deploy Befehle
├── OPENCODE_DE_PUSH_GUIDE.md           # GitLab Registry Anleitung
├── docs/
│   ├── BEST_PRACTICES.md               # Diese Datei
│   ├── SECURITY.md                     # Sicherheitsspezifisch
│   └── DEPLOYMENT.md                   # Deployment Anleitung
│
├── docker/
│   ├── sogo5/
│   │   └── Dockerfile                  # SOGo 5 Image
│   ├── sogo6/
│   │   └── Dockerfile                  # SOGo 6 Image
│   ├── dev-agent/
│   │   └── Dockerfile                  # Dev Agent Image
│   └── zot-registry/
│       ├── Dockerfile                  # Zot Registry Image
│       ├── config.yml                  # Registry Konfiguration
│       └── passwd                      # HTPasswd Datei
│
├── k8s/
│   ├── sogo5/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── pvc.yaml
│   │   └── kustomization.yaml
│   ├── sogo6/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── pvc.yaml
│   │   └── kustomization.yaml
│   ├── dev-agent/
│   │   ├── deployment.yaml
│   │   ├── rbac.yaml
│   │   └── kustomization.yaml
│   └── zot-registry/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pvc.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── rbac.yaml
│       └── kustomization.yaml
│
└── .github/
    └── workflows/
        ├── build.yml
        ├── push.yml
        ├── scan.yml
        ├── sign.yml
        └── deploy.yml
```

---

## 🔟 **✅ CHECKLISTS**

### **🚀 Pre-Deployment Checklist**

- [ ] Dockerfiles use minimal base images
- [ ] All images run as non-root
- [ ] No secrets in images or Dockerfiles
- [ ] Resource limits are set
- [ ] Health checks are configured
- [ ] Security contexts are defined
- [ ] LABELs are set correctly
- [ ] .dockerignore is configured
- [ ] Multi-stage builds are used
- [ ] Build cache is optimized
- [ ] Image tags follow naming convention

### **🔒 Security Checklist**

- [ ] Non-root user in Dockerfiles
- [ ] Read-only filesystem where possible
- [ ] ALL capabilities dropped
- [ ] No privilege escalation
- [ ] Seccomp profile set
- [ ] Secrets via Kubernetes Secrets
- [ ] Vulnerability scanning enabled
- [ ] Image signing configured
- [ ] SBOM generation enabled
- [ ] Network policies configured
- [ ] Pod security policies configured
- [ ] Storage encryption (if needed)

### **📦 Production Checklist**

- [ ] All images are built and pushed
- [ ] Images are signed
- [ ] Vulnerability scans passed
- [ ] SBOMs generated and stored
- [ ] Deployments are configured
- [ ] Resource limits are set
- [ ] HPA configured (if needed)
- [ ] Monitoring is set up
- [ ] Alerting is configured
- [ ] Backups are configured
- [ ] Disaster recovery plan exists
- [ ] Documentation is updated

### **🏗️ Kubernetes Checklist**

- [ ] Namespace created
- [ ] Service accounts configured
- [ ] RBAC rules defined
- [ ] ConfigMaps created
- [ ] Secrets created
- [ ] PVCs created
- [ ] Deployments created
- [ ] Services created
- [ ] Ingress configured (if needed)
- [ ] Network policies configured
- [ ] PDB configured
- [ ] HPA configured (if needed)
- [ ] Pod disruption budget set
- [ ] Resource quotas set

---

## 🎯 **SUMMARY**

**This document provides:**

1. ✅ **General best practices** for container image design
2. ✅ **Security hardening** guidelines
3. ✅ **Performance optimization** techniques
4. ✅ **Image building** best practices
5. ✅ **CI/CD pipeline** configurations
6. ✅ **Kubernetes deployment** best practices
7. ✅ **Monitoring & observability** setup
8. ✅ **Update & maintenance** procedures
9. ✅ **File structure** recommendations
10. ✅ **Checklists** for all stages

**Follow these best practices to ensure:**
- 🔒 Maximum security
- 🚀 Optimal performance
- 📦 Reliable deployments
- 🏛️ Production-grade infrastructure

---

## 📚 **REFERENCES**

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [OCI Image Specification](https://github.com/opencontainers/image-spec)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes/)
- [NIST Container Security Guidelines](https://csrc.nist.gov/publications/detail/sp/800-190/final)
- [CNCF Cloud Native Security Whitepaper](https://github.com/cncf/sig-security)

---

## 🤝 **CONTRIBUTING**

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Update documentation
5. Submit a Pull Request

---

## 📜 **LICENSE**

Apache-2.0 - See [LICENSE](../../LICENSE)

---

> **"Security is not a product, but a process."** - Bruce Schneier

> **"If you think security is expensive, try an incident."** - unknown

> **"Automate everything, monitor everything, secure everything."** - DevOps Mantra
