// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
Demo Environment Configuration

This environment configuration is for the demo cluster used for testing
and development purposes.
"""

{ lib, ... }:

{
  namespace = "opendesk-demo";
  
  ingress = {
    className = "nginx";
    domain = "demo.opendesk-edu.org";
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true";
    };
  };
  
  tls = {
    enabled = true;
    secretName = "opendesk-demo-tls";
    issuer = "letsencrypt-prod";
  };
  
  storage = {
    rwx = "nfs-dev";
    rwo = "standard";
    defaultClass = "standard";
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
