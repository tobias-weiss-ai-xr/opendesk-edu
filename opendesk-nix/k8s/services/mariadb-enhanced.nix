{ 
  lib, 
  security ? import ../../lib/security.nix { },
  registry ? import ../../lib/registry.nix { },
  pkgs ? import <nixpkgs> { }
  env ? import ../environments/hrz/default.nix { lib = lib; },
}:

let

  # OCI Labels (OpenSpec Compliance - FR-IMAGE-007)
  ociLabels = lib.mkOCILabels {
    name = name;
    version = tag;
    description = "mariadb-enhanced service for openDesk";
    serviceType = "web";
    component = "backend";
  };
  # Service configuration
  name = "mariadb";
  instance = "ilias";
  fullName = "${instance}-${name}";
  
  # Image configuration
  imageVersion = "11.4.4";
  
  # Generate image name using registry helper
  imageName = registry.formatServiceImageName {
    serviceName = "mariadb";
    serviceVersion = imageVersion;
    registry = registry.ghcr { namespace = "opendesk-edu"; };
  };
  
  # Storage configuration
  storageSize = "10Gi";
  storageClass = "ceph-rbd";
  
  # Security configuration (database profile)
  containerSecurity = security.mkContainerSecurityContext {
    profile = "database";
    extraCapabilities = [ "SYS_NICE" ];  # MariaDB needs this
  };
  
  podSecurity = security.mkPodSecurityContext {
    user = 999;  # mysql user
    group = 999;
    fsGroup = 999;
  };
  
  # Resource configuration
  resources = {
    requests = {
      cpu = "500m";
      memory = "1Gi";
    };
    limits = {
      cpu = "2";
      memory = "4Gi";
    };
  };
  
  # Probe configuration using lib.mkProbe
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

in [
  # StatefulSet with enhanced security and configuration
  (lib.statefulset {
    inherit name fullName;
    image = imageName;
    tag = imageVersion;
    instance = instance;
    port = 3306;
    
    containerSecurityContext = containerSecurity;
    podSecurityContext = podSecurity;
    resources = resources;
    livenessProbe = livenessProbe;
    readinessProbe = readinessProbe;
    
    volumeClaims = [
      {
        name = "data";
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = storageClass;
          resources = { requests = { storage = storageSize; }; };
        };
      }
    ];
    
    env = [
      {
        name = "MYSQL_ROOT_PASSWORD";
        valueFrom = { 
          secretKeyRef = { 
            name = "${fullName}-secrets";
            key = "root-password";
          };
        };
      }
    ];
    
    labels = security.mkPodSecurityAdmission {
      profile = "restricted";
    } // {
      app = fullName;
      component = name;
      part-of = "opendesk-edu";
    };
  })
  
  # Service
  (lib.service {
    name = fullName;
    port = 3306;
    selector = { app = fullName; };
  })
]
