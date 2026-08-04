# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# rstudio Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.rstudio = {
    # password = config.sops.secrets.rstudio-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.rstudio-api-key or "";
  };
}
