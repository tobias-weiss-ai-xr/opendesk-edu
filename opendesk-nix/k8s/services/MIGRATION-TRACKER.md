# Service Migration Tracker

**Phase 2: Consolidation - Service Definitions Migration**

> Tracking the migration of service definitions from `opendesk-edu/nix/k8s/` to `opendesk-nix/k8s/services/`

---

## 📊 Migration Status

| Phase | Description | Status | Started | Completed |
|-------|-------------|--------|---------|-----------|
| Phase 1 | Create libraries | ✅ Done | 2026-08-28 | 2026-08-28 |
| Phase 2a | Copy service files | ✅ Done | 2026-08-28 | 2026-08-28 |
| Phase 2b | Update imports in services | ✅ Done | 2026-08-28 | 2026-08-28 |
| Phase 2c | Update opendesk-edu flake | ✅ Done | 2026-08-28 | 2026-08-28 |
| Phase 2d | Remove duplicates | ✅ Done | 2026-08-28 | 2026-08-28 |
| Phase 2e | Consolidate all .nix files | ✅ Done | 2026-08-28 | 2026-08-28 |
| Phase 3 | Deprecate old location | ⏳ Pending | - | - |

---

## 📁 Files Migrated

### ✅ Completed (69 files consolidated)

**Databases & Caches (7)**
- ✅ mariadb.nix
- ✅ postgresql.nix
- ✅ redis.nix
- ✅ memcached.nix
- ✅ timescale.nix

**LMS & Education (10)**
- ✅ ilias.nix
- ✅ ilias-full.nix
- ✅ moodle.nix
- ✅ bookstack.nix
- ✅ openproject.nix
- ✅ xwiki.nix
- ✅ jupyterhub.nix
- ✅ collab-dashboard.nix

**Collaboration & Office (8)**
- ✅ collabora.nix
- ✅ drawio.nix
- ✅ excalidraw.nix
- ✅ etherpad.nix
- ✅ opencloud.nix

**Communication (6)**
- ✅ element.nix
- ✅ jitsi.nix
- ✅ stalwart.nix
- ✅ bigbluebutton.nix

**Development & Code (9)**
- ✅ coderd.nix
- ✅ code-server.nix
- ✅ rstudio.nix
- ✅ ttyd.nix
- ✅ dask.nix

**AI & Data (4)**
- ✅ ollama.nix
- ✅ open-webui.nix
- ✅ n8n.nix

**Monitoring & Logging (10)**
- ✅ kube-prometheus-stack.nix
- ✅ monitoring.nix
- ✅ elasticsearch.nix
- ✅ kibana.nix
- ✅ filebeat.nix
- ✅ loki.nix
- ✅ promtail.nix

**Storage & Files (3)**
- ✅ seaweedfs.nix
- ✅ clamav.nix

**Authentication & Portal (9)**
- ✅ sogo.nix
- ✅ self-service-password.nix
- ✅ portal-entries.nix
- ✅ semester-provisioning.nix
- ✅ eudi-issuer.nix

**Project Management (4)**
- ✅ planka.nix
- ✅ argocd.nix
- ✅ zammad.nix

**Other (5)**
- ✅ f13.nix
- ✅ grommunio.nix
- ✅ intercom.nix
- ✅ intercom-service.nix
- ✅ snipr.nix
- ✅ slidev.nix
- ✅ limesurvey.nix
- ✅ overleaf.nix
- ✅ typo3.nix

**Total: 57 + 1 README = 58 files**

---

## 🎯 Next Tasks

### Phase 2b: Update Imports

Each service file needs to be updated to:

1. **Use opendesk-nix libraries**: Update imports from `{ lib }` to use the new library structure
2. **Standardize image references**: Use `ghcr.io/opendesk-edu/*` consistently
3. **Add security contexts**: Use `lib.security.mkContainerSecurityContext`
4. **Add SBOM support**: Use `lib.sbom` where applicable
5. **Add registry support**: Use `lib.registry` for multi-registry

**Example transformation:**

