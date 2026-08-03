# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
coderd Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.coderd = {
    # password = config.sops.secrets.coderd-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.coderd-api-key or "";
  };
}
