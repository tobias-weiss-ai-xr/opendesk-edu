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
│  │   Node 1     │  │   Node 2     │  │   Node 3     │          │
│  │ k3s-server   │  │ k3s-server   │  │ k3s-server   │          │
│  │ (etcd)       │  │ (etcd)       │  │ (etcd)       │          │
│  │              │  │              │  │              │          │
│  │ Traefik      │  │ Traefik      │  │ Traefik      │          │
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
│  Hardware: 3× Huawei RH2288E V2                                  │
│  CPU: 16+ Cores x86_64 per Node                                  │
│  RAM: 64+ GB per Node                                            │
│  Storage: Ceph (>4 TB, Replikation 3)                            │
│  Network: 2× 10GbE Intel X540, VLAN 424                          │
│  OS: Debian 12 (bookworm)                                        │
└─────────────────────────────────────────────────────────────────┘
```

## K3s vs OSISM (OpenStack + Ceph + K8s)

| Aspect | OSISM (old) | SCS-K3s (new) |
|--------|-------------|---------------|
| Orchestration | OpenStack | None (bare metal) |
| Kubernetes | Full K8s (OSISM-managed) | K3s (lightweight, single binary) |
| Ingress | HAProxy | Traefik (K3s built-in) |
| LoadBalancer | MetalLB | MetalLB (unchanged) |
| Storage | Ceph (OSISM-managed) | Ceph-CSI (direct, external Ceph) |
| CNI | Calico/Canal | Flannel (K3s built-in) |
| etcd | External etcd cluster | Embedded etcd (K3s HA mode) |
| Control Plane | OpenStack API + K8s API | K3s API only (simpler) |
| Overhead | High (OpenStack + K8s) | Low (K3s ~512MB) |

## Files

- `k3s-install.yaml` — K3s server installation manifest (HA mode, embedded etcd)
- `metallb-config.yaml` — MetalLB IPAddressPool configuration
- `ceph-csi-config.yaml` — Ceph-CSI driver configuration (RBD + CephFS)
- `traefik-config.yaml` — Traefik ingress controller overrides
- `registry-pull-secret.yaml` — Container registry credentials

## Deployment

```bash
# 1. Install K3s server on Node 1 (cluster init)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.31.2+k3s1" \
  K3S_TOKEN=<shared-secret> \
  sh -s - server \
  --cluster-init \
  --disable traefik \
  --disable servicelb \
  --disable local-storage \
  --flannel-backend=vxlan \
  --node-external-ip=<node1-ip>

# 2. Join Node 2 and Node 3 (server agents, HA)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.31.2+k3s1" \
  K3S_TOKEN=<shared-secret> \
  sh -s - server \
  --server https://<node1-ip>:6443 \
  --node-external-ip=<node2-ip>

# 3. Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
kubectl apply -f metallb-config.yaml

# 4. Install Traefik (custom config)
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --values traefik-config.yaml

# 5. Install Ceph-CSI
kubectl apply -f ceph-csi-config.yaml

# 6. Apply openDesk Edu
nix build .#allServices
kubectl apply -f result/ -n opendesk
```
