// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Demo Environment Configuration

This environment configuration is for the demo cluster used for testing
and development purposes, running on SCS-K3s.
"""

{ lib, ... }:

{
  namespace = "opendesk-demo";

  # ── Cluster Configuration (SCS-K3s) ──
  cluster = {
    type = "k3s";
    version = "v1.31.2+k3s1";
    ha = false;
    embeddedEtcd = false;
    nodes = 1;
    cni = "flannel";
    cri = "containerd";
    loadBalancer = "servicelb";
    ingressController = "traefik";
    storageDriver = "local-path";
  };

  ingress = {
    className = "traefik";
    domain = "demo.opendesk-edu.org";
    annotations = {
      "traefik.ingress.kubernetes.io/ssl-redirect" = "true";
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
      "traefik.ingress.kubernetes.io/router.tls" = "true";
    };
  };

  tls = {
    enabled = true;
    secretName = "opendesk-demo-tls";
    issuer = "letsencrypt-prod";
  };

  storage = {
    rwx = "local-path";
    rwo = "local-path";
    defaultClass = "local-path";
  };

  networking = {
    proxy = "";
    dns = [ "8.8.8.8" "8.8.4.4" ];
    noProxy = [ "localhost" "127.0.0.1" ];
  };

  resources = {
    small = { cpu = "100m"; memory = "128Mi"; };
    medium = { cpu = "200m"; memory = "256Mi"; };
    large = { cpu = "500m"; memory = "512Mi"; };
    database = { cpu = "1"; memory = "1Gi"; };
  };

  replicas = {
    min = 1;
    max = 2;
    default = 1;
  };

  monitoring = {
    enabled = true;
    prometheus = true;
    grafana = false;
  };

  security = {
    podSecurityAdmission = "privileged";  # Demo environment - less restrictive
    networkPolicies = false;
    readOnlyRootFilesystem = false;
  };
}
