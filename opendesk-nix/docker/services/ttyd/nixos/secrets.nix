# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ttyd Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.ttyd = {
    # password = config.sops.secrets.ttyd-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.ttyd-api-key or "";
  };
}
