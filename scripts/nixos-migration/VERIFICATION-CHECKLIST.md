# Service Migration Verification Checklist

## Overview

This document provides a **comprehensive verification checklist** for ensuring each NixOS container migration meets all OpenSpec requirements and production standards.

---

## Verification Levels

### Level 1: Pre-Build Verification ✅ (Required)
Verify before attempting to build the container.

### Level 2: Build Verification ✅ (Required)
Verify the container builds successfully.

### Level 3: Runtime Verification ✅ (Required)
Verify the container runs and is healthy.

### Level 4: Production Verification ⚪ (Recommended)
Verify the container is production-ready.

---

## Level 1: Pre-Build Verification Checklist

### Directory Structure
- [ ] `opendesk-nix/docker/services/<service>/nixos/` exists
- [ ] `configuration.nix` exists and is valid Nix syntax
- [ ] `default.nix` exists and is valid Nix syntax
- [ ] `secrets.nix` exists
- [ ] `README.md` exists
- [ ] No duplicate files in root directory (secrets.yaml, README.md, etc.)

### Configuration.nix
- [ ] Has SPDX license header
- [ ] Has SPDX copyright header
- [ ] Has service description
- [ ] Has version information
- [ ] Imports opendesk overlays
- [ ] Defines service configuration
- [ ] Creates system user (non-root)
- [ ] Creates system group
- [ ] Sets up directories with `system.activationScripts`
- [ ] Disables polkit
- [ ] Disables openssh
- [ ] Sets `system.stateVersion`

### Default.nix
- [ ] Has SPDX license header
- [ ] Has SPDX copyright header
- [ ] Has service description
- [ ] Has version information
- [ ] Imports configuration.nix
- [ ] Uses `docks.mkImage`
- [ ] Has correct image name: `<service>-opendesk`
- [ ] Has correct tag: `<version>-nixos`
- [ ] Defines `ExposedPorts`
- [ ] Defines `Volumes`
- [ ] Sets `Env` with at least: OPENDESK_ENV, TZ, LC_ALL, LANG
- [ ] Defines `HealthCheck` with: Test, Interval, Timeout, Retries, StartPeriod
- [ ] Sets non-root `User`
- [ ] Sets `WorkingDir`
- [ ] Sets `Cmd` or `Entrypoint`
- [ ] Sets `StopSignal` (SIGTERM)
- [ ] Sets `StopTimeout` (30s)
- [ ] Defines `extraPackages`
- [ ] Has 12+ OCI labels

### OCI Labels (FR-IMAGE-007)
Verify all labels are present in `default.nix`:

```nix
ociLabels = {
  "org.opencontainers.image.title" = "...";           # Required
  "org.opencontainers.image.description" = "...";     # Required
  "org.opencontainers.image.version" = "...";          # Required
  "org.opencontainers.image.authors" = "...";         # Required
  "org.opencontainers.image.url" = "...";              # Required
  "org.opencontainers.image.documentation" = "...";   # Required
  "org.opencontainers.image.source" = "...";           # Required
  "org.opencontainers.image.licenses" = "...";        # Required
  "com.opendesk.service" = "...";                     # Required
  "com.opendesk.environment" = "...";                 # Required
  "com.opendesk.managed" = "...";                     # Required
  "com.opendesk.nixos" = "...";                       # Required
};
```

### Service Catalog Entry
- [ ] Entry exists in `opendesk-nix/lib/nixos/services.nix`
- [ ] Uses `mkService` function
- [ ] Has correct `name`
- [ ] Has correct `version`
- [ ] Has `description`
- [ ] Has `category` (database, cache, web, iam, lms, etc.)
- [ ] Has `tier` (backend, infrastructure, application)
- [ ] Has `ports` list
- [ ] Has `configPath`
- [ ] Has `defaultNixPath`
- [ ] Merges with service type: `// serviceTypes.<type>`

### Overlays Entry
- [ ] Entry exists in `opendesk-nix/overlays/opendesk.nix`
- [ ] Uses `super.<service>.overrideAttrs`
- [ ] Sets `version`
- [ ] Sets `pname` to `<service>-opendesk`

### Flake.nix Entry
- [ ] `<service>-nixos` listed in packages
- [ ] `<service>-nixos` included in `allContainers` (if applicable)

---

## Level 2: Build Verification Checklist

### Build Test
```bash
cd opendesk-nix
nix build .#<service>-nixos
```

