# Nix-based Kubernetes Deployment for openDesk Edu

## Quick Start

```bash
# Build a single service
nix build .#kubernetes.mariadb
cat result  # → YAML manifest (Deployment + Service)

# Build ALL 12 services
nix build .#kubernetes-all
ls result/  # → 12 YAML files + kustomization.yaml

# Apply all to cluster
nix run .#apply

# Dev shell with tools
nix develop
```

## Services (12)

| Service | Image | Type |
|---------|-------|------|
| mariadb | ghcr.io/opendesk-edu/mariadb:11.4.4 | StatefulSet |
| ilias | ghcr.io/opendesk-edu/ilias-shibboleth:9-php8.2-apache | Deployment |
| moodle | ghcr.io/opendesk-edu/moodle-shib:v1.4.0 | Deployment |
| bookstack | ghcr.io/opendesk-edu/bookstack:v26.05.2-ls276 | Deployment |
| drawio | ghcr.io/opendesk-edu/drawio:latest | Deployment |
| excalidraw | ghcr.io/opendesk-edu/excalidraw:latest | Deployment |
| planka | ghcr.io/opendesk-edu/planka:latest | Deployment |
| self-service-password | ghcr.io/opendesk-edu/self-service-password:latest | Deployment |
| code-server | ghcr.io/opendesk-edu/code-server:latest | Deployment |
| rstudio | ghcr.io/opendesk-edu/rstudio:latest | Deployment |
| ttyd | ghcr.io/opendesk-edu/ttyd:latest | Deployment |
| slidev | ghcr.io/opendesk-edu/slidev:latest | Deployment |

## Compared to Helmfile

| Aspect | Helmfile | Nix |
|--------|----------|-----|
| Template engine | Go templates | Nix expressions |
| Deterministic | No (side effects) | Yes (pure evaluation) |
| Caching | No | Yes (Nix store) |
| Error messages | "failed to render" | Build failure at eval time |
| Secrets | SOPS + helmfile | sops-nix |
| Locking | Chart.lock | flake.lock |

## Adding a new service

1. Add a `nix/k8s/<name>.nix` file
2. Add the name to the `services` list in `flake.nix`
3. Run `nix build .#kubernetes.<name>`
