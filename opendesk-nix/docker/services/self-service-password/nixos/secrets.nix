# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
self-service-password Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.self-service-password = {
    # password = config.sops.secrets.self-service-password-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.self-service-password-api-key or "";
  };
}
