# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# typo3 Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.typo3 = {
    # password = config.sops.secrets.typo3-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.typo3-api-key or "";
  };
}
