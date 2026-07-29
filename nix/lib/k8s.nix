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

  httpProbe = { path ? "/health", port ? 80 }: {
    httpGet = { path = path; port = port; };
    initialDelaySeconds = 30;
    periodSeconds = 10;
  };

  defaultResources = {
    requests = { cpu = "100m"; memory = "128Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };

  # Build environment variables from attrs
  mkEnv = env:
    builtins.map (name: {
      inherit name;
      value = env.${name};
    }) (builtins.attrNames env);

  # Environment from secrets
  mkEnvFromSecret = { name, key, secret }: {
    name = name;
    valueFrom = { secretKeyRef = { name = secret; key = key; }; };
  };

  # Volume mounts for configs/secrets
  mkVolume = { name, mountPath, subPath ? null, secret ? null, configMap ? null, items ? null }: {
    volume = {
      inherit name;
    } // (if secret != null then { secret = { secretName = secret; }; }
       else if configMap != null then { configMap = { name = configMap; }; }
       else {});
    mount = {
      inherit name mountPath;
    } // (if subPath != null then { subPath = subPath; } else {});
  };

  # Container builder (now supports init containers and sidecars)
  mkContainer = { name, image, tag ? "latest", port ? null, ports ? [ ], env ? [ ], envFrom ? [ ], resources ? defaultResources, probes ? true, volumes ? [ ], command ? null, args ? null }:
    let
      base = {
        inherit name;
        image = "${image}:${tag}";
        imagePullPolicy = "IfNotPresent";
      } // (if command != null then { command = command; } else {})
        // (if args != null then { args = args; } else {});
      withPorts = if port != null then base // { ports = [{ containerPort = port; }] ++ ports; } else base // { ports = ports; };
      withEnv = withPorts // { env = env ++ envFrom; };
      withResources = withEnv // { resources = resources // defaultResources; };
      withProbes = if probes then withResources // {
        livenessProbe = tcpProbe (if port != null then port else 80);
        readinessProbe = tcpProbe (if port != null then port else 80);
      } else withResources;
    in withProbes;

  # Full deployment with init containers, volumes, sidecars
  deployment = { name, image, tag ? "latest", port ? 80, replicas ? 1
    , env ? [ ], envFrom ? [ ]
    , resources ? defaultResources, probes ? true
    , volumes ? [ ], extraContainers ? [ ], initContainers ? [ ]
  }: {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = { inherit name; labels = {
      "app.kubernetes.io/name" = name;
      "app.kubernetes.io/instance" = name;
    }; };
    spec = {
      replicas = replicas;
      selector = { matchLabels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      }; };
      template = {
        metadata = { labels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = name;
        }; };
        spec = {
          securityContext = { fsGroup = 1000; };
          initContainers = initContainers;
          containers = [
            (mkContainer { inherit name image tag port env envFrom resources probes volumes; })
          ] ++ extraContainers;
          volumes = map (v: v.volume) volumes;
        };
      };
    };
  };

  service = { name, port ? 80, targetPort ? port }: {
    apiVersion = "v1";
    kind = "Service";
    metadata = { inherit name; labels = {
      "app.kubernetes.io/name" = name;
      "app.kubernetes.io/instance" = name;
    }; };
    spec = {
      ports = [{ port = port; targetPort = targetPort; }];
      selector = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      };
    };
  };

  ingress = { name, host, port ? 80, className ? "haproxy", tls ? true, annotations ? {} }: {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      inherit name;
      annotations = { "haproxy-ingress.github.io/ssl-redirect" = "true"; } // annotations;
    };
    spec = {
      ingressClassName = className;
      rules = [{
        inherit host;
        http.paths = [{ path = "/"; pathType = "Prefix"; backend.service = { name = name; port = { number = port; }; }; }];
      }];
    } // (if tls then { tls = [{ hosts = [ host ]; secretName = "opendesk-certificates-tls"; }]; } else {});
  };

  statefulset = { name, image, tag ? "latest", port ? 80, replicas ? 1
    , env ? [ ], envFrom ? [ ]
    , resources ? defaultResources, probes ? true
    , storageSize ? "10Gi", storageClass ? null
    , volumes ? [ ], extraContainers ? [ ], initContainers ? [ ]
  }: {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = { inherit name; labels = {
      "app.kubernetes.io/name" = name;
      "app.kubernetes.io/instance" = name;
    }; };
    spec = {
      serviceName = name;
      replicas = replicas;
      selector = { matchLabels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      }; };
      template = {
        metadata = { labels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = name;
        }; };
        spec = {
          securityContext = { fsGroup = 1000; };
          initContainers = initContainers;
          containers = [
            (mkContainer { inherit name image tag port env envFrom resources probes volumes; })
          ] ++ extraContainers;
          volumes = map (v: v.volume) volumes;
        };
      };
    };
  };

  # ConfigMap generator
  configMap = { name, data }: {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { inherit name; };
    data = data;
  };

in {
  inherit deployment service ingress statefulset configMap
    securityContext tcpProbe httpProbe defaultResources
    mkEnv mkEnvFromSecret mkVolume mkContainer;
}
