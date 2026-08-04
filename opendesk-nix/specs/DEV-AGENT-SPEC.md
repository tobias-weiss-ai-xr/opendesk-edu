# openDesk Dev Agent Operator - Technical Specification

## 📋 Document Information

| Field | Value |
|-------|-------|
| **Title** | openDesk Dev Agent Operator Technical Specification |
| **Version** | 1.2.0 |
| **Author** | openDesk Edu Team |
| **License** | Apache-2.0 |
| **Created** | 2026-08-02 |
| **Last Updated** | 2026-08-02 |
| **Status** | Production Ready |
| **SPDX-License-Identifier** | Apache-2.0 |

---

## 🎯 Overview

The **openDesk Dev Agent Operator** is a **Kubernetes-nativeself-healing agent** that **automatically monitors, detects, and repairs issues** in openDesk deployments. It implements a **closed-loop feedback system** where problems are automatically identified and resolved without human intervention.

### 🎯 Primary Objectives
1. **Automated Monitoring**: Continuously watch all openDesk components
2. **Health Detection**: Identify unhealthy components and pods
3. **Root Cause Analysis**: Determine the underlying cause of issues
4. **Automated Repair**: Apply appropriate fixes automatically
5. **Self-Learning**: Build knowledge base of common issues and solutions
6. **Notification**: Alert when issues cannot be auto-resolved

### 🏗️ Architecture Overview

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                            openDesk Dev Agent                            │
 │  ┌─────────────────────────────────────────────────────────────────────┐ │
 │  │                            Operator Pod                              │ │
 │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐   │ │
 │  │  │   Health    │  │   Repair    │  │       PI Memory            │   │ │
 │  │  │   Controller│  │   Controller│  │     Integration (LLM)      │   │ │
 │  │  │             │  │             │  │                             │   │ │
 │  │  └──────┬──────┘  └──────┬──────┘  └─────────────┬───────────────┘   │ │
 │  │         │                │                        │                 │ │
 │  └─────────┼────────────────┼────────────────────────┼─────────────────┘ │
 │            │                │                        │                   │
 │  ┌─────────▼──────┐  ┌─────▼──────┐           ┌──────▼─────────┐      │
 │  │  HealthPolicy  │  │ RepairStrategy│        │ Knowledge     │      │
 │  │  CRD           │  │ CRD          │        │ Base          │      │
 │  │                │  │              │        │ (Neo4j/PI)    │      │
 │  └────────────────┘  └──────────────┘        └────────────────┘      │
 │                                                                      │
 └──────────────────────────────────────────────────────────────────────────┘
                    │           │           │
                    ▼           ▼           ▼
        ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
        │  Watch          │ │  Detect         │ │  Repair         │
        │  Kubernetes     │ │  Issues         │ │  Issues         │
        │  Resources      │ │                 │ │                 │
        └─────────┬───────┘ └─────────┬───────┘ └─────────┬───────┘
                  │                   │                     │
        ┌─────────▼───────┐ ┌─────────▼───────┐ ┌─────────▼───────┐
        │  Namespaces:    │ │  Conditions:    │ │  Actions:      │
        │  - opendesk     │ │  - CrashLoop    │ │  - Restart     │
        │  - opendesk-edu │ │  - Error        │ │  - Recreate    │
        │  - default      │ │  - ImagePull    │ │  - Scale       │
        │                 │ │  - NotReady     │ │  - Patch       │
        └─────────────────┘ │  - HighLoad     │ │  - CollectLogs│
                              └─────────────────┘ └─────────────────┘

  ┌─────────────────────────────────────────────────────────────────────────┐
 │                         MONITORED COMPONENTS                              │
 ├─────────────────────────────────────────────────────────────────────────┤
 │  Authentication:      Database:         File Storage:       Search:     │
 │  - Keycloak            - MariaDB          - Nextcloud          - OpenSearch│
 │  - UCS                 - PostgreSQL       - SeaweedFS                      │
 │                        - MongoDB                                       │
 │  Groupware:            Message Queue:     Identity:          Monitoring: │
 │  - SOGo 5              - RabbitMQ         - UDMC REST API     - Prometheus│
 │  - SOGo 6              - Redis            - UCS Master        - Grafana   │
 │                                     Caching:                              │
 │                                     - Memcached                           │
 └─────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Image Details

### Image Registry & Tags
```
Registry: registry.gitlab.opencode.de/umr/
Repository: dev-agent
Tags:
  - latest
  - v1.2.0
  - v1.2.0-opendesk-001
  - v1.x
```

### Build Context
```
Source Repository: https://github.com/opendesk-edu/opendesk-dev-agent-operator
Build Command:     docker build -t registry.gitlab.opencode.de/umr/dev-agent:latest -f docker/dev-agent/Dockerfile .
Nix Command:        nix build .#dev-agent-image
```

### Base Image
```
Builder: golang:1.19-alpine3.18
Final:   alpine:3.18
Size: ~50MB (compressed), ~150MB (uncompressed)
```

---

## 🏗️ Build Process

### Stage 1: Builder Stage
**Purpose**: Compile Go operator binary from source

**Includes**:
- Go 1.19 toolchain
- CA certificates (for Go module downloads)
- Git (for cloning repository)
- Build essentials (gcc, musl-dev, make)
- Linux headers

**Build Process**:
```bash
# Clone the operator repository
RUN git clone https://github.com/opendesk-edu/opendesk-dev-agent-operator.git .

# Checkout specific version
RUN git checkout v${OPERATOR_VERSION}

# Build with ldflags for version metadata
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -a \
    -installsuffix cgo \
    -ldflags "-w -s \
        -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.Version=${VERSION}' \
        -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.BuildDate=${BUILD_DATE}' \
        -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.GitCommit=${GIT_COMMIT}' \
        -X 'github.com/opendesk-edu/opendesk-dev-agent-operator/cmd.GitBranch=${GIT_BRANCH}'" \
    -o /usr/local/bin/manager \
    ./cmd/main.go
```

**Output**: Single statically-linked binary at `/usr/local/bin/manager` (~55MB)

### Stage 2: Final Production Stage
**Purpose**: Create minimal, production-ready image

