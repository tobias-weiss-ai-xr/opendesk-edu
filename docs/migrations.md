<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Upgrade migrations</h1>

* [Disclaimer](#disclaimer)
* [From v0.9.0](#from-v090)
  * [Automated migrations](#automated-migrations)
    * [Updated IAM component Nubus](#updated-iam-component-nubus)
      * [Manual cleanup](#manual-cleanup)
* [From v0.8.1](#from-v081)
  * [Updated `cluster.networking.cidr`](#updated-clusternetworkingcidr)
  * [Updated customizable template attributes](#updated-customizable-template-attributes)
  * [`migrations` S3 bucket](#migrations-s3-bucket)

# Disclaimer

We do not offer support for upgrades before we reach openDesk 1.0.

Though we try to ease the pain when it comes to 0.x upgrades. That is what this document is for.

Limitations:
- We assume that the PV reclaim policy is set to `delete`, so expect that PVs get deleted as soon as the related PVC was deleted and will cover an explicit delete for PVs.

# From v0.9.0

## Automated migrations

### Updated IAM component Nubus

openDesk is integrating the latest [Nubus](https://www.univention.de/produkte/nubus/) development from Univention. The new redundant and scalable LDAP requires migration activities. These have been automated to avoid manual interaction. The `run_2` of the openDesk
upgrade migrations executes the following steps

- Stage PRE:
  - Delete service `ums-keycloak`, as it will be recreated headless.
  - Scale down `statefulset/ums-ldap-server` and `statefulset/ums-ldap-notifier` in preparation or the next step:
  - Create two new PVCs `shared-data-ums-ldap-server-primary-0` and `shared-data-ums-ldap-server-primary-1` for the new LDAP primary pods as copy from the existing `shared-data-ums-ldap-server-0`. The LDAP secondaries will sync from the primary nodes.
- Stage POST:
  - Restart Keycloak.

#### Manual cleanup

Currently we do not execute possible cleanup steps as part of the migrations POST stage. So you might want to remove the no longer used PVCs after successful upgrade:
```
NAMESPACE=<your_namespace>
kubectl -n ${NAMESPACE} delete pvc shared-data-ums-ldap-server-0
kubectl -n ${NAMESPACE} delete pvc shared-run-ums-ldap-server-0
```

# From v0.8.1

## Updated `cluster.networking.cidr`

- Action: `cluster.networking.cidr` is now an array (was a string until 0.8.1), please update your setup accordingly if you explicitly set this value.
- Reference:[cluster.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/cluster.yaml)

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
