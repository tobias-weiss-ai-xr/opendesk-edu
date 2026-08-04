# Security Hardening Guide for openDesk Nix Infrastructure

## SPDX-License-Identifier: Apache-2.0

**Maintainer:** openDesk Edu Team <team@opendesk-edu.org>  
**Version:** 1.0.0  
**Last Updated:** 2026-08-03  

---

## Table of Contents

1. [Overview](#overview)
2. [Security Principles](#security-principles)
3. [Container Security](#container-security)
4. [Kubernetes Security](#kubernetes-security)
5. [Network Security](#network-security)
6. [Application Security](#application-security)
7. [Monitoring and Logging](#monitoring-and-logging)
8. [Compliance Standards](#compliance-standards)
9. [Security Checklists](#security-checklists)
10. [Automated Security Scanning](#automated-security-scanning)
11. [Incident Response](#incident-response)
12. [References](#references)

---

## Overview

This document provides comprehensive security hardening guidelines for the openDesk Nix infrastructure, including containers, Kubernetes deployments, networks, and applications. All security measures are designed to comply with industry best practices and regulatory requirements.

### Scope

This guide covers:
- Docker container security
- Kubernetes cluster security
- Network security configurations
- Application-level security
- Monitoring and logging security
- Compliance with CIS benchmarks
- Automated security scanning

### Target Audience

- DevOps engineers
- Security analysts
- System administrators
- Compliance officers

---

## Security Principles

### 1. Defense in Depth

Implement multiple layers of security controls:

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│                    Runtime Layer                            │
├─────────────────────────────────────────────────────────────┤
│                    Container Layer                          │
├─────────────────────────────────────────────────────────────┤
│                    Orchestration Layer                      │
├─────────────────────────────────────────────────────────────┤
│                    Network Layer                            │
├─────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                     │
└─────────────────────────────────────────────────────────────┘
```

### 2. Least Privilege

- Run containers as non-root users
- Grant minimum required permissions
- Use read-only filesystems where possible
- Implement fine-grained RBAC

### 3. Zero Trust

- Never trust, always verify
- Continuous authentication and authorization
- Micro-segmentation
- Mutual TLS for service-to-service communication

### 4. Immutable Infrastructure

- Containers are immutable
- No runtime modifications
- Infrastructure as code
- Rebuild instead of patch

### 5. Secure by Default

- Security is not optional
- Secure defaults for all configurations
- Opt-out rather than opt-in for security features

---

## Container Security

### 1. Base Image Security

#### Use Official or Verified Images

```dockerfile
# ✅ GOOD: Use official images
FROM alpine:3.18
FROM debian:12-slim
FROM ubuntu:22.04

# ❌ BAD: Unverified images
FROM some-registry/unknown-image:latest
```

#### Use Minimal Base Images

```dockerfile
# ✅ GOOD: Minimal images
FROM alpine:3.18
FROM distroless/base-debian12

# ❌ BAD: Bloated images
FROM ubuntu:22.04
FROM debian:12
```

#### Image Version Pinning

```dockerfile
# ✅ GOOD: Specific version
FROM alpine:3.18.4
FROM node:18.16.0-alpine

# ❌ BAD: Floating tags
FROM alpine:latest
FROM node:18
```

### 2. Multi-Stage Builds

```dockerfile
# Build stage
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o /app/manager .

# Final stage
FROM alpine:3.18
WORKDIR /app
COPY --from=builder /app/manager /app/manager
USER 1000:1000
EXPOSE 8080
CMD ["/app/manager"]
```

### 3. User and Permissions

#### Run as Non-Root

```dockerfile
# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Switch to non-root user
USER appuser

# Set working directory
WORKDIR /app

# Ensure correct permissions
RUN chown -R appuser:appgroup /app
```

#### File Permissions

```dockerfile
# Set restrictive permissions
RUN chmod 700 /app/secrets && \
    chmod 600 /app/config.yaml && \
    chmod 500 /app/entrypoint.sh
```

### 4. filesystem Security

#### Read-Only Filesystem

```dockerfile
# Run with read-only filesystem
RUN touch /tmp/empty && chmod 777 /tmp/empty

# Docker run with read-only filesystem
# docker run --read-only --tmpfs /tmp --tmpfs /var/run ...
```

In Docker Compose:

```yaml
services:
  app:
    image: myapp
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid
      - /var/run:rw,noexec,nosuid
```

In Kubernetes:

```yaml
securityContext:
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
```

#### Tmpfs Mounts

For temporary directories:

```yaml
# Kubernetes
volumes:
  - name: tmp
    emptyDir: {}

volumeMounts:
  - name: tmp
    mountPath: /tmp
    readOnly: false
```

### 5. Capability Dropping

#### Linux Capabilities

```dockerfile
# Drop all capabilities (Docker default)
# Then add only required ones
```

In Docker:

```bash
# Drop all capabilities
--cap-drop=ALL

# Add specific capabilities
--cap-add=CHOWN --cap-add=SETGID --cap-add=SETUID
--cap-add=NET_BIND_SERVICE
```

In Kubernetes:

```yaml
securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - CHOWN
      - SETGID
      - SETUID
      - NET_BIND_SERVICE
```

#### Common Required Capabilities

| Capability | Purpose | Required By |
|------------|---------|-------------|
| `NET_BIND_SERVICE` | Bind to privileged ports (<1024) | Web servers |
| `CHOWN` | Change file ownership | Many applications |
| `SETGID` | Set group ID | Many applications |
| `SETUID` | Set user ID | Many applications |
| `DAC_OVERRIDE` | Override file permissions | Containers writing to host volumes |
| `SYS_PTRACE` | Debugging | Development only |

### 6. Seccomp Profiles

#### Use Custom Seccomp Profiles

```yaml
# Kubernetes
securityContext:
  seccompProfile:
    type: RuntimeDefault
    # or use custom profile
    type: Local
    localProfile:
      path: /var/lib/kubelet/seccomp/profiles/app.json
```

#### Sample Seccomp Profile (app.json)

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": ["accept", "accept4", "access", "bind", "chmod", "clock_gettime"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["execve"],
      "action": "SCMP_ACT_ALLOW",
      "args": [
        {
          "index": 0,
          "value": "/app/entrypoint.sh",
          "op": "SCMP_CMP_EQ"
        }
      ]
    }
  ]
}
```

### 7. AppArmor and SELinux

#### AppArmor Profiles

```bash
# Check if AppArmor is enabled
cat /proc/sys/kernel/security/lsm

# Load AppArmor profiles for Docker
aa-status
aa-complain /etc/apparmor.d/docker
```

In Docker:

```yaml
# Docker Compose
services:
  app:
    image: myapp
    security_opt:
      - apparmor=no_new_privs
      - apparmor=docker-default
```

In Kubernetes:

```yaml
securityContext:
  appArmorProfile:
    type: RuntimeDefault
    # or custom
    type: Local
    localProfile: docker/default
```

### 8. Image Security Scanning

#### Use Trivy for Vulnerability Scanning

```yaml
# .github/workflows/security-scan.yml
name: Security Scan
on: [push, pull_request]

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: docker build -t myapp:latest .
      
      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:latest'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
      
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

#### Use Grype for SBOM-based Scanning

```bash
# Install grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Scan image
grype myapp:latest -o json > vulnerabilities.json

# Scan with SBOM
grype dir:/path/to/project -o json
```

### 9. Image Signing and Verification

#### Sign Images with Cosign

```bash
# Install cosign
curl -LO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
sudo install -m 755 cosign-linux-amd64 /usr/local/bin/cosign

# Generate key pair
cosign generate-key-pair

# Sign image
cosign sign --key cosign.key myapp:latest

# Verify signature
cosign verify --key cosign.pub myapp:latest
```

#### Use Docker Content Trust

```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Sign images
docker trust sign myrepo/myapp:latest

# Verify images before pull
docker pull myrepo/myapp:latest
```

### 10. Secrets Management

#### Never Store Secrets in Images

```dockerfile
# ❌ BAD: Secrets in Dockerfile
ENV DB_PASSWORD=mysecretpassword
COPY config-with-secrets.yaml /app/config.yaml

# ✅ GOOD: Use secrets from external sources
# - Environment variables (injected at runtime)
# - Kubernetes Secrets
# - HashiCorp Vault
# - AWS Secrets Manager
```

#### Use BuildKit Secret Mounting

```dockerfile
# syntax=docker/dockerfile:1.4

FROM alpine

# Mount secret during build
RUN --mount=type=secret,id=mysecret,target=/tmp/secret \
    cat /tmp/secret && \
    rm /tmp/secret
```

Build with secrets:

```bash
docker build --secret id=mysecret,src=/path/to/secret -t myapp .
```

### 11. Health Checks and Readiness Probes

#### Docker Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1
```

#### Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 1
  successThreshold: 1

startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 30
  successThreshold: 1
```

---

## Kubernetes Security

### 1. Cluster Configuration

#### Enable RBAC

```bash
# Check if RBAC is enabled
kubectl api-versions | grep rbac.authorization.k8s.io

# Enable RBAC in kube-apiserver
# --enable-admission-plugins=NodeRestriction,RBAC
```

#### Enable Audit Logging

```yaml
# kube-apiserver audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods", "services", "nodes"]
  
- level: Request
  resources:
  - group: ""
    resources: ["pods/log", "pods/exec"]
  
- level: None
  resources:
  - group: ""
    resources: ["endpoints", "events"]
```

Command line arguments:

```
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
--audit-log-path=/var/log/kubernetes/audit.log
--audit-log-maxage=30
--audit-log-maxbackup=10
--audit-log-maxsize=100
```

### 2. Pod Security

#### Pod Security Standards (PSS)

Kubernetes Pod Security Admission (PSA) enforces three levels:

1. **Privileged**: Unrestricted policy
2. **Baseline**: Minimally restrictive policy
3. **Restricted**: Heavily restricted policy

```yaml
# Enable Pod Security Admission
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

#### Pod Security Context

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
    supplementalGroups: []
    sysctls:
      - name: kernel.dmesg_restricted
        value: "1"
  
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
        add:
          - NET_BIND_SERVICE
    volumeMounts:
    - name: tmp
      mountPath: /tmp
      readOnly: false
  
  volumes:
  - name: tmp
    emptyDir: {}
```

### 3. Network Policies

#### Default Deny All

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: my-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

#### Allow Internal Communication

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-internal
  namespace: my-namespace
spec:
  podSelector: {}
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
```

#### Allow DNS Lookups

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: my-namespace
spec:
  podSelector: {}
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

#### Application-Specific Policies

```yaml
# Allow SOGo to access MariaDB
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-sogo-to-mariadb
  namespace: opendesk
spec:
  podSelector:
    matchLabels:
      app: sogo5
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: mariadb
    ports:
    - protocol: TCP
      port: 3306
```

### 4. Role-Based Access Control (RBAC)

#### Principle of Least Privilege

```yaml
# Role with minimum permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: my-namespace
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: my-namespace
subjects:
- kind: User
  name: "alice@example.com"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

#### Service Accounts

```yaml
# Service Account with limited permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-agent-sa
  namespace: opendesk

# Role for Dev Agent
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dev-agent-role
  namespace: opendesk
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "statefulsets", "replicasets", "jobs"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-agent-binding
  namespace: opendesk
subjects:
- kind: ServiceAccount
  name: dev-agent-sa
  namespace: opendesk
roleRef:
  kind: Role
  name: dev-agent-role
  apiGroup: rbac.authorization.k8s.io
```

#### Cluster-Wide Roles

```yaml
# ClusterRole for monitoring
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
  verbs: ["get", "list", "watch"]

# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-monitoring
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: monitoring-reader
  apiGroup: rbac.authorization.k8s.io
```

### 5. API Server Security

#### Rate Limiting

```
--enable-admission-plugins=NodeRestriction,LimitRanger
--max-requests-inflight=1500
--max-mutating-requests-inflight=500
--request-timeout=1m
--watch-cache-sizes=100#1000
```

#### Enable Encryption at Rest

```bash
# Generate encryption key
openssl genrsa -out kubernetes-key.pem 2048

# Create encryption configuration
cat > /etc/kubernetes/enc/enc.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: $(base64 -w0 kubernetes-key.pem)
      - identity: {}
EOF

# Pass to kube-apiserver
--encryption-provider-config-file=/etc/kubernetes/enc/enc.yaml
```

### 6. Etcd Security

#### Enable TLS for Etcd

```bash
# Generate certificates
openssl genrsa -out etcd-key.pem 2048
openssl req -new -key etcd-key.pem -out etcd-csr.pem -subj "/CN=etcd"
openssl x509 -req -in etcd-csr.pem -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd-cert.pem -days 365

# Pass to etcd
--cert-file=/etc/kubernetes/pki/etcd/etcd-cert.pem
--key-file=/etc/kubernetes/pki/etcd/etcd-key.pem
--client-cert-auth=true
--trusted-ca-file=/etc/kubernetes/pki/ca.crt
```

#### Enable Automatic Compaction

```
--auto-compaction-retention=1h
--auto-compaction-mode=periodic
```

### 7. Kubelet Security

#### Enable TLS Bootstrapping

```yaml
# kubelet configuration
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: 0.0.0.0
port: 10250
readOnlyPort: 10255
tlsCertFile: /var/lib/kubelet/pki/kubelet.crt
tlsPrivateKeyFile: /var/lib/kubelet/pki/kubelet.key
tlsCipherSuites: 
  - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
  - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
  - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
  - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
  - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
  - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
    cacheTTL: 2m
  x509:
    clientCAFile: /var/lib/kubelet/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheTTL: 2m

# Enable rotation of kubelet certificates
rotateCertificates: true
 serverTLSBootstrap: true
```

### 8. Control Plane Security

#### Secure Control Plane Endpoints

```bash
# Only allow control plane to listen on internal IP
--advertise-address=<INTERNAL_IP>
--bind-address=<INTERNAL_IP>

# Enable authentication and authorization
--authorization-mode=Node,RBAC
--enable-bootstrap-token-auth=true
```

#### Network Hardening

```bash
# Restrict access to control plane ports
ufw allow from <TRUSTED_SUBNET> to any port 6443 proto tcp
ufw allow from <TRUSTED_SUBNET> to any port 2379:2380 proto tcp
ufw allow from <TRUSTED_SUBNET> to any port 10250:10252 proto tcp
ufw allow from <TRUSTED_SUBNET> to any port 10255 proto tcp
```

### 9. CIS Kubernetes Benchmark

#### CIS Controls Implementation

| Control ID | Description | Implementation |
|------------|-------------|----------------|
| 1.1 | Ensure API server pod spec file permissions are set to 600 or more restrictive | `chmod 600 /etc/kubernetes/manifests/kube-apiserver.yaml` |
| 1.2 | Ensure API server pod spec file ownership is set to root:root | `chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml` |
| 1.3 | Ensure the etcd data directory permissions are set to 700 or more restrictive | `chmod 700 /var/lib/etcd` |
| 1.4 | Ensure the etcd data directory ownership is set to etcd:etcd | `chown etcd:etcd /var/lib/etcd` |
| 2.1 | Ensure that the --anonymous-auth argument is set to false | `--anonymous-auth=false` |
| 2.2 | Ensure that the --basic-auth-file argument is not set | Remove `--basic-auth-file` |
| 3.1 | Ensure that the --kubelet-https argument is set to true | `--kubelet-https=true` |
| 4.1 | Ensure that the --authorization-mode argument includes Node | `--authorization-mode=Node,RBAC` |
| 5.1 | Ensure that the --admission-control argument includes PodSecurityAdmission | `--enable-admission-plugins=NodeRestriction,PodSecurityAdmission` |

#### Run CIS Benchmark Tests

```bash
# Install kube-bench
curl -L https://github.com/aquasecurity/kube-bench/releases/download/v0.6.8/kube-bench_0.6.8_linux_amd64.tar.gz | tar -xz

# Run tests
./kube-bench --benchmark cis-1.8 --targets node,master

# Generate report
./kube-bench --benchmark cis-1.8 --targets node,master --json > cis-report.json
```

---

## Network Security

### 1. Network Segmentation

#### Micro-Segmentation Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                              Firewall                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────┐    ┌───────────────┐    ┌──────────────────┐  │
│  │  Ingress      │    │  Egress       │    │  Internal Load   │  │
│  │  Controller   │    │  Gateway      │    │  Balancer        │  │
│  └───────┬───────┘    └───────┬───────┘    └─────────┬─────────┘  │
│          │                    │                         │            │
│          ▼                    ▼                         ▼            │
│  ┌───────────────────────────────────────────────────────┐        │
│  │                      K3s Cluster                        │        │
│  │                                 ┌─────────────────┐    │
│  │  ┌──────────┐  ┌──────────┐    │┌─────────────┐ │    │
│  │  │   app1   │  │   app2   │    ││  Database   │ │    │
│  │  │ Namespace │  │ Namespace │    ││   Namespace  │ │    │
│  │  └────┬─────┘  └────┬─────┘    │└──────┬──────┘ │    │
│  │       │            │           │       │        │    │
│  │  ┌────▼─────┐  ┌──▼────┐    ┌──▼──────▼──────┐ │    │
│  │  │ Pods     │  │ Pods   │    ││  Pods        │ │    │
│  │  └──────────┘  └──────┘    │└─────────────┘ │    │
│  │                                  │                │    │
│  └──────────────────────────────────┼────────────────┘    │
│                                   Network Policies                     │
└─────────────────────────────────────┴────────────────────────────────┘
```

### 2. Ingress Security

#### Use Network Policies with Ingress

```yaml
# Ingress Controller Network Policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-allow-external
  namespace: ingress-nginx
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ingnress-nginx
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
```

#### Rate Limiting

```yaml
# Ingress with rate limiting
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: my-namespace
  annotations:
    nginx.ingress.kubernetes.io/limit-rpm: "100"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "10"
    nginx.ingress.kubernetes.io/limit-whitelist: "1.2.3.4/32"
    nginx.ingress.kubernetes.io/limit-key: "${binary_remote_addr}"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-buffering: "enabled"
    nginx.ingress.kubernetes.io/proxy-buffer-size: "16k"
    nginx.ingress.kubernetes.io/proxy-buffers-number: "4"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.yaml
    secretName: app-tls
  rules:
  - host: app.yaml
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 8080
```

### 3. TLS/SSL Configuration

#### Use Cert-Manager for TLS

```yaml
# ClusterIssuer for Let's Encrypt
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@opendesk-edu.org
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

#### Strong TLS Configuration

```yaml
# Ingress TLS configuration
annotations:
  nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
  nginx.ingress.kubernetes.io/ssl-ciphers: "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
  nginx.ingress.kubernetes.io/ssl-prefer-server-ciphers: "true"
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
  nginx.ingress.kubernetes.io/proxy-ssl-verify-depth: "2"
  nginx.ingress.kubernetes.io/proxy-ssl-server-name: "on"
  nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
```

### 4. Private Registry Security

#### Zot Registry Security

```yaml
# Zot Registry configuration with authentication
# docker/zot-registry/config.yml
{
  "extensions": {
    "search": {
      "enable": true
    },
    "notification": {
      "enable": true,
      "endpoints": [
        {
          "name": "slack",
          "url": "https://hooks.slack.com/services/...",
          "priority": 1
        }
      ]
    }
  },
  "storage": {
    "rootDirectory": "/var/lib/registry",
    "gc": {
      "delay": "24h",
      "deleteUntagged": true
    },
    "dedupe": {
      "enabled": true
    }
  },
  "http": {
    "address": "0.0.0.0",
    "port": "8080",
    "tls": {
      "cert": "/etc/registry/tls/cert.pem",
      "key": "/etc/registry/tls/key.pem"
    },
    "auth": {
      "htpasswd": {
        "path": "/etc/registry/auth/htpasswd"
      },
      "allowReadsWithoutAuth": false
    },
    "realm": "zot",
    "headers": {
      "X-Content-Type-Options": ["nosniff"],
      "X-Frame-Options": ["DENY"],
      "X-XSS-Protection": ["1; mode=block"]
    }
  },
  "log": {
    "level": "info",
    "output": "stdout",
    "json": true
  }
}
```

Create htpasswd file:

```bash
# Create htpasswd file for basic auth
htpasswd -c /etc/registry/auth/htpasswd admin
htpasswd /etc/registry/auth/htpasswd user1
htpasswd /etc/registry/auth/htpasswd user2
```

### 5. Firewall Configuration

#### UFW Configuration

```bash
# Enable UFW
sudo ufw enable

# Allow SSH (adjust port as needed)
sudo ufw allow 22/tcp

# Allow Kubernetes API
sudo ufw allow from <TRUSTED_SUBNET> to any port 6443 proto tcp

# Allow incoming traffic to services
sudo ufw allow from any to any port 80 proto tcp
sudo ufw allow from any to any port 443 proto tcp

# Allow internal cluster communication
sudo ufw allow from <CLUSTER_SUBNET> to any proto tcp
sudo ufw allow from <CLUSTER_SUBNET> to any proto udp

# Deny everything else by default
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

#### IPTables Rules

```bash
# Flush all rules
iptables -F
iptables -X
iptables -Z

# Set default policies
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow Kubernetes API
iptables -A INPUT -p tcp --dport 6443 -s <TRUSTED_SUBNET> -j ACCEPT

# Allow internal cluster traffic
iptables -A INPUT -s <CLUSTER_SUBNET> -j ACCEPT

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "[DROPPED] " --log-level 4

# Save rules
iptables-save > /etc/iptables/rules.v4
```

---

## Application Security

### 1. OWASP Top 10 Prevention

#### A01:2021 - Broken Access Control

```yaml
# Kubernetes NetworkPolicy for access control
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-namespace-access
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    namespaceSelector:
      matchLabels:
        access: allowed
```

#### A02:2021 - Cryptographic Failures

```yaml
# Use Cert-Manager for automatic TLS
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-certificate
  namespace: my-namespace
spec:
  secretName: app-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: "app.example.com"
  dnsNames:
  - "app.example.com"
  - "www.app.example.com"
  duration: 2160h
  renewBefore: 720h
  privateKey:
    rotationPolicy: Always
    algorithm: RSA
    size: 2048
    encoding: PKCS8
```

#### A03:2021 - Injection

```yaml
# Database configuration with parameterized queries
# This is application-level, but can be enforced through
# the use of ORMs and prepared statements

# Example for MariaDB in Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DB_HOST
          value: "mariadb"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: DB_NAME
          value: "app_db"
        # Ensure application uses prepared statements
        command: ["/app/start.sh"]
        args: ["--use-prepared-statements=true"]
```

### 2. Secrets Management

#### Use Kubernetes Secrets

```yaml
# Create encrypted secret
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password='S3cr3tP@ssw0rd!'

# Or from files
kubectl create secret generic app-secrets \
  --from-file=./username.txt \
  --from-file=./password.txt

# Use secrets in deployments
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        volumeMounts:
        - name: app-secrets
          mountPath: /secrets
          readOnly: true
      volumes:
      - name: app-secrets
        secret:
          secretName: app-secrets
          defaultMode: 0400
```

#### Use External Secrets Operator

```yaml
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets

# Create ExternalSecret for AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: my-namespace
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: aws-secret-store
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: /prod/db/username
  - secretKey: password
    remoteRef:
      key: /prod/db/password

# Create SecretStore
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secret-store
  namespace: my-namespace
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-central-1
      auth:
        secretRef:
          accessKeyID:
            name: aws-credentials
            key: access-key
          secretAccessKey:
            name: aws-credentials
            key: secret-access-key
```

#### Use HashiCorp Vault

```yaml
# Install Vault Agent Injector
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --set "injector.enabled=true"

# Deploy application with Vault annotation
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "my-app"
        vault.hashicorp.com/agent-inject-secret-db-password: "secret/data/myapp/db"
        vault.hashicorp.com/agent-inject-template-db-password: "|
          {{- with secret \"secret/data/myapp/db\" -}}
          {{ .Data.data.password }}
          {{- end -}}
        "
    spec:
      serviceAccountName: my-app
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-password
              key: db-password
```

### 3. API Security

#### API Gateway Configuration

```yaml
# API Gateway with authentication
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: gateway
        image: kong:3.4
        ports:
        - containerPort: 8000
          name: http
        - containerPort: 8443
          name: https
        env:
        - name: KONG_DATABASE
          value: "postgres"
        - name: KONG_PG_HOST
          value: "postgres"
        - name: KONG_PG_USER
          valueFrom:
            secretKeyRef:
              name: kong-db-credentials
              key: username
        - name: KONG_PG_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kong-db-credentials
              key: password
        - name: KONG_PROXY_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_ADMIN_ACCESS_LOG
          value: "/dev/stdout"
        - name: KONG_PROXY_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_ADMIN_ERROR_LOG
          value: "/dev/stderr"
        - name: KONG_LOG_LEVEL
          value: "info"
        - name: KONG_PLUGINS
          value: "bundled,oidc"
        - name: KONG jižN_mem_cache_size
          value: "128m"
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          capabilities:
            drop:
              - ALL
            add:
              - NET_BIND_SERVICE
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
```

#### Rate Limiting and Quotas

```yaml
# Kong Plugin for rate limiting
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: rate-limiting
  namespace: api
plugin: rate-limiting
config:
  minute: 100
  hour: 1000
  day: 10000
  month: 100000
  year: 1000000
  limit_by: header
  header_name: X-API-Key
  policy: local
  redis_database: 0
  redis_host: redis
```

### 4. Web Application Firewall (WAF)

#### ModSecurity Configuration

```apache
# Apache ModSecurity configuration
SecRuleEngine On
SecRuleUpdateTargetById 941180 "!REQUEST_HEADERS:User-Agent"

# OWASP Core Rule Set (CRS)
Include /etc/modsecurity/crs/crs-setup.conf
Include /etc/modsecurity/crs/rules/*.conf

# Custom rules
SecRule REQUEST_FILENAME|ARGS_NAMES|ARGS|XML:/* "@detectSQLi" \
    "id:1000,phase:2,deny,status:406,msg:'SQL Injection Detected',logdata:'Matched Data: {TX.0}'"

SecRule REQUEST_FILENAME|ARGS_NAMES|ARGS|XML:/* "@detectXSS" \
    "id:1001,phase:2,deny,status:406,msg:'XSS Detected',logdata:'Matched Data: {TX.0}'"

# Block common attack patterns
SecRule REQUEST_HEADERS:User-Agent "nikto" "id:1002,deny,status:403,msg:'Nikto Scanner Detected'"
SecRule REQUEST_HEADERS:User-Agent "sqlmap" "id:1003,deny,status:403,msg:'SQLMap Scanner Detected'"
SecRule REQUEST_HEADERS:User-Agent "dirbuster" "id:1004,deny,status:403,msg:'DirBuster Scanner Detected'"
```

---

## Monitoring and Logging

### 1. Centralized Logging

#### EFK Stack (Elasticsearch, Fluentd, Kibana)

```yaml
# Fluentd configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: logging
  labels:
    k8s-app: fluentd-logging
    version: v1
    kubernetes.io/cluster-service: "true"
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      read_from_head true
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
        json_time_key time
        json_time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    
    # Detect exceptions in the log output and forward them as one log entry.
    <match kubernetes.**>
      @type detect_exceptions
      remove_tag_prefix kubernetes.var.log.containers
      message log
      stream stream
      multiline_flush_interval 5
      max_lines 1000
      max_bytes 1000000
    </match>
    
    <filter kubernetes.**>
      @type kubernetes_metadata
      skip_labels false
      skip_container_metadata false
      skip_master_url false
      skip_namespace_metadata false
    </filter>
    
    <match kubernetes.**>
      @type elasticsearch
      host elasticsearch
      port 9200
      logstash_format true
      logstash_prefix kubernetes
      include_tag_key true
      type_name kubernetes
      <buffer>
        @type file
        path /var/log/fluentd-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever true
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>
```

### 2. Container Logging

#### Log Rotation

```yaml
# Sidecar container for log rotation
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
      - name: log-rotator
        image: alpine:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            find /var/log/app -name "*.log" -size +10M -exec gzip {} \;
            find /var/log/app -name "*.log.*" -mtime +30 -delete
            sleep 3600
          done
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
      volumes:
      - name: logs
        emptyDir: {}
```

#### Application-Level Logging

```json
# Sample log format (JSON)
{
  "timestamp": "2026-08-03T12:34:56.789Z",
  "level": "INFO",
  "logger": "com.opendesk.app",
  "service": "sogo5",
  "request_id": "abc123",
  "user_id": "user456",
  "ip_address": "192.168.1.100",
  "method": "GET",
  "url": "/api/health",
  "status": 200,
  "duration_ms": 12,
  "message": "Health check passed"
}
```

### 3. Security Event Logging

#### Audit Logging

```yaml
# Kubernetes audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods", "deployments", "services"]
  - group: "apps"
    resources: ["deployments", "statefulsets"]
  - group: "rbac.authorization.k8s.io"
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  
- level: Request
  resources:
  - group: ""
    resources: ["pods/log", "pods/exec", "pods/attach"]
  
- level: None
  resources:
  - group: ""
    resources: ["endpoints", "events"]
  namespaces: ["kube-system", "kube-public"]
```

### 4. Alerting

#### Security Alerts in Prometheus

```yaml
# security-alerts.rules.yml
groups:
- name: security.alerts
  interval: 30s
  
  rules:
  # Failed login attempts
  - alert: FailedLoginAttempts
    expr: rate(container_logs{log="Failed login"}[5m]) > 0
    labels:
      severity: warning
      category: security
    annotations:
      summary: "Failed login attempts detected"
      description: "{{ printf \"%.0f\" $value }} failed login attempts in the last 5 minutes"
      action: "Investigate authentication logs"
  
  # Container running as root
  - alert: ContainerRunningAsRoot
    expr: kube_pod_container_security_context_run_as_user == 0
    labels:
      severity: critical
      category: security
    annotations:
      summary: "Container running as root"
      description: "Container {{ $labels.container }} in pod {{ $labels.pod }} is running as root"
      action: "Reconfigure container to run as non-root user"
  
  # Privileged containers
  - alert: PrivilegedContainer
    expr: kube_pod_container_security_context_privileged == true
    labels:
      severity: critical
      category: security
    annotations:
      summary: "Privileged container running"
      description: "Container {{ $labels.container }} in pod {{ $labels.pod }} is running in privileged mode"
      action: "Remove privileged flag from container"
  
  # Containers with ALL capabilities
  - alert: ContainerAllCapabilities
    expr: kube_pod_container_security_context_capabilities_add{capability="ALL"} == true
    labels:
      severity: critical
      category: security
    annotations:
      summary: "Container with ALL capabilities"
      description: "Container {{ $labels.container }} has ALL capabilities"
      action: "Drop ALL capabilities and add only required ones"
  
  # Open network policies
  - alert: OpenNetworkPolicy
    expr: kube_networkpolicy_ingress_count == 0
    labels:
      severity: warning
      category: security
    annotations:
      summary: "Namespace with no network policies"
      description: "Namespace {{ $labels.namespace }} has no ingress network policies"
      action: "Define network policies for the namespace"
  
  # Unauthorized API access
  - alert: UnauthorizedAPIAccess
    expr: rate(kube_apiserver_request_total{code=~"401|403"}[5m]) > 0
    labels:
      severity: warning
      category: security
    annotations:
      summary: "Unauthorized API access attempts"
      description: "{{ printf \"%.0f\" $value }} unauthorized API access attempts in the last 5 minutes"
      action: "Investigate API access logs"
  
  # Suspicious process execution
  - alert: SuspiciousProcessExecution
    expr: container_processes{process=~"bash|sh|nc|netcat|wget|curl.*\-o"} > 0
    labels:
      severity: critical
      category: security
    annotations:
      summary: "Suspicious process detected in container"
      description: "Process {{ $labels.process }} running in container {{ $labels.container }}"
      action: "Investigate container immediately"
```

---

## Compliance Standards

### 1. ISO 27001

#### Information Security Management System (ISMS)

| Control | Description | Implementation |
|---------|-------------|----------------|
| A.5.1 | Information security policies | Documented in this guide |
| A.5.2 | Information security roles and responsibilities | RBAC configurations |
| A.6.1 | Information security objectives | Security KPIs and metrics |
| A.8.2 | Privacy and protection of PII | Encryption in transit and at rest |
| A.9.1 | Access to networks and network services | Network policies and firewall rules |
| A.9.2 | User access management | Kubernetes RBAC and authentication |
| A.9.4 | System and application access control |Container and application authentication |
| A.10.1 | Policy on use of cryptographic controls | TLS and encryption standards |
| A.12.1 | Operational procedures and responsibilities | Automated CI/CD pipelines |
| A.12.2 | Protection from malware | Container image scanning |
| A.12.4 | Logging and monitoring | Centralized logging and monitoring |
| A.12.5 | Control of operational software | Image version pinning and signing |
| A.12.6 | Technical vulnerability management | Automated security scanning |
| A.13.1 | Network security controls | Network policies and segmentation |
| A.14.1 | Security requirements analysis and specification | Threat modeling and risk assessment |
| A.14.2 | Security in development and support processes | Secure SDLC practices |

### 2. NIST SP 800-53

#### Security Controls Mapping

| Control | Description | Implementation |
|---------|-------------|----------------|
| AC-1 | Policy and Procedures | Security policies and procedures |
| AC-2 | Account Management | Kubernetes RBAC |
| AC-3 | Access Enforcement | Network policies and service mesh |
| AC-6 | Least Privilege | RBAC and capability dropping |
| AC-17 | Remote Access | VPN and zero-trust access |
| AT-1 | Security Awareness and Training | Security training programs |
| AU-1 | Audit and Accountability Policy | Audit logging configuration |
| AU-2 | Audit Events | Comprehensive audit logging |
| AU-3 | Content of Audit Records | Structured log formats |
| AU-9 | Protection of Audit Information | Log encryption and integrity |
| CA-2 | Security Assessments | Vulnerability scanning and penetration testing |
| CM-2 | Baseline Configuration | Standardized container images and configurations |
| CM-3 | Configuration Change Control | GitOps and CI/CD pipelines |
| CM-5 | Access Restrictions for Change | RBAC for configuration changes |
| CM-6 | Configuration Settings | Automated configuration management |
| CP-2 | Contingency Plan | Disaster recovery procedures |
| CP-9 | Information System Backup | Automated backup procedures |
| IA-2 | Identification and Authentication | TLS client certificates and OAuth |
| PL-4 | Rules of Behavior | Security policies and guidelines |
| PS-3 | personnel Screening | Background checks and access reviews |
| RA-1 | Risk Assessment Policy | Risk assessment procedures |
| RA-2 | Security Categorization | Data classification and handling |
| RA-3 | Risk Assessment | Regular risk assessments |
| SC-7 | Boundary Protection | Network segmentation and firewall rules |
| SC-12 | Cryptographic Key Establishment | TLS and certificate management |
| SC-13 | Cryptographic Protection | Encryption in transit and at rest |
| SI-1 | System and Information Integrity Policy | Security policies |
| SI-2 | Flaw Remediation | Patch management procedures |
| SI-3 | Malicious Code Protection | Container image scanning |
| SI-4 | System Monitoring | Centralized monitoring and alerting |
| SI-7 | Software, Firmware, and Information Integrity | Image signing and verification |

### 3. CIS Controls

#### Center for Internet Security Controls

| Control | Description | Implementation |
|---------|-------------|----------------|
| 1 | Inventory and Control of Hardware Assets | Automated asset discovery |
| 2 | Inventory and Control of Software Assets | Container image registry and SBOM |
| 3 | Continuous Vulnerability Management | Automated vulnerability scanning |
| 4 | Secure Configuration of Assets | CIS benchmark compliance |
| 5 | Account Management | RBAC and access controls |
| 6 | Access Control Management | Network policies and service mesh |
| 7 | Continuous Monitoring | Centralized monitoring and logging |
| 8 | Audit Log Management | Comprehensive audit logging |
| 9 | Email and Web Protections | WAF and email filtering |
| 10 | Malware Defenses | Container image scanning |
| 11 | Data Recovery | Automated backup procedures |
| 12 | Network Infrastructure Management | Network segmentation and firewall rules |
| 13 | Network Monitoring and Defense | Network monitoring and intrusion detection |
| 14 | Security Awareness and Skills Training | Security training programs |
| 15 | Service Provider Management | Vendor risk management |
| 16 | Application Software Security | Secure SDLC and code reviews |
| 17 | Incident Response Management | Incident response procedures |
| 18 | Penetration Testing | Regular penetration testing |

### 4. SOC 2 Type II

#### Trust Services Criteria

| Principle | Description | Implementation |
|-----------|-------------|----------------|
| Security | Protection against unauthorized access | Authentication, authorization, encryption |
| Availability | System availability | High availability configuration, backups |
| Processing Integrity | System processing is complete and accurate | Validated applications, error handling |
| Confidentiality | Information is protected | Access controls, encryption |
| Privacy | Personal information is protected | Data classification, PII handling |

### 5. GDPR

#### General Data Protection Regulation

| Requirement | Description | Implementation |
|-------------|-------------|----------------|
| Article 5 | Principles relating to processing of personal data | Data protection by design and default |
| Article 6 | Lawfulness of processing | Consent and legitimate interest management |
| Article 9 | Special categories of personal data | Enhanced protection for sensitive data |
| Article 15 | Right of access by the data subject | Data subject access request procedures |
| Article 16 | Right to rectification | Data correction procedures |
| Article 17 | Right to erasure | Data deletion procedures |
| Article 18 | Right to restriction of processing | Data processing restriction procedures |
| Article 20 | Right to data portability | Data export procedures |
| Article 25 | Data protection by design and by default | secure architecture and default configurations |
| Article 28 | Processor | Vendor security assessments |
| Article 32 | Security of processing | Encryption, access controls, monitoring |
| Article 33 | Notification of a personal data breach | Breach notification procedures |
| Article 34 | Communication of a personal data breach | Breach communication procedures |
| Article 35 | Data protection impact assessment | DPIA procedures |

### 6. PCI DSS

#### Payment Card Industry Data Security Standard

| Requirement | Description | Implementation |
|-------------|-------------|----------------|
| 1 | Install and maintain a firewall | Network segmentation and firewall rules |
| 2 | Do not use vendor-supplied defaults | Hardened configurations |
| 3 | Protect stored cardholder data | Encryption at rest |
| 4 | Encrypt transmission of cardholder data | TLS for all connections |
| 5 | Protect all systems against malware | Container image scanning |
| 6 | Develop and maintain secure systems | Secure SDLC and patch management |
| 7 | Restrict access to cardholder data | RBAC and access controls |
| 8 | Identify and authenticate access | Strong authentication |
| 9 | Restrict physical access | Physical security controls |
| 10 | Track and monitor all access | Centralized logging and monitoring |
| 11 | Regularly test security systems | Vulnerability scanning and penetration testing |
| 12 | Maintain a policy that addresses information security | Security policies and procedures |

### 7. BSI C5

#### Cloud Computing Compliance Criteria Catalogue

The BSI C5 attestation is specifically designed for cloud services and is highly relevant for the openDesk infrastructure.

| Control | Description | Implementation |
|---------|-------------|----------------|
| C5-01 | Information Collection | Asset inventory and SBOM |
| C5-02 | Incident Response Management | Incident response procedures |
| C5-03 | Security Monitoring | Centralized monitoring and logging |
| C5-04 | Vulnerability Management | Automated vulnerability scanning |
| C5-05 | Change Management | GitOps and CI/CD pipelines |
| C5-06 | Configuration Management | Infrastructure as code |
| C5-07 | Access Control | RBAC and network policies |
| C5-08 | Data Protection | Encryption and access controls |
| C5-09 | Data Deletion | Data retention and deletion procedures |
| C5-10 | Cryptographic Procedures | TLS and certificate management |
| C5-11 | Key Management | Certificate lifecycle management |
| C5-12 | Authentication | Strong authentication mechanisms |
| C5-13 | Authorization | RBAC and least privilege |
| C5-14 | Audit Logging | Comprehensive audit logging |
| C5-15 | Backup Management | Automated backup procedures |
| C5-16 | Business Continuity Management | Disaster recovery procedures |
| C5-17 | Asset Management | Asset inventory and lifecycle management |

---

## Security Checklists

### 1. Container Security Checklist

- [ ] Use official or verified base images
- [ ] Use minimal base images (Alpine, Distroless)
- [ ] Pin image versions with specific tags
- [ ] Use multi-stage builds
- [ ] Run containers as non-root users
- [ ] Set appropriate file permissions
- [ ] Use read-only filesystems where possible
- [ ] Use tmpfs for temporary directories
- [ ] Drop unnecessary capabilities
- [ ] Use custom seccomp profiles
- [ ] Enable AppArmor/SELinux
- [ ] Scan images for vulnerabilities
- [ ] Sign images (cosign, Docker Content Trust)
- [ ] Never store secrets in images
- [ ] Use BuildKit secret mounting for build-time secrets
- [ ] Configure proper health checks
- [ ] Configure proper liveness, readiness, and startup probes
- [ ] Set resource limits (CPU, memory)
- [ ] Configure proper logging
- [ ] Implement proper signal handling

### 2. Kubernetes Security Checklist

- [ ] Enable RBAC
- [ ] Enable audit logging
- [ ] Enable Pod Security Admission (PSA)
- [ ] Apply appropriate Pod Security Standards
- [ ] Configure Pod Security Context
- [ ] Configure Container Security Context
- [ ] Define appropriate Network Policies
- [ ] Configure RBAC with least privilege
- [ ] Use dedicated service accounts
- [ ] Enable encryption at rest
- [ ] Configure API server security
- [ ] Secure etcd with TLS
- [ ] Configure kubelet security
- [ ] Secure control plane endpoints
- [ ] Implement network segmentation
- [ ] Run CIS Kubernetes Benchmark tests
- [ ] Configure rate limiting for API server
- [ ] Enable garbage collection for etcd
- [ ] Rotate certificates regularly
- [ ] Enable automatic certificate rotation
- [ ] Configure proper resource quotas
- [ ] Configure limit ranges

### 3. Network Security Checklist

- [ ] Implement network segmentation
- [ ] Define appropriate Network Policies
- [ ] Configure