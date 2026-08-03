{ lib, pkgs, ... }:

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

#"""
# Security hardening presets and utilities for openDesk container images and deployments.
# 
# This library provides:
# - Security profiles for different service types
# - Hardened base images
# - Security context builders
# - CIS compliance helpers
# - OpenDesk security standards
# 
# Usage:
#   security = import ./lib/security.nix { inherit pkgs lib; };
#   
#   # Apply security to a container
#   security.applySecurity { package = myPackage; profile = "database"; }
#   
#   # Get default security context
#   security.defaultContext
#"""

let
  # =============================================================================
  # SECURITY PROFILES
  # =============================================================================
  #
  # Security profiles define the security posture for different types of services.
  # Each profile includes:
  # - Container user/group
  # - Dropped capabilities
  # - Added capabilities (if necessary)
  # - Read-only root filesystem
  # - Allow privilege escalation
  # - Seccomp profile
  # - AppArmor profile
  # - SELinux context

  securityProfile = { name, user, group, fsGroup ? null, 
    dropCapabilities ? [ "ALL" ], addCapabilities ? [ ], 
    readOnlyRootFS ? true, allowPrivilegeEscalation ? false, 
    runAsNonRoot ? true, seccompProfile ? "runtime/default", 
    appArmorProfile ? null, selinuxContext ? null }:
    {
      name = name;
      inherit user group fsGroup;
      securityContext = {
        inherit runAsNonRoot allowPrivilegeEscalation seccompProfile;
        User = toString user;
        Group = toString group;
        capabilities = {
          drop = dropCapabilities;
          add = addCapabilities;
        };
        readOnlyRootFilesystem = readOnlyRootFS;
      } // (if fsGroup != null then { fsGroup = toString fsGroup; } else {});
    };

  # Default profile - most secure for stateless applications
  defaultProfile = securityProfile {
    name = "default";
    user = 1000;
    group = 1000;
    fsGroup = 1000;
    dropCapabilities = [ "ALL" ];
    readOnlyRootFS = true;
    allowPrivilegeEscalation = false;
  };

  # Web application profile - for web servers (nginx, apache, etc.)
  webProfile = securityProfile {
    name = "web";
    user = 1000;
    group = 1000;
    fsGroup = 1000;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ "NET_BIND_SERVICE" ];  # Needed for binding to ports < 1024
    readOnlyRootFS = true;
    allowPrivilegeEscalation = false;
  };

  # Database profile - for databases (mariadb, postgresql)
  databaseProfile = securityProfile {
    name = "database";
    user = 999;  # MariaDB default
    group = 999;
    fsGroup = 999;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ 
      "DAC_OVERRIDE"  # Needed for chmod, chown
      "SYS_NICE"      # Needed for setpriority (MySQL uses this)
      "NET_BIND_SERVICE"
    ];
    readOnlyRootFS = false;  # Databases need to write to data directory
    allowPrivilegeEscalation = false;
  };

  # Cache profile - for caches (redis, memcached)
  cacheProfile = securityProfile {
    name = "cache";
    user = 999;  # Redis default
    group = 999;
    fsGroup = 999;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ 
      "DAC_OVERRIDE"  # May need to write to config files
      "NET_BIND_SERVICE"
    ];
    readOnlyRootFS = true;
    allowPrivilegeEscalation = false;
  };

  # Storage profile - for storage services (minio, seaweedfs)
  storageProfile = securityProfile {
    name = "storage";
    user = 1000;
    group = 1000;
    fsGroup = 1000;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ 
      "DAC_OVERRIDE"
      "SYS_ADMIN"  # Sometimes needed for filesystem operations
    ];
    readOnlyRootFilesystem = false;
    allowPrivilegeEscalation = false;
  };

  # LMS profile - for learning management systems (moodle, ilias)
  lmsProfile = securityProfile {
    name = "lms";
    user = 33;  # Apache www-data
    group = 33;
    fsGroup = 33;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ 
      "DAC_OVERRIDE"  # Needs to write to moodledata directory
      "NET_BIND_SERVICE"
    ];
    readOnlyRootFS = false;  # Needs to write uploads
    allowPrivilegeEscalation = false;
  };

  # Collaboration profile - for collaboration (nextcloud, collabora)
  collaborationProfile = securityProfile {
    name = "collaboration";
    user = 33;  # Apache www-data
    group = 33;
    fsGroup = 33;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ 
      "DAC_OVERRIDE"
      "NET_BIND_SERVICE"
    ];
    readOnlyRootFS = false;  # Needs to write user data
    allowPrivilegeEscalation = false;
  };

  # Monitoring profile - for monitoring (prometheus, grafana)
  monitoringProfile = securityProfile {
    name = "monitoring";
    user = 1000;
    group = 1000;
    fsGroup = 1000;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ "NET_BIND_SERVICE" ];
    readOnlyRootFS = true;
    allowPrivilegeEscalation = false;
  };

  # Logging profile - for logging (elastic, kibana, loki)
  loggingProfile = securityProfile {
    name = "logging";
    user = 1000;
    group = 1000;
    fsGroup = 1000;
    dropCapabilities = [ "ALL" ];
    addCapabilities = [ 
      "DAC_OVERRIDE"
      "NET_BIND_SERVICE"
    ];
    readOnlyRootFS = false;  # Needs to write logs
    allowPrivilegeEscalation = false;
  };

  # =============================================================================
  # SECURITY PROFILE SELECTOR
  # =============================================================================

  getProfile = profileName:
    if builtins.elem profileName [ "default" "stateless" "app" ] then defaultProfile
    else if builtins.elem profileName [ "web" "frontend" "backend" "api" ] then webProfile
    else if builtins.elem profileName [ "database" "db" "mariadb" "postgresql" "mysql" ] then databaseProfile
    else if builtins.elem profileName [ "cache" "redis" "memcached" ] then cacheProfile
    else if builtins.elem profileName [ "storage" "minio" "seaweedfs" "object-storage" ] then storageProfile
    else if builtins.elem profileName [ "lms" "moodle" "ilias" "jupyterhub" ] then lmsProfile
    else if builtins.elem profileName [ "collaboration" "nextcloud" "collabora" "element" "jitsi" ] then collaborationProfile
    else if builtins.elem profileName [ "monitoring" "prometheus" "grafana" ] then monitoringProfile
    else if builtins.elem profileName [ "logging" "loki" "elastic" "kibana" "filebeat" ] then loggingProfile
    else defaultProfile
    ;

  # =============================================================================
  # CONTAINER HARDENING
  # =============================================================================

  # Apply security hardening to a Docker image build
  hardenContainer = { pkg, profile ? "default", extraArgs ? {} }:
    let
      prof = getProfile profile;
      securityFlags = [
        "--no-new-privileges"
        "--cap-drop=ALL"
      ] ++ map (cap: "--cap-add=${cap}") prof.securityContext.capabilities.add;
      
      runFlags = [
        "--user=${prof.securityContext.User}:${prof.securityContext.Group}"
      ] ++ (if prof.securityContext.readOnlyRootFilesystem then [ "--read-only" ] else []);
    in
      pkg.overrideAttrs (oldAttrs: rec {
        inherit (oldAttrs) pname version;
        
        # Add security labels
        dockerLabels = (oldAttrs.dockerLabels or { }) // {
          maintainer = "opendesk-edu";
          "org.opencontainers.image.vendor" = "openDesk Edu";
          "org.opencontainers.image.licenses" = "Apache-2.0";
        };
        
        # Add security build flags
        dockerBuildFlags = (oldAttrs.dockerBuildFlags or [ ]) ++ securityFlags;
        
        # Add runtime flags
        dockerRunFlags = (oldAttrs.dockerRunFlags or [ ]) ++ runFlags;
        
        # Set user explicitly
        config = (oldAttrs.config or { }) // {
          User = "${prof.securityContext.User}:${prof.securityContext.Group}";
          WorkingDir = "/app";
        };
        
        # Add environment variables
        configEnv = (oldAttrs.configEnv or { }) // {
          HOME = "/home/appuser";
          PATH = "${pkgs.coreutils}/bin:${pkgs.bash}/bin:${pkgs.findutils}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
        };
      });

  # Apply minimal security to an existing package
  minimalHardening = pkg: pkg.overrideAttrs (oldAttrs: {
    config = (oldAttrs.config or { }) // {
      User = "1000:1000";
      WorkingDir = "/app";
    };
    dockerLabels = (oldAttrs.dockerLabels or { }) // {
      maintainer = "opendesk-edu";
    };
  });

  # =============================================================================
  # CAPABILITY DEFINITIONS
  # =============================================================================

  # Standard Linux capabilities
  capabilities = {
    ALL = "ALL";
    AUDIT_CONTROL = "AUDIT_CONTROL";
    AUDIT_READ = "AUDIT_READ";
    AUDIT_WRITE = "AUDIT_WRITE";
    BLOCK_SUSPEND = "BLOCK_SUSPEND";
    CHOWN = "CHOWN";
    DAC_OVERRIDE = "DAC_OVERRIDE";
    DAC_READ_SEARCH = "DAC_READ_SEARCH";
    FOWNER = "FOWNER";
    FSETID = "FSETID";
    IPC_LOCK = "IPC_LOCK";
    IPC_OWNER = "IPC_OWNER";
    KILL = "KILL";
    LEASE = "LEASE";
    LINUX_IMMUTABLE = "LINUX_IMMUTABLE";
    MAC_ADMIN = "MAC_ADMIN";
    MAC_OVERRIDE = "MAC_OVERRIDE";
    MKNOD = "MKNOD";
    NET_ADMIN = "NET_ADMIN";
    NET_BIND_SERVICE = "NET_BIND_SERVICE";
    NET_BROADCAST = "NET_BROADCAST";
    NET_RAW = "NET_RAW";
    SETFCAP = "SETFCAP";
    SETGID = "SETGID";
    SETPCAP = "SETPCAP";
    SETUID = "SETUID";
    SYS_ADMIN = "SYS_ADMIN";
    SYS_BOOT = "SYS_BOOT";
    SYS_CHROOT = "SYS_CHROOT";
    SYS_MODULE = "SYS_MODULE";
    SYS_NICE = "SYS_NICE";
    SYS_PACCT = "SYS_PACCT";
    SYS_PTRACE = "SYS_PTRACE";
    SYS_RAWIO = "SYS_RAWIO";
    SYS_RESOURCE = "SYS_RESOURCE";
    SYS_TIME = "SYS_TIME";
    SYS_TTY_CONFIG = "SYS_TTY_CONFIG";
    SYSLOG = "SYSLOG";
    WAKE_ALARM = "WAKE_ALARM";
  };

  # Common capability sets
  capabilitySets = {
    none = [ ];
    minimal = [ ];
    basic = [ capabilities.NET_BIND_SERVICE ];
    writeable = [ capabilities.DAC_OVERRIDE capabilities.NET_BIND_SERVICE ];
    database = [ capabilities.DAC_OVERRIDE capabilities.SYS_NICE capabilities.NET_BIND_SERVICE ];
    storage = [ capabilities.DAC_OVERRIDE capabilities.SYS_ADMIN capabilities.NET_BIND_SERVICE ];
    networking = [ capabilities.NET_ADMIN capabilities.NET_BIND_SERVICE capabilities.NET_RAW ];
    full = [ capabilities.ALL ];
  };

  # =============================================================================
  # SECCOMP PROFILES
  # =============================================================================

  # Seccomp profiles restrict which system calls a container can make
  seccompProfiles = {
    default = "runtime/default";
    unconfined = "unconfined";
    local = "localhost/default";
    dockerDefault = "docker/default";
  };

  # =============================================================================
  # KUBERNETES SECURITY CONTEXT BUILDERS
  # =============================================================================

  # Build a security context for a Kubernetes pod
  mkPodSecurityContext = { profile ? "default", extra ? {} }:
    let prof = getProfile profile;
    in {
      runAsNonRoot = true;
      runAsUser = prof.user;
      runAsGroup = prof.group;
      fsGroup = prof.fsGroup or prof.group;
      fsGroupChangePolicy = "OnRootMismatch";
      seccompProfile = { type = "RuntimeDefault"; };
    } // extra;

  # Build a security context for a Kubernetes container
  mkContainerSecurityContext = { profile ? "default", extra ? {} }:
    let prof = getProfile profile;
    in {
      allowPrivilegeEscalation = false;
      runAsNonRoot = true;
      runAsUser = prof.user;
      runAsGroup = prof.group;
      readOnlyRootFilesystem = prof.securityContext.readOnlyRootFilesystem;
      capabilities = {
        drop = [ "ALL" ];
        add = prof.securityContext.capabilities.add;
      };
      seccompProfile = { type = "RuntimeDefault"; };
    } // extra;

  # =============================================================================
  # CIS COMPLIANCE HELPERS
  # =============================================================================
  #
  # CIS Kubernetes Benchmark compliance helpers
  # See: https://www.cisecurity.org/benchmark/kubernetes/

  # CIS 5.2.x - Pod Security Standards
  cisPodSecurity = {
    privileged = false;
    allowPrivilegeEscalation = false;
    runAsNonRoot = true;
    readOnlyRootFilesystem = true;
    capabilities = { drop = [ "ALL" ]; };
  };

  # CIS 5.3.x - Pod Security Context
  cisPodSecurityContext = {
    runAsNonRoot = true;
    runAsUser = 1000;
    fsGroup = 1000;
    fsGroupChangePolicy = "OnRootMismatch";
  };

  # CIS 5.4.x - Container Security Context
  cisContainerSecurityContext = {
    allowPrivilegeEscalation = false;
    runAsNonRoot = true;
    runAsUser = 1000;
    readOnlyRootFilesystem = true;
    capabilities = { drop = [ "ALL" ]; };
    privileged = false;
    seccompProfile = { type = "RuntimeDefault"; };
  };

  # Validate against CIS benchmark
  validateCIS = config:
    let
      issues = [
        (if config.privileged == true then "CIS 5.2.1: Container should not run as privileged" else null)
        (if config.allowPrivilegeEscalation == true then "CIS 5.2.2: Container should disable privilege escalation" else null)
        (if config.runAsNonRoot == false then "CIS 5.2.3: Container should run as non-root" else null)
        (if config.readOnlyRootFilesystem == false then "CIS 5.2.4: Root filesystem should be read-only" else null)
        (if !builtins.elem "ALL" config.capabilities.drop then "CIS 5.2.5: All capabilities should be dropped" else null)
        (if config.seccompProfile != "RuntimeDefault" then "CIS 5.2.10: Seccomp profile should be RuntimeDefault" else null)
      ];
      cisIssues = builtins.filter (x: x != null) issues;
    in let
      compliantVal = builtins.length cisIssues == 0;
    in {
      compliant = compliantVal;
      issues = cisIssues;
      warnings = if compliantVal then [ ] else [ "Container does not meet CIS benchmark standards" ];
    };

  # =============================================================================
  # OPENDESK SECURITY STANDARDS
  # =============================================================================

  # openDesk security standards per service tier
  opendeskSecurityStandards = {
    critical = {
      disabledCapabilities = [ "ALL" ];
      enabledCapabilities = [ ];
      runAsNonRoot = true;
      readOnlyRootFS = true;
      allowPrivilegeEscalation = false;
      privileged = false;
      hostPID = false;
      hostIPC = false;
      hostNetwork = false;
    };
    high = {
      disabledCapabilities = [ "ALL" ];
      enabledCapabilities = [ "NET_BIND_SERVICE" ];  # Allows binding to ports < 1024
      runAsNonRoot = true;
      readOnlyRootFS = true;
      allowPrivilegeEscalation = false;
      privileged = false;
      hostPID = false;
      hostIPC = false;
      hostNetwork = false;
    };
    medium = {
      disabledCapabilities = [ "ALL" ];
      enabledCapabilities = [ "DAC_OVERRIDE" "NET_BIND_SERVICE" ];  # Allows writing files
      runAsNonRoot = true;
      readOnlyRootFS = false;  # Some apps need to write
      allowPrivilegeEscalation = false;
      privileged = false;
      hostPID = false;
      hostIPC = false;
      hostNetwork = false;
    };
    low = {
      disabledCapabilities = [ "ALL" ];
      enabledCapabilities = [ "DAC_OVERRIDE" "NET_BIND_SERVICE" "SYS_NICE" "SYS_ADMIN" ];
      runAsNonRoot = true;
      readOnlyRootFS = false;
      allowPrivilegeEscalation = false;
      privileged = false;
      hostPID = false;
      hostIPC = false;
      hostNetwork = false;
    };
  };

  # Get security standard by criticality
  getSecurityStandard = criticality:
    if criticality == "critical" then opendeskSecurityStandards.critical
    else if criticality == "high" then opendeskSecurityStandards.high
    else if criticality == "medium" then opendeskSecurityStandards.medium
    else if criticality == "low" then opendeskSecurityStandards.low
    else opendeskSecurityStandards.high
    ;

  # =============================================================================
  # NETWORK POLICY HELPERS
  # =============================================================================

  # Deny all ingress by default (zero-trust)
  denyAllIngress = { name, selector ? null, instance ? name }:
    let
      defaultSelector = if selector == null then {
        matchLabels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = instance;
        };
      } else selector;
    in {
      apiVersion = "networking.k8s.io/v1";
      kind = "NetworkPolicy";
      metadata = { inherit name; };
      spec = {
        podSelector = defaultSelector;
        policyTypes = [ "Ingress" ];
        ingress = [ ];  # Deny all
      };
    };

  # Allow ingress only from specific namespaces
  allowIngressFrom = { name, fromNamespaces, ports ? [ 80 443 ], selector ? null, instance ? name }:
    let
      defaultSelector = if selector == null then {
        matchLabels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = instance;
        };
      } else selector;
    in {
      apiVersion = "networking.k8s.io/v1";
      kind = "NetworkPolicy";
      metadata = { inherit name; };
      spec = {
        podSelector = defaultSelector;
        policyTypes = [ "Ingress" ];
        ingress = [{
          from = map (ns: { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = ns; }; }; }) fromNamespaces;
          ports = map (p: { protocol = "TCP"; port = p; }) ports;
        }];
      };
    };

  # Allow egress to DNS only
  allowDNSEgressOnly = { name, dnsServers ? [ "10.43.0.10" "8.8.8.8" "1.1.1.1" ], selector ? null, instance ? name }:
    let
      defaultSelector = if selector == null then {
        matchLabels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = instance;
        };
      } else selector;
    in {
      apiVersion = "networking.k8s.io/v1";
      kind = "NetworkPolicy";
      metadata = { inherit name; };
      spec = {
        podSelector = defaultSelector;
        policyTypes = [ "Egress" ];
        egress = [
          {
            to = [{ ipBlock = { cidr = "0.0.0.0/0"; }; }];
            ports = [
              { protocol = "UDP"; port = 53; }
              { protocol = "TCP"; port = 53; }
            ];
          }
          {
            to = map (ip: { ipBlock = { cidr = "${ip}/32"; }; }) dnsServers;
            ports = [
              { protocol = "UDP"; port = 53; }
              { protocol = "TCP"; port = 53; }
            ];
          }
        ];
      };
    };

  # =============================================================================
  # POD SECURITY ADMISSION HELPERS
  # =============================================================================

  # Pod Security Admission labels
  psaLabels = {
    privileged = {
      "pod-security.kubernetes.io/warn" = "privileged";
      "pod-security.kubernetes.io/audit" = "privileged";
    };
    baseline = {
      "pod-security.kubernetes.io/warn" = "baseline";
      "pod-security.kubernetes.io/audit" = "baseline";
      "pod-security.kubernetes.io/warn-version" = "latest";
      "pod-security.kubernetes.io/audit-version" = "latest";
    };
    restricted = {
      "pod-security.kubernetes.io/warn" = "restricted";
      "pod-security.kubernetes.io/audit" = "restricted";
      "pod-security.kubernetes.io/warn-version" = "latest";
      "pod-security.kubernetes.io/audit-version" = "latest";
    };
  };

  # =============================================================================
  # EXPORT ALL
  # =============================================================================

in {
  inherit
    # Profiles
    defaultProfile webProfile databaseProfile cacheProfile storageProfile
    lmsProfile collaborationProfile monitoringProfile loggingProfile
    
    # Profile utilities
    securityProfile getProfile
    
    # Container hardening
    hardenContainer minimalHardening
    
    # Capabilities
    capabilities capabilitySets
    
    # Seccomp profiles
    seccompProfiles
    
    # Kubernetes security contexts
    mkPodSecurityContext mkContainerSecurityContext
    
    # CIS compliance
    cisPodSecurity cisPodSecurityContext cisContainerSecurityContext validateCIS
    
    # openDesk standards
    opendeskSecurityStandards getSecurityStandard
    
    # Network policy helpers
    denyAllIngress allowIngressFrom allowDNSEgressOnly
    
    # Pod Security Admission
    psaLabels
    ;
}
