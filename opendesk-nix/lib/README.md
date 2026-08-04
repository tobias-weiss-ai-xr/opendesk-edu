# OpenDesk Nix Libraries

This directory contains all Nix libraries for the openDesk platform.

## Library Overview

| Library | Purpose | OpenSpec Compliance |
|---------|---------|---------------------|
| [`types.nix`](./types.nix) | Type definitions for the entire codebase | Core |
| [`security.nix`](./security.nix) | Security hardening presets (8 profiles) | FR-IMAGE-001, 002, 003, 005 |
| [`sbom.nix`](./sbom.nix) | SBOM generation (SPDX + CycloneDX) | FR-SEC-002 |
| [`registry.nix`](./registry.nix) | Multi-registry support (GHCR, GitLab, Zot) | FR-DEPLOY-003 |
| [`k8s.nix`](./k8s.nix) | Kubernetes resource builders | FR-K8S-001 - FR-K8S-010 |
| [`build.nix`](./build.nix) | Docker/OCI image building system | FR-BUILD-001 - FR-BUILD-007 |
| [`security-scanning.nix`](./security-scanning.nix) | Vulnerability scanning (Grype, Trivy, Snyk) | FR-SEC-001, FR-SEC-004 |
| [`cosign.nix`](./cosign.nix) | Image signing and verification | FR-SEC-003, FR-SEC-004 |
| [`cicd.nix`](./cicd.nix) | CI/CD pipeline configurations | FR-CICD-001 - FR-CICD-006 |
| [`dev.nix`](./dev.nix) | Development environments and IDE integration | FR-DEV-001, FR-DEV-002, FR-DEV-004 |
| [`tests.nix`](./tests.nix) | Compliance test suite | Verification |

---

## Usage

### In a Nix Expression

```nix
{ pkgs, ... }:
let
  lib = import ./lib { pkgs = pkgs; };
  
  # Access individual libraries
  k8s = lib.k8s;
  security = lib.security;
  sbom = lib.sbom;
  registry = lib.registry;
  types = lib.types;
  build = lib.build;
  scanning = lib.security-scanning;
  cosign = lib.cosign;
  cicd = lib.cicd;
  dev = lib.dev;
in {
  # Use libraries...
}
```

### In a Flake

```nix
outputs = { self, nixpkgs, ... }:
  let
    lib = import ./lib { pkgs = nixpkgs.legacyPackages.x86_64-linux; };
  in {
    packages = {
      my-package = lib.build.docker.mkServiceImage {
        serviceName = "mariadb";
        version = "11.4.4";
      };
    };
    
    devShells.default = lib.dev.shells.default;
  };
```

---

## Library Details

### types.nix

Provides type definitions for consistent code across all libraries.

**Key Functions:**
- `Types` - Attribute set of all type definitions

### security.nix

Defines security profiles and helper functions for container security.

**Key Features:**
- 8 security profiles: default, web, database, cache, storage, lms, collaboration, monitoring
- `mkContainerSecurityContext()` - Automatic security context generation
- `mkPodSecurityContext()` - Pod-level security
- `mkPodSecurityAdmission()` - PSA labels
- CIS Kubernetes Benchmark compliance helpers

**Usage:**
```nix
security.mkContainerSecurityContext {
  profile = "database";
  readOnlyRootFilesystem = true;
}
```

### sbom.nix

Generates Software Bill of Materials (SBOM) for container images.

**Key Functions:**
- `generateSPDX()` - Generate SPDX 2.3 format SBOM
- `generateCycloneDX()` - Generate CycloneDX 1.4 format SBOM
- `generateFor()` - Generate SBOM for a derivation
- `sbomPipeline()` - Complete SBOM workflow
- `withSBOM()` - Add SBOM to a package

### registry.nix

Multi-registry support for container images.

