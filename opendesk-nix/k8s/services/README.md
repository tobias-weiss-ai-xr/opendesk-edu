# openDesk Services

> **Migrated from opendesk-edu/nix/k8s/ on 2026-08-28**

This directory contains Nix-based Kubernetes service definitions for all openDesk Edu services.

## Structure

Each service is defined in a `.nix` file that exports a list of Kubernetes resources (deployments, services, ingresses, etc.) using the consolidated library from `../lib/k8s.nix`.

## Migration Notes

These files were migrated from `opendesk-edu/nix/k8s/` as part of Phase 2 consolidation:

| Service File | Status | Notes |
|--------------|--------|-------|
| `*.nix` | ✅ Migrated | All files copied from opendesk-edu/nix/k8s/ |
| Import paths | ⚠️ TODO | Need to update to use opendesk-nix/lib/k8s |
| Image references | ⚠️ TODO | Standardize on ghcr.io/opendesk-edu/* |

## Current Services (69 total)

### Databases & Caches
- mariadb.nix
- postgresql.nix
- redis.nix
- memcached.nix
- timescale.nix

### LMS & Education
- ilias.nix
- ilias-full.nix
- moodle.nix
- bookstack.nix
- openproject.nix
- xwiki.nix
- jupyterhub.nix
- collab-dashboard.nix

### Collaboration & Office
- collabora.nix
- drawio.nix
- excalidraw.nix
- etherpad.nix
- grommunio.nix
- opencloud.nix
- onlyoffice.nix (if exists)
- nextcloud.nix (already in parent k8s/)

### Communication
- element.nix
- jitsi.nix
- stalwart.nix
- bigbluebutton.nix

### Development & Code
- coderd.nix
- code-server.nix
- ide.nix (if exists)
- rstudio.nix
- ttyd.nix

### AI & Data
- ollama.nix
- open-webui.nix
- dask.nix
- n8n.nix

### Monitoring & Logging
- kube-prometheus-stack.nix
- monitoring.nix
- elasticsearch.nix
- kibana.nix
- filebeat.nix
- loki.nix
- promtail.nix

### Storage & Files
- minio.nix (already in parent k8s/)
- seaweedfs.nix
- clamav.nix

### Authentication & Portal
- keycloak.nix (already in parent k8s/)
- sogo.nix
- nubus-portal.nix (already in parent k8s/)
- nubus-provisioning.nix (already in parent k8s/)
- self-service-password.nix
- portal-entries.nix
- semester-provisioning.nix

### Project Management
- planka.nix
- argocd.nix
- zammad.nix

### Other Services
- f13.nix
- eudi-issuer.nix
- intercom.nix
- intercom-service.nix
- snipr.nix
- slidev.nix
- typo3.nix
- limesurvey.nix
- overleaf.nix

## Usage

### Import from opendesk-edu/nix/ (Legacy - During Transition)

```nix
{ lib }:
import ./opendesk-nix/k8s/services/mariadb.nix { inherit lib; }
```

### Import from opendesk-nix/ (New - Recommended)

```nix
{ pkgs, lib, ... }:
let
  k8s = lib.k8s;
in
import ./k8s/services/mariadb.nix { lib = k8s; }
```

## Service Definition Format

Each service file follows this pattern:

```nix
{ lib }:
let
  name = "mariadb";
  instance = "ilias";
  fullName = "${instance}-${name}";
  image = "ghcr.io/opendesk-edu/mariadb";
  tag = "11.4.4";
in [
  (lib.statefulset { 
    inherit name fullName image tag;
    port = 3306;
    volumeClaims = [ ... ];
  })
  (lib.service { inherit name fullName; port = 3306; })
]
```

## Next Steps

1. Update all imports to use `opendesk-nix.lib.k8s` instead of local `lib`
2. Standardize image names to use `ghcr.io/opendesk-edu/*`
3. Add security contexts using `lib.security`
4. Add SBOM generation where applicable
5. Add multi-registry support using `lib.registry`

## See Also

- [../../lib/k8s.nix](../../lib/k8s.nix) - Kubernetes library
- [../../lib/security.nix](../../lib/security.nix) - Security profiles
- [../../lib/registry.nix](../../lib/registry.nix) - Registry support
- [../../lib/sbom.nix](../../lib/sbom.nix) - SBOM generation
- [../../OPENSPEC.md](../../OPENSPEC.md) - Full specification

---

**Migration Date:** 2026-08-28  
**Phase:** 2 (Consolidation)  
**Status:** Files migrated, imports need updating
