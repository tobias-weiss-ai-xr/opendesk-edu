// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
HRZ-specific overrides for MariaDB

This override increases resources for MariaDB in production,
using faster storage and more CPU/memory.
"""

{ baseConfig }:

baseConfig // {
  resources = {
    cpu = "500m";
    memory = "4Gi";
  };
  
  # Use the fastest storage class available in HRZ
  storage = {
    rwo = "ceph-rbd-ssd";
    rwx = "ceph-cephfs-hdd-ec";
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
    alerts = true;
  };
}
