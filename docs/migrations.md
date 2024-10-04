<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Upgrade migrations</h1>

* [Disclaimer](#disclaimer)
* [Releases upgrades](#releases-upgrades)
  * [From v0.9.0](#from-v090)
    * [Changed openDesk defaults](#changed-opendesk-defaults)
      * [Removal of unnecessary OX-Profiles in Nubus](#removal-of-unnecessary-ox-profiles-in-nubus)
      * [Matrix ID localpart update](#matrix-id-localpart-update)
      * [File-share configurability](#file-share-configurability)
      * [Updated default subdomains in `global.hosts`](#updated-default-subdomains-in-globalhosts)
      * [Updated `global.imagePullSecrets`](#updated-globalimagepullsecrets)
      * [Dedicated group for access to the UDM REST API](#dedicated-group-for-access-to-the-udm-rest-api)
    * [Automated migrations](#automated-migrations)
      * [Manual cleanup](#manual-cleanup)
  * [From v0.8.1](#from-v081)
    * [Updated `cluster.networking.cidr`](#updated-clusternetworkingcidr)
    * [Updated customizable template attributes](#updated-customizable-template-attributes)
    * [`migrations` S3 bucket](#migrations-s3-bucket)
* [Related components and artifacts](#related-components-and-artifacts)
  * [Development](#development)

# Disclaimer

With openDesk 1.0, we aim to offer hassle-free updates. Though some situations may require manual interaction, these are described in this document.

> **Known limitations:**<br>
> We assume that the PV reclaim policy is set to `delete`, resulting in PVs getting deleted as soon as the related PVC was deleted; we will not address explicit deletion for PVs.

# Releases upgrades

## From v0.9.0

Before openDesk 1.0, we faced significant changes in some components and the overall platform configuration. Therefore, please review the

### Changed openDesk defaults

#### Removal of unnecessary OX-Profiles in Nubus

> **Warning**<br>
> The upgrade will fail if you do not address this section for your current deployment.

The update will remove unnecessary OX-Profiles in Nubus, but it can not as long as these profiles are in use.

So please ensure that only the following two supported profiles are assigned to your users:
- `opendesk_standard`: "opendesk Standard"
- `none`: "Login disabled"

You can review and update other accounts as follows:
- Login as IAM admin.
- Open the user module.
- Open the extended search by clicking the funnel (DE: "Trichter") icon next to the search input field.
- Open the "Property" (DE: "Eigenschaft") list and select "OX Access" (DE: "OX-Berechtigung").
- Enter an asterisk (*) in the input field next to the list.
- Start the search by clicking once more on the funnel icon.
- Sort the result list for the "OX Access" column.
- Edit every user that has a value different to `opendesk_standard` or `none`:
  - Open the user.
  - Go to section "OX App Suite".
  - Change the value in the dropdown "OX Access" to either:
    - "openDesk Standard" if the user should be able to use the Groupware module or
    - "Login disabled" if the user should not use the Groupware module.
  - Update the user account with the green "SAVE" button at the top of the page.

#### Matrix ID localpart update

Until 0.9.0 openDesk used the LDAP entryUUID of a user to generate the user's Matrix ID. Due to restrictions on the
Matrix protocol, an update of a Matrix ID is not possible; therefore, it was technically convenient to use the UUID
as it is immutable (see https://de.wikipedia.org/wiki/Universally_Unique_Identifier for more details on UUIDs.)

From the user experience perspective, that was a flawed approach, so from openDesk 1.0 on, by default, the username which
is also used for logging into openDesk is used to define the localpart of the Matrix ID.

For existing installations: The changed setting only affects users who log in to Element for the first time. Existing
user accounts will not be harmed. If you want existing users to get new Matrix IDs based on the new setting, you
must update their external ID in Synapse and deactivate the old user afterward. The user will get a new
Matrix account from scratch, losing the existing contacts, chats, and rooms.

The following Admin API calls are helpful:
- `GET /_synapse/admin/v2/users/@<entryuuid>:<matrixdomain>` to get the user's existing external_id (auth_provider: "oidc")
- `PUT /_synapse/admin/v2/users/@<entryuuid>:<matrixdomain>` to update user's external_id with JSON payload:
  `{ "external_ids": [ { "auth_provider": "oidc", "external_id": "<old_id>+deprecated" } ] }`
- `POST /_synapse/admin/v1/deactivate/@<entryuuid>:<matrixdomain>` to deactivate old user with JSON payload:
  `{ "erase": true }`

For more details, check the Admin API documentation:
https://element-hq.github.io/synapse/latest/usage/administration/admin_api/index.html

You can enforce the old standard with the following setting:
```yaml
functional:
 chat:
   matrix:
     profile:
       useImmutableIdentifierForLocalpart: true
```

#### File-share configurability

Now, we provide some configurability regarding the sharing capabilities of the Nextcloud component.

See the settings under `functional.filestore` in [functional.yaml](../helmfile/environments/default/functional.yaml).

For the following settings, the default in openDesk 1.0 has changed, so you might want to update
the settings for your deployment to keep its current behavior:

```yaml
functional:
 filestore:
   sharing:
     external:
       enabled: true
       expiry:
         activeByDefault: false
```

#### Updated default subdomains in `global.hosts`

We have streamlined the subdomain names in openDesk to be more user-friendly and to avoid the use of specific
product names.

This results in the following changes to the default subdomain naming:

- **collabora**: `collabora` → `office`
- **cryptpad**: `cryptpad` → `pad`
- **minioApi**: `minio` → `objectstore`
- **minioConsole**: `minio-console` → `objectstore-ui`
- **nextcloud**: `fs` → `files`
- **openproject**: `project` → `projects`

Existing deployments should keep the old subdomains cause URL/link changes are not supported through all components.

If you have not already defined the entire `global.hosts` dictionary in your custom environments values, please set it
to the defaults that were used before the upgrade:

```yaml
global:
  hosts:
    collabora: "collabora"
    cryptpad: "cryptpad"
    element: "chat"
    intercomService: "ics"
    jitsi: "meet"
    keycloak: "id"
    matrixNeoBoardWidget: "matrix-neoboard-widget"
    matrixNeoChoiceWidget: "matrix-neochoice-widget"
    matrixNeoDateFixBot: "matrix-neodatefix-bot"
    matrixNeoDateFixWidget: "matrix-neodatefix-widget"
    minioApi: "minio"
    minioConsole: "minio-console"
    nextcloud: "fs"
    openproject: "project"
    openxchange: "webmail"
    synapse: "matrix"
    synapseFederation: "matrix-federation"
    univentionManagementStack: "portal"
    whiteboard: "whiteboard"
    xwiki: "wiki"
```

In case you would like to update an existing deployment to the new hostnames, please check the following list:

- Do this at your own risk.
- Some of your user's bookmarks and links will stop working.
- Portal links are getting updated automatically.
- The update of the OpenProject <-> Nextcloud file integration needs to be updated manually as follows:
  - Use an account with functional admin permissions on both components
  - In OpenProject: *Administration* > *Files* > *External file storages* > Select `Nextcloud at [your_domain]`
    - Edit *Details* - *General Information* - *Storage provider* and update the *hostname* to `files.<your_domain>`
  - In Nextcloud: *Administration* > *OpenProject* > *OpenProject server*
    - Update the *OpenProject host* to `projects.<your_domain>`

#### Updated `global.imagePullSecrets`

Without using a custom registry, you can pull all the openDesk images without authentication.
Thus defining not existing imagePullSecrets creates unnecessary errors, so we removed them.

You can keep the current settings by setting the `external-registry` in your custom environment values:

```yaml
global:
  imagePullSecrets:
    - "external-registry"
```

#### Dedicated group for access to the UDM REST API

Prerequisite: You allow the use of the [IAM's API](https://docs.software-univention.de/developer-reference/5.0/en/udm/rest-api.html)
with the following settings:

```yaml
functional:
  externalServices:
    nubus:
      udmRestApi:
        enabled: true
```

With 0.9.0, all members of the group "Domain Admins" could successfully authenticate with the API.

With openDesk 1.0, we introduced a specific group for permission to use the API: `IAM API - Full Access`.

The IAMs admin account `Administrator` is a member of this group by default, but no other user is.

If you need other accounts to use the API, please assign them to the aforementioned group.

### Automated migrations

The `migrations-pre` and `migrations-post` jobs in the openDesk deployment address the automated migration tasks.

The permissions required to execute the migrations can be found in the migration's Helm chart [`role.yaml'](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/v1.3.5/charts/opendesk-migrations/templates/role.yaml?ref_type=tags#L29)

The actual actions are described as code comments in the related run module [`run_2.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_2.py).

#### Manual cleanup

We do not execute possible cleanup steps as part of the migrations POST stage. So you might want to remove the no longer used PVCs after a successful upgrade:

```shell
NAMESPACE=<your_namespace>
kubectl -n ${NAMESPACE} delete pvc shared-data-ums-ldap-server-0
kubectl -n ${NAMESPACE} delete pvc shared-run-ums-ldap-server-0
kubectl -n ${NAMESPACE} delete pvc ox-connector-ox-contexts-ox-connector-0
```

## From v0.8.1

### Updated `cluster.networking.cidr`

- Action: `cluster.networking.cidr` is now an array (was a string until 0.8.1); please update your setup accordingly if you explicitly set this value.
- Reference:[cluster.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/cluster.yaml)

### Updated customizable template attributes

- Action: Please update your custom deployment values according to the updated default value structure.
- References:
  - `functional.` prefix for `authentication.*`, `externalServices.*`, `admin.*` and `filestore.*`, see [functional.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/functional.yaml).
  - `debug.` prefix for `cleanup.*`, see [debug.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/debug.yaml).
  - `monitoring.` prefix for `prometheus.*` and `graphana.*`, see [monitoring.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/monitoring.yaml).
  - `smtp.` prefix for `localpartNoReply`, see [smtp.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/smtp.yaml).

### `migrations` S3 bucket

- Action: For self-managed/external S3/object storages, please ensure you add a bucket `migrations` to your S3.
- Reference: `objectstores.migrations` in [objectstores.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/objectstores.yaml)

# Related components and artifacts

openDesk comes with two upgrade steps as part of the deployment; they can be found in the folder [/helmfile/apps](../helmfile/apps/) as all other components:

- `migrations-pre`: Is the very first app that gets deployed.
- `migrations-post`: Is the last app that gets deployed.

Both migrations must be deployed exclusively at their first/last position and not parallel with other components.

The status of the upgrade migrations is tracked in the ConfigMap `migrations-status`, more details can be found in the [README.md of the related container image](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/README.md).

## Development

When a new upgrade migration is required, ensure to address the following list:

- Update the generated release version file [`global.generated.yaml`](../helmfile/environments/default/global.generated.yaml) at least on the patch level to test the upgrade in your feature branch and trigger it in the `develop` branch after the feature branch was merged. During the release process, the value is overwritten by the release's version number.
- You have to implement the migration logic as a runner script in the [`opendesk-migrations`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations) image. Please find more instructions in the linked repository.
- You most likely have to update the [`opendesk-migrations` Helm chart](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations) within the `rules` section of the [`role.yaml`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/templates/role.yaml) to provide the permissions required for the execution of your migration's logic.
- You must set the runner's ID you want to execute in the [migrations.yaml.gotmpl](../helmfile/shared/migrations.yaml.gotmpl). See also the `migrations.*` section of [the Helm chart's README.md](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/README.md).
- Update the [`charts.yaml`](../helmfile/environments/default/charts.yaml) and [`images.yaml`](../helmfile/environments/default/images.yaml) to reflect the newer releases of the `opendesk-migrations` Helm chart and container image.
