# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
sogo6 Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.sogo6 = {
    # password = config.sops.secrets.sogo6-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.sogo6-api-key or "";
  };
}
