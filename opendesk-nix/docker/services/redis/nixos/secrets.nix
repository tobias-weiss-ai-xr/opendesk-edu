# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# redis Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.redis = {
    # password = config.sops.secrets.redis-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.redis-api-key or "";
  };
}
