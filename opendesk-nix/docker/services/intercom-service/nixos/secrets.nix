# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# intercom-service Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.intercom-service = {
    # password = config.sops.secrets.intercom-service-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.intercom-service-api-key or "";
  };
}
