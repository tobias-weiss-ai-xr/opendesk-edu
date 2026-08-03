# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
sogo Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.sogo = {
    # password = config.sops.secrets.sogo-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.sogo-api-key or "";
  };
}
