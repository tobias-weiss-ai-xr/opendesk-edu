# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
kasmvnc Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.kasmvnc = {
    # password = config.sops.secrets.kasmvnc-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.kasmvnc-api-key or "";
  };
}
