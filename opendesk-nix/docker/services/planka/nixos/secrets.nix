# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
planka Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.planka = {
    # password = config.sops.secrets.planka-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.planka-api-key or "";
  };
}
