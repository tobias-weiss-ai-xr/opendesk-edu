# SCS-K3s Cluster Configuration

**openDesk Edu — HRZ Production Cluster**

This directory contains the K3s cluster bootstrap and configuration for the
SCS (Sovereign Cloud Stack) deployment at Philipps-Universität Marburg.

## Cluster Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    SCS-K3s Cluster (3 Nodes)                     │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  clrz14-06   │  │  clrz14-07   │  │  clrz14-08   │          │
│  │ control-plane│  │  worker      │  │  worker      │          │
│  │ (etcd)       │  │              │  │              │          │
│  │              │  │              │  │              │          │
│  │ HAProxy      │  │ HAProxy      │  │ HAProxy      │          │
│  │ Flannel CNI  │  │ Flannel CNI  │  │ Flannel CNI  │          │
│  │ MetalLB      │  │ MetalLB      │  │ MetalLB      │          │
│  │ Ceph-CSI     │  │ Ceph-CSI     │  │ Ceph-CSI     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         └──────────────────┼──────────────────┘                  │
│                            │                                     │
│                   ┌────────▼────────┐                           │
│                   │  Ceph Cluster    │                           │
│                   │  (external,      │                           │
│                   │   RBD + CephFS)  │                           │
│                   └─────────────────┘                           │
│                                                                  │
│  K3s v1.36.3+k3s1                                               │
│  HAProxy v3.2.12 (Helm, kube-system)                            │
│  MetalLB: rz03-fip-pool (172.25.3.181-172.25.3.196)             │
│  Ceph-CSI: ceph-rbd (RWO), ceph-cephfs (RWX)                    │
│  Domain: home.opendesk-edu.org → 172.25.3.181                   │
│  OS: Ubuntu 24.04.4 LTS, kernel 6.8.0-137-generic               │
└─────────────────────────────────────────────────────────────────┘
```

## Actual Cluster State (as observed)

| Component | Value |
|-----------|-------|
| K3s version | v1.36.3+k3s1 |
| Nodes | clrz14-06 (control-plane), clrz14-07, clrz14-08 |
| Ingress | HAProxy v3.2.12 (Helm, kube-system) |
| Ingress class | `haproxy` |
| LoadBalancer | MetalLB, pool `rz03-fip-pool` (172.25.3.181-196) |
| Storage (RWO) | `ceph-rbd` (rbd.csi.ceph.com) |
| Storage (RWX) | `ceph-cephfs` (cephfs.csi.ceph.com) |
| Storage (default) | `local-path` (rancher.io/local-path) |
| TLS secret | `opendesk-certificates-tls` (kubernetes.io/tls) |
| Domain | `home.opendesk-edu.org` (→ 172.25.3.181) |
| ArgoCD | Installed, manages opendesk + opendesk-edu namespaces |

## Files

- `k3s-install.yaml` — K3s server configuration reference (HA mode, embedded etcd)
- `metallb-config.yaml` — MetalLB IPAddressPool (rz03-fip-pool)
- `ceph-csi-config.yaml` — Ceph-CSI storage classes (ceph-rbd, ceph-cephfs)
- `haproxy-config.yaml` — HAProxy ingress documentation (already installed)

## Namespaces

| Namespace | Purpose | Managed by |
|-----------|---------|------------|
| `opendesk` | Shared services (Keycloak, Element, Synapse, Galera) | ArgoCD |
| `opendesk-edu` | Edu services (openCloud, SOGo, Stalwart, OpenProject, Redis, Postfix) | ArgoCD |
| `opendesk-staff` | Staff tenant (mail: SOGo, Postfix, Dovecot; XWiki-staff) | TBD |
| `opendesk-students` | Student tenant (mail: SOGo, Postfix, Dovecot) | TBD |
| `argocd` | ArgoCD GitOps | Helm |
| `metallb-system` | MetalLB LoadBalancer | Helm |
| `kube-system` | K3s core, Ceph-CSI, HAProxy, CoreDNS | K3s |
| `monitoring` | Prometheus, Grafana | ArgoCD |
| `backup` | K8up backup, SeaweedFS | ArgoCD |