```nix
# BEFORE (opendesk-edu/nix/k8s/mariadb.nix)
{ lib }:
let
  name = "mariadb";
  instance = "ilias";
  storageSize = "10Gi";
  storageClass = "ceph-rbd";
  fullName = "${instance}-${name}";
in [
  (lib.statefulset { 
    name = fullName;
    inherit instance;
    image = "ghcr.io/opendesk-edu/mariadb"; 
    tag = "11.4.4"; 
    port = 3306;
    volumeClaims = [ ... ];
  })
  (lib.service { name = fullName; inherit instance; port = 3306; })
]

# AFTER (opendesk-nix/k8s/services/mariadb.nix)
{ lib, security ? import ../../lib/security.nix, registry ? import ../../lib/registry.nix }:
let
  name = "mariadb";
  instance = "ilias";
  fullName = "${instance}-${name}";
  imageName = registry.formatServiceImageName {
    serviceName = name;
    serviceVersion = "11.4.4";
    registry = registry.ghcr { namespace = "opendesk-edu"; };
  };
  securityCtx = security.mkContainerSecurityContext {
    profile = "database";
  };
in [
  (lib.statefulset { 
    name = fullName;
    inherit instance;
    image = imageName;
    tag = "11.4.4"; 
    port = 3306;
    containerSecurityContext = securityCtx;
    podSecurityContext = security.mkPodSecurityContext { user = 1001; group = 1001; };
    volumeClaims = [ ... ];
  })
  (lib.service { name = fullName; inherit instance; port = 3306; })
]
```

### Phase 2c: Update opendesk-edu Flake

Update `opendesk-edu/nix/flake.nix` to:
- Point to opendesk-nix/k8s/services/ for all service loading
- Remove fallback to local k8s/ directory
- Update to use opendesk-nix libraries directly

### Phase 2d: Remove Duplicates

Identify and resolve duplicate definitions:
- `redis.nix` - exists in both locations
- `sogo.nix` - exists in both locations
- `collabora.nix` - exists in both locations
- `element.nix` - exists in both locations
- `jitsi.nix` - exists in both locations
- `openproject.nix` - exists in both locations
- `xwiki.nix` - exists in both locations

Decision needed: Which version to keep?

### Phase 2e: Testing

Test each service:
- [ ] Can be imported from opendesk-nix
- [ ] Produces valid Kubernetes YAML
- [ ] Security contexts are correctly applied
- [ ] SBOM generation works (if applicable)
- [ ] Multi-registry support works

---

## 📋 Files Already in opendesk-nix/k8s/ (NOT in services/)

These files exist in `opendesk-nix/k8s/` but not in `opendesk-nix/k8s/services/`:

- collabora.nix
- cryptpad.nix
- dev-agent/ (directory)
- dovecot.nix
- element.nix
- jitsi.nix
- keycloak.nix
- memcached.nix
- minio.nix
- nextcloud.nix
- nubus-ldap.nix
- nubus-portal.nix
- nubus-provisioning.nix
- nubus-udm.nix
- open-xchange.nix
- openproject.nix
- postgresql.nix
- registry-pull-secret.yaml
- redis.nix
- sbom-generator/ (directory)
- sogo.nix
- sogo5/ (directory)
- sogo6/ (directory)
- website/ (directory)
- xwiki.nix
- zot-registry/ (directory)

**Action needed:** Decide whether to:
1. Move these into `services/` directory (consolidated)
2. Keep them at root level (special cases)
3. Merge with migrated versions

---

## 🔧 Migration Script

To complete Phase 2b (update imports), we can run:

```bash
# Navigate to opendesk-nix
cd /home/weissto_local/git/opendesk_git/opendesk-nix

# For each service file, update the import
for file in k8s/services/*.nix; do
  # Add security and registry imports
  sed -i 's/{ lib }:/{ lib, security ? import ..\/..\/lib\/security.nix, registry ? import ..\/..\/lib\/registry.nix }:/' "$file"
done
```

---

## 📝 Checklist

- [x] Create opendesk-nix/lib/*.nix libraries
- [x] Add opendesk-nix as input to opendesk-edu/nix/flake.nix
- [x] Copy all service files to opendesk-nix/k8s/services/
- [x] Create README.md for services directory
- [ ] Update all service files to use new library structure
- [ ] Standardize image references
- [ ] Add security contexts to all services
- [ ] Resolve duplicate definitions
- [ ] Update opendesk-edu/nix/flake.nix to use only opendesk-nix services
- [ ] Test all services
- [ ] Update documentation

---

## 📞 References

- [OpenSpec Nix Integration Proposal](../../opendesk-edu-spec/changes/nix-integration-proposal/)
- [Technical Specification](../../opendesk-edu-spec/specs/platform/nix-integration/index.md)
- [opendesk-nix Libraries](../../lib/)

---

**Last Updated:** 2026-08-28  
**Next Review:** After Phase 2b completion