**Includes**:
- Alpine 3.18 base
- Non-root user (`opendesk`, UID 1000)
- CA certificates (for HTTPS connections)
- curl (for health checking)
- bash (for entrypoint scripts)
- tzdata (timezone support)
- Entrypoint script
- Health check script
- Default configuration

**Excludes**:
- Go toolchain
- Build tools
- Development headers
- Unnecessary packages

---

## 🔐 Security Specifications

### User & Permissions
```yaml
User: opendesk (UID 1000, GID 1000)
Home: /home/opendesk
Shell: /bin/false (non-interactive)
Security Context:
  runAsNonRoot: true
  readOnlyRootFilesystem: false  # Required for /tmp, /home/opendesk/.kube
  allowPrivilegeEscalation: false
  privileged: false
  capabilities:
    drop: ["ALL"]
```

### Filesystem Permissions
```
/home/opendesk              - 755  - opendesk:opendesk    - User home
/home/opendesk/.kube        - 700  - opendesk:opendesk    - Kubeconfig directory
/var/log/opendesk           - 755  - opendesk:opendesk    - Log directory
/tmp                         - 777  - root:root            - Temporary files
/etc/opendesk-dev-agent      - 755  - opendesk:opendesk    - Configuration directory
/etc/opendesk-dev-agent/config.yaml - 644  - opendesk:opendesk    - Default config
/usr/local/bin/manager       - 500  - opendesk:opendesk    - Operator binary (read-only for others)
/entrypoint.sh               - 755  - opendesk:opendesk    - Entrypoint script
/healthcheck.sh              - 755  - opendesk:opendesk    - Health check script
```

### Security Hardening
- ✅ **Non-root execution**: Always runs as `opendesk` user
- ✅ **Minimal base image**: Alpine 3.18 with only essential packages
- ✅ **No setuid/setgid binaries**: Verified with `find / -perm /6000 -type f`
- ✅ **No world-writable files**: Verified with `find / -perm /0002 -type f`
- ✅ **Dependency scanning**: CVE scanning with `grype` in CI/CD
- ✅ **Image signing**: Cosign signatures for all released images
- ✅ **No secrets in image**: All sensitive data via environment variables or mounted secrets
- ✅ **SBOM generation**: Software Bill of Materials generated for each build

### Security Context (Kubernetes)
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: false
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
    add: []
  seLinuxOptions:
    level: "s0:c123,c456"
  seccompProfile:
    type: RuntimeDefault
  appArmorProfile:
    type: RuntimeDefault
```

---

## 🎯 Custom Resource Definitions (CRDs)

### HealthPolicy CRD
**Purpose**: Define which components to monitor and how often

**API Version**: `opendesk-dev-agent.tobias-weiss-ai-xr.github.com/v1`

**Kind**: `HealthPolicy`

**Spec fields**:

```yaml
spec:
  # Check interval (default: 5m)
  checkInterval: 5m
  
  # Namespaces to monitor
  namespaces: ["opendesk", "opendesk-edu", "default"]
  
  # Component health checks
  componentHealth:
    - name: nextcloud
      type: Deployment
      minReadyReplicas: 1
      healthCheck:
        type: http  # http, tcp, exec
        path: /status.php
        port: 80
        initialDelay: 45s
        period: 30s
        timeout: 10s
        failureThreshold: 3
    - name: postgres
      type: StatefulSet
      minReadyReplicas: 1
      healthCheck:
        type: tcp
        port: 5432
    - name: keycloak
      type: StatefulSet
      minReadyReplicas: 1
      healthCheck:
        type: http
        path: /auth/realms/master
        port: 8080
  
  # Pod health monitoring
  podHealth:
    crashLoopThreshold: 5
    errorThreshold: 3
    warningThreshold: 2
    maxPodAge: 30d
    checkConditions: ["Ready", "ContainersReady", "PodScheduled"]
  
  # Node health monitoring
  nodeHealth:
    enabled: true
    checkConditions: ["Ready", "MemoryPressure", "DiskPressure", "PIDPressure"]
    thresholds:
      memoryUsage: 90%
      diskUsage: 85%
      cpuUsage: 80%
```

### RepairStrategy CRD
**Purpose**: Define automated repair actions to take when issues are detected

**API Version**: `opendesk-dev-agent.tobias-weiss-ai-xr.github.com/v1`

**Kind**: `RepairStrategy`

**Spec fields**:

```yaml
spec:
  # Enable/disable automatic repairs
  enabled: true
  
  # Time window for repairs
  repairWindow: 24h
  
  # Rate limiting
  maxRepairsPerHour: 12
  cooldownPeriod: 30m
  podCooldownPeriod: 5m
  
  # Components to target
  targets: ["keycloak*", "nextcloud*", "postgres*", "*sogo*"]
  targetNamespaces: ["opendesk", "opendesk-edu", "default"]
  
  # Repair actions
  repairActions:
    - type: restart
      priority: 10
      conditions: ["crashLoopBackOff", "error", "waiting"]
      config:
        deletePod: true
        useRolloutRestart: false
        gracePeriodSeconds: 30
        waitForReady: true
        readyTimeout: 300
      triggers:
        - type: podRestartCount
          operator: ">="
          value: 5
          within: 5m
        - type: containerStatus
          status: Waiting
          reason: CrashLoopBackOff
          within: 2m
    
    - type: recreate
      priority: 20
      conditions: ["imagePullBackOff", "errImagePull"]
      config:
        deletePod: true
        gracePeriodSeconds: 10
        waitForReady: true
      triggers:
        - type: containerStatus
          status: Waiting
          reason: ImagePullBackOff
          within: 30s
    
    - type: scale
      priority: 30
      conditions: ["highLoad", "memoryPressure"]
      config:
        targetReplicas: 2
        maxReplicas: 5
        scaleDown: true
        targetReplicasForScaleDown: 1
      triggers:
        - type: resourceUsage
          resource: cpu
          operator: ">"
          value: 80%
          within: 5m
