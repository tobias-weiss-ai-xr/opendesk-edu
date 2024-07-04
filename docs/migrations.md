<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Migrations</h1>

* [Disclaimer](#disclaimer)
* [From v0.8.1](#from-v081)
  * [`migrations` S3 bucket](#migrations-s3-bucket)

# Disclaimer

We do not offer support for upgrades before we reach openDesk 1.0.

Though we try to ease the pain when it comes to 0.x upgrades. That is what this document is for.

# From v0.8.1

## `migrations` S3 bucket

- Commit: [1e834fee](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/commit/1e834fee9db6bdb948f31c994d5ab309e6f86947)
- Action: Please ensure you add a bucket `migrations` to your S3.
