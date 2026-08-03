# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
nextcloud Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.nextcloud = {
    # password = config.sops.secrets.nextcloud-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.nextcloud-api-key or "";
  };
}
