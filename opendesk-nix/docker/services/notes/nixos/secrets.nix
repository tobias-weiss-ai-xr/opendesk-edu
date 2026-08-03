# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
notes Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.notes = {
    # password = config.sops.secrets.notes-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.notes-api-key or "";
  };
}
