# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# timescale Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.timescale = {
    # password = config.sops.secrets.timescale-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.timescale-api-key or "";
  };
}
