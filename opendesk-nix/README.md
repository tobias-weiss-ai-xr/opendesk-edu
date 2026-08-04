# openDesk-Nix

> **Nix flakes for openDesk container images and Kubernetes deployments**

**Registry:** `registry.gitlab.opencode.de/umr/`  
**Status:** Production Ready  
**Maintenance:** openDesk Edu Team

---

## 🚀 Quick Start

### **Build SOGo 5 & 6 Images**
```bash
# Install Nix (if not installed)
curl -L https://nixos.org/nix/install | sh

# Enable flakes
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Build all images
nix build .#sogo5-image .#sogo6-image .#dev-agent-image

# Load into Docker
docker load < result

# Tag and push (after login)
docker tag $(docker images -q | head -1) registry.gitlab.opencode.de/umr/sogo6:latest
docker push registry.gitlab.opencode.de/umr/sogo6:latest
```

### **Deploy to Kubernetes**
```bash
# Login to registry
export OPENCODE_TOKEN="your-pat"
echo "$OPENCODE_TOKEN" | docker login registry.gitlab.opencode.de -u weiss --password-stdin

# Create pull secret
kubectl apply -f k8s/gitlab-registry-secret.yaml

# Deploy SOGo 5
kubectl apply -k k8s/sogo5

# Deploy SOGo 6
kubectl apply -k k8s/sogo6

# Deploy Dev Agent
kubectl apply -k k8s/dev-agent
```

---

## 📦 Available Images

| Image | Description | Nix Flake | Docker Image |
|-------|-------------|-----------|--------------|
| **sogo5** | SOGo 5 Groupware | `.#sogo5-image` | `registry.gitlab.opencode.de/umr/sogo5:latest` |
| **sogo6** | SOGo 6 Groupware | `.#sogo6-image` | `registry.gitlab.opencode.de/umr/sogo6:latest` |
| **dev-agent** | Dev Agent Operator | `.#dev-agent-image` | `registry.gitlab.opencode.de/umr/dev-agent:latest` |
| **website** | Next.js Website | `.#website-image` | `registry.gitlab.opencode.de/umr/opendesk-edu-website:latest` |
| **sbom-generator** | SBOM Tools | `.#sbom-generator-image` | `registry.gitlab.opencode.de/umr/sbom-generator:latest` |

---

## 📁 Repository Structure

```
opendesk-nix/
├── README.md                    # This file
├── flake.nix                    # Main flake - builds all images
├── flake.lock                   # Lock file
│
├── sogo/
│   └── flake.nix               # SOGo 5 & 6 Docker images
│
├── dev-agent/
│   └── flake.nix               # Dev Agent Docker image
│
├── k8s/                         # Kubernetes deployments
│   ├── sogo5/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── pvc.yaml
│   │   └── kustomization.yaml
│   ├── sogo6/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── configmap.yaml
│   │   ├── pvc.yaml
│   │   └── kustomization.yaml
│   └── dev-agent/
│       ├── deployment.yaml
│       ├── rbac.yaml
│       └── kustomization.yaml
│
├── OPENCODE_DE_PUSH_GUIDE.md    # Complete push guide
└── push-to-gitlab.sh           # Push script (symlink to ../../../)
```

---

## 📚 Libraries

This project includes comprehensive Nix libraries for building, securing, and deploying containerized applications:

| Library | Purpose | OpenSpec Compliance |
|---------|---------|---------------------|
| `lib/k8s.nix` | Kubernetes resource builders | FR-K8S-001 - FR-K8S-010 |
| `lib/security.nix` | Security hardening presets (8 profiles) | FR-IMAGE-001, 002, 003, 005 |
| `lib/sbom.nix` | SBOM generation (SPDX + CycloneDX) | FR-SEC-002 |
| `lib/registry.nix` | Multi-registry support (GHCR, GitLab, Zot) | FR-DEPLOY-003 |
| `lib/types.nix` | Type definitions | All |
| `lib/build.nix` | Docker/OCI image building | FR-BUILD-001 - FR-BUILD-007 |
| `lib/security-scanning.nix` | Vulnerability scanning (Grype, Trivy, Snyk) | FR-SEC-001, FR-SEC-004 |
| `lib/cosign.nix` | Image signing and verification | FR-SEC-003, FR-SEC-004 |
| `lib/cicd.nix` | CI/CD pipelines (GitHub Actions, GitLab CI) | FR-CICD-001 - FR-CICD-006 |
| `lib/dev.nix` | Development environments and IDE integration | FR-DEV-001, FR-DEV-002, FR-DEV-004 |

