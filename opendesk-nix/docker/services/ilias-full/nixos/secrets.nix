# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# ilias-full Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.ilias-full = {
    # password = config.sops.secrets.ilias-full-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.ilias-full-api-key or "";
  };
}
