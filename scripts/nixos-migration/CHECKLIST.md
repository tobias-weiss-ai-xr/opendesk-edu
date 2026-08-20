# NixOS Container Migration Checklist

## Quick Reference

This checklist tracks the migration status of all services. Use it to monitor progress and ensure all requirements are met.

---

## Migration Status Tracker

### Legend
| Symbol | Meaning |
|--------|---------|
| ✅ | Complete - Fully migrated and tested |
| 🔄 | In Progress - Migration started |
| ⚪ | Pending - Not started |
| ❌ | Blocked - Issues preventing migration |

---

## Phase 1: Pilot (Testing Complete)

| Service | Version | Type | NixOS Config | Build Test | Docker Test | Health Check | Documentation | Status |
|---------|---------|------|--------------|------------|-------------|--------------|---------------|--------|
| mariadb | 11.4.4 | database | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Phase 2: Core Services (100% Complete)

| Service | Version | Type | NixOS Config | Build Test | Docker Test | Health Check | Documentation | Status |
|---------|---------|------|--------------|------------|-------------|--------------|---------------|--------|
| **mariadb** | 11.4.4 | database | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **postgresql** | 16.3 | database | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **redis** | 7.2.4 | cache | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **nginx** | 1.25.3 | web | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **traefik** | v2.10.0 | web | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **keycloak** | 24.0.0 | iam | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**Location:** `opendesk-nix/docker/services/{service}/nixos/`

---

## Phase 3: LMS Services (Priority 1 - Ready to Start)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| moodle | 4.4.0 | lms | mariadb, php-fpm | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| ilias | 8.0.0 | lms | mariadb, php-fpm | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| nextcloud | 29.0.0 | collaboration | mariadb/postgresql, redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

**Priority:** HIGH - Required for educational use cases

---

## Phase 4: Collaboration Tools (Priority 2)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| collabora | 22.05.0 | office | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| planka | 1.0.0 | project-management | postgresql, redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| etherpad | 1.9.0 | collaboration | mariadb | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| cryptpad | 5.0.0 | collaboration | mongodb, redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| drawio | 21.0.0 | diagramming | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| excalidraw | 0.17.0 | diagramming | redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| bookstack | v26.05.2 | documentation | mariadb | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

---

## Phase 5: Communication (Priority 3)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| rocketchat | 6.0.0 | communication | mongodb, redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| element | 1.11.0 | communication | postgresql | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| jitsi | 8.0.0 | communication | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

---

## Phase 6: Monitoring (Priority 4)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| grafana | 10.0.0 | monitoring | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| prometheus | 2.47.0 | monitoring | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

---

## Phase 7: Infrastructure (Priority 5)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| docker-registry | 2.8.0 | registry | redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| zot-registry | 2.0.0 | registry | postgresql | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

---

## Phase 8: Documentation (Priority 6)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| xwiki | 15.0.0 | documentation | postgresql | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| dokuwiki | latest | documentation | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

---

## Phase 9: Authentication & Identity (Priority 7)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| openx | - | authentication | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| shibboleth-idp | - | iam | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| shibboleth-sp | - | iam | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

---

## Phase 10: Development Tools (Priority 8)

| Service | Version | Type | Dependencies | NixOS Config | Build | Docker | Health | Docs | Status |
|---------|---------|------|--------------|--------------|-------|--------|--------|------|--------|
| gitlab | 16.0.0 | devops | postgresql, redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| gitea | 1.21.0 | devops | postgresql | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| jenkins | 2.414 | ci | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| drone | 2.0.0 | ci | postgresql, redis | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |
| argocd | 2.10.0 | cd | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ |

---

## Phase 11: Miscellaneous Services (Priority 9)

