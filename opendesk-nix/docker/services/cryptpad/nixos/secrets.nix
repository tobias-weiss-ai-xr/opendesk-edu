# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
cryptpad Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.cryptpad = {
    # password = config.sops.secrets.cryptpad-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.cryptpad-api-key or "";
  };
}
