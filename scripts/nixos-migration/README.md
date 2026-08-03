# NixOS Container Migration Tools

This directory contains scripts and tools for migrating Dockerfile-based services to NixOS containers.

## Overview

The goal is to migrate all 69 openDesk services from Dockerfile-based builds to NixOS container builds:

- **Deterministic Runtime**: All packages and dependencies come from `nixpkgs`
- **Reproducible Builds**: Nix ensures identical builds every time
- **Security**: Automatic hardening with seccomp, capabilities, read-only filesystems
- **Compliance**: Full OpenSpec compliance (FR-BUILD-001 through FR-BUILD-007)

## Migration Strategy

### Phase 1: Pilot ✅ Complete
- ✅ Mariadb 11.4.4

### Phase 2: Core Services ✅ Complete
- ✅ PostgreSQL 16.3
- ✅ Redis 7.2.4
- ✅ Nginx 1.25.3
- ✅ Traefik v2.10.0
- ✅ Keycloak 24.0.0

### Phase 3: LMS Services 🔄 In Progress
- Moodle 4.4.0
- ILIAS 8.0.0
- Nextcloud 29.0.0

### Phase 4: Collaboration Tools
- Collabora 22.05.0
- Planka 1.0.0
- Etherpad 1.9.0
- CryptPad 5.0.0
- DrawIO 21.0.0
- Excalidraw 0.17.0

### Phase 5: All Other Services
- OpenProject 14.0.0
- Rocket.Chat 6.0.0
- Element 1.11.0
- Jitsi 8.0.0
- BookStack v26.05.2
- XWiki 15.0.0
- Grafana 10.0.0
- Prometheus 2.47.0
- Docker Registry 2.8.0
- Zot Registry 2.0.0
- And 50+ more...

## Directory Structure

```
scripts/nixos-migration/
├── migrate-service.sh      # Single service migration (bash)
├── migrate-service.py      # Dockerfile to Nix converter (python)
├── batch-migrate.sh        # Batch migration for multiple services
└── README.md               # This file
```

Each service after migration:
```
opendesk-nix/docker/services/<service>/nixos/
├── configuration.nix       # NixOS system configuration
├── default.nix             # Docker image definition
├── secrets.nix             # sops-nix secrets configuration
└── README.md               # Service documentation
```

## Quick Start

### Migrate a Single Service

```bash
# Basic usage
./scripts/nixos-migration/migrate-service.sh <service-name> [version]

# Example: Migrate moodle
./scripts/nixos-migration/migrate-service.sh moodle 4.4.0
```

### Using the Python Converter

```bash
# Convert Dockerfile to NixOS configuration
python3 scripts/nixos-migration/migrate-service.py \
    opendesk-nix/docker/services/moodle/Dockerfile \
    moodle \
    4.4.0
```

### Batch Migration

```bash
# Migrate all pending services (recommended)
./scripts/nixos-migration/batch-migrate.sh --pending

# Migrate specific services
./scripts/nixos-migration/batch-migrate.sh moodle ilias nextcloud

# Migrate ALL services
./scripts/nixos-migration/batch-migrate.sh --all
```

## Manual Migration Steps

If you prefer to migrate manually, follow these steps:

### 1. Create Directory Structure

```bash
mkdir -p opendesk-nix/docker/services/<service>/nixos
mkdir -p opendesk-nix/docker/services/<service>/secrets
```

### 2. Create `configuration.nix`

```nix
{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [ (import ../../../../../overlays/opendesk.nix) ];
  
  services.<service> = {
    enable = true;
    package = pkgs.opendeskPackages.<service>;
    port = <port>;
  };
  
  users.users.<user> = {
    isSystemUser = true;
    uid = 1000;
    group = "<group>";
  };
  
  system.stateVersion = "23.11";
}
```

### 3. Create `default.nix`

