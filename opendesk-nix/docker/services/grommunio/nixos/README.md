# grommunio NixOS Container

## Version: latest

### OpenSpec Compliance
- FR-BUILD-001: Docker image build for service
- FR-BUILD-002: Nix flakes for reproducible builds  
- FR-BUILD-003: Multi-architecture builds (amd64, arm64)
- FR-BUILD-004: OCI-compliant images
- FR-IMAGE-001: Non-root user
- FR-IMAGE-007: OCI labels
- FR-IMAGE-009: Health checks

---

## Quick Start

### Build the container
cd opendesk-nix
nix build .#grommunio-nixos

### Load into Docker
docker load < result

### Run the container
docker run -d --name grommunio \
  -p 8080:8080 \
  grommunio-opendesk:latest-nixos

---

## Configuration

Edit configuration.nix to configure:
- Services configuration
- User settings
- Directory permissions
- Service-specific settings

---

## Secrets Management

1. Edit secrets.yaml with your credentials
2. Encrypt: sops --encrypt --age age1... secrets.yaml > secrets.enc.yaml
3. Reference in secrets.nix

---

## License
Apache-2.0
