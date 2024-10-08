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
      * [MatrixID localpart update](#matrixid-localpart-update)
      * [File-share configurability](#file-share-configurability)
      * [Updated default subdomains in `global.hosts`](#updated-default-subdomains-in-globalhosts)
      * [Updated `global.imagePullSecrets`](#updated-globalimagepullsecrets)
      * [Dedicated group for access of the UDM REST API](#dedicated-group-for-access-of-the-udm-rest-api)
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

**Limitations:**
- We assume that the PV reclaim policy is set to `delete`, so expect that PVs get deleted as soon as the related PVC was
  deleted and will cover an explicit delete for PVs.

# Releases upgrades

## From v0.9.0

### Changed openDesk defaults


#### Removal of unnecessary OX-Profiles in Nubus

**Warning: If you do not address this section with your current deployment the upgrade will fail.**

The update will remove unnecessary OX-Profiles in Nubus, but can't as long as these profiles are in use.

So please ensure that only the following two supported profiles are assigned to your users:
- `opendesk_standard`: "opendesk Standard"
- `none`: "Login disabled"

You can review and update other accounts as follows:
- Login as IAM admin.
- Open the user module.
- Open the extended search by clicking the funnel (Trichter) icon next to the search input field.
- Open the "Property" (Eigenschaft) list and select "OX Access" (OX-Berechtigung).
- In the input field right next to the list enter an asterisk (*).
- Start the search by clicking once more on the funnel icon.
- Sort the result list for the "OX Access" column
- Edit every user that has a value different to `opendesk_standard` or `none`:
  - Open the user.
  - Go to section "OX App Suite".
  - Change the value in the dropdown "OX Access" to either:
    - "openDesk Standard" if the user should be able to use the Groupware module or
    - "Login disabled" if the user should not user the Groupware module.
    - Update the user account with the green "SAVE" button on top of the page.

#### MatrixID localpart update

Until 0.9.0 openDesk used the LDAP entryUUID of a user to generate the user's MatrixID. Due to restrictions of the
Matrix protocol, an update of a MatrixID is not possible, therefore, it was technically convenient to use the UUID
as it is immutable (see https://de.wikipedia.org/wiki/Universally_Unique_Identifier for more details on UUIDs.)

From the user experience perspective, that was a bad approach, so from now on, by default, the username which
is also used for logging into openDesk is used to define the localpart of the MatrixID.

For existing installations: The changed setting only affects users that login to Element the first time. Existing
user accounts will not be harmed. If you want existing users to get new MatrixIDs based on the new setting, you
need to update their external ID in Synapse and deactivate the old user afterward. The user will get a new
Matrix account from scratch, losing the existing contacts, chats and rooms.

The following Admin API calls are helpful:
- GET /_synapse/admin/v2/users/@<entryuuid>:<matrixdomain> get the user's existing external_id (auth_provider: "oidc")
- PUT /_synapse/admin/v2/users/@<entryuuid>:<matrixdomain> update user's external_id with JSON payload:
  `{ "external_ids": [ { "auth_provider": "oidc", "external_id": "<old_id>+deprecated" } ] }`
- POST /_synapse/admin/v1/deactivate/@<entryuuid>:<matrixdomain> deactivate old user with JSON payload:
  `{ "erase": true }`

For more details, check the Admin API documentation:
https://element-hq.github.io/synapse/latest/usage/administration/admin_api/index.html

You can enforce the old standard with the following setting:
```
functional:
  chat:
    matrix:
      profile:
        useImmutableIdentifierForLocalpart: true
```

#### File-share configurability

Now we provide some configurability regarding the sharing capabilities of the Nextcloud component.

The new default is different from the standard until now.
To keep the current state after the upgrade from 0.9.0, you have to provide the following settings:

```
functional:
  filestore:
    sharing:
      external:
        enabled: true
```

Please also check the other new options available at `functional.filestore.sharing`.

#### Updated default subdomains in `global.hosts`

We have streamlined the subdomain names used by openDesk to be more user-friendly and to avoid the use of specific
product names.

This results in following change of default subdomain naming:

- **collabora**: `collabora` → `office`
- **cryptpad**: `cryptpad` → `pad`
- **minioApi**: `minio` → `objectstore`
- **minioConsole**: `minio-console` → `objectstore-ui`
- **nextcloud**: `fs` → `files`
- **openproject**: `project` → `projects`

During upgrade, any existing environment needs to keep the old subdomains,
cause url/link changes are not every supported and not tested at all.

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

In case you would like to use the updated hostnames you at least have to apply some manual changes. But do this at
your own risk. Be also aware that some of your user's bookmarks and links will stop working.

- Update the affected portal tiles:
  - All tiles in the "Files" category.
  - The "Projects" tile in the "Management" category.
- There are two options to change the link for the portal tiles:
  - Use an admin account to access the portal's edit mode (on the bottom of the sidebar portal's menu).
  - Utilize the UDM REST API to update the portal tile objects.
- Update the hostnames for the OpenProject-Nextcloud integration using a functional admin user for both components:
  - In OpenProject: *Administration* > *Files* > *External file storages* > Select `Nextcloud at [your_domain]`
    Edit *Details* - *General Information* - *Storage provider* and update the *hostname* to `files.<your_domain>`.
  - In Nextcloud: *Administration* > *OpenProject* > *OpenProject server* update the *OpenProject host* to
    to `projects.<your_domain>`.

#### Updated `global.imagePullSecrets`

Without using a custom registry, you can pull all the openDesk images without authentication.
Thus defining not existing imagePullSecrets creates unnecessary errors, so we removed them.

You can keep the current settings by setting the `external-registry` in your custom environment values:

```yaml
global:
  imagePullSecrets:
    - "external-registry"
```

#### Dedicated group for access of the UDM REST API

Prerequisite: You allow the use of the [IAM's API](https://docs.software-univention.de/developer-reference/5.0/en/udm/rest-api.html)
with the following settings:

```
functional:
  externalServices:
    nubus:
      udmRestApi:
        enabled: true
```

With 0.9.0 all members of the group "Domain Admins" were able to successfully authenticate with the API.

This has been changed and there is now a dedicated group required for using the API: `IAM API - Full Access`

If you need specific accounts to make use of the API, please go ahead and assign them to the aforementioned group.

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
