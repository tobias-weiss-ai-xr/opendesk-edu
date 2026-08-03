# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
jitsi Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.jitsi = {
    # password = config.sops.secrets.jitsi-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.jitsi-api-key or "";
  };
}
