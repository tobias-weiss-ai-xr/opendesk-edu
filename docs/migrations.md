<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Migrations</h1>

* [Disclaimer](#disclaimer)
* [From v0.8.1](#from-v081)
  * [Updated customizable template attributes](#updated-customizable-template-attributes)
  * [`migrations` S3 bucket](#migrations-s3-bucket)

# Disclaimer

We do not offer support for upgrades before we reach openDesk 1.0.

Though we try to ease the pain when it comes to 0.x upgrades. That is what this document is for.

# From v0.8.1

## Updated customizable template attributes

- Action: Please ensure you update you custom deployment values according with the updated default value structure.
- References:
  - `functional.` prefix for `authentication.*`, `externalServices.*`, `admin.*` and `filestore.*`, see [functional.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/functional.yaml).
  - `debug.` prefix for `cleanup.*`, see [debug.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/debug.yaml).
  - `monitoring.` prefix for `prometheus.*` and `graphana.*`, see [monitoring.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/monitoring.yaml).
  - `smtp.` prefix for `localpartNoReply`, see [smtp.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/smtp.yaml).

## `migrations` S3 bucket

- Action: For self managed/external S3/object storages, please ensure you add a bucket `migrations` to your S3.
- Reference: `objectstores.migrations` in [objectstores.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/objectstores.yaml)
