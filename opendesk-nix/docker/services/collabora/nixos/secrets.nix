# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# collabora Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.collabora = {
    # password = config.sops.secrets.collabora-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.collabora-api-key or "";
  };
}
