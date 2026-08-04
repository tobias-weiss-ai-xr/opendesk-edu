# dev-dns

Helm chart for dev DNS server customization in k3s clusters.

Adds static host entries to k3s CoreDNS for internal services not resolvable via public DNS, and exposes CoreDNS externally via NodePort.

Uses the CoreDNS `file` plugin (zone file) rather than `hosts` plugin because k3s already uses the `hosts` plugin for NodeHosts and it can only be used once per server block.

## Installation

```bash
# From the repository root
helm upgrade --install dev-dns helmfile/charts/dev-dns --namespace kube-system

# Restart CoreDNS to pick up changes
kubectl -n kube-system rollout restart deployment coredns
kubectl -n kube-system rollout status deployment coredns
```

## Configuration

See [values.yaml](values.yaml) for the full configuration reference.

### Host Entries

Default entries resolve `*.opendesk.hrz.uni-marburg.de` services (r, term, slides, collab, code, ai, jupyter) to `192.168.3.201` (HAProxy).

Override in your own values file:

```yaml
coredns:
  targetIP: 10.0.0.50
  hostEntries:
    - hostnames:
        - my-service.internal.local
```

### NodePort

Default UDP: 30535, TCP: 30534.

## Files

| File | Description |
|------|-------------|
| `templates/configmap.yaml` | `coredns-custom` ConfigMap with `.override` and `.db` data |
| `templates/service.yaml` | NodePort service exposing CoreDNS externally |
| `templates/tests/test-connection.yaml` | Helm test pod for DNS verification |

## Notes

- Requires k3s (uses k3s-specific `coredns-custom` ConfigMap import mechanism)
- ConfigMap must be in `kube-system` namespace
- Service points to `k8s-app: kube-dns` selector (k3s CoreDNS pods)

## Client Access

Since NodePort is typically firewalled between subnets, use the setup script to create an SSH tunnel + socat bridge + dnsmasq forwarder:

```bash
bash scripts/setup-dev-dns-local.sh start
```
