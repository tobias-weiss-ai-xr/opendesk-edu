{ pkgs, lib, ... }:

# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Kubernetes resource builders for openDesk Edu.

This library provides reusable builders for Kubernetes resources with:
- Security hardening by default (non-root, read-only FS, dropped capabilities)
- Standard probes (TCP, HTTP, command)
- Resource limits and requests
- Volume and environment helpers
- Network policies
- Automatic certificate generation

Usage:
  { pkgs, lib, ... }:
  let
    k8s = import ./lib/k8s.nix { inherit pkgs lib; };
  in {
    # Use k8s spelled functions
    deployment = k8s.deployment { name = "my-app"; image = "my-image"; };
    service = k8s.service { name = "my-service"; port = 80; };
    # etc.
  }
"""

let
  toYAML = value: builtins.toJSON value;

  # =============================================================================
  # SECURITY DEFAULT
  # =============================================================================

  # Default security context - all containers run as non-root
  # with all capabilities dropped and read-only root filesystem
  securityContext = {
    allowPrivilegeEscalation = false;
    runAsNonRoot = true;
    runAsUser = 1000;
    runAsGroup = 1000;
    readOnlyRootFilesystem = true;
    capabilities = { drop = [ "ALL" ]; add = [ ]; };
  };

  # Less restrictive security context for containers that need to write files
  # (e.g., containers that need to write to /var/lib or other locations)
  writeableSecurityContext = {
    allowPrivilegeEscalation = false;
    runAsNonRoot = true;
    runAsUser = 1000;
    runAsGroup = 1000;
    capabilities = { drop = [ "ALL" ]; add = [ "DAC_OVERRIDE" ]; };
  };

  # Security context for database containers (needs more capabilities)
  databaseSecurityContext = {
    allowPrivilegeEscalation = false;
    runAsNonRoot = true;
    runAsUser = 999;  # PostgreSQL, MariaDB default user
    runAsGroup = 999;
    capabilities = { drop = [ "ALL" ]; add = [ "DAC_OVERRIDE" "SYS_NICE" "NET_BIND_SERVICE" ]; };
  };

  # =============================================================================
  # PROBES
  # =============================================================================

  tcpProbe = port: {
    tcpSocket = { port = port; };
    initialDelaySeconds = 30;
    periodSeconds = 10;
    timeoutSeconds = 5;
    successThreshold = 1;
    failureThreshold = 3;
  };

  httpProbe = { path ? "/healthz", port ? 80, initialDelaySeconds ? 30, periodSeconds ? 10, timeoutSeconds ? 5, successThreshold ? 1, failureThreshold ? 3 }: {
    httpGet = { path = path; port = port; };
    inherit initialDelaySeconds periodSeconds timeoutSeconds successThreshold failureThreshold;
  };

  commandProbe = { command, initialDelaySeconds ? 5, periodSeconds ? 10, timeoutSeconds ? 5, successThreshold ? 1, failureThreshold ? 3 }: {
    exec = { command = command; };
    inherit initialDelaySeconds periodSeconds timeoutSeconds successThreshold failureThreshold;
  };

  # =============================================================================
  # RESOURCE DEFAULTS
  # =============================================================================

  # Default resources for most applications
  defaultResources = {
    requests = { cpu = "100m"; memory = "128Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };

  # Default resources for small sidecar containers
  smallResources = {
    requests = { cpu = "50m"; memory = "64Mi"; };
    limits = { cpu = "200m"; memory = "256Mi"; };
  };

  # Default resources for databases
  databaseResources = {
    requests = { cpu = "250m"; memory = "256Mi"; };
    limits = { cpu = "2000m"; memory = "2Gi"; };
  };

  # Default resources for large applications (Nextcloud, Moodle, etc.)
  largeResources = {
    requests = { cpu = "500m"; memory = "512Mi"; };
    limits = { cpu = "4000m"; memory = "4Gi"; };
  };

  # Default resources for frontends
  frontendResources = {
    requests = { cpu = "100m"; memory = "128Mi"; };
    limits = { cpu = "1000m"; memory = "1Gi"; };
  };

  # Default resources for caches (Redis, Memcached)
  cacheResources = {
    requests = { cpu = "100m"; memory = "128Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };

  # =============================================================================
  # CONTAINER BUILDER
  # =============================================================================

  # Build a container specification for use in Deployments, StatefulSets, etc.
  mkContainer = { name, image, tag ? "latest", port ? null, ports ? [ ]
    , env ? [ ], envFrom ? [ ], resources ? defaultResources
    , probes ? true, probeType ? "tcp", probePath ? "/healthz", probePort ? null
    , volumes ? [ ], command ? null, args ? null
    , securityContext ? null, lifecycle ? null
    , livenessProbe ? null, readinessProbe ? null
    , startupProbe ? null
  }:
    let
      base = {
        inherit name;
        image = "${image}:${tag}";
        imagePullPolicy = "IfNotPresent";
      } // (if command != null then { command = command; } else {})
        // (if args != null then { args = args; } else {});
      
      withPorts = if port != null then 
        base // { ports = [{ containerPort = port; }] ++ ports; } 
        else base // { ports = ports; };
      
      withEnv = withPorts // { 
        env = env;
      } // (if envFrom != [] then { envFrom = envFrom; } else {});
      
      withResources = withEnv // { resources = resources; };
      
      # Security context: use provided or default to secure context
      withSecurity = if securityContext != null then 
        withResources // { securityContext = securityContext; } 
        else withResources // { securityContext = writeableSecurityContext; };
      
      withLifecycle = if lifecycle != null then 
        withSecurity // { lifecycle = lifecycle; } 
        else withSecurity;
      
      # Add probes if enabled
      withProbes = if probes && livenessProbe == null && readinessProbe == null then
        if probeType == "http" then
          withLifecycle // {
            livenessProbe = httpProbe { 
              path = probePath; 
              port = if probePort != null then probePort else if port != null then port else 80;
              initialDelaySeconds = 60;  # Longer for apps that take time to start
              periodSeconds = 10;
            };
            readinessProbe = httpProbe { 
              path = probePath; 
              port = if probePort != null then probePort else if port != null then port else 80;
              initialDelaySeconds = 30;
              periodSeconds = 5;
            };
          }
        else if probeType == "tcp" then
          withLifecycle // {
            livenessProbe = tcpProbe (if probePort != null then probePort else if port != null then port else 80);
            readinessProbe = tcpProbe (if probePort != null then probePort else if port != null then port else 80);
          }
        else
          withLifecycle
      else if livenessProbe == null && readinessProbe == null then
        withLifecycle  # No probes if disabled and none provided
      else if livenessProbe != null && readinessProbe != null then
        withLifecycle // { inherit livenessProbe readinessProbe; }
      else if livenessProbe != null then
        withLifecycle // { inherit livenessProbe; readinessProbe = livenessProbe; }
      else if readinessProbe != null then
        withLifecycle // { livenessProbe = readinessProbe; inherit readinessProbe; }
      else
        withLifecycle;
      
      withStartup = if startupProbe != null then
        withProbes // { startupProbe = startupProbe; }
        else withProbes;
      
      volumeMounts = map (v: {
        name = v.name;
        mountPath = v.mountPath;
      } // (if v ? subPath then { subPath = v.subPath; } else {})
        // (if v ? readOnly then { readOnly = v.readOnly; } else { readOnly = true; })) volumes;
    in withStartup // { inherit volumeMounts; };

  # =============================================================================
  # POD SPEC BUILDER (shared between Deployment, StatefulSet, DaemonSet, Job)
  # =============================================================================

  # Full pod specification builder
  podSpec = { name, image, tag ? "latest", port ? null, ports ? [ ]
    , replicas ? 1, env ? [ ], envFrom ? [ ]
    , resources ? defaultResources, probes ? true, probeType ? "tcp"
    , volumes ? [ ], extraContainers ? [ ], initContainers ? null
    , nodeSelector ? null, affinity ? null, tolerations ? null
    , priorityClassName ? null, terminationGracePeriodSeconds ? null
    , dnsConfig ? null, hostAliases ? null, dnsPolicy ? null
    , imagePullSecrets ? null, serviceAccountName ? null, defaultToken ? null
    , podAnnotations ? {}, podLabels ? {}
    , topologySpreadConstraints ? null
    , securityContext ? null
    , runAsUser ? 1000
    , runAsGroup ? 1000
    , fsGroup ? 1000
    , volumeClaims ? [ ]
    , instance ? name
    , hostNetwork ? false
  }:
    let
      defaultLabels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = instance;
        "app.kubernetes.io/version" = tag;
      };
      mergedLabels = defaultLabels // podLabels;
      podSecurity = (if securityContext != null then securityContext else {})
        // { runAsUser = runAsUser; runAsGroup = runAsGroup; fsGroup = fsGroup; };
      volumeMounts = map (v: v.mount) volumes;
    in {
      metadata = {
        inherit name;
        labels = mergedLabels;
      } // (if podAnnotations != {} then { annotations = podAnnotations; } else {});
      spec = {
        inherit replicas;
        selector = { matchLabels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = instance;
        }; };
        template = {
          metadata = { labels = mergedLabels; };
          spec = {
            securityContext = podSecurity;
            containers = [
              (mkContainer { 
                inherit name image tag port ports env envFrom resources probes probeType volumes;
                livenessProbe = if (builtins.hasAttr "livenessProbe" (args: args)) then livenessProbe else null;
                readinessProbe = if (builtins.hasAttr "readinessProbe" (args: args)) then readinessProbe else null;
              })
            ] ++ extraContainers ++ (if initContainers != null then [] else []);
          }
          // (if initContainers != null then { spec.initContainers = initContainers; } else {})
          // (if nodeSelector != null then { spec.nodeSelector = nodeSelector; } else {})
          // (if affinity != null then { spec.affinity = affinity; } else {})
          // (if tolerations != null then { spec.tolerations = tolerations; } else {})
          // (if priorityClassName != null then { spec.priorityClassName = priorityClassName; } else {})
          // (if terminationGracePeriodSeconds != null then { spec.terminationGracePeriodSeconds = terminationGracePeriodSeconds; } else {})
          // (if dnsConfig != null then { spec.dnsConfig = dnsConfig; } else {})
          // (if hostAliases != null then { spec.hostAliases = hostAliases; } else {})
          // (if dnsPolicy != null then { spec.dnsPolicy = dnsPolicy; } else {})
          // (if imagePullSecrets != null then { spec.imagePullSecrets = imagePullSecrets; } else {})
          // (if serviceAccountName != null then { spec.serviceAccountName = serviceAccountName; } else {})
          // (if topologySpreadConstraints != null then { spec.topologySpreadConstraints = topologySpreadConstraints; } else {})
          // (if hostNetwork then { spec.hostNetwork = hostNetwork; } else {})
          ;
        };
      };
    };

  # =============================================================================
  # WORKLOAD BUILDERS (Deployment, StatefulSet, DaemonSet)
  # =============================================================================

  # Build a Deployment resource
  deployment = args:
    let 
      ps = podSpec (args // { instance = args.name; });
      customLabels = args.labels or { };
    in {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = ps.metadata // {
        annotations = (ps.metadata.annotations or { }) // (args.annotations or { });
        labels = (ps.metadata.labels or { }) // customLabels;
      };
      spec = (builtins.removeAttrs ps.spec [ "template" ]) // {
        selector = ps.spec.template.spec.selector;
        template = ps.spec.template;
        strategy = args.strategy or { type = "RollingUpdate"; rollingUpdate = { maxSurge = "25%", maxUnavailable = "25%" }; };
        revisionHistoryLimit = args.revisionHistoryLimit or 10;
        paused = args.paused or false;
      };
    };

  # Build a StatefulSet resource
  statefulset = args:
    let 
      ps = podSpec (args // { instance = args.name; });
      volumeClaims = if args ? volumeClaims then 
        map (vc: { 
          metadata = { name = vc.name; };
          spec = vc.spec // { accessModes = vc.accessModes or [ "ReadWriteOnce" ]; };
        }) args.volumeClaims 
        else [];
    in {
      apiVersion = "apps/v1";
      kind = "StatefulSet";
      metadata = ps.metadata;
      spec = (builtins.removeAttrs ps.spec [ "template" ]) // {
        serviceName = args.serviceName or args.name;
        selector = ps.spec.template.spec.selector;
        template = ps.spec.template;
        volumeClaimTemplates = volumeClaims;
        podManagementPolicy = args.podManagementPolicy or "OrderedReady";
        updateStrategy = args.updateStrategy or { type = "RollingUpdate" };
        revisionHistoryLimit = args.revisionHistoryLimit or 10;
      };
    };

  # Build a DaemonSet resource
  daemonSet = args:
    let ps = podSpec (args // { replicas = null; instance = args.name; });
    in {
      apiVersion = "apps/v1";
      kind = "DaemonSet";
      metadata = ps.metadata;
      spec = (builtins.removeAttrs ps.spec [ "replicas" "template" ]) // {
        selector = ps.spec.template.spec.selector;
        template = ps.spec.template;
        updateStrategy = args.updateStrategy or { type = "RollingUpdate"; rollingUpdate = { maxUnavailable = "25%" }; };
        minReadySeconds = args.minReadySeconds or 0;
      };
    };

  # =============================================================================
  # SERVICE BUILDERS
  # =============================================================================

  # Build a standard ClusterIP Service
  service = { name, port ? 80, targetPort ? null, type ? "ClusterIP", clusterIP ? null 
    , ports ? [ ], annotations ? {}, labels ? {}, selector ? null, instance ? name }:
    let 
      defaultSelector = if selector == null then {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = instance;
      } else selector;
    in {
      apiVersion = "v1";
      kind = "Service";
      metadata = { inherit name annotations labels; };
      spec = {
        ports = [ { port = port; targetPort = if targetPort != null then targetPort else port; } ] ++ ports;
        selector = defaultSelector;
      } // (if type != "ClusterIP" then { type = type; } else {})
        // (if clusterIP != null then { clusterIP = clusterIP; } else {})
        // (if type == "ExternalName" && builtins.hasAttr "externalName" args then { externalName = args.externalName; } else {});
    };

  # Build a headless Service (ClusterIP = None)
  headlessService = { name, port ? 80, selector ? null, instance ? name, ... }:
    service { 
      inherit name port;
      type = "ClusterIP";
      clusterIP = "None";
      selector = if selector == null then {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = instance;
      } else selector;
    };

  # Build an ExternalName Service
  externalService = { name, externalName, port ? null, ... }:
    service { 
      inherit name port;
      type = "ExternalName";
      externalName = externalName;
    };

  # Build a LoadBalancer Service
  loadBalancerService = { name, port ? 80, targetPort ? null, selector ? null, instance ? name, ... }:
    service { 
      inherit name port targetPort selector instance;
      type = "LoadBalancer";
    };

  # Build a NodePort Service
  nodePortService = { name, port ? 80, targetPort ? null, nodePort, selector ? null, instance ? name, ... }:
    service { 
      inherit name port targetPort selector instance;
      type = "NodePort";
      nodePort = nodePort;
    };

  # =============================================================================
  # INGRESS BUILDERS
  # =============================================================================

  # Build a standard Ingress resource
  ingress = { name, host, port ? 80, className ? "haproxy", tls ? true 
    , tlsSecret ? "opendesk-certificates-tls", annotations ? {}, paths ? null }:
    let
      defaultPaths = if paths != null then paths else [{
        path = "/";
        pathType = "Prefix";
        backend = { service = { name = name; port = { number = port; }; }; };
      }];
    in {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata = { inherit name annotations; };
      spec = {
        ingressClassName = className;
        rules = [{ host = host; http = { paths = defaultPaths; }; }];
      } // (if tls then { tls = [{ hosts = [ host ]; secretName = tlsSecret; }]; } else {});
    };

  # Build an Ingress with automatic certificate generation (requires cert-manager)
  ingressWithCert = { name, host, port ? 80, className ? "haproxy" 
    , issuerName ? "opendesk-ca", secretName ? "${name}-tls", certDuration ? "8760h" 
    , annotations ? {}, paths ? null }:
    let
      cert = certificate { 
        inherit name issuerName secretName;
        hostname = host;
        duration = certDuration;
      };
      ing = ingress { 
        inherit name host port className;
        tls = true;
        tlsSecret = secretName;
        annotations = annotations;
        paths = paths;
      };
    in [ cert ing ];

  # =============================================================================
  # AUTOSCALING BUILDERS
  # =============================================================================

  # Build a HorizontalPodAutoscaler
  hpa = { name, minReplicas ? 1, maxReplicas ? 10, targetCPU ? 70, targetMemory ? null, scaleTarget ? null }:
    let
      targetRef = if scaleTarget != null then scaleTarget else {
        apiVersion = "apps/v1";
        kind = "Deployment";
        name = name;
      };
      metrics = [{
        type = "Resource";
        resource = {
          name = "cpu";
          target = {
            type = "Utilization";
            averageUtilization = targetCPU;
          };
        };
      }] ++ (if targetMemory != null then [{
        type = "Resource";
        resource = {
          name = "memory";
          target = {
            type = "Utilization";
            averageUtilization = targetMemory;
          };
        };
      }] else []);
    in {
      apiVersion = "autoscaling/v2";
      kind = "HorizontalPodAutoscaler";
      metadata = { inherit name; };
      spec = {
        scaleTargetRef = targetRef;
        minReplicas = minReplicas;
        maxReplicas = maxReplicas;
        metrics = metrics;
        behavior = {
          scaleDown = {
            stabilizationWindowSeconds = 300;
            policies = [{
              type = "Pods";
              value = 1;
              periodSeconds = 60;
            }];
          };
          scaleUp = {
            stabilizationWindowSeconds = 60;
            policies = [{
              type = "Pods";
              value = 4;
              periodSeconds = 60;
            } {
              type = "Percent";
              value = 200;
              periodSeconds = 60;
            }];
          };
        };
      };
    };

  # =============================================================================
  # POD DISRUPTION BUDGET
  # =============================================================================

  # Build a PodDisruptionBudget
  pdb = { name, minAvailable ? null, maxUnavailable ? null, selector ? null, instance ? name }:
    let
      defaultSelector = if selector == null then {
        matchLabels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = instance;
        };
      } else selector;
    in {
      apiVersion = "policy/v1";
      kind = "PodDisruptionBudget";
      metadata = { inherit name; };
      spec = {
        selector = defaultSelector;
      } // (if minAvailable != null then { minAvailable = minAvailable; } else {})
        // (if maxUnavailable != null then { maxUnavailable = maxUnavailable; } else {});
    };

  # =============================================================================
  # NETWORK POLICY BUILDERS
  # =============================================================================

  # Build a NetworkPolicy allowing ingress from same namespace
  networkPolicy = { name, namespace, ports ? [ ], selector ? null, instance ? name }:
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
        policyTypes = [ "Ingress" "Egress" ];
        ingress = [{
          from = [
            { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = namespace; }; }; }
          ];
          ports = map (p: { protocol = "TCP"; port = p; }) ports;
        }];
        egress = [{
          to = [
            { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = namespace; }; };
            }
          ];
        }];
      };
    };

  # Build a NetworkPolicy allowing ingress from specific namespaces
  networkPolicyFromNamespaces = { name, allowedNamespaces ? [ ], ports ? [], selector ? null, instance ? name }:
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
        ingress = [
          {
            from = map (ns: { namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = ns; }; }; }) allowedNamespaces;
            ports = map (p: { protocol = "TCP"; port = p; }) ports;
          }
        ];
      };
    };

  # Build a NetworkPolicy allowing only DNS egress
  networkPolicyDnsOnly = { name, dnsServers ? [ "10.43.0.10" "8.8.8.8" "1.1.1.1" ], selector ? null, instance ? name }:
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
  # JOB BUILDERS
  # =============================================================================

  # Build a Job resource
  job = { name, image, tag ? "latest", command, args ? [ ], env ? [ ], backoffLimit ? 3 
    , completions ? 1, parallelism ? 1, ttlSecondsAfterFinished ? null 
    , serviceAccount ? null, restartPolicy ? "OnFailure" }:
    let
      container = {
        inherit name image;
        image = "${image}:${tag}";
        command = command;
        args = args;
        env = env;
        securityContext = { runAsNonRoot = true; runAsUser = 1000; capabilities = { drop = [ "ALL" ]; }; };
      };
    in {
      apiVersion = "batch/v1";
      kind = "Job";
      metadata = { inherit name; };
      spec = {
        inherit backoffLimit completions parallelism;
        ttlSecondsAfterFinished = ttlSecondsAfterFinished;
        template = {
          metadata = { name = name; };
          spec = {
            restartPolicy = restartPolicy;
            containers = [ container ];
          } // (if serviceAccount != null then { serviceAccountName = serviceAccount; } else {});
        };
      };
    };

  # Build a CronJob resource
  cronJob = { name, image, tag ? "latest", schedule, command, args ? [ ], env ? [ ]
    , backoffLimit ? 3, successfulJobsHistoryLimit ? 3, failedJobsHistoryLimit ? 1 
    , concurrencyPolicy ? "Allow", suspend ? false, serviceAccount ? null }:
    let
      container = {
        inherit name image;
        image = "${image}:${tag}";
        command = command;
        args = args;
        env = env;
        securityContext = { runAsNonRoot = true; runAsUser = 1000; capabilities = { drop = [ "ALL" ]; }; };
      };
    in {
      apiVersion = "batch/v1";
      kind = "CronJob";
      metadata = { inherit name; };
      spec = {
        schedule = schedule;
        jobTemplate = {
          spec = {
            template = {
              spec = {
                restartPolicy = "OnFailure";
                containers = [ container ];
              } // (if serviceAccount != null then { serviceAccountName = serviceAccount; } else {});
            };
          };
        };
        successfulJobsHistoryLimit = successfulJobsHistoryLimit;
        failedJobsHistoryLimit = failedJobsHistoryLimit;
        concurrencyPolicy = concurrencyPolicy;
        suspend = suspend;
      };
    };

  # =============================================================================
  # CONFIG AND STORAGE BUILDERS
  # =============================================================================

  # Build a ConfigMap
  configMap = { name, data, annotations ? {}, labels ? {} }:
    {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = { inherit name annotations labels; };
      data = data;
    };

  # Build a Secret (for non-sensitive data, use sealed-secrets for production)
  secret = { name, stringData ? {}, data ? {}, type ? "Opaque", annotations ? {}, labels ? {} }:
    {
      apiVersion = "v1";
      kind = "Secret";
      metadata = { inherit name annotations labels; };
      type = type;
    } // (if stringData != {} then { stringData = stringData; } else {})
      // (if data != {} then { data = data; } else {});

  # Build a PersistentVolumeClaim
  pvc = { name, accessModes ? [ "ReadWriteOnce" ], storageSize ? "10Gi", storageClass ? null 
    , volumeMode ? "Filesystem", annotations ? {}, labels ? {} }:
    {
      apiVersion = "v1";
      kind = "PersistentVolumeClaim";
      metadata = { inherit name annotations labels; };
      spec = {
        accessModes = accessModes;
        resources = { requests = { storage = storageSize; }; };
      } // (if storageClass != null then { storageClassName = storageClass; } else {})
        // (if volumeMode != "Filesystem" then { volumeMode = volumeMode; } else {});
    };

  # Build a Namespace
  namespace = { name, annotations ? {}, labels ? {} }:
    {
      apiVersion = "v1";
      kind = "Namespace";
      metadata = { inherit name annotations labels; };
    };

  # =============================================================================
  # SERVICE ACCOUNT AND RBAC
  # =============================================================================

  # Build a ServiceAccount
  serviceAccount = { name, secrets ? [ ], imagePullSecrets ? [ ], annotations ? {}, defaultToken ? true }:
    {
      apiVersion = "v1";
      kind = "ServiceAccount";
      metadata = { inherit name annotations; };
      secrets = secrets;
      imagePullSecrets = imagePullSecrets;
    };

  # Build a Role
  role = { name, rules, namespace }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "Role";
      metadata = { inherit name; namespace = namespace; };
      rules = rules;
    };

  # Build a ClusterRole
  clusterRole = { name, rules }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRole";
      metadata = { inherit name; };
      rules = rules;
    };

  # Build a RoleBinding
  roleBinding = { name, roleRef, subjects, namespace }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "RoleBinding";
      metadata = { inherit name; namespace = namespace; };
      subjects = subjects;
      roleRef = roleRef;
    };

  # Build a ClusterRoleBinding
  clusterRoleBinding = { name, clusterRoleRef, subjects }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRoleBinding";
      metadata = { inherit name; };
      subjects = subjects;
      roleRef = clusterRoleRef;
    };

  # =============================================================================
  # CERT-MANAGER INTEGRATION
  # =============================================================================

  # Build a cert-manager Certificate resource
  certificate = { name, hostname, issuerName ? "opendesk-ca", secretName ? "${name}-tls" 
    , namespace ? "opendesk", duration ? "8760h", renewBefore ? "360h", dnsNames ? [ hostname ] }:
    {
      apiVersion = "cert-manager.io/v1";
      kind = "Certificate";
      metadata = { inherit name namespace; };
      spec = {
        secretName = secretName;
        duration = duration;
        renewBefore = renewBefore;
        issuerRef = {
          name = issuerName;
          kind = "ClusterIssuer";
          group = "cert-manager.io";
        };
        dnsNames = dnsNames;
      };
    };

  # Build a cert-manager Issuer (namespace-scoped)
  issuer = { name, caSecretName, namespace }:
    {
      apiVersion = "cert-manager.io/v1";
      kind = "Issuer";
      metadata = { inherit name namespace; };
      spec = {
        ca = { secretName = caSecretName; };
      };
    };

  # Build a cert-manager ClusterIssuer (cluster-scoped)
  clusterIssuer = { name, caSecretName }:
    {
      apiVersion = "cert-manager.io/v1";
      kind = "ClusterIssuer";
      metadata = { inherit name; };
      spec = {
        ca = { secretName = caSecretName; };
      };
    };

  # =============================================================================
  # ENVIRONMENT VARIABLE HELPERS
  # =============================================================================

  # Helper to reference a secret as envFrom
  mkEnvFromSecret = { secret }:
    { secretRef = { name = secret; }; };

  # Helper to reference a configMap as envFrom
  mkEnvFromConfigMap = { configMap }:
    { configMapRef = { name = configMap; optional = false; }; };

  # Helper to reference a single secret key as env var
  mkEnvVarFromSecret = { name, key, secret }:
    { name = name; valueFrom = { secretKeyRef = { name = secret; key = key; }; }; };

  # Helper to reference a single configMap key as env var
  mkEnvVarFromConfigMap = { name, key, configMap }:
    { name = name; valueFrom = { configMapKeyRef = { name = configMap; key = key; }; }; };

  # Helper to create an env var from a field reference
  mkEnvVarFromField = { name, fieldPath }:
    { name = name; valueFrom = { fieldRef = { fieldPath = fieldPath; }; }; };

  # =============================================================================
  # VOLUME HELPERS
  # =============================================================================

  # Helper to create a volume and volumeMount
  mkVolume = { name, mountPath, subPath ? null, secret ? null, configMap ? null, items ? null 
    , hostPath ? null, emptyDir ? null, pvc ? null, persistentVolumeClaim ? null, readOnly ? true }:
    let
      volumeDef = { inherit name; } //
        (if secret != null then { secret = { secretName = secret; } // (if items != null then { items = items; } else {}); }
        else if configMap != null then { configMap = { name = configMap; } // (if items != null then { items = items; } else {}); }
        else if hostPath != null then { hostPath = { path = hostPath; type = "DirectoryOrCreate"; };
        }
        else if emptyDir != null then { emptyDir = emptyDir; }
        else if pvc != null || persistentVolumeClaim != null then { 
          persistentVolumeClaim = { claimName = if pvc != null then pvc else persistentVolumeClaim; };
        }
        else { emptyDir = {}; });
      
      mountDef = { inherit name mountPath; } //
        (if subPath != null then { subPath = subPath; } else {}) //
        { readOnly = readOnly; };
    in {
      inherit volumeDef mountDef;
    };

  # Helper for emptyDir volume
  emptyDirVolume = { name, mountPath, medium ? null, sizeLimit ? null, readOnly ? true }:
    {
      volume = { inherit name; emptyDir = {} // (if medium != null then { medium = medium; } else {})
        // (if sizeLimit != null then { sizeLimit = sizeLimit; } else {}); };
      mount = { inherit name mountPath readOnly; };
    };

  # Helper for hostPath volume
  hostPathVolume = { name, mountPath, path, type ? "DirectoryOrCreate", readOnly ? true }:
    {
      volume = { inherit name; hostPath = { inherit path type; }; };
      mount = { inherit name mountPath readOnly; };
    };

  # Helper for PVC volume
  pvcVolume = { name, mountPath, claimName, readOnly ? true, subPath ? null }:
    {
      volume = { inherit name; persistentVolumeClaim = { inherit claimName; }; };
      mount = { inherit name mountPath readOnly; } // (if subPath != null then { subPath = subPath; } else {});
    };

  # =============================================================================
  # NODE AFFINITY HELPERS
  # =============================================================================

  # Prefer nodes with specific label
  mkPreferNodeLabel = { label, value }:
    {
      preferredDuringSchedulingIgnoredDuringExecution = [{
        weight = 100;
        preference = {
          matchExpressions = [{
            key = label;
            operator = "In";
            values = [ value ];
          }];
        };
      }];
    };

  # Require nodes with specific label
  mkRequireNodeLabel = { label, value }:
    {
      nodeSelector = { "${label}" = value; };
    };

  # Require nodes with specific label (match expression)
  mkRequireNodeLabelExpr = { label, operator ? "In", values }:
    {
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [{
              matchExpressions = [{
                inherit label operator;
                values = values;
              }];
            }];
          };
        };
      };
    };

  # =============================================================================
  # POLICY TYPES
  # =============================================================================

  podDisruptionBudgetType = lib.types.enum [ "minAvailable" "maxUnavailable" ];
  
  # =============================================================================
  # EXPORT ALL
  # =============================================================================

in {
  inherit
    # Security contexts
    securityContext writeableSecurityContext databaseSecurityContext
    
    # Probes
    tcpProbe httpProbe commandProbe
    
    # Resource defaults
    defaultResources smallResources databaseResources largeResources frontendResources cacheResources
    
    # Container and Pod builders
    mkContainer podSpec
    
    # Workload builders
    deployment statefulset daemonSet
    
    # Service builders
    service headlessService externalService loadBalancerService nodePortService
    
    # Ingress builders
    ingress ingressWithCert
    
    # Autoscaling
    hpa
    
    # Pod Disruption Budget
    pdb
    
    # Network policies
    networkPolicy networkPolicyFromNamespaces networkPolicyDnsOnly
    
    # Job builders
    job cronJob
    
    # Config and Storage
    configMap secret pvc namespace
    
    # Service Account and RBAC
    serviceAccount role clusterRole roleBinding clusterRoleBinding
    
    # cert-manager
    certificate issuer clusterIssuer
    
    # Environment helpers
    mkEnvFromSecret mkEnvFromConfigMap mkEnvVarFromSecret mkEnvVarFromConfigMap mkEnvVarFromField
    
    # Volume helpers
    mkVolume emptyDirVolume hostPathVolume pvcVolume
    
    # Node affinity helpers
    mkPreferNodeLabel mkRequireNodeLabel mkRequireNodeLabelExpr
    
    # Utility
    toYAML
    ;
}
