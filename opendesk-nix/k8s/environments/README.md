// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# Kubernetes Environments

This directory contains environment-specific configuration for openDesk deployments.

## Environments

### Production (HRZ)
- **Directory:** `hrz/`
- **Namespace:** `opendesk`
- **Ingress:** HAProxy (hrz infrastructure)
- **Domain:** `opendesk.hrz.uni-marburg.de`
- **Storage:** Ceph-CSI (RBD SSD for RWO, CephFS HDD EC for RWX)
- **Features:** Full production configuration with TLS, monitoring, security

### Demo
- **Directory:** `demo/`
- **Namespace:** `opendesk-demo`
- **Ingress:** NGINX
- **Domain:** `demo.opendesk-edu.org`
- **Storage:** NFS or standard provisioner
- **Features:** Public demo environment with TLS via Let's Encrypt

### Local Development
- **Directory:** `local/`
- **Namespace:** `opendesk-local`
- **Ingress:** NGINX (optional)
- **Domain:** `localhost`
- **Storage:** Local hostPath or emptyDir
- **Features:** Minimal configuration for local testing (Minikube, KIND)

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
