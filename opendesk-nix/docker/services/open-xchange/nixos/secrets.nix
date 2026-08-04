# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# open-xchange Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.open-xchange = {
    # password = config.sops.secrets.open-xchange-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.open-xchange-api-key or "";
  };
}
