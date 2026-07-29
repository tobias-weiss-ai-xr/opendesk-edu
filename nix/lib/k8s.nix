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

  defaultResources = {
    requests = { cpu = "100m"; memory = "128Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };

  mkContainer = { name, image, tag, port, env, resources, probes }:
    let
      base = {
        inherit name;
        image = "${image}:${tag}";
        imagePullPolicy = "IfNotPresent";
        ports = [{ containerPort = port; }];
        inherit securityContext;
        inherit env;
        resources = resources // defaultResources;
      };
      probeAttrs = if probes then {
        livenessProbe = tcpProbe port;
        readinessProbe = tcpProbe port;
      } else {};
    in
    base // probeAttrs;

  deployment = { name, image, tag ? "latest", port ? 80, replicas ? 1, env ? [ ], resources ? defaultResources, probes ? true }: {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      inherit name;
      labels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      };
    };
    spec = {
      replicas = replicas;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = name;
        };
      };
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = name;
            "app.kubernetes.io/instance" = name;
          };
        };
        spec = {
          securityContext = { fsGroup = 1000; };
          containers = [ (mkContainer { inherit name image tag port env resources probes; }) ];
        };
      };
    };
  };

  service = { name, port ? 80, targetPort ? port }: {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      inherit name;
      labels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      };
    };
    spec = {
      ports = [{
        port = port;
        targetPort = targetPort;
      }];
      selector = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      };
    };
  };

  ingress = { name, host, port ? 80, className ? "haproxy", tls ? true }: {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      inherit name;
      annotations = {
        "haproxy-ingress.github.io/ssl-redirect" = "true";
      };
    };
    spec = {
      ingressClassName = className;
      rules = [{
        inherit host;
        http = {
          paths = [{
            path = "/";
            pathType = "Prefix";
            backend = {
              service = {
                name = name;
                port = { number = port; };
              };
            };
          }];
        };
      }];
    } // (if tls then {
      tls = [{ hosts = [ host ]; secretName = "opendesk-certificates-tls"; }];
    } else {});
  };

  statefulset = { name, image, tag ? "latest", port ? 80, replicas ? 1, env ? [ ], resources ? defaultResources, probes ? true, storageSize ? "10Gi", storageClass ? "" }: {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      inherit name;
      labels = {
        "app.kubernetes.io/name" = name;
        "app.kubernetes.io/instance" = name;
      };
    };
    spec = {
      serviceName = name;
      replicas = replicas;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = name;
          "app.kubernetes.io/instance" = name;
        };
      };
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = name;
            "app.kubernetes.io/instance" = name;
          };
        };
        spec = {
          securityContext = { fsGroup = 1000; };
          containers = [ (mkContainer { inherit name image tag port env resources probes; }) ];
        };
      };
    };
  };

in
{
  inherit toYAML securityContext tcpProbe defaultResources deployment service ingress statefulset mkContainer;
}