- [ ] Build completes without errors
- [ ] No missing package errors
- [ ] No hash mismatch errors
- [ ] Build time is reasonable (< 10 min cold, < 1s cached)
- [ ] Result symlink points to valid store path

### Build Artifacts
- [ ] Result directory exists
- [ ] Contains Docker image
- [ ] Docker image has correct name
- [ ] Docker image has correct tag

---

## Level 3: Runtime Verification Checklist

### Docker Load
```bash
docker load < result
```

- [ ] Image loads without errors
- [ ] Image appears in `docker images`
- [ ] Image name is `<service>-opendesk:<version>-nixos`
- [ ] Image size is reasonable (< 200MB average)

### Docker Inspect
```bash
docker inspect <image>
```

- [ ] `User` is set to non-root user
- [ ] `WorkingDir` is set
- [ ] `ExposedPorts` are configured
- [ ] `Volumes` are configured
- [ ] `Env` variables are set
- [ ] `HealthCheck` is configured
- [ ] `StopSignal` is SIGTERM
- [ ] `StopTimeout` is set
- [ ] All 12 OCI labels are present
- [ ] `Cmd` or `Entrypoint` is set

### Docker Run
```bash
docker run -d --name test-<service> -p <port>:<port> <image>
```

- [ ] Container starts successfully
- [ ] Container exits immediately (check logs)
- [ ] No permission denied errors
- [ ] No configuration file not found errors
- [ ] No missing dependency errors

### Health Check
```bash
docker inspect --format='{{json .State.Health}}' test-<service>
```

- [ ] Health check passes within StartPeriod
- [ ] Health status becomes "healthy"
- [ ] Health check runs at correct interval
- [ ] Health check respects timeout

### Functionality Test
Varies by service type:

#### Database Services (mariadb, postgresql)
```bash
# Mariadb
docker exec test-mariadb mysql -uroot -p<password> -e "SELECT 1;"
# Should return: +------+ | 1 | +------+

# PostgreSQL
docker exec test-postgresql psql -U postgres -c "SELECT 1;"
# Should return: ?column? | 1
```

#### Cache Services (redis)
```bash
docker exec test-redis redis-cli ping
# Should return: PONG

docker exec test-redis redis-cli set test value
# Should return: OK

docker exec test-redis redis-cli get test
# Should return: "value"
```

#### Web Services (nginx, traefik)
```bash
curl http://127.0.0.1:<port>/healthz
# Should return: 200 OK or similar

curl -v http://127.0.0.1:<port>/
# Should return: HTTP 200 with content
```

#### IAM Services (keycloak)
```bash
curl http://127.0.0.1:<port>/auth/realms/master
# Should return: 200 OK with JSON

# Test admin credentials (if configured)
curl -u admin:admin http://127.0.0.1:<port>/auth/admin
# Should return: 200 OK
```

#### PHP Services (moodle, ilias, nextcloud)
```bash
# Check PHP-FPM is running
docker exec test-moodle ps aux | grep php-fpm
# Should show php-fpm processes

# Check web server
docker exec test-moodle ps aux | grep nginx
# Should show nginx processes

# Test web request
curl http://127.0.0.1:<port>/install.php
# Should return HTML
```

---

## Level 4: Production Verification Checklist

### Security (FR-IMAGE-001 through FR-IMAGE-009)

#### Non-Root User
- [ ] Container runs as non-root user (UID 999 or 1000+)
- [ ] No processes running as root
- [ ] Files are owned by non-root user

```bash
# Check user
docker inspect --format='{{.Config.User}}' <image>
# Should be non-root

# Check running processes
docker exec test-<service> ps aux
# All processes should be non-root

# Check file ownership
docker exec test-<service> ls -la /var/lib/<service>
# Files should be owned by service user
```

#### Capabilities
- [ ] All unnecessary capabilities are dropped
- [ ] Only required capabilities are kept

```bash
docker inspect --format='{{.HostConfig.CapAdd}}' <image>
docker inspect --format='{{.HostConfig.CapDrop}}' <image>
```

#### Seccomp Profile
- [ ] Seccomp profile is configured
- [ ] Syscalls are restricted

```bash
docker inspect --format='{{.HostConfig.SecurityOpt}}' <image>
# Should include seccomp option
```

#### Read-Only Filesystem
- [ ] Filesystem is read-only where possible
- [ ] Writeable directories are explicitly mounted

