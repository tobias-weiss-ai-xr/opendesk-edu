<!--
SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
SPDX-License-Identifier: Apache-2.0
-->

<h1>Updates & Upgrades</h1>

<!-- TOC -->
* [Disclaimer](#disclaimer)
* [Automated migrations - Overview and mandatory upgrade path](#automated-migrations---overview-and-mandatory-upgrade-path)
* [Manual checks/actions](#manual-checksactions)
  * [From v1.1.1](#from-v111)
    * [Pre-upgrade from v1.1.1](#pre-upgrade-from-v111)
      * [Helmfile feature update: App settings wrapped in `apps.` element](#helmfile-feature-update-app-settings-wrapped-in-apps-element)
  * [From v1.1.0](#from-v110)
    * [Pre-upgrade from v1.1.0](#pre-upgrade-from-v110)
      * [Helmfile feature update: Component specific `storageClassName`](#helmfile-feature-update-component-specific-storageclassname)
      * [Helmfile new secret: `secrets.nubus.masterpassword`](#helmfile-new-secret-secretsnubusmasterpassword)
  * [From v1.0.0](#from-v100)
    * [Pre-upgrade from v1.0.0](#pre-upgrade-from-v100)
      * [Helmfile cleanup: Restructured `/helmfile/files/theme` folder](#helmfile-cleanup-restructured-helmfilefilestheme-folder)
      * [Helmfile cleanup: Consistent use of `*.yaml.gotmpl`](#helmfile-cleanup-consistent-use-of-yamlgotmpl)
      * [Helmfile cleanup: Prefixing certain app directories with `opendesk-`](#helmfile-cleanup-prefixing-certain-app-directories-with-opendesk-)
      * [Helmfile cleanup: Helmfile cleanup: Splitting external vs. openDesk services](#helmfile-cleanup-helmfile-cleanup-splitting-external-vs-opendesk-services)
      * [Helmfile cleanup: Streamlining `openxchange` and `oxAppSuite` attribute names](#helmfile-cleanup-streamlining-openxchange-and-oxappsuite-attribute-names)
      * [Helmfile feature update: Dicts to define `customization.release`](#helmfile-feature-update-dicts-to-define-customizationrelease)
      * [openDesk defaults (new): Enforce login](#opendesk-defaults-new-enforce-login)
      * [openDesk defaults (changed): Jitsi room history enabled](#opendesk-defaults-changed-jitsi-room-history-enabled)
      * [External requirements: Redis 7.4](#external-requirements-redis-74)
    * [Post-upgrade from v1.0.0](#post-upgrade-from-v100)
      * [XWiki fix-ups](#xwiki-fix-ups)
  * [From v0.9.0](#from-v090)
    * [Pre-upgrade from v0.9.0](#pre-upgrade-from-v090)
      * [Configuration Cleanup: Removal of unnecessary OX-Profiles in Nubus](#configuration-cleanup-removal-of-unnecessary-ox-profiles-in-nubus)
      * [Configuration Cleanup: Updated `global.imagePullSecrets`](#configuration-cleanup-updated-globalimagepullsecrets)
      * [Changed openDesk defaults: Matrix presence status disabled](#changed-opendesk-defaults-matrix-presence-status-disabled)
      * [Changed openDesk defaults: Matrix ID](#changed-opendesk-defaults-matrix-id)
      * [Changed openDesk defaults: File-share configurability](#changed-opendesk-defaults-file-share-configurability)
      * [Changed openDesk defaults: Updated default subdomains in `global.hosts`](#changed-opendesk-defaults-updated-default-subdomains-in-globalhosts)
      * [Changed openDesk defaults: Dedicated group for access to the UDM REST API](#changed-opendesk-defaults-dedicated-group-for-access-to-the-udm-rest-api)
    * [Post-upgrade from v0.9.0](#post-upgrade-from-v090)
      * [Configuration Improvement: Separate user permission for using Video Conference component](#configuration-improvement-separate-user-permission-for-using-video-conference-component)
      * [Optional Cleanup](#optional-cleanup)
  * [From v0.8.1](#from-v081)
    * [Pre-upgrade from v0.8.1](#pre-upgrade-from-v081)
      * [Updated `cluster.networking.cidr`](#updated-clusternetworkingcidr)
      * [Updated customizable template attributes](#updated-customizable-template-attributes)
      * [`migrations` S3 bucket](#migrations-s3-bucket)
* [Automated migrations - Details](#automated-migrations---details)
  * [From v1.0.0 (automated)](#from-v100-automated)
  * [From v0.9.0 (automated)](#from-v090-automated)
  * [Related components and artifacts](#related-components-and-artifacts)
  * [Development](#development)
<!-- TOC -->

# Disclaimer

Starting with openDesk 1.0, we aim to offer hassle-free updates/upgrades.

Therefore openDesk contains automated migrations between versions to lower the requirements for manual interaction. These automated migrations can have limitations in the way that they need a certain openDesk version to be installed causing a mandatory upgrade path that is described in the section [Automated migrations](#automated-migrations).

Manual checks and possible activities are also required by openDesk updates, they are described in the section [Manual update steps](#manual-update-steps).

> **Note**<br>
> Please be sure you read / follow the requirements before you update / upgrade thoroughly.

> **Known limitations**<br>
> We assume that the PV reclaim policy is set to `delete`, resulting in PVs getting deleted as soon as the related PVC was deleted; we will not address explicit deletion for PVs.

# Automated migrations - Overview and mandatory upgrade path

The following table gives an overview of the mandatory upgrade path of openDesk for the automated migrations to work as expected.

To upgrade existing deployments, you cannot skip any version mentioned in the column *Mandatory version*. When a version number is not fully defined (e.g. `v1.1.x`), you can install any version matching the given schema.

| Mandatory version |
| ----------------- |
| v1.2.x            |
| v1.1.x            |
| v1.0.0            |
| v0.9.0            |
| v0.8.1            |

> **Note**<br>
> Be sure you check out the table in the release version you are going to install, an not the one that is currently installed.

When interested in more details about the automated migrations, please read section [Automated migrations - Details](#automated-migrations---details).

# Manual checks/actions

Be sure you check all the sections for the releases your are going to update your current deployment from.

## From v1.1.2

#### Helmfile cleanup: Do not configure OX provisioning when no OX installed

**Target group:** Installations that have no OX App Suite installed.

With openDesk 1.2.0 the OX provisioning consumer will not be registered when there is no OX installed.

We do not remove the consumer for existing installations, if you want to do that for your existing installation please perform the following steps:

```
export NAMESPACE=<your_namespace>
kubectl -n ${NAMESPACE} exec -it ums-provisioning-nats-0 -c nats-box -- sh -c 'nats consumer rm stream:ox-connector durable_name:ox-connector --user=admin --password=${NATS_PASSWORD} --force'
kubectl -n ${NAMESPACE} exec -it ums-provisioning-nats-0 -c nats-box -- sh -c 'nats stream rm stream:ox-connector --user=admin --password=${NATS_PASSWORD} --force'
kubectl -n ${NAMESPACE} delete secret ums-provisioning-ox-credentials-test
```

#### Helmfile new default: PostgreSQL for XWiki and Nextcloud

**Target group:** All upgrade installations that do not already use the previous optional PostgreSQL database backend for Nextcloud and XWiki.

openDesk now uses PostgreSQL as default database backend for Nextcloud and XWiki.

When upgrading existing instances you likely want to keep the current database backend (MariaDB).

**Use case A:** You use your own external database services, if not see "Use case B" further down.

You just have to add the new `type` attribute and set it to `mariadb`:

```yaml
databases:
  nextcloud:
    type: "mariadb"
  xwiki:
    type: "mariadb"
```

**Use case B:** You use the openDesk supplied database services.

Ensure you set the following attributes before upgrading, this includes the aforementioned `type` attribute.

```yaml
databases:
  nextcloud:
    type: "mariadb"
    host: "mariadb"
    port: 3306
  xwiki:
    type: "mariadb"
    host: "mariadb"
    port: 3306
    username: "root"
```

In case you are planning to migrate an existing instance from MariaDB to PostgreSQL please check the upstream documentation for details:

- Nextcloud database migration: https://docs.nextcloud.com/server/latest/admin_manual/configuration_database/db_conversion.html
- XWiki:
  - https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Backup#HUsingtheXWikiExportfeature
  - https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/ImportExport

## From v1.1.1

### Pre-upgrade from v1.1.1

#### Helmfile feature update: App settings wrapped in `apps.` element

We require now [Helmfile v1.0.0-rc.8](https://github.com/helmfile/helmfile/releases/tag/v1.0.0-rc.8) for the deployment. This enables openDesk to lay the foundation for some significant cleanups where the information for the different apps especially on their `enabled` state is needed.

Therefore it was required to introduce the `apps` level in [`opendesk_main.yaml.gotmpl`](../helmfile/environments/default/opendesk_main.yaml.gotmpl).

If you have a deployment where you specify settings that can be found in the aforementioned file, usually to disable components or enable others, please ensure you insert the top-level attribute `apps` like shown in the following example:

So a setting of:

```
certificates:
  enabled: false
notes:
  enabled: true
```

needs to be changed to:

```
apps:
  certificates:
    enabled: false
  notes:
    enabled: true
```

## From v1.1.0

### Pre-upgrade from v1.1.0

#### Helmfile feature update: Component specific `storageClassName`

With openDesk 1.1.1 we support component specific `storageClassName` definitions beside the global ones, but we had to adapt the structure that can be found in `persistence.yaml.gotmpl` to achieve this in a clean manner.

If you have set custom `persistence.size.*`-values for your deployment, please continue reading as you need to adapt your `persistence` settings to the new structure.

When comparing the [old 1.1.0 structure](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/v1.1.0/helmfile/environments/default/persistence.yaml.gotmpl) with the [new one](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/v1.1.1/helmfile/environments/default/persistence.yaml.gotmpl) you can spot the changes:

- We replaced `persistence.size` with `persistence.storages`.
- Below each component you can define now the `size` and the optional component specific `storageClassName`.
- We streamlined all components to be on the same level, as Nubus had an additional level of nesting before.

So a setting of:

```yaml
persistence:
  size:
    synapse: "1Gi"
```

needs to be changed to:

```yaml
persistence:
  storages:
    synapse:
      size: "1Gi"
```

or for the Nubus related entries, the following:

```yaml
persistence:
  size:
    nubus:
      ldapServerData: "1Gi"
```

needs to be changed to:

```yaml
persistence:
  storages:
    nubusLdapServerData:
      size: "1Gi"
```

#### Helmfile new secret: `secrets.nubus.masterpassword`

A not yet templated secret was discovered in the Nubus deployment that is now defined in [`secrets.yaml.gotmpl`](../helmfile/environments/default/theme.yaml.gotmpl) with the key `secrets.nubus.masterpassword`. If you define your own secrets, please be sure this new secret is set to the value of the `MASTER_PASSWORD` environment variable used in your deployment.

## From v1.0.0

### Pre-upgrade from v1.0.0

#### Helmfile cleanup: Restructured `/helmfile/files/theme` folder

If you make use of the [theme folder](../helmfile/files/theme/) or the [`theme.yaml.gotmpl`](../helmfile/environments/default/theme.yaml.gotmpl), e.g. to applying your own imagery, please ensure you adhere to the new structure of the folder and the yaml-file.

#### Helmfile cleanup: Consistent use of `*.yaml.gotmpl`

In v1.0.0 the files in [`/helmfile/environments/default`](../helmfile/environments/default/) had mixed extensions,
we have streamlined them to consistently use `*.yaml.gotmpl`.

This change requires manual action likely in two situations:

1. You are referencing our upstream files from the aforementioned directory, e.g. in your Argo CD deployment. Please update your references to use the filenames with the new extension.
2. You have custom files containing configuration information that are named just `*.yaml`: Please rename them to `*.yaml.gotmpl`.

#### Helmfile cleanup: Prefixing certain app directories with `opendesk-`

To make it more obvious that some elements from below the [`apps`](../helmfile/apps/) directory are completely
provided by openDesk, we have prefixed these app directories with `opendesk-`.

Affected are the following directories, here listed directly with the new prefix:

- [`./helmfile/apps/opendesk-migrations-pre`](../helmfile/apps/opendesk-migrations-pre)
- [`./helmfile/apps/opendesk-migrations-post`](../helmfile/apps/opendesk-migrations-post)
- [`./helmfile/apps/opendesk-openproject-bootstrap`](../helmfile/apps/opendesk-openproject-bootstrap)

The described changes most likely require manual action in the following situation:

- You are referencing our upstream files e.g. in your Argo CD deployment, please update your references to use the new directory names.

#### Helmfile cleanup: Helmfile cleanup: Splitting external vs. openDesk services

In v1.0.0 there was a directory `/helmfile/apps/services` that was intended to contain all the services an operator had to provide externally for production deployments.

As some services that are actually part of openDesk snuck in there, so we had to split the directory into two separate ones:

- [`./helmfile/apps/opendesk-services`](../helmfile/apps/opendesk-services)
- [`./helmfile/apps/services-external`](../helmfile/apps/services-external)

The described changes most likely require manual action in the following situation:

- You are referencing our upstream files e.g. in your Argo CD deployment, please update your references to use the new directory names.

#### Helmfile cleanup: Streamlining `openxchange` and `oxAppSuite` attribute names

We have updated some attribute names around Open-Xchange / OX App Suite to be consistent within our Helmfile
deployment and to aligning with the actual brand names as well as with our rule of thumb for brand based
attribute names[^1].

In case you are using any of the customizations below (`WAS`), please update as shown (`NOW`):

```
WAS: oxAppsuite: ...
NOW: oxAppSuite: ...
```

```
WAS: cache.oxAppsuite: ...
NOW: cache.oxAppSuite: ...
```

```
WAS: charts.openXchangeAppSuite: ...
NOW: charts.oxAppSuite: ...
```

```
WAS: charts.openXchangeAppSuiteBootstrap: ...
NOW: charts.oxAppSuiteBootstrap: ...
```

```
WAS: customization.release.openXchange: ...
NOW: customization.release.openxchange: ...
```

```
WAS: customization.release.opendeskOpenXchangeBootstrap: ...
NOW: customization.release.opendeskOpenxchangeBootstrap: ...
```

```
WAS: databases.oxAppsuite: ...
NOW: databases.oxAppSuite: ...
```

```
WAS: ingress.parameters.openXchangeAppSuite: ...
NOW: ingress.parameters.oxAppSuite: ...
```

```
WAS: ingress.bodyTimeout.openXchangeAppSuite: ...
NOW: ingress.bodyTimeout.oxAppSuite: ...
```

```
WAS: migration.oxAppsuite: ...
NOW: migration.oxAppSuite: ...
```

```
WAS: secrets.oxAppsuite: ...
NOW: secrets.oxAppSuite: ...
```

#### Helmfile feature update: Dicts to define `customization.release`

If you make use of the `customization.release` option, you have to switch to a dictionary based definition of customization files e.g. from

```yaml
customization:
  release:
    collaboraOnline: "./my_custom_templating.yaml.gotmpl"
```

to

```yaml
customization:
  release:
    collaboraOnline:
      file1: "./my_custom_templating.yaml.gotmpl"
```

You can freely choose the `file1` dictionary key used in the example above, but it should start with a letter.

#### openDesk defaults (new): Enforce login

Users accessing the openDesk portal are now automatically redirected to the login screen as a default.

In case you want to keep the previous behavior you need to set the following `functional` flag:

```yaml
functional:
  portal:
    enforceLogin: false
```

#### openDesk defaults (changed): Jitsi room history enabled

The default to store the Jitsi room history in the local storage of a user's browser has changed.

It is now enabled and therefore stored by default.

To preserve the 1.0.0 behavior of not storing the room history you have to explicitly configure it:

```yaml
functional:
  dataProtection:
    jitsiRoomHistory:
      enabled: false
```

#### External requirements: Redis 7.4

The update from openDesk 1.0.0 contains Redis 7.4.1, like the other openDesk bundled services the bundled Redis is as well not meant to be used in production.

Please ensure for the Redis you are using that it is updated to at least 7.4 to support the requirement of OX App Suite.

### Post-upgrade from v1.0.0

#### XWiki fix-ups

Unfortunately XWiki does not upgrade itself as expected. A bug with the supplier has already been filed. The following additional steps are required:

1. To enforce re-indexing of the now fixed full-text search access the XWiki Pod and run the following commands to delete two search related directories. To complete this you need to restart the XWiki Pod, but that is anyway part of the next step:
   ```
   rm -rf /usr/local/xwiki/data/store/solr/search_9
   rm -rf /usr/local/xwiki/data/cache/solr/search_9
   ```

2. This is necessary if the openDesk single sign-on does not longer work and you get a standard XWiki login dialogue instead.
   - Find the XWiki ConfigMap `xwiki-init-scripts` and find in its `entrypoint` key data the lines beginning with `xwiki_replace_or_add "/usr/local/xwiki/data/xwiki.cfg"`
   - Before those lines add the following line, of course setting `<YOUR_TEMPORARY_SUPERADMIN_PASSWORD>` to a value you are happy with.
     ```
         xwiki_replace_or_add "/usr/local/xwiki/data/xwiki.cfg" 'xwiki.superadminpassword' '<YOUR_TEMPORARY_SUPERADMIN_PASSWORD>'
     ```
   - Restart the XWiki Pod.
   - Access XWiki's web UI and login with `superadmin` and the above set password.
   - Once XWiki UI is fully rendered, remove the line with the temporary `superadmin` password from the aforementioned ConfigMap.
   - Restart the XWiki Pod.

You should have now a properly working XWiki instance with single sign-on and full-text search.

## From v0.9.0

### Pre-upgrade from v0.9.0

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

#### Changed openDesk defaults: Matrix presence status disabled

Show other user's Matrix presence status is now disabled by default to comply with data protection requirements.

To enable it or keep the v0.9.0 default please set:

```yaml
functional:
  dataProtection:
    matrixPresence:
      enabled: true
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

### Post-upgrade from v0.9.0

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

### Pre-upgrade from v0.8.1

#### Updated `cluster.networking.cidr`

- Action: `cluster.networking.cidr` is now an array (was a string until 0.8.1); please update your setup accordingly if you explicitly set this value.
- Reference:[cluster.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/cluster.yaml)

#### Updated customizable template attributes

- Action: Please update your custom deployment values according to the updated default value structure.
- References:
  - `functional.` prefix for `authentication.*`, `externalServices.*`, `admin.*` and `filestore.*`, see [functional.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/functional.yaml).
  - `debug.` prefix for `cleanup.*`, see [debug.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/debug.yaml).
  - `monitoring.` prefix for `prometheus.*` and `graphana.*`, see [monitoring.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/monitoring.yaml).
  - `smtp.` prefix for `localpartNoReply`, see [smtp.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/smtp.yaml).

#### `migrations` S3 bucket

- Action: For self-managed/external S3/object storages, please ensure you add a bucket `migrations` to your S3.
- Reference: `objectstores.migrations` in [objectstores.yaml](https://gitlab.opencode.de/bmi/opendesk/deployment/opendesk/-/blob/main/helmfile/environments/default/objectstores.yaml)

# Automated migrations - Details

## From v1.1.2 (automated)

> **Note**<br>
> Details can be found in [run_4.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_4.py).

### migrations-pre

- Delete PVC `group-membership-cache-ums-portal-consumer-0`: With the upgrade the Nubus Portal Consumer no longer requires to be executed with root privileges. The PVC contains files that require root permission to access them, therefore the PVC gets deleted (and re-created) during the upgrade.
- Delete StatefulSet `ums-portal-consumer`: A bug was fixed in the templating of the Portal Consumer's PVC causing the values in `persistence.storages.nubusPortalConsumer.*` to be ignored. As these values are immutable, we had to delete the whole StatefulSet.

### migrations-post

- Restarting Deployment `ums-provisioning-udm-transformer` and StatefulSet `ums-provisioning-udm-listener` as well as deleting the Nubus Provisioning consumer `durable_name:incoming` on stream `stream:incoming`: Due to a bug in Nubus 1.7.0 the `incoming` stream was blocked after the upgrade, the aforementioned measures unblock the stream.

## From v1.0.0 (automated)

With openDesk v1.1.0 the IAM stack supports HA LDAP primary as well as scalable LDAP secondary pods.

openDesk's automated migrations takes care of this upgrade requirement described here for
[Nubus 1.5.1](https://docs.software-univention.de/nubus-kubernetes-release-notes/1.5.1/en/changelog.html#migrate-existing-ldap-server-to-mirror-mode-readiness),
creating the config map with the mentioned label.

> **Note**<br>
> Details can be found in [run_3.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_3.py).

## From v0.9.0 (automated)

The `migrations-pre` and `migrations-post` jobs in the openDesk deployment address the automated migration tasks.

The permissions required to execute the migrations can be found in the migration's Helm chart [`role.yaml'](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/v1.3.5/charts/opendesk-migrations/templates/role.yaml?ref_type=tags#L29)

> **Note**<br>
> Details can be found in [run_2.py](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/-/blob/main/odmigs-python/odmigs_runs/run_3.py).

## Related components and artifacts

openDesk comes with two upgrade steps as part of the deployment; they can be found in the folder [/helmfile/apps](../helmfile/apps/) as all other components:

- `migrations-pre`: Is the very first app that gets deployed.
- `migrations-post`: Is the last app that gets deployed.

Both migrations must be deployed exclusively at their first/last position and not parallel with other components.

The status of the upgrade migrations is tracked in the ConfigMap `migrations-status`, more details can be found in the [README.md of the related container image](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations/README.md).

## Development

When a new upgrade migration is required, ensure to address the following list:

- Update the generated release version file [`global.generated.yaml.gotmpl`](../helmfile/environments/default/global.generated.yaml.gotmpl) at least on the patch level to test the upgrade in your feature branch and trigger it in the `develop` branch after the feature branch was merged. During the release process, the value is overwritten by the release's version number.
- You have to implement the migration logic as a runner script in the [`opendesk-migrations`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/images/opendesk-migrations) image. Please find more instructions in the linked repository.
- You most likely have to update the [`opendesk-migrations` Helm chart](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations) within the `rules` section of the [`role.yaml`](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/templates/role.yaml) to provide the permissions required for the execution of your migration's logic.
- You must set the runner's ID you want to execute in the [migrations.yaml.gotmpl](../helmfile/shared/migrations.yaml.gotmpl). See also the `migrations.*` section of [the Helm chart's README.md](https://gitlab.opencode.de/bmi/opendesk/components/platform-development/charts/opendesk-migrations/-/blob/main/charts/opendesk-migrations/README.md).
- Update the [`charts.yaml.gotmpl`](../helmfile/environments/default/charts.yaml.gotmpl) and [`images.yaml.gotmpl`](../helmfile/environments/default/images.yaml.gotmpl) to reflect the newer releases of the `opendesk-migrations` Helm chart and container image.

[^1]: We do not follow a brand name's specific spelling when it comes to upper and lower case and only use new word
uppercase when names consist of multiple, space divided words.
