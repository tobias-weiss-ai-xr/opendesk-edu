# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# nubus-portal Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.nubus-portal = {
    # password = config.sops.secrets.nubus-portal-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.nubus-portal-api-key or "";
  };
}
