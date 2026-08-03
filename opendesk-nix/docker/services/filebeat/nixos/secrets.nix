# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# filebeat Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.filebeat = {
    # password = config.sops.secrets.filebeat-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.filebeat-api-key or "";
  };
}
