<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Upgrade migrations</h1>

* [Disclaimer](#disclaimer)
* [Releases upgrades](#releases-upgrades)
  * [From v0.9.0](#from-v090)
    * [Manual interaction](#manual-interaction)
      * [Fileshare configurability](#fileshare-configurability)
    * [Automated migrations](#automated-migrations)
      * [Local Postfix as Relay](#local-postfix-as-relay)
      * [Updated IAM component Nubus](#updated-iam-component-nubus)
        * [Manual cleanup](#manual-cleanup)
  * [From v0.8.1](#from-v081)
    * [Updated `cluster.networking.cidr`](#updated-clusternetworkingcidr)
    * [Updated customizable template attributes](#updated-customizable-template-attributes)
    * [`migrations` S3 bucket](#migrations-s3-bucket)
* [Related components and artefacts](#related-components-and-artefacts)
  * [Development](#development)

# Disclaimer

We do not offer support for upgrades before we reach openDesk 1.0.

Though we try to ease the pain when it comes to 0.x upgrades. That is what this document is for.

Limitations:
- We assume that the PV reclaim policy is set to `delete`, so expect that PVs get deleted as soon as the related PVC was deleted and will cover an explicit delete for PVs.

# Releases upgrades

## From v0.9.0

### Manual interaction

#### Fileshare configurability

We provide now some configurability regarding the sharing capabilities of the Nextcloud component.

The new default is different from the standard until now. To keep the current state after the upgrade from 0.9.0 you have to provide the following settings:

```
functional:
  filestore:
    sharing:
      # Enables sharing of files with external participants (create external links, send links by mail and allow external upload in shared folders).
      enableExternalSharing: true
      # Enforces passwords to be used on external shares.
      enforceSharingPasswords: false
```

### Automated migrations

#### Local Postfix as Relay

All components relay outgoing mails to the local Postfix. In order for the configuration to be picked up by all components the following restarts are triggered in the migrations `POST` stage:

- Deployments:
  - `opendesk-nextcloud-php`
  - `ums-umc-server`
- Stateful Sets:
  - `ums-selfservice-listener`
  - `opendesk-synapse`

#### Updated IAM component Nubus

openDesk is integrating the latest [Nubus](https://www.univention.de/produkte/nubus/) development from Univention. The now redundant and scalable LDAP requires migration activities. These have been automated to avoid manual interaction. The `run_2` of the openDesk
upgrade migrations executes the following steps:

- Stage `PRE`:
  - Delete service `ums-keycloak`, as it will be recreated headless.
  - Scale down `statefulset/ums-ldap-server` and `statefulset/ums-ldap-notifier` in preparation or the next step:
  - Create two new PVCs `shared-data-ums-ldap-server-primary-0` and `shared-data-ums-ldap-server-primary-1` for the new LDAP primary pods as copy from the existing `shared-data-ums-ldap-server-0`. The LDAP secondaries will sync from the primary nodes.
- Stage `POST`:
  - Restart Keycloak.

##### Manual cleanup

Currently we do not execute possible cleanup steps as part of the migrations POST stage. So you might want to remove the no longer used PVCs after successful upgrade:
```
NAMESPACE=<your_namespace>
kubectl -n ${NAMESPACE} delete pvc shared-data-ums-ldap-server-0
kubectl -n ${NAMESPACE} delete pvc shared-run-ums-ldap-server-0
```

## From v0.8.1

### Updated `cluster.networking.cidr`

- Action: `cluster.networking.cidr` is now an array (was a string until 0.8.1), please update your setup accordingly if you explicitly set this value.
- Reference:[cluster.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/cluster.yaml)

### Updated customizable template attributes

- Action: Please ensure you update you custom deployment values according with the updated default value structure.
- References:
  - `functional.` prefix for `authentication.*`, `externalServices.*`, `admin.*` and `filestore.*`, see [functional.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/functional.yaml).
  - `debug.` prefix for `cleanup.*`, see [debug.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/debug.yaml).
  - `monitoring.` prefix for `prometheus.*` and `graphana.*`, see [monitoring.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/monitoring.yaml).
  - `smtp.` prefix for `localpartNoReply`, see [smtp.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/smtp.yaml).

### `migrations` S3 bucket

- Action: For self managed/external S3/object storages, please ensure you add a bucket `migrations` to your S3.
- Reference: `objectstores.migrations` in [objectstores.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/objectstores.yaml)

# Related components and artefacts

openDesk comes with two upgrade steps as part of the deployment, they can be found in the folder [/helmfile/apps](../helmfile/apps/) as all other components:

- `migrations-pre`: Is the very first app that gets deployed.
- `migrations-post`: Is the last app that gets deployed.

Both migrations have to be deployed exclusively at their first/last position and not in parallel with other components.

The status of the upgrade migrations is tracked in the ConfigMap `migrations-status`, more details can be found in the [README.md of the related container image](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/README.md).

## Development

When a new upgrade migration is required, ensure to address the following list:

- Update the generated release version file [`global.generated.yaml`](../helmfile/environments/default/global.generated.yaml) at least on the patch level to test the upgrade in your feature branch as well as trigger it in the `develop` branch after the feature branch was merged. The set value gets overwritten during the release process with the release's actual version number.
- You have to implement the migration logic as a runner script in the [`opendesk-migrations`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations) image. Please find more instructions in the linked repository.
- You most likely have to update the [`opendesk-migrations` Helm chart](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations) within the `rules` section of the [`role.yaml`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/templates/role.yaml) to provide the permissions required for the execution of your migration's logic.
- You have to set the runner's ID you want to execute in the [migrations.yaml.gotmpl](../helmfile/shared/migrations.yaml.gotmpl). See also the `migrations.*` section of [the Helm chart's README.md](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/README.md).
- Update the [`charts.yaml`](../helmfile/environments/default/charts.yaml) and [`images.yaml`](../helmfile/environments/default/images.yaml) to reflect the newer releases of the `opendesk-migrations` Helm chart and container image.
