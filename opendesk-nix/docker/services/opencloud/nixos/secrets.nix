# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# opencloud Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.opencloud = {
    # password = config.sops.secrets.opencloud-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.opencloud-api-key or "";
  };
}
