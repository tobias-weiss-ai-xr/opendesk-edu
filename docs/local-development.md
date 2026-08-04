# Local Development Environment

## Prerequisites

### Required Tools

- **Docker Desktop** - For local containerized development
- **kubectl** - Kubernetes CLI for cluster management
- **Helm 3.16+** - Package manager for Kubernetes
- **helmfile** - Declarative deployment for Helm charts
- **Make** - Build automation
- **Python 3.12** - For linting tools
- **Node.js 20+** - For documentation spellcheck

### Installation

#### macOS (Homebrew)

```bash
brew install docker-desktop
brew install kubectl
brew install helm
brew install helmfile
brew install python
brew install node
```

#### Ubuntu/Debian

```bash
# Docker Desktop
wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.32.0-amd64.deb
sudo apt install ./docker-desktop-4.32.0-amd64.deb

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# helmfile
wget -O- -q https://github.com/helmfile/helmfile/releases/download/v0.168.0/helmfile_0.168.0_linux_amd64.tar.gz | tar xz
sudo mv helmfile /usr/local/bin/

# Python, Node.js
sudo apt install python3 python3-pip nodejs npm
```

#### Windows (winget/powershell)

```powershell
# Docker Desktop
winget install Docker.DockerDesktop

# kubectl
winget install Kubernetes.kubectl

# Helm
winget install Kubernetes.Helm

# helmfile
winget install helmfile

# Python
winget install Python.Python.3.12

# Node.js
winget install OpenJS.NodeJS
```

## Local Cluster Setup

### Option 1: Kind (Recommended)

```bash
# Install kind
go install sigs.k8s.io/kind@v0.24.0
kind create cluster --name opendesk-edu
```

### Option 2: Minikube

```bash
# Install minikube
winget install Kubernetes.minikube
minikube start
```

### Option 3: Docker Desktop Kubernetes

- Enable Kubernetes in Docker Desktop settings
- Set as default context: `kubectl config use-context docker-desktop`

## Development Workflow

### 1. Configure Environment

```bash
# Copy environment template
cp helmfile/environments/default/global.yaml.gotmpl \
   helmfile/environments/default/global.yaml

# Edit configuration for local testing
nano helmfile/environments/default/global.yaml
```

### 2. Install Dependencies

```bash
# Download chart dependencies
cd helmfile
helmfile deps
```

### 3. Test Charts

```bash
# Run all tests (lint + template + unit tests)
make test

# Run individual tests
make lint      # Helm linting
make template  # Template validation
make yamllint  # YAML linting
make spellcheck # Documentation spellcheck
```

### 4. Deploy Locally

```bash
# Dry-run to see what would be deployed
helmfile -e default apply --diff

# Deploy to local cluster
helmfile -e default apply

# Check deployment status
kubectl get pods -A
kubectl get svc -A
```

### 5. Access Services

```bash
# Port-forward to a service (example)
kubectl port-forward svc/keycloak 8080:8080 -n keycloak

# Get ingress URLs (if configured)
kubectl get ingress -A
```

## Troubleshooting

### Helm/ helmfile Issues

```bash
# Verify helmfile syntax
helmfile -e default template

# Debug helmfile with verbose output
helmfile -e default apply --debug
```

### Cluster Issues

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# View pod logs
kubectl logs -f <pod-name> -n <namespace>

# Descriptions
kubectl describe pod <pod-name> -n <namespace>
```

### Resource Issues

```bash
# Increase Docker Desktop resource allocation
# Settings > Resources > CPUs/Memory

# Check pod resource usage
kubectl top pods -A
```

## Development Scripts

The `scripts/` directory contains utility scripts:

- `scripts/user_import/` - User provisioning tooling
- `scripts/maintenance/` - Backup/restore operations

## IDE Setup

### VS Code Extensions

- [Helm Intellisense](https://marketplace.visualstudio.com/items?itemName=technosophos.helm-vscode)
- [Kubernetes](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)
- [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)

## Next Steps

- [Getting Started Guide](./getting-started.md)
- [Configuration](./enhanced-configuration.md)
- [Testing Guide](./testing.md)
