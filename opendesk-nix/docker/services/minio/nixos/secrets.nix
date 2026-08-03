# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

"""
minio Secrets Configuration
Uses sops-nix for encrypted secrets management
OpenSpec: FR-SEC-004 (Image verification & secrets)
"""

{ config, lib, ... }:

{
  services.minio = {
    # password = config.sops.secrets.minio-password or "CHANGE_ME";
    # apiKey = config.sops.secrets.minio-api-key or "";
  };
}
