# opendesk-edu Demo Instance with Private DNS Namespace

## TL;DR
> Create a demo namespace with private CoreDNS server and deploy opendesk-edu (OpenCloud + SOGo)

## Context

**Requirements**:
- Namespace: `demo-opendesk-edu`
- DNS: CoreDNS (Kubernetes-native)
- Domain: `opendesk-edu-demo.local`
- Scope: Complete edu platform with one app per function

## Work Objectives

1. Create namespace `demo-opendesk-edu`
2. Deploy private CoreDNS with zone `opendesk-edu-demo.local`
3. Configure DNS records for services
4. Deploy OpenCloud in demo namespace
5. Deploy SOGo in demo namespace
6. Verify DNS resolution and service access

## TODOs

- [x] 1. Create namespace manifest [quick]
- [x] 2. Create CoreDNS ConfigMap with zone [quick]
- [x] 3. Create CoreDNS Deployment and Service [quick]
- [x] 4. Create DNS record definitions [quick]
- [x] 5. ConfigMap for service-to-DNS mappings [quick]
- [x] 6. Create OpenCloud manifest for demo namespace [quick]
- [x] 7. Create SOGo manifest for demo namespace [quick]
- [x] 8. Create ingress manifest for demo services [quick]
- [x] 9. Apply namespace and CoreDNS [unspecified-low]
- [x] 10. Deploy OpenCloud [unspecified-low]
- [x] 11. Deploy SOGo [unspecified-low]
- [x] 12. Verify DNS resolution to services [unspecified-low]
- [x] 13. Verify service accessibility [unspecified-low]

## Definition of Done

- [x] Namespace exists: `demo-opendesk-edu`
- [x] CoreDNS pod running and serving DNS queries
- [x] DNS resolution works: `opencloud.opendesk-edu-demo.local` → CoreDNS service IP
- [x] OpenCloud deployed and accessible at `opencloud.opendesk-edu-demo.local`
- [x] SOGo deployed and accessible at `sogo.opendesk-edu-demo.local`

## Success Criteria

```bash
kubectl get namespace demo-opendesk-edu
kubectl get pods -n demo-opendesk-edu -l app=coredns
kubectl get pods -n demo-opendesk-edu -l app=opencloud
kubectl get pods -n demo-opendesk-edu -l app=sogo
```

## References

- CoreDNS documentation: https://coredns.io/manual/toc/
- helmfile/charts/opencloud/* - OpenCloud chart reference
- helmfile/charts/sogo/* - SOGo chart reference
