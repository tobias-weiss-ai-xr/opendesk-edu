# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
open-webui Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.open-webui = {
    # password = config.sops.secrets.open-webui-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.open-webui-api-key or "";
  };
}
