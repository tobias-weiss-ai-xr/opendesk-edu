# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# nginx Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.nginx = {
    # password = config.sops.secrets.nginx-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.nginx-api-key or "";
  };
}
