# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# bigbluebutton Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.bigbluebutton = {
    # password = config.sops.secrets.bigbluebutton-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.bigbluebutton-api-key or "";
  };
}
