# CIS Kubernetes Benchmark Implementation Guide

## SPDX-License-Identifier: Apache-2.0

**Maintainer:** openDesk Edu Team <team@opendesk-edu.org>  
**Version:** 1.0.0  
**Last Updated:** 2026-08-03  
**Benchmark Version:** CIS Kubernetes Benchmark v1.8.0  

---

## Table of Contents

1. [Overview](#overview)
2. [Benchmark Versions](#benchmark-versions)
3. [Control Plane (Master Nodes)](#1-control-plane-master-nodes)
4. [Drawer (Worker Nodes)](#2-drawer-worker-nodes)
5. [Automated Testing with kube-bench](#automated-testing-with-kube-bench)
6. [Remediation Scripts](#remediation-scripts)
7. [Continuous Compliance Monitoring](#continuous-compliance-monitoring)
8. [Custom Profiles](#custom-profiles)
9. [Reporting and Documentation](#reporting-and-documentation)
10. [References](#references)

---

## Overview

This document provides a comprehensive guide to implementing and maintaining compliance with the **CIS Kubernetes Benchmark v1.8.0** for the openDesk infrastructure. The CIS Benchmark provides prescriptive guidance for securing Kubernetes clusters against today's evolving threats.

### What is CIS Kubernetes Benchmark?

The **Center for Internet Security (CIS) Kubernetes Benchmark** is a set of security configuration best practices for Kubernetes, developed through a global community consensus process. It provides:

- **Prescriptive guidance** for securing Kubernetes deployments
- **Configuration recommendations** for control plane components
- **Security settings** for worker nodes
- **Compliance checking** capabilities
- **Automated testing** through kube-bench

### Importance

- **Security Hardening**: Protects against common attacks and misconfigurations
- **Compliance**: Helps meet regulatory requirements (PCI DSS, SOC 2, ISO 27001, etc.)
- **Auditability**: Provides documented evidence of security posture
- **Consistency**: Ensures uniform security configurations across clusters

### Scope

This guide covers:
- **Control Plane (Master Nodes)**: API Server, Controller Manager, Scheduler, etcd
- **Worker Nodes**: Kubelet, Kube-Proxy, Container Runtime
- **Components**: Networking, Storage, RBAC

---

## Benchmark Versions

| Version | Release Date | Kubernetes Version | Status |
|---------|--------------|-------------------|--------|
| v1.0.0 | 2019-03-20 | 1.15 | Legacy |
| v1.1.0 | 2019-08-07 | 1.15-1.16 | Legacy |
| v1.2.0 | 2020-01-27 | 1.17 | Legacy |
| v1.3.0 | 2020-08-13 | 1.18-1.19 | Legacy |
| v1.4.0 | 2021-03-09 | 1.19-1.20 | Legacy |
| v1.5.0 | 2021-10-14 | 1.21-1.22 | Legacy |
| v1.6.0 | 2022-04-26 | 1.23-1.24 | Legacy |
| **v1.7.0** | **2023-01-18** | **1.25-1.26** | **Current** |
| **v1.8.0** | **2023-11-15** | **1.27-1.28** | **Latest** |

### Benchmark Structure

The CIS Kubernetes Benchmark is organized into the following sections:

1. **Control Plane Configuration**
   - API Server
   - Controller Manager
   - Scheduler
   - etcd

2. **Worker Node Configuration**
   - Kubelet
   - Kube-Proxy
   - Container Runtime (containerd, CRI-O, Docker)

3. **Polkit Configuration**

4. **Network Configuration**

### Scoring Levels

| Level | Description | Number of Recommendations |
|-------|-------------|--------------------------|
| **Level 1 (L1)** | Recommended minimum security settings that should be applied to any system | ~50 |
| **Level 2 (L2)** | Additional security settings that should be applied where enhanced security is required | ~70 |
| **Total** | +120 security recommendations |

---

## 1. Control Plane (Master Nodes)

The control plane consists of the following components:
- **kube-apiserver**: Primary API entry point for all cluster operations
- **kube-controller-manager**: Manages controller loops (replica, node, job controllers)
- **kube-scheduler**: Schedules pods to nodes based on resource availability
- **etcd**: Distributed key-value store for cluster state

### 1.1 API Server Configuration

#### File Permissions

| ID | Control | Level | Type | Remediation | openDesk Implementation |
|----|---------|-------|------|-------------|-------------------------|
| 1.1.1 | Ensure that the API server pod specification file permissions are set to 600 or more restrictive | L1 | Automatic | `chmod 600 /etc/kubernetes/manifests/kube-apiserver.yaml` | ✅ Automated in deployment scripts |
| 1.1.2 | Ensure that the API server pod specification file ownership is set to root:root | L1 | Automatic | `chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml` | ✅ Automated in deployment scripts |
| 1.1.3 | Ensure that the controller manager pod specification file permissions are set to 600 or more restrictive | L1 | Automatic | `chmod 600 /etc/kubernetes/manifests/kube-controller-manager.yaml` | ✅ Automated in deployment scripts |
| 1.1.4 | Ensure that the controller manager pod specification file ownership is set to root:root | L1 | Automatic | `chown root:root /etc/kubernetes/manifests/kube-controller-manager.yaml` | ✅ Automated in deployment scripts |
| 1.1.5 | Ensure that the scheduler pod specification file permissions are set to 600 or more restrictive | L1 | Automatic | `chmod 600 /etc/kubernetes/manifests/kube-scheduler.yaml` | ✅ Automated in deployment scripts |
| 1.1.6 | Ensure that the scheduler pod specification file ownership is set to root:root | L1 | Automatic | `chown root:root /etc/kubernetes/manifests/kube-scheduler.yaml` | ✅ Automated in deployment scripts |
| 1.1.7 | Ensure that the etcd pod specification file permissions are set to 600 or more restrictive | L1 | Automatic | `chmod 600 /etc/kubernetes/manifests/etcd.yaml` | ✅ Automated in deployment scripts |
| 1.1.8 | Ensure that the etcd pod specification file ownership is set to root:root | L1 | Automatic | `chown root:root /etc/kubernetes/manifests/etcd.yaml` | ✅ Automated in deployment scripts |

**Implementation Script:**

```bash
#!/bin/bash
# scripts/apply-cis-file-permissions.sh

set -euo pipefail

MANIFEST_DIR="/etc/kubernetes/manifests"

if [ -d "$MANIFEST_DIR" ]; then
    echo "Applying CIS benchmark file permissions..."
    
    # Set permissions to 600
    find "$MANIFEST_DIR" -type f -name "*.yaml" -exec chmod 600 {} \;
    
    # Set ownership to root:root
    find "$MANIFEST_DIR" -type f -name "*.yaml" -exec chown root:root {} \;
    
    echo "File permissions applied successfully."
else
    echo "Manifest directory not found: $MANIFEST_DIR"
    exit 1
fi
```

#### API Server Settings

| ID | Control | Level | Type | Remediation | openDesk Implementation |
|----|---------|-------|------|-------------|-------------------------|
| 1.2.1 | Ensure that the --anonymous-auth argument is set to false | L1 | Manual | Add `--anonymous-auth=false` to kube-apiserver arguments | ✅ Configured in kube-apiserver manifest |
| 1.2.2 | Ensure that the --basic-auth-file argument is not set | L1 | Manual | Remove `--basic-auth-file` from kube-apiserver arguments | ✅ Not configured (authentication via certificates) |
| 1.2.3 | Ensure that the --insecure-allow-any-token argument is not set | L1 | Manual | Remove `--insecure-allow-any-token` from kube-apiserver arguments | ✅ Not configured |
| 1.2.4 | Ensure that the --insecure-bind-address argument is not set | L1 | Manual | Remove `--insecure-bind-address` from kube-apiserver arguments | ✅ Not configured |
| 1.2.5 | Ensure that the --insecure-port argument is set to 0 | L1 | Manual | Set `--insecure-port=0` in kube-apiserver arguments | ✅ Configured to use secure port only |
| 1.2.6 | Ensure that the --secure-port argument is not set to 0 | L1 | Manual | Set `--secure-port=6443` (or custom secure port) | ✅ Configured to use port 6443 |
| 1.2.7 | Ensure that the --profiler-address argument is not set | L1 | Manual | Remove `--profiler-address` from kube-apiserver arguments | ✅ Not configured (profiling disabled) |
| 1.2.8 | Ensure that the --allow-privileged argument is set to false | L1 | Manual | Set `--allow-privileged=false` in kube-apiserver arguments | ✅ Configured (Pod Security Admission enforced) |
| 1.2.9 | Ensure that the --audit-log-path argument is set | L1 | Manual | Set `--audit-log-path=/var/log/kubernetes/audit.log` | ✅ Configured |
| 1.2.10 | Ensure that the --audit-log-maxage argument is set to 30 or appropriate | L1 | Manual | Set `--audit-log-maxage=30` | ✅ Configured |
| 1.2.11 | Ensure that the --audit-log-maxbackup argument is set to 10 or as appropriate | L1 | Manual | Set `--audit-log-maxbackup=10` | ✅ Configured |
| 1.2.12 | Ensure that the --audit-log-maxsize argument is set to an appropriate size | L1 | Manual | Set `--audit-log-maxsize=100` | ✅ Configured |
| 1.2.13 | Ensure that the --authorization-mode argument includes Node | L1 | Manual | Set `--authorization-mode=Node,RBAC` | ✅ Configured |
| 1.2.14 | Ensure that the --authorization-mode argument includes RBAC | L1 | Manual | RBAC included in authorization mode | ✅ Configured |
| 1.2.15 | Ensure that the --authorization-mode argument does not include AlwaysAllow | L1 | Manual | Remove `AlwaysAllow` from authorization mode | ✅ Not configured |
| 1.2.16 | Ensure that the --token-auth-file parameter is not set | L1 | Manual | Remove `--token-auth-file` from kube-apiserver arguments | ✅ Not configured |
| 1.2.17 | Ensure that the --kubelet-certificate-authority argument is set as appropriate | L1 | Manual | Set `--kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt` | ✅ Configured |
| 1.2.18 | Ensure that the --kubelet-client-certificate argument is set as appropriate | L1 | Manual | Set proper client certificate | ✅ Configured |
| 1.2.19 | Ensure that the --kubelet-client-key argument is set as appropriate | L1 | Manual | Set proper client key | ✅ Configured |
| 1.2.20 | Ensure that the --service-account-lookup argument is set to true | L1 | Manual | Set `--service-account-lookup=true` | ✅ Configured |
| 1.2.21 | Ensure that the --service-account-key-file argument is set as appropriate | L1 | Manual | Set proper service account key file | ✅ Configured |
| 1.2.22 | Ensure that the --etcd-cafile argument is set as appropriate | L1 | Manual | Set proper etcd CA file | ✅ Configured |
| 1.2.23 | Ensure that the --etcd-certfile argument is set as appropriate | L1 | Manual | Set proper etcd certificate file | ✅ Configured |
| 1.2.24 | Ensure that the --etcd-keyfile argument is set as appropriate | L1 | Manual | Set proper etcd key file | ✅ Configured |

**kube-apiserver Manifest Example:**

```yaml
# /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
  labels:
    component: kube-apiserver
    tier: control-plane
spec:
  containers:
  - name: kube-apiserver
    image: registry.k8s.io/kube-apiserver:v1.32.3
    command:
    - kube-apiserver
    - --advertise-address=192.168.3.200
    - --allow-privileged=false
    - --anonymous-auth=false
    - --api-audiences=https://kubernetes.default.svc.cluster.local
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
    - --audit-log-path=/var/log/kubernetes/audit.log
    - --authorization-mode=Node,RBAC
    - --bind-address=192.168.3.200
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction,PodSecurityAdmission
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://192.168.3.200:2379,https://192.168.3.201:2379,https://192.168.3.202:2379
    - --insecure-port=0
    - --kubelet-certificate-authority=/etc/kubernetes/pki/ca.crt
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-issuer=https://kubernetes.default.svc.cluster.local
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-lookup=true
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=10.96.0.0/12
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
    - --watch-cache-sizes=100#1000
    volumeMounts:
    - mountPath: /var/log/kubernetes
      name: audit-log
      readOnly: false
    - mountPath: /etc/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /usr/local/share/ca-certificates
      name: usr-local-share-ca-certificates
      readOnly: true
    - mountPath: /usr/share/ca-certificates
      name: usr-share-ca-certificates
      readOnly: true
  hostNetwork: true
  priorityClassName: system-node-critical
  volumes:
  - name: audit-log
    hostPath:
      path: /var/log/kubernetes
      type: DirectoryOrCreate
  - name: k8s-certs
    hostPath:
      path: /etc/kubernetes/pki
      type: DirectoryOrCreate
  - name: ca-certs
    hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
  - name: usr-local-share-ca-certificates
    hostPath:
      path: /usr/local/share/ca-certificates
      type: DirectoryOrCreate
  - name: usr-share-ca-certificates
    hostPath:
      path: /usr/share/ca-certificates
      type: DirectoryOrCreate
```

#### etcd Configuration

| ID | Control | Level | Type | Remediation | openDesk Implementation |
|----|---------|-------|------|-------------|-------------------------|
| 1.3.1 | Ensure that the --cert-file argument is set as appropriate | L1 | Manual | Set `--cert-file=/etc/kubernetes/pki/etcd/server.crt` | ✅ Configured |
| 1.3.2 | Ensure that the --key-file argument is set as appropriate | L1 | Manual | Set `--key-file=/etc/kubernetes/pki/etcd/server.key` | ✅ Configured |
| 1.3.3 | Ensure that the --trusted-ca-file argument is set as appropriate | L1 | Manual | Set `--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt` | ✅ Configured |
| 1.3.4 | Ensure that the --client-cert-auth argument is set to true | L1 | Manual | Set `--client-cert-auth=true` | ✅ Configured |
| 1.3.5 | Ensure that the --auto-tls argument is not set to true | L1 | Manual | Remove `--auto-tls=true` or set to `false` | ✅ Not configured |
| 1.3.6 | Ensure that the --peer-cert-file argument is set as appropriate | L1 | Manual | Set proper peer certificate file | ✅ Configured |
| 1.3.7 | Ensure that the --peer-key-file argument is set as appropriate | L1 | Manual | Set proper peer key file | ✅ Configured |
| 1.3.8 | Ensure that the --peer-trusted-ca-file argument is set as appropriate | L1 | Manual | Set proper peer CA file | ✅ Configured |
| 1.3.9 | Ensure that the --peer-client-cert-auth argument is set to true | L1 | Manual | Set `--peer-client-cert-auth=true` | ✅ Configured |
| 1.3.10 | Ensure that the --data-dir argument is set as appropriate | L1 | Manual | Set `--data-dir=/var/lib/etcd` | ✅ Configured |
| 1.3.11 | Ensure that the etcd data directory permissions are set to 700 or more restrictive | L1 | Automatic | `chmod 700 /var/lib/etcd` | ✅ Automated in deployment |
| 1.3.12 | Ensure that the etcd data directory ownership is set to etcd:etcd | L1 | Automatic | `chown etcd:etcd /var/lib/etcd` | ✅ Automated in deployment |

**etcd Manifest Example:**

```yaml
# /etc/kubernetes/manifests/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd
  namespace: kube-system
  labels:
    component: etcd
    tier: control-plane
spec:
  containers:
  - name: etcd
    image: registry.k8s.io/etcd:3.5.11-0
    command:
    - etcd
    - --advertise-client-urls=https://192.168.3.200:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://192.168.3.200:2380
    - --initial-cluster=node1=https://192.168.3.200:2380,node2=https://192.168.3.201:2380,node3=https://192.168.3.202:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://192.168.3.200:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.3.200:2380
    - --name=node1
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --auto-compaction-mode=periodic
    - --auto-compaction-retention=1h
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
      readOnly: true
  hostNetwork: true
  priorityClassName: system-node-critical
  volumes:
  - name: etcd-data
    hostPath:
      path: /var/lib/etcd
      type: DirectoryOrCreate
  - name: etcd-certs
    hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
```

---

## Automated Testing with kube