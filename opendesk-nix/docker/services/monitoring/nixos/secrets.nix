# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# monitoring Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.monitoring = {
    # password = config.sops.secrets.monitoring-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.monitoring-api-key or "";
  };
}
