# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# argocd Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.argocd = {
    # password = config.sops.secrets.argocd-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.argocd-api-key or "";
  };
}
