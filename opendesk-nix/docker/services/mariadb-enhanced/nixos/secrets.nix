# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
mariadb-enhanced Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.mariadb-enhanced = {
    # password = config.sops.secrets.mariadb-enhanced-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.mariadb-enhanced-api-key or "";
  };
}
