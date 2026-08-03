# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
n8n Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.n8n = {
    # password = config.sops.secrets.n8n-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.n8n-api-key or "";
  };
}