**Key Functions:**
- `pushToRegistry()` - Push image to a single registry
- `pushAll()` - Push image to multiple registries
- `formatImageName()` - Format image name according to conventions
- `formatServiceImageName()` - Format service-specific image name

**Factories:**
- `ghcr()` - GitHub Container Registry
- `gitlab()` - GitLab Container Registry
- `zot()` - Zot registry
- `dockerHub()` - Docker Hub
- `quay()` - Quay.io
- `local()` - Local registry

### k8s.nix

Kubernetes resource builders with security and OCI integration.

**Resource Builders:**
- `deployment`, `statefulSet`, `daemonSet`, `pod`
- `service`, `headlessService`, `ingress`
- `configMap`, `secret`
- `persistentVolumeClaim`, `storageClass`
- `resourceQuota`, `limitRange`
- `horizontalPodAutoscaler`, `podDisruptionBudget`
- `networkPolicy`
- `certificate`, `issuer`, `clusterIssuer`
- `serviceAccount`

**OCI Integration:**
- `mkOCILabels()` - Generate OCI-compliant labels
- `mkOCILabelsBase()` - Base OCI labels
- `mkOCILabelsOpendesk()` - openDesk-specific labels

**Ingress Helpers:**
- `mkIngressLabels()` - Standard ingress labels
- `mkIngressWithTLS()` - Ingress with TLS configuration

**Probes:**
- `mkProbe()`, `mkHttpProbe()`, `mkTcpProbe()`, `mkCommandProbe()`

### build.nix

Complete build system for Docker/OCI images.

**Key Functions:**
- `mkServiceImage()` - Build a service image
- `buildFromDockerfile()` - Build from Dockerfile
- `buildFromNix()` - Build from Nix derivation
- `buildAllServices()` - Build all services
- `buildMultiArch()` - Multi-architecture builds

**Service Configurations:**
Pre-configured build configs for all openDesk services:
- `serviceBuildConfig.mariadb`
- `serviceBuildConfig.postgresql`
- `serviceBuildConfig.redis`
- `serviceBuildConfig.nextcloud`
- etc.

**Customization:**
- `customization.addPackage()` - Add custom package
- `customization.addEnv()` - Add environment variables
- `customization.overrideArgs()` - Override build arguments
- `customization.useCustomDockerfile()` - Use custom Dockerfile

**Flake Support:**
- `flake.mkFlakeOutput()` - Flake output for a service
- `flake.allOutputs()` - All service outputs
- `flake.exampleFlake` - Example flake.nix

**Migration Tools:**
- `migration.analyzeDockerfile()` - Analyze Dockerfile
- `migration.convertBuildCommand()` - Convert build command to Nix
- `migration.verifyCompatibility()` - Verify Dockerfile compatibility

### security-scanning.nix

Vulnerability scanning for container images.

**Scanners:**
- `scanWithGrype()` - Grype vulnerability scanner
- `scanWithTrivy()` - Trivy vulnerability scanner
- `scanWithSnyk()` - Snyk vulnerability scanner
- `scanImage()` - Generic scan function
- `scanInCI()` - Scan in CI/CD pipeline
- `scanMultiple()` - Scan multiple images

**Build Integration:**
- `withScanning()` - Add scanning to a package build

**Reporting:**
- `generateSecurityReport()` - Generate security report
- `scanResultsToCSV()` - Convert results to CSV

**Integrated Pipelines:**
- `scanAndGenerateSBOM()` - Scan and generate SBOM
- `securityPipeline()` - Complete security pipeline

### cosign.nix

Image signing and verification with Cosign.

**Key Functions:**
- `signImage()` - Sign a container image
- `signFile()` - Sign a local file
- `signWithSBOM()` - Sign with SBOM annotations
- `verifyImage()` - Verify image signature
- `verifyFile()` - Verify file signature
- `verifySBOM()` - Verify SBOM signature
- `signAndVerify()` - Sign and verify an image

**Build Integration:**
- `withSigning()` - Add signing to a package build
- `signAfterPush()` - Sign after pushing to registry

