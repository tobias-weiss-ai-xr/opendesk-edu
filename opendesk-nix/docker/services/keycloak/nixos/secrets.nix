# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# keycloak Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.keycloak = {
    # password = config.sops.secrets.keycloak-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.keycloak-api-key or "";
  };
}
