// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

{ 
  lib,
  security ? import ../../lib/security.nix { },
  registry ? import ../../lib/registry.nix { },
  types ? import ../../lib/types.nix { },
  sbom ? import ../../lib/sbom.nix { },
  pkgs ? import <nixpkgs> { },
  env ? import ../environments/hrz/default.nix { lib = lib; },
}:

let

  name = "mariadb";
  instance = "ilias";
  version = "11.4.4";
  description = "MariaDB 11.4 database server for ILIAS";
  fullName = "${instance}-${name}";
  storageSize = "10Gi";
  
  # OCI Labels (OpenSpec Compliance - FR-IMAGE-007)
  ociLabels = lib.mkOCILabels {
    name = fullName;
    version = version;
    description = description;
    serviceType = "database";
    component = "backend";
  };
  storageClass = env.storage.rwo;
  
  # OCI Labels (OpenSpec Compliance - FR-IMAGE-007)
  ociLabels = lib.mkOCILabels {
    name = fullName;
    version = version;
    description = description;
    serviceType = "database";
    component = "backend";
  };

  # Security configuration
  containerSecurity = security.mkContainerSecurityContext { profile = "database"; };
  podSecurity = security.mkPodSecurityContext { user = 1000; group = 1000; fsGroup = 1000; };

  # Probe configuration
  livenessProbe = lib.mkProbe {
    type = "tcp";
    port = 3306;
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
  };
  readinessProbe = lib.mkProbe {
    type = "tcp";
    port = 3306;
    initialDelaySeconds = 5;
    periodSeconds = 5;
    timeoutSeconds = 3;
  };


in
 [
  (lib.statefulset { 
    name = fullName;
    inherit instance;
    image = registry.formatServiceImageName { service = name; };
    tag = version; 
    port = 3306;
    labels = ociLabels;
    namespace = env.namespace;
    securityContext = containerSecurity;
    podSecurityContext = podSecurity;
    livenessProbe = livenessProbe;
    readinessProbe = readinessProbe;
    resources = {
      requests = { cpu = "500m"; memory = "512Mi"; };
      limits = { cpu = "2"; memory = "2Gi"; };
    };
    volumeClaims = [
      { name = "data"; spec = { 
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = storageClass;
        resources = { requests = { storage = storageSize; }; };
      }; }
    ];
  })
  (lib.service { 
    name = fullName;
    inherit instance;
    port = 3306;
    labels = ociLabels;
    selector = { app = fullName; };
  })
  (lib.headlessService { 
    name = "${fullName}-headless";
    labels = ociLabels;
    port = 3306;
    selector = { app = fullName; };
  })
  
  # Ingress for admin interface (optional, can be disabled per environment)
  (if env.ingress.className != null then 
    lib.mkIngressWithTLS {
      name = fullName;
      host = "mariadb-admin.${env.ingress.domain}";
      serviceName = fullName;
      servicePort = 3306;
      ingressClass = env.ingress.className;
      annotations = env.ingress.annotations;
    }
   else null)
  
  # NetworkPolicy (lookup by labels)
  (lib.networkPolicy {
    name = "${fullName}-allow-from-opendesk";
    labels = ociLabels;
    namespace = env.namespace;
    ingress = [ {
      from = [ { namespaceSelector = { matchLabels = { name = env.namespace; }; }; } ];
      ports = [ { protocol = "TCP"; port = 3306; } ];
    } ];
    podSelector = { app = fullName; };
  })
  
  # PodDisruptionBudget
  (lib.pdb {
    name = fullName;
    labels = ociLabels;
    namespace = env.namespace;
    minAvailable = 1;
    podSelector = { app = fullName; };
  })
  
  # HorizontalPodAutoscaler (only for stateless, but included for completeness)
  (lib.hpa {
    name = fullName;
    labels = ociLabels;
    namespace = env.namespace;
    minReplicas = 1;
    maxReplicas = 2;
    targetCPUUtilization = 80;
    scaleTargetRef = { apiVersion = "apps/v1"; kind = "StatefulSet"; name = fullName; };
  })
  
  # ConfigMap for configuration
  (lib.configMap {
    name = "${fullName}-config";
    labels = ociLabels;
    namespace = env.namespace;
    data = {
      "my.cnf" = ''
        [mysqld]
        character-set-server = utf8mb4
        collation-server = utf8mb4_unicode_ci
        innodb_buffer_pool_size = 2G
      '';
    };
  })
  
  # Secrets (example - actual password should be from external secret)
  (lib.secret {
    name = "${fullName}-secrets";
    labels = ociLabels;
    namespace = env.namespace;
    type = "Opaque";
    stringData = {
      "MARIADB_ROOT_PASSWORD" = "CHANGE_ME";
      "MARIADB_DATABASE" = "ilias";
      "MARIADB_USER" = "ilias";
      "MARIADB_PASSWORD" = "CHANGE_ME";
    };
  })
  
] // builtins.filter (x: x != null)