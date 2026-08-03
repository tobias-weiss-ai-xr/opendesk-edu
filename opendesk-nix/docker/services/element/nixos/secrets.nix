# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# element Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.element = {
    # password = config.sops.secrets.element-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.element-api-key or "";
  };
}
