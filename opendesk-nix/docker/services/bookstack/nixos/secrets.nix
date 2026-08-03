# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# bookstack Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.bookstack = {
    # password = config.sops.secrets.bookstack-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.bookstack-api-key or "";
  };
}
