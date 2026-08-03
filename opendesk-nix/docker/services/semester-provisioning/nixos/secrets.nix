# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
semester-provisioning Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.semester-provisioning = {
    # password = config.sops.secrets.semester-provisioning-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.semester-provisioning-api-key or "";
  };
}