### Web & CMS (10 services)
| Service | Version | Type | Dependencies | Status |
|---------|---------|------|--------------|--------|
| apache | 2.4.58 | web | - | ⚪ |
| wordpress | 6.4.0 | cms | mariadb | ⚪ |
| matomo | 5.0.0 | analytics | mariadb | ⚪ |
| nubus | - | portal | mariadb, redis | ⚪ |
| pleroma | - | federated social | postgresql, redis | ⚪ |
| mastodon | - | federated social | postgresql, redis | ⚪ |
| matrix-synapse | 1.97.0 | communication | postgresql | ⚪ |
| onlyoffice | 7.5.0 | office | postgresql, redis | ⚪ |
| z-push | 2.6.0 | activesync | - | ⚪ |
| equations | - | math | - | ⚪ |

### SOGo Groupware (2 services)
| Service | Version | Type | Dependencies | Status |
|---------|---------|------|--------------|--------|
| sogo5 | 5.8.0 | groupware | postgresql, memcached | ⚪ |
| sogo6 | 6.0.0 | groupware | postgresql, memcached | ⚪ |

### Registry & Storage (3 services)
| Service | Version | Type | Dependencies | Status |
|---------|---------|------|--------------|--------|
| seaweedfs | - | storage | - | ⚪ |
| minio | - | storage | - | ⚪ |
| ceph-exporter | - | monitoring | - | ⚪ |

### Messaging (3 services)
| Service | Version | Type | Dependencies | Status |
|---------|---------|------|--------------|--------|
| postfixadmin | - | mail | mariadb | ⚪ |
| dovecot | - | mail | mariadb | ⚪ |
| rainloop | - | mail | mariadb | ⚪ |

### Search & Indexing (2 services)
| Service | Version | Type | Dependencies | Status |
|---------|---------|------|--------------|--------|
| elasticsearch | 8.11.0 | search | - | ⚪ |
| kibana | 8.11.0 | search | elasticsearch | ⚪ |

### Reverse Proxy (1 service)
| Service | Version | Type | Dependencies | Status |
|---------|---------|------|--------------|--------|
| haproxy | - | proxy | - | ⚪ |

---

## Summary Statistics

### Progress Overview
| Phase | Total | Completed | In Progress | Pending | % Complete |
|-------|-------|-----------|--------------|---------|-------------|
| Phase 1: Pilot | 1 | 1 | 0 | 0 | 100% |
| Phase 2: Core | 6 | 6 | 0 | 0 | 100% |
| Phase 3: LMS | 3 | 0 | 0 | 3 | 0% |
| Phase 4: Collaboration | 7 | 0 | 0 | 7 | 0% |
| Phase 5: Communication | 3 | 0 | 0 | 3 | 0% |
| Phase 6: Monitoring | 2 | 0 | 0 | 2 | 0% |
| Phase 7: Infrastructure | 2 | 0 | 0 | 2 | 0% |
| Phase 8: Documentation | 2 | 0 | 0 | 2 | 0% |
| Phase 9: Authentication | 3 | 0 | 0 | 3 | 0% |
| Phase 10: Dev Tools | 5 | 0 | 0 | 5 | 0% |
| Phase 11: Miscellaneous | 27 | 0 | 0 | 27 | 0% |
| **Total** | **61** | **7** | **0** | **54** | **11.5%** |

**Note:** Count may vary as new services are added. The total includes all services in openDesk Edu.

---

## Service Migration Commands

### Quick Migration
```bash
# Single service
./scripts/nixos-migration/migrate-service.sh <service-name> <version> <dockerfile-path>

# Multiple services
./scripts/nixos-migration/batch-migrate.sh service1 service2 service3

# All pending services
./scripts/nixos-migration/batch-migrate.sh --pending
```

### Manual Migration Steps
1. Create directory: `mkdir -p opendesk-nix/docker/services/<service>/nixos`
2. Create configuration.nix
3. Create default.nix
4. Create secrets.nix
5. Create README.md
6. Update overlays/opendesk.nix
7. Update lib/nixos/services.nix
8. Update flake.nix
9. Test: `nix build .#<service>-nixos`
10. Verify: `docker load < result && docker run -d ...`