```

---

## 📁 Files & Directories

### File System Layout
```
/
├── bin/
│   └── bash -> /usr/bin/bash
├── etc/
│   └── opendesk-dev-agent/
│       ├── config.yaml          # Default configuration
│       └── custom-config.yaml   # User customizations (optional)
├── home/
│   └── opendesk/
│       ├── .kube/               # Kubeconfig (empty by default)
│       │   └── config           # Optional kubeconfig override
│       └── logs/                # Application logs
├── tmp/                         # Temporary files
├── usr/
│   └── local/
│       └── bin/
│           └── manager          # Operator binary
├── var/
│   └── log/
│       └── opendesk/            # Operator logs
│           ├── operator.log     # Main operator log
│           ├── health.log       # Health check log
│           └── repair.log       # Repair action log
├── entrypoint.sh                # Container entrypoint
└── healthcheck.sh               # Health check script
```

### Key Files

#### `/usr/local/bin/manager` (Operator Binary)
- **Size**: ~55MB
- **Type**: Statically-linked Go binary
- **Permissions**: 500 (opendesk:opendesk)
- **Build**: From opendesk-dev-agent-operator repository
- **Features**:
  - HealthController: Monitors component health
  - RepairController: Executes repair actions
  - PI Memory Integration: Optional LLM-based knowledge
  - Metrics Server: Prometheus metrics endpoint
  - Health Server: Liveness/readiness endpoints

#### `/entrypoint.sh` (Entrypoint Script)
- **Size**: ~17KB
- **Type**: Bash script
- **Permissions**: 755 (opendesk:opendesk)

**Features**:
- Environment validation
- Directory setup with proper permissions
- Configuration template processing
- Health check server startup
- Main operator startup
- Signal handling (TERM, INT, QUIT, HUP)
- Graceful shutdown
- Multi-process management
- Cluster-specific optimizations (K3s, GKE, EKS, etc.)
- Error handling and logging

#### `/healthcheck.sh` (Health Check Script)
- **Size**: ~13KB
- **Type**: Bash script
- **Permissions**: 755 (opendesk:opendesk)

**Features**:
- Liveness check: Basic health verification
- Readiness check: Full health including dependencies
- Startup check: Extended timeout for initialization
- HTTP server mode: Can run as standalone health check server
- Comprehensive sub-checks:
  - Operator binary check
  - Operator process check
  - Environment validation
  - Configuration validation
  - Kubernetes cluster health
  - Required CRDs check
  - Operator RBAC check
  - Operator initialization check

#### `/etc/opendesk-dev-agent/config.yaml` (Default Configuration)
- **Size**: ~13KB
- **Type**: YAML configuration
- **Permissions**: 644 (opendesk:opendesk)

**Contents**:
- HealthPolicy: Default health monitoring configuration
- RepairStrategy: Default repair actions
- Component definitions for all openDesk services
- Priority-ordered repair actions
- Rate limiting and cooldown settings

---

## ⚙️ Environment Variables

### Required Variables
| Variable | Default | Description | Sensitive |
|----------|---------|-------------|-----------|
| `OPERATOR_NAME` | `opendesk-dev-agent` | Name of the operator | ❌ No |
| `OPERATOR_NAMESPACE` | `opendesk` | Namespace where operator runs | ❌ No |

### Core Configuration Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `OPERATOR_VERSION` | `1.2.0` | Operator version |
| `OPERATOR_LOG_LEVEL` | `info` | Logging verbosity (debug, info, warn, error, fatal, panic) |
| `OPERATOR_WATCH_NAMESPACES` | `opendesk,opendesk-edu,default` | Comma-separated list of namespaces to watch |
| `OPERATOR_DISABLE_PI_MEMORY` | `true` | Disable PI Memory (LLM) integration |
| `OPERATOR_ENABLE_LEADER_ELECTION` | `false` | Enable leader election for HA |
| `OPERATOR_METRICS_BIND_ADDRESS` | `0.0.0.0:8080` | Address for metrics server |
| `OPERATOR_HEALTH_PROBE_BIND_ADDRESS` | `0.0.0.0:8081` | Address for health probe server |
| `OPERATOR_ZAP_LOG_LEVEL` | `info` | Zap logger level |
| `OPERATOR_ZAP_ENCODER` | `json` | Log encoder (json or console) |
| `OPERATOR_DEBUG` | `false` | Enable debug mode |

### Kubernetes-Specific Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `K8S_CLUSTER_TYPE` | `k3s` | Kubernetes distribution (k3s, k8s, minikube, kind, gke, eks, aks, openshift) |
| `KUBERNETES_SERVICE_HOST` | *from service* | Kubernetes API server host |
| `KUBERNETES_SERVICE_PORT` | *from service* | Kubernetes API server port |

### Security Variables
| Variable | Default | Description | Sensitive |
|----------|---------|-------------|-----------|
| `OPERATOR_SERVICE_ACCOUNT` | *auto-generated* | Service account name | ❌ No |
| `OPERATOR_TLS_CERT` | *none* | TLS certificate for metrics server | ❌ No |
| `OPERATOR_TLS_KEY` | *none* | TLS key for metrics server | ✅ **YES** |

### PI Memory (LLM) Variables (Optional)
| Variable | Default | Description | Sensitive |
|----------|---------|-------------|-----------|
| `PI_MEMORY_ENABLED` | `false` | Enable PI Memory integration | ❌ No |
| `PI_MEMORY_ENDPOINT` | *none* | PI Memory API endpoint | ❌ No |
| `PI_MEMORY_API_KEY` | *none* | PI Memory API key | ✅ **YES** |
| `PI_MEMORY_MODEL` | `gpt-4` | LLM model to use | ❌ No |
| `PI_MEMORY_MAX_TOKENS` | `4096` | Maximum tokens per request | ❌ No |

---

## 🔗 Exposed Ports

| Port | Protocol | Description | Internal/External |
|------|----------|-------------|-------------------|
| 8080 | TCP | Metrics server (Prometheus) | Internal |
| 8081 | TCP | Health probe server (Liveness/Readiness) | Internal |
| 9443 | TCP | HTTPS metrics (if TLS configured) | Internal/External |

### Port Configuration
```yaml
ports:
  - containerPort: 8080
    name: metrics
    protocol: TCP
  - containerPort: 8081
    name: health
    protocol: TCP
  - containerPort: 9443
    name: https-metrics
    protocol: TCP
