# Dev DNS Setup

This document describes how the dev DNS server works and how to deploy it repeatably.

## Problem

Internal services (r, term, slides, collab, code, ai, jupyter) on `*.opendesk.hrz.uni-marburg.de` resolve to an internal IP (192.168.3.201 - HAProxy) that has no public DNS record.

Team machines need to resolve these hostnames during development.

## Solution

Two layers:

1. **Cluster side** (repeatable via Helm chart): Add static records to k3s CoreDNS using the `file` plugin with a zone file
2. **Client side** (per machine): SSH tunnel + socat bridge + dnsmasq to route dev queries to the cluster

## Cluster Deployment (Repeatable)

### Prerequisites

- `kubectl` and `helm` configured for the target k3s cluster

### Deploy via Helm

```bash
# From the opendesk-edu repository root
helm upgrade --install dev-dns helmfile/charts/dev-dns --namespace kube-system

# Restart CoreDNS to pick up changes
kubectl -n kube-system rollout restart deployment coredns
kubectl -n kube-system rollout status deployment coredns
```

Or use the deploy script:

```bash
bash scripts/deploy-dev-dns.sh
```

### Verify from within cluster

```bash
kubectl run dns-test --image=busybox:1.36 --rm -it --restart=Never -- sh -c \
  "nslookup r.opendesk.hrz.uni-marburg.de 172.17.128.10"
# Expected: Address 192.168.3.201
```

### Custom Values

```bash
# my-dev-dns-values.yaml
coredns:
  targetIP: 10.0.0.50
  zoneName: "internal.local"
  hostEntries:
    - hostnames:
        - service-a.internal.local
        - service-b.internal.local

helm upgrade --install dev-dns helmfile/charts/dev-dns \
  --namespace kube-system -f my-dev-dns-values.yaml
```

### Removal

```bash
helm uninstall dev-dns --namespace kube-system
kubectl -n kube-system delete configmap coredns-custom --ignore-not-found
kubectl -n kube-system rollout restart deployment coredns
kubectl -n kube-system delete svc dev-dns-external --ignore-not-found
```

---

## Client Setup (Per Machine)

Since the NodePort range (30535) is firewalled between subnets, we use an SSH tunnel through a cluster node to reach CoreDNS.

### Quick Setup

```bash
# Start all forwarding (SSH tunnel + socat bridge + dnsmasq)
bash scripts/setup-dev-dns-local.sh start

# Stop everything and restore system DNS
bash scripts/setup-dev-dns-local.sh stop

# Check status
bash scripts/setup-dev-dns-local.sh status
```

### What it sets up

```
DNS query → dnsmasq (127.0.0.1:53)
  ├─ *.opendesk.hrz.uni-marburg.de → socat (UDP→TCP) → SSH tunnel (TCP)
  │    → socat (TCP→UDP) on node → NodePort → kube-proxy → CoreDNS
  │    → file plugin → dev zone file → returns 192.168.3.201
  └─ everything else → HRZ DNS (137.248.1.8, 137.248.1.5)
```

Components:
- **SSH tunnel**: Forwards local port 30534 to cluster node's localhost (TCP only)
- **socat** (remote): Converts TCP→UDP on the node, reaches NodePort at `127.0.0.1:30535`
- **socat** (local): Converts UDP→TCP for DNS queries to go through SSH
- **dnsmasq**: Local DNS forwarder that routes dev domain queries through the tunnel and everything else directly to HRZ DNS
- **resolvconf**: `/etc/resolv.conf` configured with `127.0.0.1` as primary nameserver

### Requirements

- SSH key `~/.ssh/id_ed25519_ssh` with root access to cluster nodes (192.168.3.110-118)
- `socat` and `dnsmasq-base` installed locally
- sudo access (for dnsmasq + resolvconf)

---

## How It Works: k3s CoreDNS Custom ConfigMap

k3s has a built-in mechanism to customize CoreDNS: create a ConfigMap named `coredns-custom` in `kube-system` namespace with label `k8s-app: kube-dns`.

Each key becomes a file in `/etc/coredns/custom/`. The key suffix determines loading:

| Suffix | Behavior |
|--------|----------|
| `.override` | Imported inline into the default `.:53` server block |
| `.server` | Loaded as a separate server block |

We use `.override` to add a `file` plugin (zone file) directive. The `hosts` plugin cannot be used twice in the same server block (k3s already uses it for NodeHosts).

### Zone file structure

The `.db` file is a standard RFC 1035 zone file that CoreDNS loads via the `file` plugin. All dev hostnames are absolute FQDNs (with trailing dots in the zone file). The `file` plugin only responds for the configured zone - queries outside the zone pass through to the next plugin (forward → upstream DNS).

### Configuration Reference

#### `coredns.hostEntries`

List of hostname groups (all resolve to `coredns.targetIP`):

```yaml
coredns:
  targetIP: 192.168.3.201  # IP to resolve hostnames to
  zoneName: "opendesk.hrz.uni-marburg.de"  # Zone origin
  serial: "2026052901"  # SOA serial (increment on change)
  ttl: 300  # Record TTL in seconds
  hostEntries:
    - hostnames:
        - r.opendesk.hrz.uni-marburg.de
        - term.opendesk.hrz.uni-marburg.de
```

#### `service.nodePort`

External DNS access ports (NodePort):

```yaml
service:
  nodePort:
    udp: 30535
    tcp: 30534
```
