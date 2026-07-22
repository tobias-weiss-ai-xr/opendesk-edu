<!--
SPDX-FileCopyrightText: 2024-2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

# Automated migrations - Archive

> [!important]
> This document is the **archive** of openDesk's automated migration documentation. It covers the
> automated migrations of the openDesk releases **before v1.17.0**, which were implemented as
> runner scripts (`run_*.py`) inside the openDesk Migrations image rather than being declared by
> the deployment.
>
> - For the automated migrations of the openDesk releases **≥ v1.17.0** see [`migrations-automated.md`](./migrations-automated.md).
> - For the **manual** checks and actions, and for the overview of the mandatory upgrade path, see
>   [`migrations-manual.md`](./migrations-manual.md).

<!-- TOC -->
* [Automated migrations - Archive](#automated-migrations---archive)
  * [Versions ≥ v1.8.0 (automated)](#versions--v180-automated)
    * [Versions ≥ v1.8.0 migrations-post](#versions--v180-migrations-post)
  * [Versions ≥ v1.6.0 (automated)](#versions--v160-automated)
    * [Versions ≥ v1.6.0 migrations-post](#versions--v160-migrations-post)
  * [Versions ≥ v1.2.0 (automated)](#versions--v120-automated)
    * [Versions ≥ v1.2.0 migrations-pre](#versions--v120-migrations-pre)
    * [Versions ≥ v1.2.0 migrations-post](#versions--v120-migrations-post)
  * [Versions ≥ v1.1.0 (automated)](#versions--v110-automated)
  * [Versions ≥ v1.0.0 (automated)](#versions--v100-automated)
<!-- TOC -->

## Versions ≥ v1.8.0 (automated)

> [!note]
> Details can be found in [run_6.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_6.py).

### Versions ≥ v1.8.0 migrations-post

- Automatically restarts the StatefulSet `ox-connector` due to updated handling of the Connector's provisioning secret.

## Versions ≥ v1.6.0 (automated)

> [!note]
> Details can be found in [run_5.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_5.py).

### Versions ≥ v1.6.0 migrations-post

- Automatically restarts the StatefulSets `ums-provisioning-nats` and `ox-connector` due to a workaround applied on the NATS secrets, see the "Notes" segment of the ["Password seed" heading in getting-started.md](./docs/getting-started.md#password-seed)

> [!note]
> This change aims to prevent authentication failures with NATS in some Pods, which can lead to errors such as: `wait-for-nats Unavailable, waiting 2 seconds. Error: nats: 'Authorization Violation'`.

## Versions ≥ v1.2.0 (automated)

> [!note]
> Details can be found in [run_4.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_4.py).

### Versions ≥ v1.2.0 migrations-pre

- Automatically deletes PVC `group-membership-cache-ums-portal-consumer-0`: With the upgrade the Nubus Portal Consumer no longer requires to be executed with root privileges. The PVC contains files that require root permission to access them, therefore the PVC gets deleted (and re-created) during the upgrade.
- Automatically deletes StatefulSet `ums-portal-consumer`: A bug was fixed in the templating of the Portal Consumer's PVC causing the values in `persistence.storages.nubusPortalConsumer.*` to be ignored. As these values are immutable, we had to delete the whole StatefulSet.

### Versions ≥ v1.2.0 migrations-post

- Automatically restarts the Deployment `ums-provisioning-udm-transformer` and StatefulSet `ums-provisioning-udm-listener` and deletes the Nubus Provisioning consumer `durable_name:incoming` on stream `stream:incoming`: Due to a bug in Nubus 1.7.0 the `incoming` stream was blocked after the upgrade, the aforementioned measures unblock the stream.

## Versions ≥ v1.1.0 (automated)

With openDesk v1.1.0 the IAM stack supports HA LDAP primary as well as scalable LDAP secondary pods.

openDesk's automated migrations takes care of this upgrade requirement described here for
[Nubus 1.5.1](https://docs.software-univention.de/nubus-kubernetes-release-notes/1.5.1/en/changelog.html#migrate-existing-ldap-server-to-mirror-mode-readiness),
creating the config map with the mentioned label.

> [!note]
> Details can be found in [run_3.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_3.py).

## Versions ≥ v1.0.0 (automated)

The `migrations-pre` and `migrations-post` jobs in the openDesk deployment address the automated migration tasks.

The permissions required to execute the migrations can be found in the migration's Helm chart [`role.yaml'](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/v1.3.5/charts/opendesk-migrations/templates/role.yaml?ref_type=tags#L29).

> [!note]
> Details can be found in [run_2.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_3.py).
