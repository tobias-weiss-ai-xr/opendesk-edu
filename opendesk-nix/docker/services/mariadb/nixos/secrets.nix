# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# mariadb Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.mariadb = {
    # password = config.sops.secrets.mariadb-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.mariadb-api-key or "";
  };
}
