{ pkgs }:

let
  toYAML = value: builtins.toJSON value;

  securityContext = {
    allowPrivilegeEscalation = false;
    runAsNonRoot = true;
    runAsUser = 1000;
    runAsGroup = 1000;
    capabilities = { drop = [ "ALL" ]; };
  };

  tcpProbe = port: {
    tcpSocket = { port = port; };
    initialDelaySeconds = 30;
    periodSeconds = 10;
  };

  httpProbe = { path ? "/healthz", port ? 80, initialDelaySeconds ? 30, periodSeconds ? 10 }: {
    httpGet = { path = path; port = port; };
    inherit initialDelaySeconds periodSeconds;
  };

  commandProbe = { command, initialDelaySeconds ? 5, periodSeconds ? 10 }: {
    exec = { command = command; };
    inherit initialDelaySeconds periodSeconds;
  };

  defaultResources = {
    requests = { cpu = "100m"; memory = "128Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };

  mkContainer = { name, image, tag ? "latest", port ? null, ports ? [ ]
    , env ? [ ], envFrom ? [ ], resources ? defaultResources
    , probes ? true, probeType ? "tcp", probePath ? "/healthz", probePort ? null
    , volumes ? [ ], command ? null, args ? null
    , securityContext ? null, lifecycle ? null
  }:
    let
      base = {
        inherit name;
        image = "${image}:${tag}";
        imagePullPolicy = "IfNotPresent";
      } // (if command != null then { command = command; } else {})
        // (if args != null then { args = args; } else {})
        // (if lifecycle != null then { lifecycle = lifecycle; } else {});
      withPorts = if port != null then base // { ports = [{ containerPort = port; }] ++ ports; } else base // { ports = ports; };
      withEnv = withPorts // { env = env ++ envFrom; };
      withResources = withEnv // { resources = resources // defaultResources; };
      withSec = if securityContext != null then withResources // { securityContext = securityContext; } else withResources;
      withProbes = if probes then withSec // (
        if probeType == "http" then {
          livenessProbe = httpProbe { path = probePath; port = if probePort != null then probePort else port; };
          readinessProbe = httpProbe { path = probePath; port = if probePort != null then probePort else port; };
        } else {
          livenessProbe = tcpProbe (if probePort != null then probePort else if port != null then port else 80);
          readinessProbe = tcpProbe (if probePort != null then probePort else if port != null then port else 80);
        }
      ) else withSec;
      volumeMounts = map (v: v.mount) volumes;
    in withProbes // { inherit volumeMounts; };

  # Full pod spec builder (shared between Deployment, StatefulSet, DaemonSet, Job)
  podSpec = { name, image, tag ? "latest", port ? null, ports ? [ ]
    , replicas ? 1, env ? [ ], envFrom ? [ ]
    , resources ? defaultResources, probes ? true, probeType ? "tcp"
    , volumes ? [ ], extraContainers ? [ ], initContainers ? [ ]
    , nodeSelector ? null, affinity ? null, tolerations ? null
    , priorityClassName ? null, terminationGracePeriodSeconds ? null
    , dnsConfig ? null, hostAliases ? null, dnsPolicy ? null
    , imagePullSecrets ? null, serviceAccountName ? null
    , podAnnotations ? {}, podLabels ? {}
    , topologySpreadConstraints ? null
    , securityContext ? null
  }:
    let
      defaultLabels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      };
      mergedLabels = defaultLabels // podLabels;
    in {
      metadata = {
        inherit name;
        labels = mergedLabels;
      } // (if podAnnotations != {} then { annotations = podAnnotations; } else {});
      spec = {
        replicas = replicas;
        selector = { matchLabels = { "app.kubernetes.io/name" = name; "app.kubernetes.io/instance" = name; }; };
        template = {
          metadata = { labels = mergedLabels; };
          spec = {
            securityContext = (if securityContext != null then securityContext else { fsGroup = 1000; });
            containers = [
              (mkContainer { inherit name image tag port ports env envFrom resources probes probeType volumes; })
            ] ++ extraContainers;
            volumes = map (v: v.volume) volumes;
          }
            // (if initContainers != null then { initContainers = initContainers; } else {})
            // (if nodeSelector != null then { nodeSelector = nodeSelector; } else {})
            // (if affinity != null then { affinity = affinity; } else {})
            // (if tolerations != null then { tolerations = tolerations; } else {})
            // (if priorityClassName != null then { priorityClassName = priorityClassName; } else {})
            // (if terminationGracePeriodSeconds != null then { terminationGracePeriodSeconds = terminationGracePeriodSeconds; } else {})
            // (if dnsConfig != null then { dnsConfig = dnsConfig; } else {})
            // (if hostAliases != null then { hostAliases = hostAliases; } else {})
            // (if dnsPolicy != null then { dnsPolicy = dnsPolicy; } else {})
            // (if imagePullSecrets != null then { imagePullSecrets = imagePullSecrets; } else {})
            // (if serviceAccountName != null then { serviceAccountName = serviceAccountName; } else {})
            // (if topologySpreadConstraints != null then { topologySpreadConstraints = topologySpreadConstraints; } else {});
          
        };
      };
    };

  deployment = args:
    let ps = podSpec args;
    in {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = builtins.removeAttrs ps.metadata [ "spec" ];
      spec = (builtins.removeAttrs ps.spec [ "template" ]) // { template = if builtins.hasAttr "template" ps.spec then ps.spec.template else {}; };
    };

  statefulset = args:
    let ps = podSpec args;
    in {
      apiVersion = "apps/v1";
      kind = "StatefulSet";
      metadata = builtins.removeAttrs ps.metadata [ "spec" ];
      spec = (builtins.removeAttrs ps.spec [ "template" ]) // { serviceName = args.name; template = if builtins.hasAttr "template" ps.spec then ps.spec.template else {}; };
    };

  daemonSet = args:
    let ps = podSpec (args // { replicas = null; });
    in {
      apiVersion = "apps/v1";
      kind = "DaemonSet";
      metadata = builtins.removeAttrs ps.metadata [ "spec" ];
      spec = (builtins.removeAttrs ps.spec [ "replicas" "template" ]) // { template = if builtins.hasAttr "template" ps.spec then ps.spec.template else {}; };
    };

  service = { name, port ? 80, targetPort ? null, type ? "ClusterIP", clusterIP ? null, ports ? [ ], annotations ? {} }: {
    apiVersion = "v1";
    kind = "Service";
    metadata = { inherit name annotations; };
    spec = {
      ports = [ { port = port; targetPort = if targetPort != null then targetPort else port; } ] ++ ports;
      selector = { "app.kubernetes.io/name" = name; "app.kubernetes.io/instance" = name; };
    } // (if type != "ClusterIP" then { type = type; } else {})
      // (if clusterIP != null then { clusterIP = clusterIP; } else {});
  };

  headlessService = { name, port ? 80 }: service { inherit name port; clusterIP = "None"; };

  ingress = { name, host, port ? 80, className ? "haproxy", tls ? true, tlsSecret ? "opendesk-certificates-tls", annotations ? {}, paths ? null, certIssuer ? null, certDuration ? "8760h" }: {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = { inherit name annotations; };
    spec = {
      ingressClassName = className;
      rules = [{
        inherit host;
        http.paths = (
          if paths != null then paths
          else [{ path = "/"; pathType = "Prefix"; backend.service = { name = name; port = { number = port; }; }; }]
        );
      }];
    } // (if tls then { tls = [{ hosts = [ host ]; secretName = tlsSecret; }]; } else {});
  };

  # Ingress with automatic certificate generation
  ingressWithCert = { name, host, port ? 80, className ? "haproxy", issuerName ? "opendesk-ca", secretName ? "${name}-tls", certDuration ? "8760h", annotations ? {}, paths ? null }:
    [
      (certificate { inherit name issuerName secretName; hostname = host; duration = certDuration; })
      (ingress {inherit name host port className; tls = true; tlsSecret = secretName; annotations = annotations; paths = paths;})
    ];

  configMap = { name, data }: { apiVersion = "v1"; kind = "ConfigMap"; metadata = { inherit name; }; inherit data; };

  hpa = { name, minReplicas ? 1, maxReplicas ? 10, targetCPU ? 70 }: {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = { inherit name; };
    spec = {
      scaleTargetRef = { apiVersion = "apps/v1"; kind = "Deployment"; inherit name; };
      minReplicas = minReplicas; maxReplicas = maxReplicas;
      metrics = [{ type = "Resource"; resource = { name = "cpu"; target = { type = "Utilization"; averageUtilization = targetCPU; }; }; }];
    };
  };

  pdb = { name, minAvailable ? 1 }: {
    apiVersion = "policy/v1";
    kind = "PodDisruptionBudget";
    metadata = { inherit name; };
    spec = {
      selector = { matchLabels = { "app.kubernetes.io/name" = name; "app.kubernetes.io/instance" = name; }; };
      inherit minAvailable;
    };
  };

  networkPolicy = { name, namespace, ports ? [ ] }: {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = { inherit name; };
    spec = {
      podSelector = { matchLabels = { "app.kubernetes.io/name" = name; "app.kubernetes.io/instance" = name; }; };
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{ namespaceSelector = { matchLabels = { "kubernetes.io/metadata.name" = namespace; }; }; }];
        ports = map (p: { protocol = "TCP"; port = p; }) ports;
      }];
    };
  };

  job = { name, image, tag ? "latest", command, env ? [ ], backoffLimit ? 3 }: {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = { inherit name; };
    spec = {
      backoffLimit = backoffLimit;
      template.spec = {
        restartPolicy = "OnFailure";
        containers = [(mkContainer { inherit name image tag command env; probes = false; })];
      };
    };
  };

  cronJob = { name, image, tag ? "latest", schedule, command, env ? [ ], backoffLimit ? 3 }: {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = { inherit name; };
    spec = {
      inherit schedule;
      jobTemplate.spec = {
        backoffLimit = backoffLimit;
        template.spec = {
          restartPolicy = "OnFailure";
          containers = [(mkContainer { inherit name image tag command env; probes = false; })];
        };
      };
    };
  };

  serviceAccount = { name, annotations ? {} }: {
    apiVersion = "v1";
    kind = "ServiceAccount";
    metadata = { inherit name annotations; };
  };

  # cert-manager Certificate resource
  certificate = { name, hostname, issuerName ? "opendesk-ca", secretName ? "${name}-tls", namespace ? "opendesk", duration ? "8760h" }: {
    apiVersion = "cert-manager.io/v1";
    kind = "Certificate";
    metadata = { inherit name namespace; };
    spec = {
      secretName = secretName;
      duration = duration;
      renewBefore = "360h";  # 15 days
      issuerRef = {
        name = issuerName;
        kind = "ClusterIssuer";
        group = "cert-manager.io";
      };
      dnsNames = [ hostname ];
    };
  };

  # Volume helpers
  mkVolume = { name, mountPath, subPath ? null, secret ? null, configMap ? null, items ? null, hostPath ? null }: {
    volume = { inherit name; } // (if secret != null then { secret = { secretName = secret; }; }
       else if configMap != null then { configMap = { name = configMap; }; }
       else if hostPath != null then { hostPath = { path = hostPath; }; }
       else { emptyDir = {}; });
    mount = { inherit name mountPath; } // (if subPath != null then { subPath = subPath; } else {});
  };

  emptyDir = { name, mountPath, medium ? null }: {
    volume = { inherit name; emptyDir = {} // (if medium != null then { medium = medium; } else {}); };
    mount = { inherit name mountPath; };
  };

  hostPath = { name, mountPath, path, type ? "Directory" }: {
    volume = { inherit name; hostPath = { inherit path type; }; };
    mount = { inherit name mountPath; };
  };

  pvc = { name, accessModes ? [ "ReadWriteOnce" ], storageSize ? "10Gi", storageClass ? null }: {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = { inherit name; };
    spec = {
      inherit accessModes;
      resources.requests.storage = storageSize;
    } // (if storageClass != null then { storageClassName = storageClass; } else {});
  };

  namespace = { name }: { apiVersion = "v1"; kind = "Namespace"; metadata = { inherit name; }; };

in {
  inherit
    deployment statefulset daemonSet
    service headlessService ingress ingressWithCert
    configMap pvc namespace
    certificate
    hpa pdb networkPolicy job cronJob serviceAccount
    podSpec mkContainer
    mkVolume emptyDir hostPath
    securityContext tcpProbe httpProbe commandProbe defaultResources
    toYAML;
}