```nix
{ pkgs, docks, ... }:

docks.mkImage {
  name = "<service>-opendesk";
  tag = "<version>-nixos";
  config = import ./configuration.nix { inherit pkgs; };
  containerConfig = {
    ExposedPorts = { "<port>/tcp" = {}; };
    Volumes = { "/var/lib/<service>" = {}; };
    User = "<user>";
    Cmd = [ "${pkgs.opendeskPackages.<service>}/bin/<service>" ];
  };
}
```

### 4. Add Package to Overlays

Edit `opendesk-nix/overlays/opendesk.nix`:

```nix
opendeskPackages = {
  <service> = super.<service>.overrideAttrs (old: rec {
    version = "<version>";
    pname = "<service>-opendesk";
    # Add custom source or patches here
  });
};
```

### 5. Add to Service Catalog

Edit `opendesk-nix/lib/nixos/services.nix`:

```nix
services = rec {
  <service> = mkService {
    name = "<service>";
    version = "<version>";
    description = "<description>";
    category = "<category>";
    tier = "<tier>";
    ports = [ <port> ];
    configPath = ./docker/services/<service>/nixos/configuration.nix;
    defaultNixPath = ./docker/services/<service>/nixos/default.nix;
  };
};
```

### 6. Update flake.nix

Edit `opendesk-nix/flake.nix`:

```nix
packages = {
  inherit (all-containers) <service>-nixos;
};
```

### 7. Add Secrets Support

Create `secrets.yaml`:

```yaml
<service>:
  password: "CHANGE_ME"
  api-key: "CHANGE_ME"
```

Encrypt with sops:

```bash
sops --encrypt --age age1... secrets.yaml > secrets.enc.yaml
```

Update `secrets.nix`:

```nix
{ config, ... }:
{
  services.<service> = {
    password = config.sops.secrets.<service>-password or "";
    apiKey = config.sops.secrets.<service>-api-key or "";
  };
}
```

### 8. Test the Build

```bash
cd opendesk-nix
nix build .#<service>-nixos
```

### 9. Load and Test Container

```bash
docker load < result
docker run -d --name <service> -p <port>:<port> <service>-opendesk:<version>-nixos
```

## Tips & Best Practices

### 1. Package Naming

- Follow the pattern: `<service>-opendesk:<version>-nixos`
- Example: `mariadb-opendesk:11.4.4-nixos`

### 2. User and Group IDs

- Use UID/GID 1000+ for application users
- Use UID 999 for database/cache services
- Use GID matching the user

### 3. Directory Structure

```
/var/lib/<service>    # Data directory
/var/log/<service>    # Log directory
/etc/<service>        # Configuration directory
/var/run/<service>    # PID/socket directory
```

### 4. Health Checks

```nix
HealthCheck = {
  Test = [ "CMD-SHELL" "curl -f http://127.0.0.1:<port>/healthz 2>/dev/null || exit 1" ];
  Interval = 10000000000;  # 10s
  Timeout = 5000000000;   # 5s
  Retries = 3;
  StartPeriod = 30000000000; # 30s
};
```

### 5. OCI Labels

```nix
ociLabels = {
  "org.opencontainers.image.title" = "<service>-opendesk";
  "org.opencontainers.image.version" = "<version>-nixos";
  "com.opendesk.service" = "<service>";
  "com.opendesk.nixos" = "true";
};
```

## Common Patterns

### Database Services

```nix
# configuration.nix
{
  services.<database> = {
    enable = true;
    package = pkgs.opendeskPackages.<database>;
    port = <port>;
    ensureDatabases = [ "<db1>" "<db2>" ];
    ensureUsers = [ ... ];
  };
  
  users.users.<user> = {
    isSystemUser = true;
    uid = 999;
  };
}
```

### Web Services

