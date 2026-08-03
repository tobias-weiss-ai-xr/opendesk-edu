# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
limesurvey Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.limesurvey = {
    # password = config.sops.secrets.limesurvey-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.limesurvey-api-key or "";
  };
}
