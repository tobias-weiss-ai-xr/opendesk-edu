# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# memcached Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.memcached = {
    # password = config.sops.secrets.memcached-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.memcached-api-key or "";
  };
}
