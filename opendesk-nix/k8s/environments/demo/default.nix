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
    version = "v1.36.3+k3s1";
    ha = false;
    embeddedEtcd = false;
    nodes = 1;
    cni = "flannel";
    cri = "containerd";
    loadBalancer = "metallb";
    ingressController = "haproxy";
    storageDriver = "ceph-csi";
  };

  ingress = {
    className = "haproxy";
    domain = "demo.opendesk-edu.org";
    annotations = {
      "haproxy-ingress.github.io/ssl-redirect" = "true";
      "haproxy-ingress.github.io/proxy-body-size" = "50M";
    };
  };

  tls = {
    enabled = true;
    secretName = "opendesk-demo-tls";
    issuer = "opendesk-ca";
  };

  storage = {
    rwx = "ceph-cephfs";
    rwo = "ceph-rbd";
    defaultClass = "ceph-rbd";
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
