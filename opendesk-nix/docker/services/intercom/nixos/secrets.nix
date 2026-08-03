# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# intercom Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.intercom = {
    # password = config.sops.secrets.intercom-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.intercom-api-key or "";
  };
}