**Key Management:**
- `generateKeyPair()` - Generate Cosign key pair
- `getPublicKey()` - Get public key
- `getPrivateKey()` - Get private key
- `rotateKeys()` - Rotate signing keys

**Kubernetes Integration:**
- `mkVerifiedDeployment()` - Deployment with image verification
- `mkImagePolicy()` - Kubernetes ImagePolicy

**Certificate Management:**
- `generateFulcioCertificate()` - Generate Fulcio certificate

### cicd.nix

CI/CD pipeline configurations.

**GitHub Actions:**
- `githubActions.defaultConfig` - Default configuration
- `githubActions.mkServiceWorkflow()` - Workflow for single service
- `githubActions.mkMultiServiceWorkflow()` - Workflow for multiple services

**GitLab CI:**
- `gitlabCI.defaultConfig` - Default configuration
- `gitlabCI.mkServiceJob()` - Job for single service
- `gitlabCI.mkPipeline()` - Complete pipeline

**Build Triggers:**
- `buildTriggers.onCodeChange()` - Trigger on code changes
- `buildTriggers.onSchedule()` - Trigger on schedule
- `buildTriggers.onExternalTrigger()` - Trigger on external events
- `buildTriggers.onMergeRequest()` - Trigger on merge requests

**Delivery:**
- `delivery.mkPipeline()` - Complete CI/CD pipeline
- `delivery.mkReleasePipeline()` - Release pipeline with version bumping

### dev.nix

Development environments and tooling.

**Development Shells:**
- `shells.default` - Default shell with common tools
- `shells.minimal` - Minimal shell
- `shells.infrastructure` - Infrastructure development shell
- `shells.security` - Security-focused shell
- `shells.nix` - Nix development shell
- `shells.k8s` - Kubernetes development shell
- `shells.full` - Full openDesk shell
- `shells.forService()` - Shell for specific service
- `shells.forServices()` - Shell for multiple services
- `shells.mkDevShell()` - Create custom shell

**Flake Support:**
- `flake.devShells` - Dev shell outputs
- `flake.toolOverlay` - Tool overlay

**IDE Integration:**
- `ide.generateVSCodeSettings()` - VS Code settings.json
- `ide.generateVSCodeTasks()` - VS Code tasks.json
- `ide.generatePythonConfig()` - Python IDE config
- `ide.generateEditorConfig()` - .editorconfig file
- `ide.generateDirenvConfig()` - .envrc file

**Container-based Development:**
- `container.baseImage` - Base development image
- `container.devImage()` - Dev image with tools
- `container.forService()` - Dev image for service
- `container.composeConfig()` - Docker Compose config
- `container.podmanCompose()` - Podman Compose config
- `container.scripts` - Local dev scripts

**Port Mappings:**
- `container.containerPorts` - Standard service ports

**Remote Development:**
- `remote.codespacesConfig` - GitHub Codespaces config
- `remote.devpodConfig` - DevPod config

**Documentation:**
- `docs.setupGuide` - Development setup guide

---

## Dependencies

Libraries can depend on each other. The recommended import order is:

```nix
lib = import ./lib {
  pkgs = pkgs;
  # Optional dependencies (auto-imported if not provided)
  security = null;       # Will import ./security.nix
  sbom = null;            # Will import ./sbom.nix
  registry = null;       # Will import ./registry.nix
  # ... etc
};
```

---

## Testing

All libraries include a comprehensive test suite in `tests.nix`:

```bash
# Run all tests
nix eval .#lib-tests

# Check specific library
nix eval .#lib-tests.BUILD-001
```

---

## License

All libraries are licensed under **Apache-2.0** unless otherwise noted.

---

## Contributing

When adding new libraries:
1. Follow the existing naming convention (`lib/*.nix`)
2. Include SPDX license header
3. Document all public functions
4. Add tests to `tests.nix`
5. Update this README
