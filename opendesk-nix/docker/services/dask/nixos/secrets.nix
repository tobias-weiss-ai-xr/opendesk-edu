# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# 
# dask Secrets Configuration
# Uses sops-nix for encrypted secrets management
# OpenSpec: FR-SEC-004 (Image verification & secrets)
# 

{ config, lib, ... }:

{
  services.dask = {
    # password = config.sops.secrets.dask-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.dask-api-key or "";
  };
}