```bash
docker inspect --format='{{.HostConfig.ReadonlyRootfs}}' <image>
# Should be true if possible
```

### Image Size
- [ ] Image size is less than Dockerfile equivalent
- [ ] Image size is less than 200MB (target)
- [ ] No unnecessary packages included

```bash
docker images | grep <service>-opendesk
dive <service>-opendesk:<version>-nixos
```

### Determinism
- [ ] Build is deterministic (same inputs = same outputs)
- [ ] Build hash is consistent

```bash
# Build twice and compare
nix build .#<service>-nixos --json | jq '.drvPath' > build1.txt
nix build .#<service>-nixos --json | jq '.drvPath' > build2.txt
diff build1.txt build2.txt
# Should be empty (no difference)
```

### Performance
- [ ] Container starts within 30 seconds
- [ ] Health check passes within StartPeriod
- [ ] No excessive resource usage

```bash
# Monitor startup
time docker run -d --name test-<service> <image>

# Check resource usage
docker stats test-<service> --no-stream
```

### Networking
- [ ] Exposed ports are correct
- [ ] No unexpected ports are open
- [ ] DNS resolution works
- [ ] Network connectivity works

```bash
# Check exposed ports
docker inspect --format='{{.Config.ExposedPorts}}' <image>

# Test DNS
docker exec test-<service> cat /etc/resolv.conf

# Test connectivity
docker exec test-<service> curl -v http://example.com
```

---

## Service-Specific Verification

### MariaDB

```bash
# 1. Build
docker load < result

# 2. Run
docker run -d --name test-mariadb \
  -e MYSQL_ROOT_PASSWORD=test123 \
  -e MYSQL_DATABASE=testdb \
  -e MYSQL_USER=testuser \
  -e MYSQL_PASSWORD=testpass \
  mariadb-opendesk:11.4.4-nixos

# 3. Test connection
sleep 30
docker exec test-mariadb mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;"

# 4. Test database
docker exec test-mariadb mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"

# 5. Test user
docker exec test-mariadb mysql -utestuser -p"$MYSQL_PASSWORD" -e "SELECT DATABASE();"

# 6. Cleanup
docker stop test-mariadb && docker rm test-mariadb
```

### PostgreSQL

```bash
# 1. Build
docker load < result

# 2. Run
docker run -d --name test-postgresql \
  -e POSTGRES_PASSWORD=test123 \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=testuser \
  postgresql-opendesk:16.3-nixos

# 3. Test connection
sleep 30
docker exec test-postgresql psql -U postgres -c "SELECT 1;"

# 4. Test database
docker exec test-postgresql psql -U postgres -c "\l"

# 5. Test user
docker exec test-postgresql psql -U testuser -d testdb -c "SELECT 1;"

# 6. Cleanup
docker stop test-postgresql && docker rm test-postgresql
```

### Redis

```bash
# 1. Build
docker load < result

# 2. Run
docker run -d --name test-redis redis-opendesk:7.2.4-nixos

# 3. Test connection
sleep 5
docker exec test-redis redis-cli ping

# 4. Test operations
docker exec test-redis redis-cli set test key
docker exec test-redis redis-cli get test

# 5. Test persistence (if configured)
docker exec test-redis redis-cli save
docker exec test-redis ls -la /data

# 6. Cleanup
docker stop test-redis && docker rm test-redis
```

### Nginx

```bash
# 1. Build
docker load < result

# 2. Run
docker run -d --name test-nginx -p 8080:80 nginx-opendesk:1.25.3-nixos

# 3. Test HTTP
sleep 3
curl http://127.0.0.1:8080/

# 4. Test HTTPS (if configured)
curl -k https://127.0.0.1:8443/

# 5. Test static files
curl http://127.0.0.1:8080/index.html

# 6. Test configuration
docker exec test-nginx nginx -t

# 7. Cleanup
docker stop test-nginx && docker rm test-nginx
```

### Traefik

```bash
# 1. Build
docker load < result

# 2. Run
docker run -d --name test-traefik \
  -p 8080:8080 \
  -p 80:80 \
  traefik-opendesk:v2.10.0-nixos

# 3. Test HTTP
sleep 5
curl http://127.0.0.1:8080/api/rawdata

# 4. Test dashboard (if enabled)
curl http://127.0.0.1:8080/dashboard/

# 5. Cleanup
docker stop test-traefik && docker rm test-traefik
```

