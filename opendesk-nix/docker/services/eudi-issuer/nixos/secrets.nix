# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# eudi-issuer Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.eudi-issuer = {
    # password = config.sops.secrets.eudi-issuer-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.eudi-issuer-api-key or "";
  };
}
