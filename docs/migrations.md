<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Migration requirements

This document has been split up. When upgrading openDesk, two types of migrations may be required:

- **Manual checks and actions**: See [`migrations-manual.md`](./migrations-manual.md), which also holds the
  [overview of the mandatory upgrade path](./migrations-manual.md#overview-and-mandatory-upgrade-path) and the
  [deprecation warnings](./migrations-manual.md#deprecation-warnings). It contains (at least) the details for the last two mandatory releases in the upgrade path, older upgrade instructions are archived in [`migrations-manual-archive.md`](./migrations-manual-archive.md).
- **Automated migrations between versions**, which openDesk runs on its own and which reduce
  the need for manual intervention: See [`migrations-automated.md`](./migrations-automated.md), which also
  holds the [catalogue of the available actions](./migrations-automated.md#actions).

> [!important]
> Please read and follow these requirements _thoroughly_ before starting an update or upgrade. Always run your backup procedure before beginning an upgrade, as rollbacks may require restoring from backup due to non-reversible database changes within the applications.
