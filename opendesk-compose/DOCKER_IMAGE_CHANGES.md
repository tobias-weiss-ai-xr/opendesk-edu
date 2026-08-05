# Docker Image Changes - 2026-02-11

## Summary
Fixed private image access issues by replacing with public alternatives.

## Changes Made

### 1. OpenCloud Service
**Problem:** `ghcr.io/opencloud-eu/server:latest` is a private GitHub Container Registry image that requires authentication.

**Solution:** Replaced with public Docker Hub image:
```yaml
# OLD:
image: ghcr.io/opencloud-eu/server:latest

# NEW:
image: opencloudeu/opencloud:latest
```

**Details:**
- Source: https://github.com/opencloud-eu/opencloud
- Docker Hub: https://hub.docker.com/r/opencloudeu/opencloud
- License: Apache 2.0 (Open Source)
- Stars: 4777+ on GitHub

### 2. MOX Service
**Problem:** `glinds/mox:v1.3.0` image does not exist or requires authentication.

**Solution:** Replaced with official registry image:
```yaml
# OLD:
image: glinds/mox:v1.3.0

# NEW:
image: r.xmox.nl/mox:latest
```

**Details:**
- Official Registry: https://r.xmox.nl/r/mox/
- GitHub: https://github.com/mjl-/mox
- License: MIT (Open Source)
- Stars: 5457+ on GitHub
- Latest version: v0.0.11

## Authentication Status

### Docker Credentials Checked
- `~/.docker/config.json` only contains auth for Docker Hub (`index.docker.io/v1/`)
- No credentials for `ghcr.io` (GitHub Container Registry)

## Recommendations

1. **For Production:**
   - Use versioned tags instead of `:latest` (e.g., `opencloudeu/opencloud:5.0.0`)
   - Pin specific versions for stability and reproducibility

2. **For OpenCloud:**
   - Consider building from source if customizations are needed
   - Docker Hub images are maintained by the project maintainers

3. **For MOX:**
   - The official registry `r.xmox.nl` provides versioned releases
   - Use `r.xmox.nl/mox:v0.0.11` for latest stable release

## Related Documentation
- OpenCloud Installation: https://github.com/opencloud-eu/opencloud-compose
- MOX Installation: https://www.xmox.nl/install/
- MOX Docker Compose: https://github.com/mjl-/mox/blob/main/docker-compose.yml

## Verification Steps
After changes:
1. Validate docker-compose.yml: `docker-compose config`
2. Test image pull: `docker pull opencloudeu/opencloud:latest`
3. Test image pull: `docker pull r.xmox.nl/mox:latest`
4. Start services: `docker-compose up -d`
