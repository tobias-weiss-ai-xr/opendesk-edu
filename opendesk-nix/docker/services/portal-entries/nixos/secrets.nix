# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
portal-entries Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.portal-entries = {
    # password = config.sops.secrets.portal-entries-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.portal-entries-api-key or "";
  };
}
