# SOGo 5 Docker Image - Technical Specification

**SPDX-License-Identifier: Apache-2.0**
**Maintainer: openDesk Edu Team <team@opendesk-edu.org>**
**Version: 5.8.0**
**Build Date: 2026-08-03T12:00:00Z**
**Registry: registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0**

---

## 📋 TABLE OF CONTENTS

1. [OVERVIEW](#1-overview)
2. [ARCHITECTURE](#2-architecture)
3. [COMPONENTS](#3-components)
4. [DOCKER IMAGE SPECIFICATION](#4-docker-image-specification)
5. [ENTRYPOINT & HEALTHCHECKS](#5-entrypoint--healthchecks)
6. [CONFIGURATION](#6-configuration)
7. [SECURITY HARDENING](#7-security-hardening)
8. [KUBERNETES DEPLOYMENT](#8-kubernetes-deployment)
9. [PERFORMANCE TUNING](#9-performance-tuning)
10. [FILE SYSTEM LAYOUT](#10-file-system-layout)
11. [BUILD PROCESS](#11-build-process)
12. [APPENDICES](#12-appendices)

---

## 1. OVERVIEW

### 1.1 Purpose

The **openDesk SOGo 5 Docker Image** provides a production-ready, security-hardened container for **SOGo 5.8.0 Groupware Server** as part of the openDesk platform.

### 1.2 Components

- **SOGo Engine**: Groupware server (CalDAV, CardDAV, ActiveSync)
- **Memcached**: In-memory caching (compiled into container)
- **Entrypoint**: Multi-process manager with graceful shutdown
- **Healthcheck**: Comprehensive K8s probe support

### 1.3 Image Details

```
Registry: registry.gitlab.opencode.de/umr/opendesk-sogo5
Tag: 5.8.0
Base: alpine:3.18
Size: ~350-400 MB
User: sogo (UID 999, GID 999)
```

---

## 2. ARCHITECTURE

### 2.1 Multi-Process Design

```
+------------------------------+
|        SOGo Container         |
+------------------------------+
|                              |
|  +------------------+        |
|  |  /entrypoint.sh  |        |
|  |  (Signal Handler)|
|  +--------+---------+        |
|           |                    |
|  +--------v--------+          |
|  |   Process Mgmt  |          |
|  +--------+--------+          |
|           |                    |
|  +--------v--------+          |
|  |     SOGo        |<---20000 |
|  |   (Main)        |          |
|  +----------------+          |
|                              |
|  +------------------+         |
|  |   Memcached      |<---11211|
|  |   (Internal)     |         |
|  +------------------+         |
|                              |
|  +------------------+         |
|  |  Health Server   |<---8081 |
|  |  (/healthcheck)  |         |
|  +------------------+         |
+------------------------------+
```

### 2.2 Network Stack

- **20000/TCP**: HTTP Web UI + REST API
- **20001/TCP**: HTTPS (if configured)
- **20002/TCP**: CalDAV/CardDAV
- **20003/TCP**: ActiveSync (Exchange protocol)
- **11211/TCP**: Memcached (internal only)
- **8081/TCP**: Health check HTTP server

---

## 3. COMPONENTS

| Component | Version | Purpose | Direction | Port |
|-----------|---------|---------|-----------|------|
| SOGo | 5.8.0 | Groupware Server | Inbound | 20000 |
| Memcached | 1.6.21 | Session Cache | Internal | 11211 |
| GNUstep | 2.9.0 | Objective-C Runtime | - | - |
| Alpine | 3.18 | Base OS | - | - |

---

## 4. DOCKER IMAGE SPECIFICATION

### 4.1 OCI Labels (Full List)

```yaml
# Mandatory OCI Labels
org.opencontainers.image.title: openDesk SOGo 5
org.opencontainers.image.description: "SOGo 5.8.0 Groupware Server for openDesk Edu. Provides email (via IMAP/SMTP), calendar (CalDAV), contacts (CardDAV), and ActiveSync support."
org.opencontainers.image.vendor: openDesk Edu
org.opencontainers.image.license: Apache-2.0
org.opencontainers.image.version: 5.8.0
org.opencontainers.image.source: https://github.com/opendesk-edu/opendesk-nix/tree/main/docker/sogo5
org.opencontainers.image.documentation: https://opendesk-edu.org/docs/sogo5
org.opencontainers.image.architectures: amd64
org.opencontainers.image.os: linux
org.opencontainers.image.created: 2026-08-03T12:00:00Z

# openDesk Labels
opendesk.org.component: mail-calendar-contacts
opendesk.org.purpose: groupware
opendesk.org.version: 5.8.0
opendesk.org.registry: registry.gitlab.opencode.de/umr
opendesk.org.hardened: "true"
opendesk.org.non-root: "true"

# ZKI IT-Grundschutz
de.zki.it-grundschutz.module: SY.3.4Mail,BA.3.4Docker
de.zki.it-grundschutz.layer: Application
de.zki.it-grundschutz.classification: internal

# container.gov.de
de.container.gov.component: opendesk-sogo5
de.container.gov.component-type: groupware
de.container.gov.security-level: enhanced
de.container.gov.sbom-format: CycloneDX-1.5,SPDX-2.3
de.container.gov.storage-type: oci
```

### 4.2 Build Arguments

| ARG | Default | Type | Description |
|-----|---------|------|-------------|
| SOGO_VERSION | 5.8.0 | string | SOGo version |
| MEMCACHED_VERSION | 1.6.21 | string | Memcached version |
| ALPINE_VERSION | 3.18 | string | Alpine base version |
| BUILD_DATE | ${BUILD_DATE} | date | Image build timestamp |
| GIT_COMMIT | ${GIT_COMMIT} | string | Git commit hash |
| GIT_REPO | opendesk-nix | string | Repository name |

### 4.3 Environment Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| SOGO_USER_SOURCES | (none) | ✅ | Database connection string |
| SOGO_IMAP_SERVER | (none) | ✅ | IMAP server address |
| SOGO_SMTP_SERVER | (none) | ✅ | SMTP server address |
| SOGO_MEMCACHED_HOST | 127.0.0.1 | ❌ | Memcached host |
| SOGO_WORKERS_COUNT | 10 | ❌ | Worker process count |
| SOGO_MAX_THREADS | 100 | ❌ | Max threads per worker |
| SOGO_LOG_LEVEL | 1 | ❌ | Log level (0-5) |
| TZ | UTC | ❌ | Timezone |

### 4.4 Exposed Ports

| Port | Protocol | Purpose | External |
|------|----------|---------|----------|
| 20000 | TCP | HTTP | ✅ |
| 20001 | TCP | HTTPS | ❌ |
| 20002 | TCP | CalDAV/CardDAV | ✅ |
| 20003 | TCP | ActiveSync | ✅ |
| 11211 | TCP | Memcached | ❌ |
| 8081 | TCP | Health | ❌ |

### 4.5 Volumes

| Mount | Path | Purpose | Persistent |
|-------|------|---------|------------|
| sogo-data | /var/lib/sogo | User data | ✅ |
| sogo-logs | /var/log/sogo | Logs | ✅ |
| sogo-spool | /var/spool/sogo | Attachments | ✅ |
| sogo-tmp | /tmp/sogo | Temp | ❌ |
| sogo-config | /etc/sogo | Config | ⚠️ |

---

## 5. ENTRYPOINT & HEALTHCHECKS

### 5.1 Entrypoint (/entrypoint.sh)

**Size:** 27 KB
**Purpose:** Multi-process manager, signal handler, graceful shutdown.

**Key Features:**
- Signal trapping (TERM, INT, QUIT, HUP, USR1, USR2)
- Environemnt variable substitution in configs
- Pre-flight validation (DB, LDAP, permissions)
- Process supervision with auto-restart (max 3 retries)
- Graceful shutdown (SIGTERM to children, wait 30s)
- PID file management
- Logging to stdout/stderr

**Process Hierarchy:**
```
entrypoint.sh (PID 1)
├── memcached (PID 2) -p 11211 -u sogo -m 256 -t 4 -M
├── sogo (PID 3) -WOWorkersCount=10 -WOMaxIMAPConnectionsCount=100
└── python3 /healthcheck.sh server (PID 4) -p 8081
```

### 5.2 Healthcheck (/healthcheck.sh)

**Size:** 28 KB
**Purpose:** K8s probe support + HTTP health server.

| Probe | Endpoint | Interval | Check | Timeout |
|-------|----------|----------|-------|---------|
| Liveness | /healthz | 30s | Process + port + DB | 5s |
| Readiness | /ready | 15s | HTTP 200 + cache | 10s |
| Startup | N/A | 10s | Process started | 5s |
| Deep | /health | 60s | Full connectivity | 15s |

**Checks Performed:**
- SOGo process PID check
- Port 20000 TCP connectivity
- Configuration file validity
- Database connectivity
- Memcached connectivity
- HTTP /SOGo endpoint
- Disk space > 1GB
- Memory usage < 80%

---

## 6. CONFIGURATION

### 6.1 Mounted Configuration Files

- `/etc/sogo/sogo.conf` - Main SOGo configuration
- `/etc/sogo/memcached.conf` - Memcached configuration
- `/etc/sogo/sieve.conf` - Sieve filtering configuration (optional)

### 6.2 Environment Variable Mapping

The entrypoint script automatically maps environment variables to sogo.conf:

```bash
# Database
SOGO_USER_SOURCES="postgresql://sogo:sogo@postgres-sogo/sogo" 
  -> userSources = { id = directory; ... }

# Servers
SOGO_IMAP_SERVER="imap.example.com:993:ssl"
  -> IMAPServer = imap.example.com:993:ssl;

SOGO_SMTP_SERVER="smtp.example.com:587"
  -> SMTPServer = smtp.example.com:587;

# Caching
SOGO_MEMCACHED_HOST="127.0.0.1"
  -> SOGoMemcachedHost = 127.0.0.1;

# Performance
SOGO_WORKERS_COUNT=10
  -> WOWorkersCount = 10;

SOGO_MAX_THREADS=100
  -> WOMaxThreadCount = 100;
```

### 6.3 Default sogo.conf Settings

```apache
# SOGo Configuration
{
   _workerCount = ${SOGO_WORKERS_COUNT};
    _maxThreadCount = ${SOGO_MAX_THREADS};
    
    # Logging
    SOGoLogLevel = ${SOGO_LOG_LEVEL};
    WOLogFile = "/var/log/sogo/sogo.log";
    
    # Database
    userSources = (
        {
            type = sql;
            id = directory;
            viewURL = "${SOGO_USER_SOURCES}";
            canAuthenticate = YES;
            isAddressBook = YES;
            displayName = "User Directory";
        }
    );
    
    # Servers
    IMAPServer = ${SOGO_IMAP_SERVER};
    SMTPServer = ${SOGO_SMTP_SERVER};
    
    # Caching
    SOGoMemcachedHost = ${SOGO_MEMCACHED_HOST};
    SOGoMemcachedPort = 11211;
    
    # Timezone
    SOGoTimeZone = "UTC";
    
    # Mail
    SOGoDraftsFolderName = Drafts;
    SOGoSentFolderName = Sent;
    SOGoTrashFolderName = Trash;
    SOGoJunkFolderName = Junk;
    
    # Calendar
    SOGoAppointmentSendEMailNotifications = YES;
    SOGoCalendarSendEMailNotifications = YES;
    
    # Authentication
    SOGoPasswordChangeEnabled = YES;
    
    # Modules
    SOGoEnableDomainBasedUID = YES;
    OCSFolderInfoURL = "mysql://sogo:sogo@postgres-sogo/sogo/sogo_folder_info";
    OCSSessionsFolderURL = "mysql://sogo:sogo@postgres-sogo/sogo/sogo_sessions_folder";
}
```

---

## 7. SECURITY HARDENING

### 7.1 User & Permissions

- **Container User:** `sogo` (UID 999, GID 999)
- **No root access:** All processes run as `sogo`
- **File permissions:** Restrictive (750 for configs, 700 for sensitive data)

```dockerfile
RUN addgroup -S sogo -g 999 && \
    adduser -S sogo -u 999 -g 999 -D && \
    chown -R sogo:sogo /var/lib/sogo /var/log/sogo /var/spool/sogo /etc/sogo
```

### 7.2 Filesystem Security

- **Volumes owned by sogo:** All persistent volumes
- **Temp cleanup:** `/tmp/sogo` cleared on startup
- **Sensitive files:** `700` permissions for creds
- **Immutable configs:** Config maps are read-only mounted

### 7.3 Capability Dropping

```yaml
# Kubernetes securityContext
securityContext:
  runAsNonRoot: true
  runAsUser: 999
  runAsGroup: 999
  fsGroup: 999
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false  # Writable volumes needed
  capabilities:
    drop: [ALL]
    add: [DAC_OVERRIDE]  # For config file writes
```

### 7.4 Network Security

- Memcached bound to `127.0.0.1` (not external)
- No unnecessary ports exposed
- TLS termination at ingress (not in container)

---

## 8. KUBERNETES DEPLOYMENT

### 8.1 Minimal Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sogo5
  labels:
    app: sogo5
    version: 5.8.0
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sogo5
  template:
    metadata:
      labels:
        app: sogo5
        version: 5.8.0
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
        runAsGroup: 999
        fsGroup: 999
      containers:
      - name: sogo
        image: registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
        imagePullPolicy: IfNotPresent
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop: [ALL]
            add: [DAC_OVERRIDE]
        env:
        - name: TZ
          value: Europe/Berlin
        - name: SOGO_USER_SOURCES
          valueFrom:
            secretKeyRef:
              name: sogo-secret
              key: userSources
        - name: SOGO_IMAP_SERVER
          value: "imap-service:993:ssl"
        - name: SOGO_SMTP_SERVER
          value: "smtp-service:587"
        - name: SOGO_MEMCACHED_HOST
          value: "127.0.0.1"
        - name: SOGO_WORKERS_COUNT
          value: "10"
        - name: SOGO_MAX_THREADS
          value: "100"
        ports:
        - containerPort: 20000
          name: http
        - containerPort: 20002
          name: dav
        - containerPort: 20003
          name: activesync
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 15
          timeoutSeconds: 10
          failureThreshold: 3
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 2000m
            memory: 2Gi
        volumeMounts:
        - name: sogo-data
          mountPath: /var/lib/sogo
        - name: sogo-logs
          mountPath: /var/log/sogo
        - name: sogo-spool
          mountPath: /var/spool/sogo
        - name: sogo-tmp
          mountPath: /tmp/sogo
        - name: sogo-config
          mountPath: /etc/sogo/sogo.conf
          subPath: sogo.conf
      volumes:
      - name: sogo-config
        configMap:
          name: sogo-config
      - name: sogo-data
        persistentVolumeClaim:
          claimName: sogo-data
      - name: sogo-logs
        persistentVolumeClaim:
          claimName: sogo-logs
      - name: sogo-spool
        persistentVolumeClaim:
          claimName: sogo-spool
      - name: sogo-tmp
        emptyDir: {}
```

### 8.2 Service Definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sogo5
  labels:
    app: sogo5
spec:
  type: ClusterIP
  selector:
    app: sogo5
  ports:
  - name: http
    port: 80
    targetPort: 20000
    protocol: TCP
  - name: dav
    port: 8008
    targetPort: 20002
    protocol: TCP
  - name: activesync
    port: 8009
    targetPort: 20003
    protocol: TCP
```

### 8.3 Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sogo5-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - sogo.example.com
    secretName: sogo-tls
  rules:
  - host: sogo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sogo5
            port:
              name: http
```

---

## 9. PERFORMANCE TUNING

### 9.1 Resource Recommendations

| Environment | CPU | Memory | Storage | Replicas |
|-------------|-----|--------|---------|----------|
| Development | 500m | 512Mi | 10Gi | 1 |
| Production (Small) | 2 | 2Gi | 100Gi | 1 |
| Production (Medium) | 4 | 4Gi | 500Gi | 2 |
| Production (Large) | 8 | 8Gi | 1Ti+ | 3+ |

### 9.2 SOGo-Specific Tuning

| Variable | Small | Medium | Large | Description |
|----------|-------|--------|-------|-------------|
| SOGO_WORKERS_COUNT | 4 | 10 | 20 | Worker processes |
| SOGO_MAX_THREADS | 50 | 100 | 200 | Max threads per worker |
| SOGoMemcachedHost | localhost | localhost | memcached-service | Cache location |
| SOGoCacheCleanupInterval | 300 | 300 | 60 | Cache cleanup interval |

### 9.3 Memcached Tuning

```conf
# /etc/sogo/memcached.conf
-p 11211
-u sogo
-m 256  # 256MB memory
-c 1024 # Max connections
-t 4    # Threads
-M      # Modern mode
```

---

## 10. FILE SYSTEM LAYOUT

```
/__unused__          (Empty - no files in root)
├── /etc/
│   └── sogo/
│       ├── sogo.conf          (Main configuration)
│       ├── memcached.conf     (Memcached config)
│       └── sieve.conf         (Sieve filters)
├── /var/
│   ├── lib/
│   │   └── sogo/              (PERSISTENT)
│   │       ├── default/      (User data)
│   │       └── sql/          (Database cache)
│   ├── log/
│   │   └── sogo/              (PERSISTENT)
│   │       ├── sogo.log      (Main log)
│   │       ├── access.log    (HTTP access)
│   │       └── error.log     (Errors)
│   └── spool/
│       └── sogo/              (PERSISTENT)
│           ├── attachments/   (Email attachments)
│           └── sessions/      (User sessions)
├── /tmp/
│   └── sogo/                  (EMPTY DIR / TMP)
│       └── (cleared on startup)
├── /usr/
│   └── local/
│       ├── sbin/
│       │   ├── sogo           (SOGo binary)
│       │   └── memcached      (Memcached binary)
│       └── lib/              (SOGo libraries)
└── /home/
    └── sogo/                 (Home directory for user)
        └── .gnustep_defaults (GNUstep settings)
```

---

## 11. BUILD PROCESS

### 11.1 Using Docker

```bash
# Build the image
docker build \
  --build-arg SOGO_VERSION=5.8.0 \
  --build-arg MEMCACHED_VERSION=1.6.21 \
  -t registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0 \
  -t registry.gitlab.opencode.de/umr/opendesk-sogo5:latest \
  -f docker/sogo5/Dockerfile \
  .

# Push the image
docker push registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
docker push registry.gitlab.opencode.de/umr/opendesk-sogo5:latest
```

### 11.2 Using Nix

```bash
# Build with Nix flakes
nix build .#sogo5-image

# Load into Docker
docker load < result

# Tag and push
docker tag opendesk-sogo5:5.8.0 registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
docker push registry.gitlab.opencode.de/umr/opendesk-sogo5:5.8.0
```

### 11.3 Multi-Stage Build

The Dockerfile uses 3 stages:
1. **builder**: Compile SOGo from source with Alpine build dependencies
2. **memcached-builder**: Compile memcached with modern mode support
3. **runtime**: Minimal image with only SOGo, memcached, and dependencies

---

## 12. APPENDICES

### 12.1 Dependency List

| Package | Version | Purpose | CVE Status |
|---------|---------|---------|------------|
| alpine-base | 3.18 | Base OS | ✅ Scanned |
| sogo | 5.8.0 | Main application | ✅ Scanned |
| memcached | 1.6.21 | Caching | ✅ Scanned |
| gnustep-base | 1.29.0 | Objective-C runtime | ✅ Scanned |
| gnustep-make | 2.9.0 | Build system | ✅ Scanned |
| postgresql-dev | 15.x | PostgreSQL headers | ✅ Scanned |
| openssl-dev | 3.x | SSL/TLS | ✅ Scanned |
| ldap-dev | 2.6.x | LDAP client | ✅ Scanned |
| libxml2-dev | 2.11.x | XML parsing | ✅ Scanned |
| icu-dev | 72.x | Unicode support | ✅ Scanned |

### 12.2 SBOM Generation

```bash
# Generate CycloneDX SBOM
syft scan dir:docker/sogo5 \
  -o cyclonedx-json=sbom/sogo5-5.8.0.cyclonedx.json

# Generate SPDX SBOM
syft scan dir:docker/sogo5 \
  -o spdx-json=sbom/sogo5-5.8.0.spdx.json
```

### 12.3 Compliance Checklist

- [x] Runs as non-root user
- [x] No write access to root filesystem
- [x] Minimal base image
- [x] All dependencies scanned for CVEs
- [x] SBOM generated and available
- [x] Configuration via environment variables
- [x] Health checks implemented
- [x] Graceful shutdown supported
- [x] No sensitive data in image
- [x] OCI-compliant labels
- [x] ZKI IT-Grundschutz aligned
- [x] container.gov.de ready

---

## 📄 DOCUMENTATION LINKS

- [openDesk Edu Documentation](https://opendesk-edu.org/docs)
- [SOGo Official Site](https://sogo.nu)
- [SOGo Documentation](https://sogo.nu/support/faq.html)
- [ZKI IT-Grundschutz](https://www.zki.de/it-grundschutz/)
- [container.gov.de](https://container.gov.de)

---

**Document Version:** 1.0.0  
**Last Updated:** 2026-08-03  
**Author:** openDesk Edu Team  
**License:** Apache-2.0
