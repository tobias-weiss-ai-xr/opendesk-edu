<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>Scaling</h1>

This document should cover the abilities to scale apps.

<!-- TOC -->
  * [Replicas](#replicas)
<!-- TOC -->

## Replicas

The Replicas can be increased of almost any component, but is only effective for high-availability or load-balancing for
apps with a check-mark in `Scaling (effective)` column.

Verified positive effects are marke with a check-mark in `Scaling (verified)` column, apps which are not yet tested are
marked with a gear.


| Component   | Name                                     | Scaling (effective) | Scaling (verified) |
|-------------|------------------------------------------|:-------------------:|:------------------:|
| ClamAV      | `replicas.clamav`                        | :white_check_mark:  | :white_check_mark: |
|             | `replicas.clamd`                         | :white_check_mark:  | :white_check_mark: |
|             | `replicas.freshclam`                     |         :x:         |        :x:         |
|             | `replicas.icap`                          | :white_check_mark:  | :white_check_mark: |
|             | `replicas.milter`                        | :white_check_mark:  | :white_check_mark: |
| Collabora   | `replicas.collabora`                     | :white_check_mark:  |       :gear:       |
| CryptPad    | `replicas.cryptpad`                      | :white_check_mark:  |       :gear:       |
| Dovecot     | `replicas.dovecot`                       |         :x:         |       :gear:       |
| Element     | `replicas.element`                       | :white_check_mark:  | :white_check_mark: |
|             | `replicas.matrixNeoBoardWidget`          | :white_check_mark:  |       :gear:       |
|             | `replicas.matrixNeoChoiceWidget`         | :white_check_mark:  |       :gear:       |
|             | `replicas.matrixNeoDateFixBot`           | :white_check_mark:  |       :gear:       |
|             | `replicas.matrixNeoDateFixWidget`        | :white_check_mark:  |       :gear:       |
|             | `replicas.matrixUserVerificationService` | :white_check_mark:  |       :gear:       |
|             | `replicas.synapse`                       |         :x:         |       :gear:       |
|             | `replicas.synapseWeb`                    | :white_check_mark:  | :white_check_mark: |
|             | `replicas.wellKnown`                     | :white_check_mark:  | :white_check_mark: |
| Jitsi       | `replicas.jibri`                         | :white_check_mark:  |       :gear:       |
|             | `replicas.jicofo`                        | :white_check_mark:  |       :gear:       |
|             | `replicas.jitsi `                        | :white_check_mark:  |       :gear:       |
|             | `replicas.jitsiKeycloakAdapter`          | :white_check_mark:  |       :gear:       |
|             | `replicas.jvb `                          |         :x:         |        :x:         |
| Keycloak    | `replicas.keycloak`                      | :white_check_mark:  |       :gear:       |
| Minio       | `replicas.minioDistributed`              | :white_check_mark:  | :white_check_mark: |
| Nextcloud   | `replicas.nextcloud`                     | :white_check_mark:  |       :gear:       |
| OpenProject | `replicas.openproject`                   | :white_check_mark:  |       :gear:       |
| Postfix     | `replicas.postfix`                       |         :x:         |       :gear:       |
| XWiki       | `replicas.xwiki`                         | :white_check_mark:  |       :gear:       |