---

## Verification Checklist

For each migrated service, verify the following:

### ✅ Configuration.nix
- [ ] Service enabled and properly configured
- [ ] Package reference is correct
- [ ] Port configuration is correct
- [ ] User and group created (non-root, UID 1000+)
- [ ] Directories created with correct permissions
- [ ] Security hardening applied (polkit, openssh disabled)
- [ ] All dependencies included
- [ ] Activation scripts for directory setup

### ✅ Default.nix
- [ ] Correct image name: `<service>-opendesk`
- [ ] Correct tag: `<version>-nixos`
- [ ] Exposed ports configured
- [ ] Volumes configured
- [ ] Environment variables set (TZ, LC_ALL, etc.)
- [ ] Health check configured (Test, Interval, Timeout, Retries, StartPeriod)
- [ ] User set to non-root
- [ ] Working directory set
- [ ] CMD or ENTRYPOINT configured
- [ ] Stop signal configured (SIGTERM)
- [ ] Stop timeout configured (30s)
- [ ] OCI labels present (12 required labels)
- [ ] Extra packages included (openssl, curl, procps, coreutils)

### ✅ Secrets.nix
- [ ] References sops-nix
- [ ] Placeholder comments for common secrets
- [ ] No plaintext secrets

### ✅ README.md
- [ ] Service name and version
- [ ] OpenSpec compliance list
- [ ] Quick start guide
- [ ] Build instructions
- [ ] Run instructions
- [ ] Configuration reference
- [ ] Secrets management section
- [ ] Troubleshooting section
- [ ] License information

### ✅ OCI Labels (FR-IMAGE-007)
- [ ] org.opencontainers.image.title
- [ ] org.opencontainers.image.description
- [ ] org.opencontainers.image.version
- [ ] org.opencontainers.image.authors
- [ ] org.opencontainers.image.url
- [ ] org.opencontainers.image.documentation
- [ ] org.opencontainers.image.source
- [ ] org.opencontainers.image.licenses
- [ ] com.opendesk.service
- [ ] com.opendesk.environment
- [ ] com.opendesk.managed
- [ ] com.opendesk.nixos

### ✅ Security (FR-IMAGE-001)
- [ ] Non-root user (UID 999 or 1000+)
- [ ] Non-root group (GID 999 or 1000+)
- [ ] No SSH service
- [ ] No polkit service
- [ ] Read-only filesystem where possible
- [ ] Capability dropping (FR-IMAGE-002)
- [ ] Seccomp profile (FR-IMAGE-003)

### ✅ Functionality
- [ ] Build succeeds without errors
- [ ] Container loads into Docker
- [ ] Container starts successfully
- [ ] Health checks pass
- [ ] Basic functionality works
- [ ] Ports are exposed correctly
- [ ] Volumes are mounted correctly

---

## Migration Commands for Each Phase

### Phase 3: LMS Services
```bash
./scripts/nixos-migration/migrate-service.sh moodle 4.4.0
./scripts/nixos-migration/migrate-service.sh ilias 8.0.0
./scripts/nixos-migration/migrate-service.sh nextcloud 29.0.0
```

### Phase 4: Collaboration Tools
```bash
./scripts/nixos-migration/migrate-service.sh collabora 22.05.0
./scripts/nixos-migration/migrate-service.sh planka 1.0.0
./scripts/nixos-migration/migrate-service.sh etherpad 1.9.0
./scripts/nixos-migration/migrate-service.sh cryptpad 5.0.0
./scripts/nixos-migration/migrate-service.sh drawio 21.0.0
./scripts/nixos-migration/migrate-service.sh excalidraw 0.17.0
./scripts/nixos-migration/migrate-service.sh bookstack v26.05.2
```

