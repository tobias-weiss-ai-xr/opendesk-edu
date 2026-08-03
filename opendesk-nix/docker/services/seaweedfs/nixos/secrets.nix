# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
seaweedfs Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.seaweedfs = {
    # password = config.sops.secrets.seaweedfs-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.seaweedfs-api-key or "";
  };
}
