// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# Kubernetes Environments

This directory contains environment-specific configuration for openDesk deployments.

## Environments

### Production (HRZ)
- **Directory:** `hrz/`
- **Namespace:** `opendesk`
- **Cluster:** SCS-K3s (3 nodes, embedded etcd, HA mode, v1.36.3+k3s1)
- **Ingress:** HAProxy (v3.2.12, Helm, kube-system)
- **Domain:** `desk-test.uni-marburg.de` (currently `home.opendesk-edu.org`)
- **Storage:** Ceph-CSI (`ceph-rbd` for RWO, `ceph-cephfs` for RWX, external Ceph cluster)
- **LoadBalancer:** MetalLB (`rz03-fip-pool`, 172.25.3.181-196)
- **Features:** Full production configuration with TLS, monitoring, security, multi-tenant

### Demo
- **Directory:** `demo/`
- **Namespace:** `opendesk-demo`
- **Cluster:** SCS-K3s (single node)
- **Ingress:** HAProxy
- **Domain:** `demo.opendesk-edu.org`
- **Storage:** Ceph-CSI (`ceph-rbd`, `ceph-cephfs`)
- **Features:** Public demo environment with TLS

### Local Development
- **Directory:** `local/`
- **Namespace:** `opendesk-local`
- **Cluster:** K3s (single node, local)
- **Ingress:** HAProxy (optional)
- **Domain:** `localhost`
- **Storage:** local-path (K3s default provisioner)
- **Features:** Minimal configuration for local testing (K3s, Minikube, KIND)

## Usage

### In Service Definitions

Service definitions can access environment-specific configuration:

```nix
{ lib, env ? import ../environments/hrz/default.nix { }, ... }:

let
  namespace = env.namespace;
  storageClass = env.storage.rwo;
  ingressClass = env.ingress.className;
  
  deployment = lib.deployment {
    name = "my-service";
    # ...
  };
  
  service = lib.service {
    name = "my-service";
    # ...
  };
  
  ingress = lib.ingress {
    name = "my-service-ingress";
    annotations = { "kubernetes.io/ingress.class" = ingressClass; };
    hosts = [ { host = "${name}.${env.ingress.domain}"; ... } ];
    tls = if env.tls.enabled then [ { hosts = [ "${name}.${env.ingress.domain}" ]; secretName = env.tls.secretName; } ] else [];
  };

in [ deployment service ingress ]
```

### Environment Overrides

Create overrides for specific environments:

```nix
# k8s/environments/hrz/overrides/mariadb.nix
{ pkgs, lib, baseConfig, ... }:

baseConfig // {
  resources = {
    cpu = "2";
    memory = "8Gi";
  };
  replicas = 3;
}
```

## OpenSpec Compliance

This structure implements **FR-DEPLOY-001**: Support multiple environments (hrz, demo, local).

## Future Enhancements

- [ ] Dynamic environment loading based on K8s context
- [ ] Environment validation and merging
- [ ] 존Overrides per service per environment
- [ ] Environment-specific secrets management