```nix
# configuration.nix
{
  services.<web> = {
    enable = true;
    package = pkgs.opendeskPackages.<web>;
    port = <port>;
    workingDir = "/var/www/<web>";
  };
  
  users.users.www-data = {
    isSystemUser = true;
    uid = 1000;
  };
  
  system.activationScripts.setup = ''
    mkdir -p /var/www/<web> /var/log/<web>
    chown -R www-data:www-data /var/www/<web> /var/log/<web>
  '';
}
```

### Java Services

```nix
# configuration.nix
{
  environment.systemPackages = [
    pkgs.opendeskPackages.jdk21
  ];
  
  services.<service> = {
    enable = true;
    jvmOptions = [
      "-Xms1024m"
      "-Xmx2048m"
      "-Djava.awt.headless=true"
    ];
  };
  
  users.users.<user> = {
    isSystemUser = true;
    uid = 1000;
  };
}
```

## Troubleshooting

### Build Errors

**Error: Package not found in nixpkgs**

Solution: Add the package to `opendesk-nix/overlays/opendesk.nix`

**Error: Hash mismatch**

Solution: Update the sha256 hash with the correct one:
```bash
nix-prefetch-url --unpack "https://example.com/package.tar.gz"
```

### Runtime Errors

**Error: Permission denied**

Solution: Ensure correct user/group ownership:
```nix
system.activationScripts.setup = ''
  mkdir -p /var/lib/<service>
  chown -R <user>:<group> /var/lib/<service>
'';
```

**Error: File or directory not found**

Solution: Create required directories in `system.activationScripts`

### Health Check Failures

**Error: Health check never passes**

Solution: Increase `StartPeriod`:
```nix
StartPeriod = 60000000000; # 60s
```

**Error: Health check command not found**

Solution: Ensure the command is in PATH or use full path:
```nix
Test = [ "CMD-SHELL" "${pkgs.curl}/bin/curl -f http://127.0.0.1/healthz" ];
```

## Performance Optimization

### Reduce Image Size

1. **Use minimal base packages**: Only include what you need
2. **Remove build dependencies**: Use `nativeBuildInputs` for build-time only
3. **Use `dontUnpack`**: For packages that don't need unpacking
4. **Use `modules lebte`**: For packages

```nix
# Example: Minimal Redis image
{
  services.redis = {
    enable = true;
    package = pkgs.redis;
  };
  
  # Only include essential packages
  environment.systemPackages = [
    pkgs.redis
    pkgs.openssl
  ];
}
```

### Enable Caching

```nix
# In nix.conf
substituters = https://cache.nixos.org https://opendesk.cache.zci.rocks
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= opendesk:...
```

### Multi-Architecture Builds

```nix
# In flake.nix
outputs = { self, nixpkgs, ... }@inputs:
  flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: {
    packages.${system}.<service>-nixos = ...;
  });
```

## Verification

### Check OpenSpec Compliance

```bash
# Verify all requirements
python3 scripts/verify-compliance.py

# Verify specific service
nix eval .#checks.IMAGE-007
```

### Test Container Functionality

```bash
# Build and run
docker load < result
docker run -d --name test-<service> -p <port>:<port> <service>-opendesk:<version>-nixos

# Test connection
curl http://127.0.0.1:<port>/healthz

# Clean up
docker stop test-<service> && docker rm test-<service>
```

### Check Image Size

```bash
docker images | grep <service>-opendesk
dive <service>-opendesk:<version>-nixos
```

## Contributing

When adding new migration scripts:

1. Follow the existing naming convention
2. Include SPDX headers
3. Document usage in README.md
4. Add tests if applicable
5. Update the service catalog

## License

All scripts are licensed under Apache-2.0, as indicated by the SPDX headers.

## Links

- [NixOS Manual](https://nixos.org/manual/)
- [docks.nix Documentation](https://github.com/dockernix/docks.nix)
- [Nixpkgs Repository](https://github.com/NixOS/nixpkgs)
- [openDesk Documentation](https://opendesk.hrz.uni-marburg.de/docs)
- [OpenSpec Documentation](https://openspec.dev/)
