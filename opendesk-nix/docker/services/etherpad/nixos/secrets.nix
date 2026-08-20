# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# etherpad Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.etherpad = {
    # password = config.sops.secrets.etherpad-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.etherpad-api-key or "";
  };
}