```

---

## ✅ Health Checks

### Kubernetes Probes

#### Liveness Probe
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8081
    scheme: HTTP
  initialDelaySeconds: 45
  periodSeconds: 30
  timeoutSeconds: 10
  successThreshold: 1
  failureThreshold: 3
```

#### Readiness Probe
```yaml
readinessProbe:
  httpGet:
    path: /readyz
    port: 8081
    scheme: HTTP
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 3
```

#### Startup Probe
```yaml
startupProbe:
  httpGet:
    path: /readyz
    port: 8081
    scheme: HTTP
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 60
```

### Docker HEALTHCHECK
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD /healthcheck.sh liveness || exit 1
```

### Health Check Endpoints

| Endpoint | Method | Description | Expected Response |
|----------|--------|-------------|-------------------|
| `/healthz` | GET | Liveness check | HTTP 200 if alive |
| `/readyz` | GET | Readiness check | HTTP 200 if ready |
| `/metrics` | GET | Prometheus metrics | HTTP 200 with metrics |
| `/version` | GET | Version information | JSON with version details |
| `/config` | GET | Current configuration | YAML/JSON configuration |

---

## 📊 Resource Requirements

### Requests & Limits (Kubernetes)
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
    ephemeral-storage: 100Mi
  limits:
    cpu: 500m
    memory: 512Mi
    ephemeral-storage: 500Mi
```

### Minimum System Requirements
| Component | Minimum | Recommended | Maximum |
|-----------|---------|-------------|---------|
| CPU | 100m | 250m | 1000m (1 vCPU) |
| Memory | 128MB | 256MB | 1GB |
| Storage | 100MB | 500MB | 2GB |
| Ephemeral Storage | 100MB | 200MB | 1GB |

### Cluster-Specific Adjustments

#### K3s (Recommended for openDesk)
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

#### Standard Kubernetes (Minikube, Kind)
```yaml
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

#### Managed Kubernetes (GKE, EKS, AKS)
```yaml
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

---

## 🏗️ Controllers

### HealthController
**Purpose**: Monitor health of all components in watched namespaces

**Responsibilities**:
1. Watch for HealthPolicy resources
2. Monitor all components defined in HealthPolicy
3. Check component health at regular intervals
4. Update HealthPolicy status with current health
5. Trigger repair actions when issues are detected
6. Maintain health history and metrics

**Health Check Types**:
- **HTTP**: Check HTTP endpoint returns 2xx status code
- **TCP**: Check TCP port is accepting connections
- **Exec**: Execute command inside container and check exit code
- **MayBeDeployed**: Check if resource is supposed to be deployed

**Health States**:
| State | Description |
|-------|-------------|
| Healthy | Component is functioning correctly |
| Warning | Component has minor issues but is functional |
| Degraded | Component has major issues but is partially functional |
| Unhealthy | Component is not functioning |
| Unknown | Health status cannot be determined |

### RepairController
**Purpose**: Execute automated repair actions based on detected issues

**Responsibilities**:
1. Watch for RepairStrategy resources
2. Monitor health status from HealthController
3. Determine appropriate repair action based on conditions
4. Execute repair actions with proper rate limiting
5. Track repair history and outcomes
6. Prevent repair loops (same issue repaired multiple times)

**Repair Action Types**:

| Type | Description | Conditions |
|------|-------------|------------|
| **restart** | Restart the pod | crashLoopBackOff, error, waiting |
| **recreate** | Delete and recreate the pod | imagePullBackOff, errImagePull |
| **scale** | Scale deployment up or down | highLoad, memoryPressure |
| **restartDeployment** | Restart all pods in deployment | ProgressDeadlineExceeded |
| **patch** | Apply JSON patch to resource | registryUnauthorized |
| **collectLogs** | Collect logs before other action | All errors |

**Repair Priority**:
- Lower number = higher priority
- Actions with higher priority are tried first
- Order: collectLogs (5) → restart (10) → recreate (20) → scale (30) → restartDeployment (40) → patch (50)

---

## 🤖 PI Memory Integration

### Overview
The operator can optionally integrate with **PI Memory (Personal Intelligence Memory)** to:
- Build a knowledge base of common issues and solutions
- Learn from past repairs to improve future decisions
- Use LLM (Large Language Model) for root cause analysis
- Generate natural language explanations of issues

### Features
1. **Knowledge Base**: Store patterns of issues and their solutions
2. **Self-Learning**: Automatically learn from successful repairs
3. **Context Understanding**: Understand the context of issues
4. **Prediction**: Predict likely issues based on patterns
5. **Recommendation**: Suggest repair actions based on knowledge

### Configuration
```yaml
# In operator flags
--enable-pi-memory=true
--pi-memory-endpoint=https://pi-memory.example.com/api
--pi-memory-api-key=your-api-key
--pi-memory-model=gpt-4
--pi-memory-max-tokens=4096
```

### API Integration
The operator communicates with PI Memory via REST API:

**Request Example**:
```json
POST /api/v1/query
Content-Type: application/json
Authentication: Bearer <api-key>

{
  "prompt": "Analyze this Kubernetes error: CrashLoopBackOff: back-off 5m0s restarting failed container httperror pod/nextcloud-7d6d8c4b8d-abcde",
  "model": "gpt-4",
  "max_tokens": 4096,
  "temperature": 0.7,
  "context": {
    "cluster": "opendesk",
    "namespace": "opendesk",
    "component": "nextcloud",
    "previous_issues": [...],
    "repair_history": [...]
  }
}
```

**Response Example**:
```json
{
  "id": "query-123",
  "created": "2026-08-02T12:00:00Z",
  "model": "gpt-4",
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Analysis: The nextcloud pod is crash-looping due to database connection issues. The pod cannot connect to the PostgreSQL database. Recommended action: Check if PostgreSQL is running and if the connection details in Nextcloud configuration are correct. Also verify that the PostgreSQL credentials secret is correctly configured."
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 100,
    "total_tokens": 125
  }
}
```

