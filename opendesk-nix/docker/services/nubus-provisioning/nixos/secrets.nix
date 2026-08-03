# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
nubus-provisioning Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.nubus-provisioning = {
    # password = config.sops.secrets.nubus-provisioning-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.nubus-provisioning-api-key or "";
  };
}
