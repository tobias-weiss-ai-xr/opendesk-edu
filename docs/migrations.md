<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Updates & Upgrades</h1>

<!-- TOC -->
* [Disclaimer](#disclaimer)
* [openDesk supported upgrade path](#opendesk-supported-upgrade-path)
* [Releases upgrade details](#releases-upgrade-details)
  * [From v1.0.0](#from-v100)
    * [Pre-upgrade: Manual steps](#pre-upgrade-manual-steps)
      * [`customization.release`](#customizationrelease)
      * [Redis 7.4](#redis-74)
  * [From v0.9.0](#from-v090)
    * [Pre-upgrade: Manual steps](#pre-upgrade-manual-steps-1)
      * [Configuration Cleanup: Removal of unnecessary OX-Profiles in Nubus](#configuration-cleanup-removal-of-unnecessary-ox-profiles-in-nubus)
      * [Configuration Cleanup: Updated `global.imagePullSecrets`](#configuration-cleanup-updated-globalimagepullsecrets)
      * [Changed openDesk defaults: Matrix ID](#changed-opendesk-defaults-matrix-id)
      * [Changed openDesk defaults: File-share configurability](#changed-opendesk-defaults-file-share-configurability)
      * [Changed openDesk defaults: Updated default subdomains in `global.hosts`](#changed-opendesk-defaults-updated-default-subdomains-in-globalhosts)
      * [Changed openDesk defaults: Dedicated group for access to the UDM REST API](#changed-opendesk-defaults-dedicated-group-for-access-to-the-udm-rest-api)
    * [Automated migrations](#automated-migrations)
    * [Post-upgrade: Manual steps](#post-upgrade-manual-steps)
      * [Configuration Improvement: Separate user permission for using Video Conference component](#configuration-improvement-separate-user-permission-for-using-video-conference-component)
      * [Optional Cleanup](#optional-cleanup)
  * [From v0.8.1](#from-v081)
    * [Updated `cluster.networking.cidr`](#updated-clusternetworkingcidr)
    * [Updated customizable template attributes](#updated-customizable-template-attributes)
    * [`migrations` S3 bucket](#migrations-s3-bucket)
* [Related components and artifacts](#related-components-and-artifacts)
  * [Development](#development)
<!-- TOC -->

# Disclaimer

With openDesk 1.0, we aim to offer hassle-free updates/upgrades.

But openDesk requires a defined upgrade path that is described in the section [openDesk supported upgrade path](#opendesk-supported-upgrade-path).

Some upgrades even require manual interaction, which are referenced in the aforementioned section and described further down this document.

> **Known limitations:**<br>
> We assume that the PV reclaim policy is set to `delete`, resulting in PVs getting deleted as soon as the related PVC was deleted; we will not address explicit deletion for PVs.

# openDesk supported upgrade path

When updating your openDesk installation you have to install the releases listed below in the sequential order from
the lowest version number you are already on to the more current version you are looking to install.

Explanation of the table's columns:
- *Coming from*: Check the column for the release you are currently on.
- *Mandatory release*: Defines which release(s) support the upgrade from your currently installed version.
- *Automatic migration*: Summary of, or link to openDesk's automatic migration details.
- *Manual activities*: Reference to required manual steps to upgrade your openDesk installation to the *Mandatory release*.

| Coming from   | Mandatory (minimum) release | Automatic migration                                                                                                                                           | Manual activities             |
| ------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| v0.9.0        | v1.x.x                      | [run_2.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_2.py) | See [From v0.9.0](#from-v090) |
| v0.8.1        | v0.9.0                      | Initializes migration system                                                                                                                                  | See [From v0.8.1](#from-v081) |
| not supported | v0.8.1                      | First release that supporting updates                                                                                                                         |                               |

# Releases upgrade details

## From v1.0.0

### Pre-upgrade: Manual steps

#### `customization.release`

If you make use of the `customization.release` option, you have to switch to a dictionary based definition of customization files e.g. from

```
customization:
  release:
    collaboraOnline: "./my_custom_templating.yaml"
```

to

```
customization:
  release:
    collaboraOnline:
      file1: "./my_custom_templating.yaml"
```

You can freely choose the `file1` dictionary key used in the example above, but it should start with a letter.

#### Redis 7.4

The update from openDesk 1.0.0 contains Redis 7.4.1, like the other openDesk bundled services the bundled Redis is as well not meant to be used in production.

Please ensure for the Redis you are using that it is updated to at least 7.4 to support the requirement of OX App Suite.

## From v0.9.0

### Pre-upgrade: Manual steps

#### Configuration Cleanup: Removal of unnecessary OX-Profiles in Nubus

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

#### Configuration Cleanup: Updated `global.imagePullSecrets`

Without using a custom registry, you can pull all the openDesk images without authentication.
Thus defining not existing imagePullSecrets creates unnecessary errors, so we removed them.

You can keep the current settings by setting the `external-registry` in your custom environment values:

```yaml
global:
  imagePullSecrets:
    - "external-registry"
```

#### Changed openDesk defaults: Matrix ID

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

#### Changed openDesk defaults: File-share configurability

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

#### Changed openDesk defaults: Updated default subdomains in `global.hosts`

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

#### Changed openDesk defaults: Dedicated group for access to the UDM REST API

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

### Post-upgrade: Manual steps

#### Configuration Improvement: Separate user permission for using Video Conference component

With openDesk 1.0 the user permission for authenticated access to the Chat and Video Conference components was split into two separate permissions.

Therefore the newly added *Video Conference* permission has to be added to users that should have continued access to the component.

This can be done as IAM admin:
- Open the *user* module.
- Select all users that should get the permission for *Video Conference* using the select box left from the users entry.
- In top bar of the user table click on *Edit*.
- Select the *openDesk* section the the left-hand menu.
- Check the check box for *Video Conference* and the directly below check box for *Overwrite*.
- Click on the green *Save* button on top of the screen to apply the change.

> **Hint**<br>
> If you have a lot of users andd want to update (almost) all them, you can select all users by clicking the check box in the user's table header and then de-selecting the users you do not want to update.

#### Optional Cleanup

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