### Knowledge Graph
The operator builds a knowledge graph with:
- **Entities**: Kubernetes resources (Pods, Deployments, Services, etc.)
- **Issues**: Problems detected (CrashLoopBackOff, ImagePullBackOff, etc.)
- **Solutions**: Repair actions taken
- **Outcomes**: Results of repair actions (Success, Failed, Partial)
- **Relationships**: Connections between entities, issues, and solutions

### Learning Process
1. **Detect**: Issue is detected (e.g., pod crash-looping)
2. **Analyze**: PI Memory analyzes the issue and provides recommendations
3. **Repair**: Operator applies the recommended repair action
4. **Evaluate**: Monitor the result of the repair
5. **Learn**: Store the successful repair in the knowledge base
6. **Improve**: Use past experience for future similar issues

---

## 📈 Monitoring & Metrics

### Prometheus Metrics
The operator exposes Prometheus metrics at `:8080/metrics`:

#### Operator Metrics
```
# General operator metrics
opendesk_dev_agent_up{operator="opendesk-dev-agent"} 1
opendesk_dev_agent_version{version="1.2.0",git_commit="abc123"} 1
opendesk_dev_agent_start_time_seconds 1711234567.89

# Health check metrics
opendesk_healthchecks_total{namespace="opendesk",component="nextcloud",result="success"} 42
opendesk_healthchecks_total{namespace="opendesk",component="nextcloud",result="failure"} 2
opendesk_healthcheck_duration_seconds{namespace="opendesk",component="nextcloud",quantile="0.5"} 0.05
opendesk_healthcheck_duration_seconds{namespace="opendesk",component="nextcloud",quantile="0.9"} 0.89
opendesk_healthcheck_duration_seconds{namespace="opendesk",component="nextcloud",quantile="0.99"} 1.45

# Component health metrics
opendesk_component_health_info{namespace="opendesk",component="nextcloud",health="Healthy"} 1
opendesk_component_health_info{namespace="opendesk",component="postgres",health="Healthy"} 1
opendesk_component_health_changes_total{namespace="opendesk",component="nextcloud",from="Healthy",to="Unhealthy"} 1

# Repair metrics
opendesk_repairs_total{namespace="opendesk",action="restart",result="success"} 5
opendesk_repairs_total{namespace="opendesk",action="restart",result="failed"} 1
opendesk_repairs_duration_seconds{namespace="opendesk",action="restart",quantile="0.5"} 5.23
opendesk_repairs_cooldown_remaining_seconds{namespace="opendesk",component="nextcloud"} 1200

# Resource metrics
opendesk_component_cpu_usage{namespace="opendesk",component="nextcloud"} 0.45
opendesk_component_memory_usage{namespace="opendesk",component="nextcloud"} 0.67
opendesk_component_restart_count{namespace="opendesk",component="nextcloud",pod="nextcloud-7d6d8c4b8d-abcde"} 3
```

### Grafana Dashboards
Recommended Grafana dashboards:

1. **Operator Overview Dashboard**
   - Operator health and status
   - Total components monitored
   - Current health distribution
   - Recent repair actions
   - Resource usage

2. **Health Monitoring Dashboard**
   - Health check success rate
   - Health check duration
   - Health state distribution
   - Health transitions over time
   - Components with most issues

3. **Repair Actions Dashboard**
   - Total repairs by type
   - Repair success rate
   - Repair duration
   - Most repaired components
   - Recent repair history
   - Cooldown status

4. **Component-Specific Dashboards**
   - Individual component health
   - Component resource usage
   - Component-specific metrics
   - Component repair history

---

## 📊 Alerts

### Recommended Alert Rules

#### Health Alerts
```yaml
# Component Unhealthy
- alert: ComponentUnhealthy
  expr: opendesk_component_health_info{health="Unhealthy"} == 1
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Component {{ $labels.component }} in namespace {{ $labels.namespace }} is unhealthy"
    description: "The component {{ $labels.component }} has been unhealthy for 5 minutes"

# Multiple Components Unhealthy
- alert: MultipleComponentsUnhealthy
  expr: count(opendesk_component_health_info{health="Unhealthy"}) > 3
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Multiple components are unhealthy"
    description: "More than 3 components are currently unhealthy"

# Health Check Failures
- alert: HealthCheckFailures
  expr: rate(opendesk_healthchecks_total{result="failure"}[5m]) > 0.1
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High health check failure rate"
    description: "Health check failure rate is {{ $value }} per second"
```

#### Repair Alerts
```yaml
# Repair Failed
- alert: RepairFailed
  expr: opendesk_repairs_total{result="failed"} > 0
  labels:
    severity: warning
  annotations:
    summary: "Repair action failed"
    description: "A repair action of type {{ $labels.action }} failed"

# Too Many Repairs
- alert: TooManyRepairs
  expr: rate(opendesk_repairs_total[1h]) > 10
  labels:
    severity: warning
  annotations:
    summary: "High repair rate"
    description: "Repair rate is {{ $value }} per hour"

# Repair Loop Detected
- alert: RepairLoopDetected
  expr: opendesk_repairs_total{action="restart"} > 5 and opendesk_component_health_info{health="Unhealthy"} == 1
  for: 30m
  labels:
    severity: critical
  annotations:
    summary: "Repair loop detected"
    description: "Component {{ $labels.component }} has been repairing repeatedly without success"
```

---

## 🛡️ RBAC (Role-Based Access Control)

### Service Account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
automountServiceAccountToken: true
```

### ClusterRole (For Multi-Namespace Support)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: opendesk-dev-agent
  labels:
    app: opendesk-dev-agent
rules:
  # CRDs
  - apiGroups: ["opendesk-dev-agent.tobias-weiss-ai-xr.github.com"]
    resources: ["healthpolicies", "repairstrategies", "healthpolicies/status", "repairstrategies/status"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  
  # Core resources
  - apiGroups: [""]
    resources: ["pods", "deployments", "statefulsets", "replicasets", "services", "nodes", "namespaces", "secrets", "configmaps", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch"]
  
  # Apps resources
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "replicasets", "daemonsets"]
    verbs: ["get", "list", "watch"]
  
  # Batch resources (for CronJobs)
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch"]
  
  # Repair actions require these permissions
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["delete", "create"]  # For restart/recreate actions
  
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["patch", "update"]  # For scaling and patching actions
  
  # For leader election (if enabled)
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  
  # For image pull secrets
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
```

