// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
HRZ Production Environment Configuration

This environment configuration is for the HRZ Marburg production cluster
running on SCS-K3s (Sovereign Cloud Stack with K3s lightweight Kubernetes).

Cluster: 3× Huawei RH2288E V2, K3s with embedded etcd (HA mode),
Traefik ingress, Ceph-CSI storage (external Ceph cluster), MetalLB.
"""

{ lib, ... }:

{
  namespace = "opendesk";

  # ── Cluster Configuration (SCS-K3s) ──
  cluster = {
    type = "k3s";
    version = "v1.31.2+k3s1";
    ha = true;
    embeddedEtcd = true;
    nodes = 3;
    cni = "flannel";
    cri = "containerd";
    loadBalancer = "metallb";
    ingressController = "traefik";
    storageDriver = "ceph-csi";
  };

  ingress = {
    className = "traefik";
    domain = "desk-test.uni-marburg.de";
    annotations = {
      "traefik.ingress.kubernetes.io/ssl-passthrough" = "true";
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure";
      "traefik.ingress.kubernetes.io/router.tls" = "true";
    };
  };

  tls = {
    enabled = true;
    secretName = "opendesk-certificates-tls";
    issuer = "opendesk-ca";
  };

  # ── Storage (Ceph-CSI, external Ceph cluster) ──
  # K3s uses Ceph-CSI driver to connect to existing Ceph cluster
  # (no OSISM/OpenStack layer — direct Ceph access via CSI)
  storage = {
    rwx = "ceph-cephfs-hdd-ec";
    rwo = "ceph-rbd-ssd";
    defaultClass = "ceph-rbd-ssd";
    # Tenant-isolierte Storage-Klassen (separate Ceph-Pools)
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
      storageClass = "ceph-rbd-ssd";
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
