# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
f13 Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.f13 = {
    # password = config.sops.secrets.f13-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.f13-api-key or "";
  };
}
