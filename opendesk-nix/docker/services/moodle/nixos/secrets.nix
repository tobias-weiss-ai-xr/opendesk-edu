# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# moodle Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.moodle = {
    # password = config.sops.secrets.moodle-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.moodle-api-key or "";
  };
}
