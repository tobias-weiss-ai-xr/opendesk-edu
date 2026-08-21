// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# Environment Overrides

This directory contains environment-specific overrides for service configurations.

## Structure

```
environments/
├── overrides/
│   └── {environment}/
│       └── {service}.nix
└── {environment}/
    └── default.nix
```

## Usage

### Base Environment Configuration
Each environment has a `default.nix` file with default values:

```nix
# k8s/environments/hrz/default.nix
{
  namespace = "opendesk";
  storage = {
    rwx = "ceph-cephfs";
    rwo = "ceph-rbd";
  };
  # ...
}
```

### Service-Specific Overrides
Create override files for specific services:

```nix
# k8s/environments/overrides/hrz/mariadb.nix
{ baseConfig }:

baseConfig // {
  resources.cpu = "4";
  resources.memory = "8Gi";
  replicas.max = 5;
}
```

### Loading Overrides in Service Files

```nix
{ lib, env ? import ../environments/hrz/default.nix { lib = lib; }, override ? null, ... }:

let
  # Apply environment overrides if provided
  finalEnv = if override != null then override env else env;

  name = "mariadb";
  # ...
```

### Using in Flake

```nix
# In your flake.nix or deployment
{
  inputs.opendesk-nix.url = "path:../opendesk-nix";
  
  outputs = { self, opendesk-nix, ... }:
    let
      env = import opendesk-nix/k8s/environments/hrz/default.nix { };
      overrides = import opendesk-nix/k8s/environments/overrides/hrz { };
      finalEnv = overrides.mariadb env;  # Apply mariadb-specific overrides
    in {
      # ...
    };
}
```

## Example Override

```nix
# k8s/environments/overrides/demo/n8n.nix
{ baseConfig }:

baseConfig // {
  resources = {
    cpu = "500m";
    memory = "256Mi";
  };
  replicas = {
    min = 1;
    max = 1;
    default = 1;
  };
}
```

## OpenSpec Compliance

This implements **FR-DEPLOY-002**: Support environment-specific overrides.

## Implementation Status

- [x] Environment base configurations
- [x] Override directory structure
- [x] Documentation
- [ ] Override loading in service files
- [ ] Automated override application

---

*Created: 2026-08-28*  
*OpenSpec Requirement: FR-DEPLOY-002*
