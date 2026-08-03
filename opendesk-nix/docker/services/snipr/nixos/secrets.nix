# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# snipr Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.snipr = {
    # password = config.sops.secrets.snipr-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.snipr-api-key or "";
  };
}
