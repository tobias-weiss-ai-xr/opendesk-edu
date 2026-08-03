# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
stalwart Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.stalwart = {
    # password = config.sops.secrets.stalwart-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.stalwart-api-key or "";
  };
}
