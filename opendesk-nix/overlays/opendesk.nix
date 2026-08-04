# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

self: super: rec {
  opendesk = rec {
    inherit (super) mariadb postgresql redis nginx;
  };
}
