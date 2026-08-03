# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# dev-agent Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.dev-agent = {
    # password = config.sops.secrets.dev-agent-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.dev-agent-api-key or "";
  };
}