### Phase 5: Communication
```bash
./scripts/nixos-migration/migrate-service.sh rocketchat 6.0.0
./scripts/nixos-migration/migrate-service.sh element 1.11.0
./scripts/nixos-migration/migrate-service.sh jitsi 8.0.0
```

### Phase 6: Monitoring
```bash
./scripts/nixos-migration/migrate-service.sh grafana 10.0.0
./scripts/nixos-migration/migrate-service.sh prometheus 2.47.0
```

### Phase 7: Infrastructure
```bash
./scripts/nixos-migration/migrate-service.sh docker-registry 2.8.0
./scripts/nixos-migration/migrate-service.sh zot-registry 2.0.0
```

### Phase 8: Documentation
```bash
./scripts/nixos-migration/migrate-service.sh xwiki 15.0.0
./scripts/nixos-migration/migrate-service.sh dokuwiki latest
```

---

## Batch Migration Commands

### Migrate All Services
```bash
# All pending services
./scripts/nixos-migration/batch-migrate.sh --pending

# Specific phases
./scripts/nixos-migration/batch-migrate.sh moodle ilias nextcloud
./scripts/nixos-migration/batch-migrate.sh collabora planka etherpad cryptpad drawio excalidraw bookstack
./scripts/nixos-migration/batch-migrate.sh rocketchat element jitsi
./scripts/nixos-migration/batch-migrate.sh grafana prometheus
./scripts/nixos-migration/batch-migrate.sh docker-registry zot-registry
```

### Scan and Report
```bash
# Scan all services
./scripts/nixos-migration/SCAN-EXISTING-SERVICES.sh

# Count migrated services
find opendesk-nix/docker/services -name "nixos" -type d | wc -l

# List migrated services
find opendesk-nix/docker/services -name "nixos" -type d | xargs -I {} basename $(dirname {})
```

---

## Post-Migration Tasks

After all services are migrated:

1. **Update flake.nix** - Ensure all packages are listed
2. **Update allContainers** - Ensure all containers are included
3. **Run comprehensive build** - `nix build .#all-nixos-images`
4. **Test all containers** - Script to test each container
5. **Update documentation** - Update NIXOS-CONTAINER-MIGRATION.md
6. **Update compliance tracking** - Ensure all OpenSpec requirements met

---

## OpenSpec Compliance Tracking

| Requirement | Description | Status |
|-------------|-------------|--------|
| FR-BUILD-001 | Docker image build for service | ✅ Verified |
| FR-BUILD-002 | Nix flakes for reproducible builds | ✅ Verified |
| FR-BUILD-003 | Multi-architecture builds | ✅ Verified |
| FR-BUILD-004 | OCI-compliant images | ✅ Verified |
| FR-BUILD-005 | Build cache support | ✅ Verified |
| FR-BUILD-006 | Build dependencies | ✅ Verified |
| FR-BUILD-007 | Build verification | ✅ Verified |
| FR-IMAGE-001 | Non-root user | ✅ Verified |
| FR-IMAGE-002 | Dropped capabilities | ✅ Verified |
| FR-IMAGE-003 | Seccomp profiles | ✅ Verified |
| FR-IMAGE-004 | Read-only root filesystem | ✅ Partial |
| FR-IMAGE-005 | Minimal base images | ✅ Verified |
| FR-IMAGE-006 | User namespace isolation | ✅ Verified |
| FR-IMAGE-007 | OCI labels | ✅ Verified |
| FR-IMAGE-008 | Health checks | ✅ Verified |
| FR-IMAGE-009 | Image signing | ⚪ Pending |

---

## Links

- [NixOS Container Migration Guide](MIGRATION-PIPELINE.md)
- [NixOS Container Migration Overview](../NIXOS-CONTAINER-MIGRATION.md)
- [Migration Toolkit README](README.md)
- [Scan Existing Services](SCAN-EXISTING-SERVICES.sh)

---

## Last Updated

2026-08-03 - Initial checklist created

**Next Review:** After each migration batch
