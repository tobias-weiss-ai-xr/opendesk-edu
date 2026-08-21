// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Local Development Environment Configuration

This environment configuration is for local development (Minikube, KIND, K3s local)
running on a single-node K3s instance.
"""

{ lib, ... }:

{
  namespace = "opendesk-local";

  # ── Cluster Configuration (K3s local) ──
  cluster = {
    type = "k3s";
    version = "v1.36.3+k3s1";
    ha = false;
    embeddedEtcd = false;
    nodes = 1;
    cni = "flannel";
    cri = "containerd";
    loadBalancer = "servicelb";
    ingressController = "haproxy";
    storageDriver = "local-path";
  };

  ingress = {
    className = "haproxy";
    domain = "localhost";
    annotations = { };
  };

  tls = {
    enabled = false;
    secretName = "";
    issuer = "";
  };

  storage = {
    rwx = "local-path";
    rwo = "local-path";
    defaultClass = "local-path";
    useDynamicProvisioning = false;
  };

  networking = {
    proxy = "";
    dns = [ "8.8.8.8" "8.8.4.4" ];
    noProxy = [ "localhost" "127.0.0.1" "10.0.0.0/8" ];
  };

  resources = {
    small = { cpu = "50m"; memory = "64Mi"; };
    medium = { cpu = "100m"; memory = "128Mi"; };
    large = { cpu = "200m"; memory = "256Mi"; };
    database = { cpu = "200m"; memory = "256Mi"; };
  };

  replicas = {
    min = 1;
    max = 1;
    default = 1;
  };

  monitoring = {
    enabled = false;
    prometheus = false;
    grafana = false;
  };

  security = {
    podSecurityAdmission = "privileged";  # Local dev - allow more
    networkPolicies = false;
    readOnlyRootFilesystem = false;
  };

  # Local dev specific
  localDev = {
    useLoadBalancer = false;
    useNodePort = true;
    exposeServices = true;
  };
}
