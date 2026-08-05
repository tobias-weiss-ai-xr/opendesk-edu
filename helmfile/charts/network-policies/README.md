# openDesk Network Policies

SPDX-FileCopyrightText: 2024-2026 HRZ Marburg
SPDX-License-Identifier: AGPL-3.0-or-later

Kubernetes Network Policies for openDesk HRZ deployment implementing defense-in-depth security.

## Overview

This Helm chart creates Network Policies that control ingress and egress traffic between services in the openDesk namespace.

## Architecture

The policies follow the principle of least privilege:

1. **Default Deny All**: All traffic is denied by default
2. **Allow DNS**: CoreDNS/UDP+TCP port 53 access for name resolution
3. **Allow Ingress Controller**: haproxy/nginx ingress controller routing
4. **Service-to-Service**: Explicit allow rules for required communications

## Deployment

Enable network policies in opendesk deployment:

```bash
helm upgrade opendesk charts/network-policies ./network-policies \
  --namespace opendesk \
  --set defaultDenyPolicy.enabled=true \
  --set dnsPolicy.enabled=true \
  --set serviceToServicePolicies.enabled=true
```

## Policies

### default-deny-all
Denies all ingress and egress traffic by default.

### allow-dns
Allows DNS resolution (UDP/TCP port 53) to CoreDNS.

### allow-ingress-controller
Allows ingress controller to route traffic to services.

## Security Implications

Network policies are enforced at the Kubernetes network isolation level, providing:

- Service-to-service traffic segmentation
- Mitigation of lateral movement in case of compromise
- Compliance with multi-layered security requirements

## Monitoring

Check network policy status:

```bash
kubectl get networkpolicies -n opendesk
kubectl describe networkpolicy default-deny-all -n opendesk
```

View traffic blocked by policies:

```bash
kubectl logs -n opendesk <pod-name> | grep "Connection refused"
```

## Troubleshooting

If services become unreachable after enabling network policies:

1. Check policy status: `kubectl get networkpolicies -n opendesk`
2. Verify DNS policy: `kubectl get networkpolicy allow-dns -n opendesk`
3. Check pod logs for connection errors
4. Review required service communications
5. Add missing allow rules as needed