### Keycloak

```bash
# 1. Build
docker load < result

# 2. Run
docker run -d --name test-keycloak \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin123 \
  -p 8080:8080 \
  keycloak-opendesk:24.0.0-nixos

# 3. Test health
sleep 60
curl http://127.0.0.1:8080/health/ready

# 4. Test admin console
docker exec test-keycloak kcadm.sh config credentials \
  --server http://127.0.0.1:8080 \
  --user admin \
  --password admin123 \
  --realm master

# 5. Test realm creation
docker exec test-keycloak kcadm.sh create realms \
  -f - <<EOF
{
  "realm": "test-realm",
  "enabled": true
}
EOF

# 6. Cleanup
docker stop test-keycloak && docker rm test-keycloak
```

---

## Automated Verification Script

Run the automated test suite:

```bash
# Test all migrated services
./scripts/nixos-migration/test-migration.sh --all

# Test specific service
./scripts/nixos-migration/test-migration.sh mariadb

# Test pending services
./scripts/nixos-migration/test-migration.sh --pending
```

The test script performs all Level 2 and Level 3 verifications automatically.

---

## Manual Verification

For services that require manual verification (Level 4):

### Checklist Template

```markdown
## Service: <service>
## Version: <version>
## Date: <date>

### Pre-Build Verification
- [ ] Directory structure correct
- [ ] configuration.nix syntax valid
- [ ] default.nix syntax valid
- [ ] All required files present
- [ ] Service catalog entry exists
- [ ] Overlays entry exists
- [ ] Flake.nix entry exists

### Build Verification
- [ ] Build succeeds
- [ ] No errors
- [ ] Build time: <X> seconds
- [ ] Result directory valid

### Runtime Verification
- [ ] Docker load succeeds
- [ ] Docker inspect shows correct config
- [ ] Container starts
- [ ] Health check passes
- [ ] Functionality test passes

### Production Verification
- [ ] Non-root user: <UID>
- [ ] Capabilities: <list>
- [ ] Seccomp profile: <enabled/disabled>
- [ ] Read-only filesystem: <true/false>
- [ ] Image size: <X>MB
- [ ] Deterministic: <yes/no>
- [ ] Start time: <X> seconds
- [ ] Networking: <OK/FAIL>

### Service-Specific Tests
- [ ] Test 1: <description>
- [ ] Test 2: <description>
- [ ] Test 3: <description>

### Verification By
Name: _____________________
Date: _____________________
```

---

## OpenSpec Compliance Matrix

Each migrated service must comply with the following OpenSpec requirements:

| Requirement | Description | Verification Method | Status |
|-------------|-------------|---------------------|--------|
| FR-BUILD-001 | Docker image build for service | Build test | ✅ |
| FR-BUILD-002 | Nix flakes for reproducible builds | Flake check | ✅ |
| FR-BUILD-003 | Multi-architecture builds | Build for amd64+arm64 | ⚪ |
| FR-BUILD-004 | OCI-compliant images | OCI validation | ✅ |
| FR-BUILD-005 | Build cache support | Cache check | ✅ |
| FR-BUILD-006 | Build dependencies | Dependency check | ✅ |
| FR-BUILD-007 | Build verification | Build test | ✅ |
| FR-IMAGE-001 | Non-root user | User check | ✅ |
| FR-IMAGE-002 | Dropped capabilities | Capability check | ✅ |
| FR-IMAGE-003 | Seccomp profiles | Seccomp check | ✅ |
| FR-IMAGE-004 | Read-only root filesystem | Filesystem check | ⚪ |
| FR-IMAGE-005 | Minimal base images | Package check | ✅ |
| FR-IMAGE-006 | User namespace isolation | Namespace check | ✅ |
| FR-IMAGE-007 | OCI labels | Label check | ✅ |
| FR-IMAGE-008 | Health checks | Health check | ✅ |
| FR-IMAGE-009 | Image signing | Signature check | ⚪ |

**All migrated services must achieve 100% compliance (48/48 requirements).**

---

## Links

- [Migration Pipeline](MIGRATION-PIPELINE.md)
- [Migration Checklist](CHECKLIST.md)
- [Scan Existing Services](SCAN-EXISTING-SERVICES.sh)
- [Finalize Migration](finalize-migration.sh)
- [Test Migration](test-migration.sh)
