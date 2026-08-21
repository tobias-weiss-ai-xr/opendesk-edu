# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ lib, ... }:
# Type definitions for openDesk Nix configurations.
# This library provides type definitions and validations for:
# - Image configurations
# - Kubernetes resource configurations
# - Service definitions
# - Environment configurations
let
  # =============================================================================
  # IMAGE TYPES
  # =============================================================================
  # Image configuration for container images
  imageConfigType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the image";
      };
      version = lib.mkOption {
        type = lib.types.str;
        default = "latest";
        description = "Version/tag of the image";
      };
      baseImage = lib.mkOption {
        type = lib.types.either lib.types.str (lib.types.attrs);
        description = "Base image to use (string or derivation)";
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "List of packages to install";
      };
      buildSteps = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Custom build steps (bash script)";
      };
      configFiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
        default = { };
        description = "Configuration files to copy into the image";
      };
      entrypoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Entrypoint script";
      };
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment variables";
      };
      labels = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Docker labels";
      };
      ports = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        description = "Exposed ports";
      };
      volumes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Volume paths";
      };
      user = lib.mkOption {
        type = lib.types.int;
        default = 1000;
        description = "User ID to run as";
      };
      group = lib.mkOption {
        type = lib.types.int;
        default = 1000;
        description = "Group ID to run as";
      };
      security = lib.mkOption {
        type = lib.types.submodule {
          options = {
            nonRoot = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Run as non-root user";
            };
            dropCapabilities = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "ALL" ];
              description = "Capabilities to drop";
            };
            readOnlyRootFS = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Make root filesystem read-only";
            };
            noNewPrivileges = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Disable privilege escalation";
            };
            allowPrivilegeEscalation = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Allow privilege escalation";
            };
          };
        };
        default = { };
        description = "Security configuration";
      };
      healthcheck = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [ "CMD" "CMD-SHELL" "HTTP" "TCP" ];
              description = "Health check type";
            };
            command = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Command for CMD health check";
            };
            url = lib.mkOption {
              type = lib.types.str;
              default = "/healthz";
              description = "URL for HTTP health check";
            };
            port = lib.mkOption {
              type = lib.types.int;
              default = 80;
              description = "Port for health check";
            };
            interval = lib.mkOption {
              type = lib.types.int;
              default = 30;
              description = "Interval between checks (seconds)";
            };
            timeout = lib.mkOption {
              type = lib.types.int;
              default = 10;
              description = "Timeout for check (seconds)";
            };
            retries = lib.mkOption {
              type = lib.types.int;
              default = 3;
              description = "Number of retries";
            };
          };
        });
        default = null;
        description = "Health check configuration";
      };
      sbom = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Generate SBOM for this image";
      };
      sign = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Sign this image with Cosign";
      };
      scan = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run vulnerability scan on this image";
      };
    };
  };
  # =============================================================================
  # KUBERNETES TYPES
  # =============================================================================
  # Container configuration for Kubernetes
  k8sContainerType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the container";
      };
      image = lib.mkOption {
        type = lib.types.str;
        description = "Container image (with tag)";
      };
      imagePullPolicy = lib.mkOption {
        type = lib.types.enum [ "Always" "IfNotPresent" "Never" ];
        default = "IfNotPresent";
        description = "Image pull policy";
      };
      ports = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        description = "Container ports to expose";
      };
      env = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            value = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
            valueFrom = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  configMapKeyRef = lib.mkOption {
                    type = lib.types.nullOr (lib.types.submodule {
                      options = {
                        name = lib.mkOption { type = lib.types.str; };
                        key = lib.mkOption { type = lib.types.str; };
                      };
                    });
                    default = null;
                  };
                  secretKeyRef = lib.mkOption {
                    type = lib.types.nullOr (lib.types.submodule {
                      options = {
                        name = lib.mkOption { type = lib.types.str; };
                        key = lib.mkOption { type = lib.types.str; };
                      };
                    });
                    default = null;
                  };
                };
              });
              default = null;
            };
          };
        });
        default = [ ];
        description = "Environment variables";
      };
      envFrom = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            configMapRef = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  name = lib.mkOption { type = lib.types.str; };
                  optional = lib.mkOption { type = lib.types.bool; default = false; };
                };
              });
              default = null;
            };
            secretRef = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  name = lib.mkOption { type = lib.types.str; };
                  optional = lib.mkOption { type = lib.types.bool; default = false; };
                };
              });
              default = null;
            };
          };
        });
        default = [ ];
        description = "Environment variables from config maps or secrets";
      };
      resources = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            requests = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  cpu = lib.mkOption { type = lib.types.str; default = "100m"; };
                  memory = lib.mkOption { type = lib.types.str; default = "128Mi"; };
                };
              };
              default = { };
            };
            limits = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  cpu = lib.mkOption { type = lib.types.str; default = "500m"; };
                  memory = lib.mkOption { type = lib.types.str; default = "512Mi"; };
                };
              };
              default = { };
            };
          };
        });
        default = null;
        description = "Resource requests and limits";
      };
      securityContext = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            allowPrivilegeEscalation = lib.mkOption { type = lib.types.bool; default = false; };
            runAsNonRoot = lib.mkOption { type = lib.types.bool; default = true; };
            runAsUser = lib.mkOption { type = lib.types.int; default = 1000; };
            runAsGroup = lib.mkOption { type = lib.types.int; default = 1000; };
            readOnlyRootFilesystem = lib.mkOption { type = lib.types.bool; default = true; };
            capabilities = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  drop = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ "ALL" ];
                  };
                  add = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                  };
                };
              });
              default = null;
            };
          };
        });
        default = null;
        description = "Security context for the container";
      };
      livenessProbe = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            httpGet = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  path = lib.mkOption { type = lib.types.str; default = "/healthz"; };
                  port = lib.mkOption { type = lib.types.int; default = 80; };
                  scheme = lib.mkOption { type = lib.types.enum [ "HTTP" "HTTPS" ]; default = "HTTP"; };
                };
              });
              default = null;
            };
            tcpSocket = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  port = lib.mkOption { type = lib.types.int; };
                };
              });
              default = null;
            };
            exec = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  command = lib.mkOption { type = lib.types.listOf lib.types.str; };
                };
              });
              default = null;
            };
            initialDelaySeconds = lib.mkOption { type = lib.types.int; default = 30; };
            periodSeconds = lib.mkOption { type = lib.types.int; default = 10; };
            timeoutSeconds = lib.mkOption { type = lib.types.int; default = 5; };
            successThreshold = lib.mkOption { type = lib.types.int; default = 1; };
            failureThreshold = lib.mkOption { type = lib.types.int; default = 3; };
          };
        });
        default = null;
        description = "Liveness probe configuration";
      };
      readinessProbe = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            httpGet = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  path = lib.mkOption { type = lib.types.str; default = "/healthz"; };
                  port = lib.mkOption { type = lib.types.int; default = 80; };
                  scheme = lib.mkOption { type = lib.types.enum [ "HTTP" "HTTPS" ]; default = "HTTP"; };
                };
              });
              default = null;
            };
            tcpSocket = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  port = lib.mkOption { type = lib.types.int; };
                };
              });
              default = null;
            };
            exec = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  command = lib.mkOption { type = lib.types.listOf lib.types.str; };
                };
              });
              default = null;
            };
            initialDelaySeconds = lib.mkOption { type = lib.types.int; default = 5; };
            periodSeconds = lib.mkOption { type = lib.types.int; default = 5; };
            timeoutSeconds = lib.mkOption { type = lib.types.int; default = 3; };
            successThreshold = lib.mkOption { type = lib.types.int; default = 1; };
            failureThreshold = lib.mkOption { type = lib.types.int; default = 3; };
          };
        });
        default = null;
        description = "Readiness probe configuration";
      };
      volumeMounts = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            mountPath = lib.mkOption { type = lib.types.str; };
            subPath = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
            readOnly = lib.mkOption { type = lib.types.bool; default = true; };
          };
        });
        default = [ ];
        description = "Volume mounts";
      };
      command = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Command to run";
      };
      args = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Arguments for the command";
      };
    };
  };
  # =============================================================================
  # SERVICE TYPES
  # =============================================================================
  # Service category types
  serviceCategoryType = lib.types.enum [
    "core"
    "database"
    "lms"
    "collaboration"
    "utility"
    "monitoring"
    "logging"
    "security"
    "networking"
    "storage"
  ];
  # Service tier types
  serviceTierType = lib.types.enum [
    "frontend"
    "backend"
    "database"
    "cache"
    "message-queue"
    "storage"
    "auth"
    "proxy"
  ];
  # Service phase (migration priority)
  servicePhaseType = lib.types.enum [
    "phase-0"
    "phase-1"
    "phase-2"
    "phase-3"
    "phase-4"
    "phase-5"
    "phase-6"
    "phase-7"
    "phase-8"
  ];
  # Service definition
  serviceType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Service name (lowercase, hyphen-separated)";
      };
      displayName = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable display name";
      };
      description = lib.mkOption {
        type = lib.types.str;
        description = "Service description";
      };
      version = lib.mkOption {
        type = lib.types.str;
        default = "latest";
        description = "Service version";
      };
      category = lib.mkOption {
        type = serviceCategoryType;
        default = "utility";
        description = "Service category";
      };
      tier = lib.mkOption {
        type = serviceTierType;
        default = "backend";
        description = "Service tier";
      };
      phase = lib.mkOption {
        type = servicePhaseType;
        default = "phase-1";
        description = "Migration phase";
      };
      priority = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "Migration priority (lower = higher priority)";
      };
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the service is enabled";
      };
      image = lib.mkOption {
        type = lib.types.nullOr imageConfigType;
        default = null;
        description = "Image configuration";
      };
      dependsOn = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Service dependencies";
      };
      ports = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        description = "Service ports";
      };
      replicas = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Number of replicas";
      };
      storage = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Requires persistent storage";
      };
      stateful = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the service is stateful";
      };
      ingress = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Exposes an ingress";
      };
      domain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Domain name for ingress";
      };
      configFiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
        default = { };
        description = "Configuration files";
      };
      secrets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Required secrets";
      };
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment variables";
      };
      resources = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            requests = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  cpu = lib.mkOption { type = lib.types.str; default = "100m"; };
                  memory = lib.mkOption { type = lib.types.str; default = "128Mi"; };
                };
              };
              default = { };
            };
            limits = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  cpu = lib.mkOption { type = lib.types.str; default = "500m"; };
                  memory = lib.mkOption { type = lib.types.str; default = "512Mi"; };
                };
              };
              default = { };
            };
          };
        });
        default = null;
        description = "Resource requests and limits";
      };
      monitoring = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable monitoring";
      };
      logging = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable logging";
      };
    };
  };
  # =============================================================================
  # ENVIRONMENT TYPES
  # =============================================================================
  # Environment types
  environmentType = lib.types.enum [
    "local"
    "demo"
    "staging"
    "hrz"
    "production"
  ];
  # Environment configuration
  environmentConfigType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Environment name";
      };
      type = lib.mkOption {
        type = environmentType;
        description = "Environment type";
      };
      domain = lib.mkOption {
        type = lib.types.str;
        description = "Base domain for this environment";
      };
      registry = lib.mkOption {
        type = lib.types.str;
        description = "Default container registry";
      };
      namespace = lib.mkOption {
        type = lib.types.str;
        description = "Default Kubernetes namespace";
      };
      replicas = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Default number of replicas";
      };
      storageClass = lib.mkOption {
        type = lib.types.str;
        default = "ceph-cephfs";
        description = "Default storage class";
      };
      enabledServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of enabled services";
      };
      disabledServices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of disabled services";
      };
      extraConfig = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Extra configuration for this environment";
      };
    };
  };
  # =============================================================================
  # REGISTRY TYPES
  # =============================================================================
  # Registry types
  registryType = lib.types.enum [
    "ghcr"
    "gitlab"
    "zot"
    "docker-hub"
    "quay"
    "harbor"
    "ecr"
    "acr"
    "gcr"
    "local"
  ];
  # Registry configuration
  registryConfigType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Registry name";
      };
      type = lib.mkOption {
        type = registryType;
        description = "Registry type";
      };
      url = lib.mkOption {
        type = lib.types.str;
        description = "Registry URL";
      };
      username = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Registry username";
      };
      password = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Registry password/token";
      };
      namespace = lib.mkOption {
        type = lib.types.str;
        description = "Registry namespace/organization";
      };
      insecure = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use insecure connection";
      };
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this registry is enabled";
      };
    };
  };
  # =============================================================================
  # SBOM TYPES
  # =============================================================================
  # SBOM format types
  sbomFormatType = lib.types.enum [
    "spdx"
    "cyclonedx"
    "both"
  ];
  # SBOM configuration
  sbomConfigType = lib.types.submodule {
    options = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable SBOM generation";
      };
      format = lib.mkOption {
        type = sbomFormatType;
        default = "both";
        description = "SBOM format(s) to generate";
      };
      outputDir = lib.mkOption {
        type = lib.types.str;
        default = "./sbom";
        description = "Output directory for SBOMs";
      };
      includeLicenses = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Include license information";
      };
      includeDependencies = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Include dependency information";
      };
      tool = lib.mkOption {
        type = lib.types.str;
        default = "syft";
        description = "SBOM generation tool";
      };
    };
  };
in {
  inherit
    imageConfigType
    k8sContainerType
    serviceCategoryType
    serviceTierType
    servicePhaseType
    serviceType
    environmentType
    environmentConfigType
    registryType
    registryConfigType
    sbomFormatType
    sbomConfigType
    ;
}
