# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# loki Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.loki = {
    # password = config.sops.secrets.loki-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.loki-api-key or "";
  };
}
