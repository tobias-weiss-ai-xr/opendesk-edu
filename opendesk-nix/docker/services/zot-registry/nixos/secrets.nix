# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
zot-registry Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.zot-registry = {
    # password = config.sops.secrets.zot-registry-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.zot-registry-api-key or "";
  };
}
