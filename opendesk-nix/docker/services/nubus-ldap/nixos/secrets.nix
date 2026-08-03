# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# nubus-ldap Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.nubus-ldap = {
    # password = config.sops.secrets.nubus-ldap-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.nubus-ldap-api-key or "";
  };
}
