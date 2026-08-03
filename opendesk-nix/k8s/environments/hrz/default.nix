// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
HRZ Production Environment Configuration

This environment configuration is for the HRZ Marburg production cluster.
"""

{ lib, ... }:

{
  namespace = "opendesk";
  
  ingress = {
    className = "haproxy";
    domain = "opendesk.hrz.uni-marburg.de";
    annotations = {
      "haproxy.org/ssl-tls-verify-client" = "off";
      "haproxy.org/backend-config-snapshot" = "true";
    };
  };
  
  tls = {
    enabled = true;
    secretName = "opendesk-certificates-tls";
    issuer = "opendesk-ca";
  };
  
  storage = {
    rwx = "ceph-cephfs-hdd-ec";
    rwo = "ceph-rbd-ssd";
    defaultClass = "ceph-rbd-ssd";
  };
  
  networking = {
    proxy = "http://www-proxy2.uni-marburg.de:3128";
    dns = [ "137.248.21.22" "137.248.1.5" "137.248.1.8" ];
    noProxy = [ "192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12" ]; 
  };
  
  resources = {
    small = { cpu = "100m"; memory = "128Mi"; };
    medium = { cpu = "500m"; memory = "512Mi"; };
    large = { cpu = "2"; memory = "2Gi"; };
    database = { cpu = "2"; memory = "4Gi"; };
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
}
