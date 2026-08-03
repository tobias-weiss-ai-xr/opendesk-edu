# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
jupyterhub Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.jupyterhub = {
    # password = config.sops.secrets.jupyterhub-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.jupyterhub-api-key or "";
  };
}