### Role (For Single Namespace)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
rules:
  # CRDs
  - apiGroups: ["opendesk-dev-agent.tobias-weiss-ai-xr.github.com"]
    resources: ["healthpolicies", "repairstrategies", "healthpolicies/status", "repairstrategies/status"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  
  # Core resources
  - apiGroups: [""]
    resources: ["pods", "deployments", "statefulsets", "replicasets", "services", "secrets", "configmaps", "persistentvolumeclaims"]
    verbs: ["get", "list", "watch"]
  
  # Apps resources
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets", "replicasets"]
    verbs: ["get", "list", "watch"]
  
  # Repair permissions
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["delete", "create"]
  
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["patch", "update"]
```

### ClusterRoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: opendesk-dev-agent
  labels:
    app: opendesk-dev-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: opendesk-dev-agent
subjects:
  - kind: ServiceAccount
    name: opendesk-dev-agent
    namespace: opendesk
```

### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: opendesk-dev-agent
subjects:
  - kind: ServiceAccount
    name: opendesk-dev-agent
    namespace: opendesk
```

---

## 📝 Deployment Example

### Single Namespace Deployment
```yaml
---
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: opendesk
  labels:
    name: opendesk
    managed-by: opendesk-dev-agent

---
# Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent

---
# Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
rules:
  - apiGroups: ["opendesk-dev-agent.tobias-weiss-ai-xr.github.com"]
    resources: ["healthpolicies", "repairstrategies", "healthpolicies/status", "repairstrategies/status"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["pods", "deployments", "statefulsets", "services", "secrets", "configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "statefulsets"]
    verbs: ["get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["delete", "create"]

---
# Role Binding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: opendesk-dev-agent
subjects:
  - kind: ServiceAccount
    name: opendesk-dev-agent
    namespace: opendesk

---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
    version: v1.2.0
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opendesk-dev-agent
      version: v1.2.0
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: opendesk-dev-agent
        version: v1.2.0
      annotations:
        kubectl.kubernetes.io/default-container: manager
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: /metrics
    spec:
      serviceAccountName: opendesk-dev-agent
      containers:
        - name: manager
          image: registry.gitlab.opencode.de/umr/dev-agent:v1.2.0
          imagePullPolicy: Always
          args:
            - --debug
            - --disable-pi-memory
            - --watch-namespace=opendesk
            - --watch-namespace=opendesk-edu
            - --watch-namespace=default
            - --zap-log-level=info
            - --zap-encoder=json
            - --leader-elect=false
            - --metrics-addr=0.0.0.0:8080
            - --health-probe-addr=0.0.0.0:8081
          ports:
            - containerPort: 8080
              name: metrics
              protocol: TCP
            - containerPort: 8081
              name: health
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 45
            periodSeconds: 30
            timeoutSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 15
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /readyz
              port: 8081
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 60
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
              ephemeral-storage: 100Mi
            limits:
              cpu: 500m
              memory: 512Mi
              ephemeral-storage: 500Mi
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            runAsGroup: 1000
            readOnlyRootFilesystem: false
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: config
              mountPath: /etc/opendesk-dev-agent
              readOnly: true
          env:
            - name: OPERATOR_NAME
              value: opendesk-dev-agent
            - name: OPERATOR_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: OPERATOR_VERSION
              value: "1.2.0"
            - name: OPERATOR_LOG_LEVEL
              value: info
            - name: OPERATOR_WATCH_NAMESPACES
              value: "opendesk,opendesk-edu,default"
            - name: OPERATOR_DISABLE_PI_MEMORY
              value: "true"
            - name: OPERATOR_ENABLE_LEADER_ELECTION
              value: "false"
            - name: K8S_CLUSTER_TYPE
              value: "k3s"
            - name: OPERATOR_ZAP_LOG_LEVEL
              value: info
            - name: OPERATOR_ZAP_ENCODER
              value: json
      volumes:
        - name: config
          configMap:
            name: opendesk-dev-agent-config
            items:
              - key: config.yaml
                path: config.yaml

---
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: opendesk-dev-agent-config
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
data:
  config.yaml: |
    # [The contents of the default config.yaml go here]
    apiVersion: opendesk-dev-agent.tobias-weiss-ai-xr.github.com/v1
    kind: HealthPolicy
    metadata:
      name: opendesk-health-monitor
      namespace: opendesk
    spec:
      checkInterval: 5m
      namespaces:
        - opendesk
        - opendesk-edu
        - default
      componentHealth:
        - name: keycloak
          type: StatefulSet
          minReadyReplicas: 1
        - name: nextcloud
          type: Deployment
          minReadyReplicas: 1
        - name: postgres
          type: StatefulSet
          minReadyReplicas: 1
      podHealth:
        crashLoopThreshold: 5
        errorThreshold: 3
        warningThreshold: 2
    ---
    apiVersion: opendesk-dev-agent.tobias-weiss-ai-xr.github.com/v1
    kind: RepairStrategy
    metadata:
      name: opendesk-repair-strategy
      namespace: opendesk
    spec:
      enabled: true
      maxRepairsPerHour: 12
      cooldownPeriod: 30m
      targets:
        - "keycloak*"
        - "nextcloud*"
        - "postgres*"
      repairActions:
        - type: restart
          priority: 10
          conditions: ["crashLoopBackOff", "error", "waiting"]
          config:
            deletePod: true
            gracePeriodSeconds: 30
            waitForReady: true
        - type: recreate
          priority: 20
          conditions: ["imagePullBackOff", "errImagePull"]
          config:
            deletePod: true
            gracePeriodSeconds: 10

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
  labels:
    app: opendesk-dev-agent
    version: v1.2.0
spec:
  type: ClusterIP
  ports:
    - name: metrics
      port: 8080
      targetPort: 8080
      protocol: TCP
    - name: health
      port: 8081
      targetPort: 8081
      protocol: TCP
  selector:
    app: opendesk-dev-agent
    version: v1.2.0
```

### Multi-Namespace Deployment (with ClusterRole)
For watching multiple namespaces, use ClusterRole and ClusterRoleBinding:

```yaml
# Use the ClusterRole and ClusterRoleBinding from earlier
# The only difference is in the Deployment:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: opendesk-dev-agent
  namespace: opendesk
spec:
  template:
    spec:
      serviceAccountName: opendesk-dev-agent
      containers:
        - name: manager
          args:
            - --debug
            - --disable-pi-memory
            - --watch-namespace=opendesk
            - --watch-namespace=opendesk-edu  
            - --watch-namespace=default
            - --watch-namespace=monitoring
            - --watch-namespace=ingress-nginx
            - --leader-elect=true  # Recommended for multi-namespace
            # ... rest of the args
```

---

## 🚀 Startup Process

### Container Lifecycle
```
1. Container starts (PID 1 = /entrypoint.sh)
   ↓
2. entrypoint.sh executes:
   ├── Validate environment variables (OPERATOR_NAME, OPERATOR_NAMESPACE)
   ├── Set defaults for optional variables
   ├── Setup directories (/home/opendesk, /home/opendesk/.kube, /var/log/opendesk)
   ├── Apply cluster-specific optimizations (K3s, GKE, etc.)
   ├── Setup configuration (validate config.yaml)
   │
   └── Start health check server on port 8081
       └── PID stored in HEALTH_PID
   ↓
3. Start operator binary:
   ├── Parse command-line arguments
   ├── Initialize Kubernetes client
   ├── Setup signal handling
   ├── Initialize controllers (HealthController, RepairController)
   ├── Start metrics server on port 8080
   ├── Start health probe server
   ├── Wait for leader election (if enabled)
   │
   └── Start controllers
       ├── HealthController starts watching HealthPolicy resources
       └── RepairController starts watching RepairStrategy resources
   ↓
4. Signal traps configured:
   ├── TERM → Graceful shutdown
   ├── INT  → Graceful shutdown
   ├── QUIT → Graceful shutdown
   └── HUP  → Graceful shutdown
   ↓
5. Container running:
   ├── Operator monitors components health
   ├── RepairController executes repair actions when needed
   ├── Metrics exposed on port 8080/metrics
   ├── Health checks available on port 8081/healthz and /readyz
   └── Logs written to /var/log/opendesk/operator.log
   ↓
6. Graceful shutdown:
   ├── Signal received (TERM/INT)
   ├── Stop health check server
   ├── Stop operator binary
   ├── Wait for processes to exit (30s timeout)
   ├── Force kill if needed
   └── Container exits with code 0
```

### Time To Ready (TTR)
| Milestone | Time | Description |
|-----------|------|-------------|
| Container started | 0s | Entrypoint begins |
| Environment validated | 1s | All env vars checked |
| Directories created | 2s | All dirs with correct perms |
| Config validated | 3s | Configuration checked |
| Cluster optimizations applied | 4s | K3s/GKE settings applied |
| Health check server started | 5s | Health check server listening |
| Operator binary starting | 7s | operator process launched |
| Kubernetes client initialized | 15s | K8s API connection established |
| Controllers starting | 20s | HealthController + RepairController |
| **Health check passes** | **45s** | HTTP /healthz responds 200 |
| **Operator ready** | **45s** | Ready to monitor and repair |
| **First health checks** | **50s** | First component health checks |

---

## 📈 Performance Characteristics

### Throughput
| Metric | Value | Notes |
|--------|-------|-------|
| Components monitored | Unlimited | Limited by API server rate limits |
| Health checks/sec | 10-50 | Depends on checkInterval |
| Repair actions/sec | 1-5 | Rate-limited by cooldownPeriod |
| API requests/sec | 50-200 | Depends on cluster size |
| Events processed/sec | 100-500 |watch |

### Latency
| Operation | Average | P95 | P99 |
|-----------|---------|-----|-----|
| Health check | 50ms | 200ms | 500ms |
| Repair action | 5s | 30s | 60s |
| API request | 10ms | 50ms | 100ms |
| K8s API call | 5ms | 20ms | 50ms |

### Resource Usage
| Resource | Average | Peak | Notes |
|----------|---------|------|-------|
| CPU | 50m | 200m | During active repairs |
| Memory | 100MB | 200MB | Depends on cache size |
| Storage | 50MB | 100MB | Logs and configuration |
| Network | 1Mbps | 10Mbps | During health checks |

### Scalability
| Metric | Single Operator | Multiple Operators | Notes |
|--------|-----------------|---------------------|-------|
| Max Namespaces | 10 | Unlimited | With proper RBAC |
| Max Components | 1000 | 10000+ | Per operator |
| Max Health Checks | 10000/min | 100000/min | Rate-limited |
| Max Repair Actions | 50/hour | 500/hour | Configurable |

---

## 🔄 Update & Rollout Strategy

### Versioning
```
Version Format: MAJOR.MINOR.PATCH
Example: 1.2.0

# No build number suffix in operator version (unlike SOGo images)
# Build information is embedded in the binary via ldflags:
# - Version
# - Git commit
# - Build date
# - Git branch

Semantic Versioning:
- MAJOR: Breaking API changes, major architectural changes
- MINOR: Backwards-compatible features, improvements
- PATCH: Bug fixes, security patches
```

### Rolling Update
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
minReadySeconds: 30
progressDeadlineSeconds: 600
```

### Update Process
```
1. Build new image: registry.gitlab.opencode.de/umr/dev-agent:v1.2.1
   ↓
2. Pre-flight checks:
   - Verify image signature
   - Scan for vulnerabilities
   - Check CRD compatibility
   - Test in staging environment
   ↓
3. Update Kubernetes manifest:
   - image: registry.gitlab.opencode.de/umr/dev-agent:v1.2.1
   - Verify resource requests/limits
   ↓
4. Apply changes: kubectl apply -f k8s/dev-agent/
   ↓
5. Kubernetes performs rolling update:
   └── Because strategy is Recreate (not RollingUpdate):
       ├── Kill old pod
       ├── Wait for old pod to terminate
       ├── Create new pod with new image
       ├── Wait for new pod to be ready
       └── Update service endpoints
   ↓
6. Post-update verification:
   - Health checks pass
   - Pod is Ready
   - Operator version is correct
   - Controllers are running
   - No errors in logs
   ↓
7. Monitor for 24 hours
```

### Rollback Triggers
- ❌ Liveness probe failures > 5 minutes
- ❌ Readiness probe failures prevent traffic for > 10 minutes
- ❌ Error rate > 1% for > 10 minutes (unlikely for operator)
- ❌ Memory usage > 90% of limit for > 5 minutes
- ❌ CPU usage > 90% of limit for > 5 minutes

### Rollback Process
```bash
# Rollback to previous version
kubectl rollout undo deployment/opendesk-dev-agent -n opendesk

# OR manually patch the deployment
kubectl patch deployment opendesk-dev-agent -n opendesk \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"manager","image":"registry.gitlab.opencode.de/umr/dev-agent:v1.2.0"}]}}}}'
```

---

## 🛡️ Security Compliance

### CIS Kubernetes Benchmark
| Control | Status | Notes |
|---------|--------|-------|
| 5.1.1 Ensure API server pod spec file permissions | ✅ PASS | API server managed by K3s |
| 5.1.2 Ensure API server is running | ✅ PASS | Operates in K3s cluster |
| 5.2.1 Ensure controller manager pod spec file permissions | ⚠️ INFO | Not applicable to operator |
| 5.3.1 Ensure scheduler pod spec file permissions | ⚠️ INFO | Not applicable to operator |
| 5.4.1 Ensure etcd pod spec file permissions | ⚠️ INFO | Not applicable to operator |
| 6.1.1 Restrict use of the root user | ✅ PASS | Runs as UID 1000 |
| 6.1.2 Ensure containers run as non-root | ✅ PASS | Security context configured |
| 6.2.1 Restrict access to the Kubernetes API | ✅ PASS | RBAC properly configured |
| 6.3.1 Restrict access to files on the host | ✅ PASS | No hostPath volumes |

### CIS Docker Benchmark
| Control | Status | Notes |
|---------|--------|-------|
| 1.1 Ensure a minimal number of packages | ✅ PASS | Alpine base with only essential packages |
| 1.2 Ensure minimal base images | ✅ PASS | Alpine 3.18 is minimal |
| 1.3 Use trusted base images | ✅ PASS | Official Alpine image |
| 1.4 Scan images for vulnerabilities | ✅ PASS | Regular scanning in CI/CD |
| 2.1 Run as non-root user | ✅ PASS | UID 1000 |
| 2.2 Use COPY instead of ADD | ✅ PASS | Only COPY used |
| 2.3 Do not install unnecessary packages | ✅ PASS | Minimal dependencies |
| 2.4 Use multi-stage builds | ✅ PASS | Builder + final stages |
| 2.5 Set HEALTHCHECK | ✅ PASS | Configured with timeouts |
| 2.6 Do not store secrets in Dockerfile | ✅ PASS | All via env/mounts |

### OWASP Kubernetes Security
| Risk | Mitigation | Status |
|------|------------|--------|
| Insecure Pod Security Standards | Restrictive security context | ✅ MITIGATED |
| Excessive Permissions | Principle of least privilege RBAC | ✅ MITIGATED |
| Unrestricted Network Access | Network policies recommended | ⚠️ PARTIAL |
| Lack of Resource Constraints | Resource limits specified | ✅ MITIGATED |
| Sensitive Data Exposure | No secrets in image | ✅ MITIGATED |

---

## 📋 Configuration Management

### Configuration Sources (Priority Order)
1. **Command-line flags** - Highest priority
2. **Environment variables** - Override flags
3. **Configuration files** - Default configuration
4. **Operator defaults** - Built-in defaults

### Configuration Hierarchy
```
/etc/opendesk-dev-agent/
├── config.yaml          # Default configuration (loaded by default)
└── custom-config.yaml   # User customizations (optional, can be mounted)
```

### Configuration Validation
The operator validates configuration on startup:

1. **YAML Syntax**: Check for valid YAML
2. **Required Fields**: Check all required fields are present
3. **Field Types**: Check field types match expected types
4. **Field Values**: Check field values are within valid ranges
5. **Resource Names**: Check referenced resources exist
6. **Namespace Access**: Check operator has access to specified namespaces

---

## 📝 Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.2.0 | 2026-08-02 | openDesk Team | Multi-stage Docker build, improved security, better error handling |
| 1.1.0 | 2026-06-01 | openDesk Team | Added PI Memory integration, improved repair actions |
| 1.0.0 | 2026-04-01 | openDesk Team | Initial production release with health and repair controllers |
| 0.9.0 | 2026-02-01 | openDesk Team | Beta release with basic health monitoring |
| 0.1.0 | 2025-12-01 | openDesk Team | Initial development version |

---

## 📞 Support & Troubleshooting

### Common Issues & Solutions

#### Issue: Operator fails to start
**Symptoms**: Container crashes immediately, exit code 1
**Causes**:
- Missing required environment variables
- Invalid RBAC configuration
- Kubernetes API server unreachable
- CRD not installed
- Configuration error
**Solution**:
```bash
# Check logs
kubectl logs -n opendesk deployment/opendesk-dev-agent --tail=100

# Check events
kubectl describe pod -n opendesk -l app=opendesk-dev-agent

# Check RBAC
kubectl get rolebinding,clusterrolebinding -n opendesk | grep dev-agent
kubectl auth can-i --as=system:serviceaccount:opendesk:opendesk-dev-agent get pods -n opendesk

# Check CRDs
kubectl get crd | grep opendesk-dev-agent

# Test locally
docker run --rm -it \
  -e OPERATOR_NAME=test \
  -e OPERATOR_NAMESPACE=default \
  registry.gitlab.opencode.de/umr/dev-agent:latest --debug
```

#### Issue: Operator cannot watch namespaces
**Symptoms**: Logs show permission errors, no components being monitored
**Causes**:
- Missing RBAC permissions
- Service account not correctly configured
- Namespace doesn't exist
**Solution**:
```bash
# Check permissions
kubectl auth