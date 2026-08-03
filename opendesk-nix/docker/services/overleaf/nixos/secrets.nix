# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
overleaf Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.overleaf = {
    # password = config.sops.secrets.overleaf-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.overleaf-api-key or "";
  };
}
