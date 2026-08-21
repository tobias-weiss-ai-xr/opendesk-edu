// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
HRZ Production Environment Configuration

This environment configuration is for the HRZ Marburg production cluster
running on SCS-K3s (Sovereign Cloud Stack with K3s lightweight Kubernetes).

Cluster: 3× Huawei RH2288E V2 (clrz14-06, clrz14-07, clrz14-08)
K3s v1.36.3+k3s1, HAProxy ingress, Ceph-CSI storage, MetalLB.
Domain: desk-test.uni-marburg.de (currently home.opendesk-edu.org)
"""

{ lib, ... }:

{
  namespace = "opendesk";

  # ── Cluster Configuration (SCS-K3s) ──
  cluster = {
    type = "k3s";
    version = "v1.36.3+k3s1";
    ha = true;
    embeddedEtcd = true;
    nodes = 3;
    cni = "flannel";
    cri = "containerd";
    loadBalancer = "metallb";
    ingressController = "haproxy";
    storageDriver = "ceph-csi";
    # MetalLB IP pool
    loadBalancerPool = "rz03-fip-pool";
    loadBalancerRange = "172.25.3.181-172.25.3.196";
  };

  ingress = {
    className = "haproxy";
    domain = "desk-test.uni-marburg.de";
    # HAProxy annotations matching existing cluster setup
    annotations = {
      "haproxy-ingress.github.io/ssl-redirect" = "true";
      "haproxy-ingress.github.io/proxy-body-size" = "50M";
      "haproxy-ingress.github.io/timeout-server" = "300s";
    };
  };

  tls = {
    enabled = true;
    secretName = "opendesk-certificates-tls";
    issuer = "opendesk-ca";
  };

  # ── Storage (Ceph-CSI, actual cluster storage classes) ──
  storage = {
    rwx = "ceph-cephfs";
    rwo = "ceph-rbd";
    defaultClass = "ceph-rbd";
    # Tenant-isolierte Storage-Klassen (separate Ceph-Pools — to be created)
    staff = "ceph-rbd-staff";
    students = "ceph-rbd-students";
  };

  networking = {
    proxy = "http://www-proxy2.uni-marburg.de:3128";
    dns = [ "137.248.21.22" "137.248.1.5" "137.248.1.8" ];
    noProxy = [ "192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12" ];
  };

  resources = {
    small  = { cpu = "100m";  memory = "128Mi"; };
    medium = { cpu = "500m";  memory = "512Mi"; };
    large  = { cpu = "2";     memory = "2Gi";   };
    database = { cpu = "2";   memory = "4Gi";   };
    # Tenant-spezifische Ressourcen
    mail-staff    = { cpu = "1"; memory = "2Gi"; };
    mail-students = { cpu = "500m"; memory = "1Gi"; };
  };

  replicas = {
    min = 1;
    max = 3;
    default = 2;
  };

  monitoring = {
    enabled = true;
    prometheus = true;
    grafana = true;
  };

  security = {
    podSecurityAdmission = "baseline";
    networkPolicies = true;
    readOnlyRootFilesystem = true;
  };

  # ── Tenant-Konfiguration ──
  tenants = {
    shared = {
      namespace = "opendesk";
      mailDomain = "desk-test.uni-marburg.de";
      storageClass = "ceph-rbd";
      backupPipeline = "opendesk-backup";
    };
    staff = {
      namespace = "opendesk-staff";
      mailDomain = "staff.uni-marburg.de";
      storageClass = "ceph-rbd-staff";
      backupPipeline = "staff-backup";
      mailQuota = "50GB";
      resources = {
        sogo = { cpu = "1"; memory = "2Gi"; };
        postfix = { cpu = "500m"; memory = "512Mi"; };
        dovecot = { cpu = "1"; memory = "2Gi"; };
        xwiki = { cpu = "500m"; memory = "1Gi"; };
      };
    };
    students = {
      namespace = "opendesk-students";
      mailDomain = "students.uni-marburg.de";
      storageClass = "ceph-rbd-students";
      backupPipeline = "students-backup";
      mailQuota = "50GB";
      resources = {
        sogo = { cpu = "500m"; memory = "1Gi"; };
        postfix = { cpu = "250m"; memory = "256Mi"; };
        dovecot = { cpu = "500m"; memory = "1Gi"; };
      };
    };
  };
}
