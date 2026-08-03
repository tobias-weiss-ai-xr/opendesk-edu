# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
kube-prometheus-stack Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.kube-prometheus-stack = {
    # password = config.sops.secrets.kube-prometheus-stack-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.kube-prometheus-stack-api-key or "";
  };
}