**Usage Example:**
```nix
{ pkgs, lib, ... }:
let
  k8s = lib.k8s;
  security = lib.security;
  registry = lib.registry;
  types = lib.types;
  sbom = lib.sbom;
  build = lib.build;
  scanning = lib.security-scanning;
  cosign = lib.cosign;
  cicd = lib.cicd;
  dev = lib.dev;
in {
  # Kubernetes deployment with security
  deployment = k8s.deployment {
    name = "my-app";
    image = "my-image";
    securityContext = security.mkContainerSecurityContext { profile = "web"; };
    ociLabels = k8s.mkOCILabels { name = "my-app"; version = "1.0.0"; };
  };
  
  # Build a Docker image
  myImage = build.docker.mkServiceImage { serviceName = "mariadb"; version = "11.4.4"; };
  
  # Scan for vulnerabilities
  scanResult = scanning.scanImage { image = "my-image:latest"; scanner = "grype"; };
  
  # Sign with Cosign
  signedImage = cosign.withSigning myImage;
  
  # Development shell
  devShell = dev.shells.forService { serviceName = "mariadb"; };
}
```

---

## 🎯 Dependencies

- [Nix](https://nixos.org/download.html) (v2.10+ recommended)
- [Docker](https://docs.docker.com/get-docker/) (for image building)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for K8s deployment)
- [jq](https://stedolan.github.io/jq/) (for JSON processing in scripts)

---

## 🔧 Configuration

### **Flake Configuration**

All flakes support the following inputs:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  flakes-utils.url = "github:numtide/flakes-utils";
};
```

### **Customizing Images**

Edit the respective `flake.nix` files:
- `sogo/flake.nix` - For SOGo configuration
- `dev-agent/flake.nix` - For Dev Agent configuration

Example - Add packages to SOGo 6:
```nix
# In sogo/flake.nix
contents = with pkgs; [
  sogo6
  postgresql
  mysql
  memcached
  # Add your packages here
  custom-package
];
```

---

## 🚀 Usage Examples

### **Build Single Image**
```bash
nix build .#sogo6-image
```

### **Build All Images**
```bash
nix build .#sogo5-image .#sogo6-image .#dev-agent-image
```

### **Enter Development Shell**
```bash
nix develop
```

### **Update Inputs**
```bash
nix flake update
```

### **Check Available Packages**
```bash
nix flake show
```

---

## 📦 GitLab Container Registry

### **Login**
```bash
export OPENCODE_TOKEN="your-personal-access-token"
echo "$OPENCODE_TOKEN" | docker login registry.gitlab.opencode.de -u weiss --password-stdin
```

### **Push Image**
```bash
# Tag image
docker tag image-id registry.gitlab.opencode.de/umr/image-name:latest

# Push
docker push registry.gitlab.opencode.de/umr/image-name:latest
```

### **Pull Image**
```bash
docker pull registry.gitlab.opencode.de/umr/image-name:latest
```

---

## 🔐 Kubernetes Setup

### **Create Pull Secret**
```bash
kubectl create secret docker-registry gitlab-registry-opencode \
  --docker-server=registry.gitlab.opencode.de \
  --docker-username=weiss \
  --docker-password=$OPENCODE_TOKEN \
  --docker-email=your@email.de
```

### **Save Pull Secret**
```bash
kubectl get secret gitlab-registry-opencode -o yaml > k8s/gitlab-registry-secret.yaml
```

### **Deploy with Kustomize**
```bash
# SOGo 5
kubectl apply -k k8s/sogo5

# SOGo 6
kubectl apply -k k8s/sogo6

# Dev Agent
kubectl apply -k k8s/dev-agent

# All
kubectl apply -k k8s/
```

### **Verify Deployment**
```bash
kubectl get pods -n opendesk
kubectl get deployments -n opendesk
kubectl get services -n opendesk
```

---

## 🏗️ CI/CD Integration

### **GitHub Actions**

Create `.github/workflows/nix-build.yml`:

```yaml
name: Nix Build

on:
  push:
    branches: [main]
    tags: ['v*']
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Nix
        uses: cachix/install-nix-action@v22
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Enable Flakes
        run: |
          mkdir -p ~/.config/nix
          echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

      - name: Build Images
        run: |
          nix build .#sogo5-image
          nix build .#sogo6-image
          nix build .#dev-agent-image

      - name: Load Docker Images
        run: |
          docker load < result
          docker images

      - name: Login to GitLab Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v2
        with:
          registry: registry.gitlab.opencode.de
          username: weiss
          password: ${{ secrets.OPENCODE_DE_TOKEN }}

      - name: Push Images
        if: github.event_name != 'pull_request'
        run: |
          # SOGo 5
          docker tag $(docker images -q | head -1) registry.gitlab.opencode.de/umr/sogo5:latest
          docker push registry.gitlab.opencode.de/umr/sogo5:latest
          
          # SOGo 6
          # docker tag ... sogo6:latest
          # docker push ... sogo6:latest
          
          # Dev Agent
          # docker tag ... dev-agent:latest
          # docker push ... dev-agent:latest
```

---

## 🐛 Troubleshooting

### **Nix Build Issues**

| Issue | Solution |
|-------|----------|
| `flakes not enabled` | Add `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf` |
| `nixpkgs not found` | Run `nix flake update` |
| `build failed` | Check the error message and adjust the flake |
| `out of memory` | Increase system memory or use `--max-jobs 1` |

### **Docker Issues**

| Issue | Solution |
|-------|----------|
| `login failed` | Verify your PAT token is correct |
| `push denied` | Check your token has `write_registry` scope |
| `image not found` | Build the image first with `nix build` |

### **Kubernetes Issues**

| Issue | Solution |
|-------|----------|
| `ImagePullBackOff` | Create ImagePullSecret: `kubectl apply -f k8s/gitlab-registry-secret.yaml` |
| `CrashLoopBackOff` | Check logs: `kubectl logs -n opendesk <pod-name>` |
| `Pending` | Check PVC or resource availability |

---

## 📚 Resources

- [Nix Documentation](https://nixos.org/manual/nix/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📜 License

Apache-2.0 - See [LICENSE](../../LICENSE)

---

## 📞 Support

- **Matrix:** `#opendesk-ce-public:matrix.uni-marburg.de`
- **Email:** info@opendesk-edu.org
- **GitHub:** [opendesk-edu/opendesk-nix](https://github.com/opendesk-edu/opendesk-nix)
- **GitLab:** [tbsweiss/opendesk-nix](https://gitlab.com/tbsweiss/opendesk-nix)
- **opencode.de:** [umr/opendesk-nix](https://gitlab.opencode.de/umr/opendesk-nix)

---

## 🏁 Summary

**This repository contains everything you need to:**

1. ✅ **Build** Docker images for SOGo 5, SOGo 6, Dev Agent using Nix
2. ✅ **Push** images to GitLab Container Registry (opencode.de)
3. ✅ **Deploy** to Kubernetes using Kustomize
4. ✅ **Maintain** reproducible, declarative infrastructure

**Get started:** `nix build .#sogo6-image`

---

> **"With Nix, if it builds on your machine, it builds everywhere."**

> **"With GitLab Container Registry, you own your artifacts."**

> **"With Kustomize, deployment is declarative and repeatable."**
