<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

# External services

This document will cover the additional configuration for external services like databases, caches, or buckets.

<!-- TOC -->
* [External services](#external-services)
  * [Database](#database)
  * [Object storage](#object-storage)
  * [Cache](#cache)
  * [Footnotes](#footnotes)
<!-- TOC -->

## Database

When deploying this suite to production, you need to configure the applications to use your production-grade database
service.

> [!note]
> openDesk supports PostgreSQL as alternative database backend for Nextcloud and XWiki. PostgreSQL is likely
> to become the preferred option/default in the future should MariaDB become deprecated. This would cause
> migration[^1] to be necessary if you do not select PostgreSQL for new installations.

| Component          | Name               | Parameter | Key                                           | Default                      |
| ------------------ | ------------------ | --------- | --------------------------------------------- | ---------------------------- |
| Element            | Synapse            |           |                                               |                              |
|                    |                    | Type      | `databases.synapse.type`                      | `postgresql`                 |
|                    |                    | Name      | `databases.synapse.name`                      | `matrix`                     |
|                    |                    | Host      | `databases.synapse.host`                      | `postgresql`                 |
|                    |                    | Port      | `databases.synapse.port`                      | `5432`                       |
|                    |                    | Username  | `databases.synapse.username`                  | `matrix_user`                |
|                    |                    | Password  | `databases.synapse.password`                  |                              |
| Nubus              | Guardian Mgmt API  |           |                                               |                              |
|                    |                    | Type      | `databases.umsGuardianManagementApi.type`     | `postgresql`                 |
|                    |                    | Name      | `databases.umsGuardianManagementApi.name`     | `guardianmanagementapi`      |
|                    |                    | Host      | `databases.umsGuardianManagementApi.host`     | `postgresql`                 |
|                    |                    | Port      | `databases.umsGuardianManagementApi.port`     | `5432`                       |
|                    |                    | Username  | `databases.umsGuardianManagementApi.username` | `guardianmanagementapi_user` |
|                    |                    | Password  | `databases.umsGuardianManagementApi.password` |                              |
|                    | Keycloak           |           |                                               |                              |
|                    |                    | Type      | `databases.keycloak.type`                     | `postgresql`                 |
|                    |                    | Name      | `databases.keycloak.name`                     | `keycloak`                   |
|                    |                    | Host      | `databases.keycloak.host`                     | `postgresql`                 |
|                    |                    | Port      | `databases.keycloak.port`                     | `5432`                       |
|                    |                    | Username  | `databases.keycloak.username`                 | `keycloak_user`              |
|                    |                    | Password  | `databases.keycloak.password`                 |                              |
|                    | Keycloak Extension |           |                                               |                              |
|                    |                    | Type      | `databases.keycloakExtension.type`            | `postgresql`                 |
|                    |                    | Name      | `databases.keycloakExtension.name`            | `keycloak_extensions`        |
|                    |                    | Host      | `databases.keycloakExtension.host`            | `postgresql`                 |
|                    |                    | Port      | `databases.keycloakExtension.port`            | `5432`                       |
|                    |                    | Username  | `databases.keycloakExtension.username`        | `keycloak_extensions_user`   |
|                    |                    | Password  | `databases.keycloakExtension.password`        |                              |
|                    | Notifications API  |           |                                               |                              |
|                    |                    | Type      | `databases.umsNotificationsApi.type`          | `postgresql`                 |
|                    |                    | Name      | `databases.umsNotificationsApi.name`          | `notificationsapi`           |
|                    |                    | Host      | `databases.umsNotificationsApi.host`          | `postgresql`                 |
|                    |                    | Port      | `databases.umsNotificationsApi.port`          | `5432`                       |
|                    |                    | Username  | `databases.umsNotificationsApi.username`      | `notificationsapi_user`      |
|                    |                    | Password  | `databases.umsNotificationsApi.password`      |                              |
|                    | Self Service       |           |                                               |                              |
|                    |                    | Type      | `databases.umsSelfservice.type`               | `postgresql`                 |
|                    |                    | Name      | `databases.umsSelfservice.name`               | `selfservice`                |
|                    |                    | Host      | `databases.umsSelfservice.host`               | `postgresql`                 |
|                    |                    | Port      | `databases.umsSelfservice.port`               | `5432`                       |
|                    |                    | Username  | `databases.umsSelfservice.username`           | `selfservice_user`           |
|                    |                    | Password  | `databases.umsSelfservice.password`           |                              |
| Nextcloud          | Nextcloud          |           |                                               |                              |
|                    |                    | Type      | `databases.nextcloud.type`                    | `postgresql`                 |
|                    |                    | Name      | `databases.nextcloud.name`                    | `nextcloud`                  |
|                    |                    | Host      | `databases.nextcloud.host`                    | `postgresql`                 |
|                    |                    | Port      | `databases.nextcloud.port`                    | `5432`                       |
|                    |                    | Username  | `databases.nextcloud.username`                | `nextcloud_user`             |
|                    |                    | Password  | `databases.nextcloud.password`                |                              |
| Notes              | Notes              |           |                                               |                              |
|                    |                    | Type      | `databases.notes.type`                        | `postgresql`                 |
|                    |                    | Name      | `databases.notes.name`                        | `notes`                      |
|                    |                    | Host      | `databases.notes.host`                        | `postgresql`                 |
|                    |                    | Port      | `databases.notes.port`                        | `5432`                       |
|                    |                    | Username  | `databases.notes.username`                    | `notes_user`                 |
|                    |                    | Password  | `databases.notes.password`                    |                              |
| OpenProject        | OpenProject        |           |                                               |                              |
|                    |                    | Type      | `databases.openproject.type`                  | `postgresql`                 |
|                    |                    | Name      | `databases.openproject.name`                  | `openproject`                |
|                    |                    | Host      | `databases.openproject.host`                  | `postgresql`                 |
|                    |                    | Port      | `databases.openproject.port`                  | `5432`                       |
|                    |                    | Username  | `databases.openproject.username`              | `openproject_user`           |
|                    |                    | Password  | `databases.openproject.password`              |                              |
| OX App Suite[^2]   | OX App Suite       |           |                                               |                              |
|                    |                    | Type      | `databases.oxAppSuite.type`                   | `mariadb`                    |
|                    |                    | Name      | `databases.oxAppSuite.name`                   | `openxchange`                |
|                    |                    | Host      | `databases.oxAppSuite.host`                   | `mariadb`                    |
|                    |                    | Port      | `databases.oxAppSuite.port`                   | `3306`                       |
|                    |                    | Username  | `databases.oxAppSuite.username`               | `root`                       |
|                    |                    | Password  | `databases.oxAppSuite.password`               |                              |
| OX Dovecot Pro[^3] | ACLs               |           |                                               |                              |
|                    |                    | Type      | `databases.dovecotACL.type`                   | `cassandra`                  |
|                    |                    | Name      | `databases.dovecotACL.name`                   | `dovecot_acl`                |
|                    |                    | Host      | `databases.dovecotACL.host`                   | `cassandra`                  |
|                    |                    | Port      | `databases.dovecotACL.port`                   | `9042`                       |
|                    |                    | Username  | `databases.dovecotACL.username`               | `dovecot_acl_user`           |
|                    |                    | Password  | `databases.dovecotACL.password`               |                              |
|                    | Dictmap            |           |                                               |                              |
|                    |                    | Type      | `databases.dovecotDictmap.type`               | `cassandra`                  |
|                    |                    | Name      | `databases.dovecotDictmap.name`               | `dovecot_dictmap`            |
|                    |                    | Host      | `databases.dovecotDictmap.host`               | `cassandra`                  |
|                    |                    | Port      | `databases.dovecotDictmap.port`               | `9042`                       |
|                    |                    | Username  | `databases.dovecotDictmap.username`           | `dovecot_dictmap_user`       |
|                    |                    | Password  | `databases.dovecotDictmap.password`           |                              |
| XWiki[^4]          | XWiki              |           |                                               |                              |
|                    |                    | Type      | `databases.xwiki.type`                        | `postgresql`                 |
|                    |                    | Name      | `databases.xwiki.name`                        | `xwiki`                      |
|                    |                    | Host      | `databases.xwiki.host`                        | `postgresql`                 |
|                    |                    | Port      | `databases.xwiki.port`                        | `5432`                       |
|                    |                    | Username  | `databases.xwiki.username`                    | `xwiki_user`                 |
|                    |                    | Password  | `databases.xwiki.password`                    |                              |

## Object storage

When deploying this suite to production, you need to configure the applications to use your production-grade object
storage service.

| Component   | Name        | Parameter       | Key                                      | Default            |
|-------------|-------------|-----------------|------------------------------------------|--------------------|
| OpenProject | OpenProject |                 |                                          |                    |
|             |             | Backend         | `objectstores.openproject.backend`       | `minio`            |
|             |             | Bucket          | `objectstores.openproject.bucket`        | `openproject`      |
|             |             | Endpoint        | `objectstores.openproject.endpoint`      |                    |
|             |             | Provider        | `objectstores.openproject.provider`      | `AWS`              |
|             |             | Region          | `objectstores.openproject.region`        |                    |
|             |             | Secret          | `objectstores.openproject.secret`        |                    |
|             |             | Username        | `objectstores.openproject.username`      | `openproject_user` |
|             |             | Use IAM profile | `objectstores.openproject.useIAMProfile` |                    |

## Cache

When deploying this suite to production, you need to configure the applications to use your production-grade cache
service.

| Component        | Name             | Type      | Parameter | Key                          | Default          |
|------------------|------------------|-----------|-----------|------------------------------|------------------|
| Intercom Service | Intercom Service | Redis     |           |                              |                  |
|                  |                  |           | Host      | `cache.intercomService.host` | `redis-headless` |
|                  |                  |           | Port      | `cache.intercomService.port` | `6379`           |
| Nextcloud        | Nextcloud        | Redis     |           |                              |                  |
|                  |                  |           | Host      | `cache.nextcloud.host`       | `redis-headless` |
|                  |                  |           | Port      | `cache.nextcloud.port`       | `6379`           |
| OpenProject      | OpenProject      | Memcached |           |                              |                  |
|                  |                  |           | Host      | `cache.openproject.host`     | `memcached`      |
|                  |                  |           | Port      | `cache.openproject.port`     | `11211`          |
| UMS              | Self Service     | Memcached |           |                              |                  |
|                  |                  |           | Host      | `cache.umsSelfservice.host`  | `memcached`      |
|                  |                  |           | Port      | `cache.umsSelfservice.port`  | `11211`          |

## Education services (openDesk Edu)

The following external services are required by the education-focused applications added in openDesk Edu.
Configuration follows the same pattern as the upstream services above.

### Database

| Component        | Name    | Parameter                        | Key                                           | Default        |
| ---------------- | ------- | -------------------------------- | --------------------------------------------- | -------------- |
| ILIAS            | ILIAS   |                                  |                                               |                |
|                  |         | Type                             | `databases.ilias.type`                        | `postgresql`   |
|                  |         | Name                             | `databases.ilias.name`                        | `ilias`        |
|                  |         | Host                             | `databases.ilias.host`                        | `postgresql`   |
|                  |         | Port                             | `databases.ilias.port`                        | `5432`         |
|                  |         | Username                         | `databases.ilias.username`                    | `ilias_user`   |
|                  |         | Password                         | `databases.ilias.password`                    |                |
| Moodle           | Moodle  |                                  |                                               |                |
|                  |         | Type                             | `databases.moodle.type`                       | `postgresql`   |
|                  |         | Name                             | `databases.moodle.name`                       | `moodle`       |
|                  |         | Host                             | `databases.moodle.host`                       | `postgresql`   |
|                  |         | Port                             | `databases.moodle.port`                       | `5432`         |
|                  |         | Username                         | `databases.moodle.username`                   | `moodle_user`  |
|                  |         | Password                         | `databases.moodle.password`                   |                |
| BigBlueButton    | BBB     |                                  |                                               |                |
|                  |         | Type                             | `databases.bbb.type`                          | `postgresql`   |
|                  |         | Name                             | `databases.bbb.name`                          | `bigbluebutton`|
|                  |         | Host                             | `databases.bbb.host`                          | `postgresql`   |
|                  |         | Port                             | `databases.bbb.port`                          | `5432`         |
|                  |         | Username                         | `databases.bbb.username`                      | `bbb_user`     |
|                  |         | Password                         | `databases.bbb.password`                      |                |
| Etherpad         | Etherpad|                                  |                                               |                |
|                  |         | Type                             | `databases.etherpad.type`                     | `postgresql`   |
|                  |         | Name                             | `databases.etherpad.name`                     | `etherpad`     |
|                  |         | Host                             | `databases.etherpad.host`                     | `postgresql`   |
|                  |         | Port                             | `databases.etherpad.port`                     | `5432`         |
|                  |         | Username                         | `databases.etherpad.username`                 | `etherpad_user`|
|                  |         | Password                         | `databases.etherpad.password`                 |                |
| BookStack        | BookStack|                                 |                                               |                |
|                  |         | Type                             | `databases.bookstack.type`                    | `mariadb`      |
|                  |         | Name                             | `databases.bookstack.name`                    | `bookstack`    |
|                  |         | Host                             | `databases.bookstack.host`                    | `mariadb`      |
|                  |         | Port                             | `databases.bookstack.port`                    | `3306`         |
|                  |         | Username                         | `databases.bookstack.username`                | `bookstack_user`|
|                  |         | Password                         | `databases.bookstack.password`                |                |
| Planka           | Planka   |                                  |                                               |                |
|                  |         | Type                             | `databases.planka.type`                       | `postgresql`   |
|                  |         | Name                             | `databases.planka.name`                       | `planka`       |
|                  |         | Host                             | `databases.planka.host`                       | `postgresql`   |
|                  |         | Port                             | `databases.planka.port`                       | `5432`         |
|                  |         | Username                         | `databases.planka.username`                   | `planka_user`  |
|                  |         | Password                         | `databases.planka.password`                   |                |
| Zammad           | Zammad   |                                  |                                               |                |
|                  |         | Type                             | `databases.zammad.type`                       | `postgresql`   |
|                  |         | Name                             | `databases.zammad.name`                       | `zammad`       |
|                  |         | Host                             | `databases.zammad.host`                       | `postgresql`   |
|                  |         | Port                             | `databases.zammad.port`                       | `5432`         |
|                  |         | Username                         | `databases.zammad.username`                   | `zammad_user`  |
|                  |         | Password                         | `databases.zammad.password`                   |                |
| LimeSurvey       | LimeSurvey|                                 |                                               |                |
|                  |         | Type                             | `databases.limesurvey.type`                   | `mariadb`      |
|                  |         | Name                             | `databases.limesurvey.name`                   | `limesurvey`   |
|                  |         | Host                             | `databases.limesurvey.host`                   | `mariadb`      |
|                  |         | Port                             | `databases.limesurvey.port`                   | `3306`         |
|                  |         | Username                         | `databases.limesurvey.username`               | `limesurvey_user`|
|                  |         | Password                         | `databases.limesurvey.password`               |                |
| SOGo             | SOGo    |                                  |                                               |                |
|                  |         | Type                             | `databases.sogo.type`                         | `postgresql`   |
|                  |         | Name                             | `databases.sogo.name`                         | `sogo`         |
|                  |         | Host                             | `databases.sogo.host`                         | `postgresql`   |
|                  |         | Port                             | `databases.sogo.port`                         | `5432`         |
|                  |         | Username                         | `databases.sogo.username`                     | `sogo_user`    |
|                  |         | Password                         | `databases.sogo.password`                     |                |
| TYPO3 CMS        | TYPO3   |                                  |                                               |                |
|                  |         | Type                             | `databases.typo3.type`                        | `mariadb`      |
|                  |         | Name                             | `databases.typo3.name`                        | `typo3`        |
|                  |         | Host                             | `databases.typo3.host`                        | `mariadb`      |
|                  |         | Port                             | `databases.typo3.port`                        | `3306`         |
|                  |         | Username                         | `databases.typo3.username`                    | `typo3_user`   |
|                  |         | Password                         | `databases.typo3.password`                    |                |

> [!note]
> Draw.io, Excalidraw, and Self-Service Password are stateless applications and do not require a database.

### Object storage

| Component     | Name    | Parameter                    | Key                                  | Default     |
| ------------- | ------- | ---------------------------- | ------------------------------------ | ----------- |
| ILIAS         | ILIAS   |                              |                                      |             |
|               |         | Backend                      | `objectstores.ilias.backend`         | `s3`        |
|               |         | Bucket                       | `objectstores.ilias.bucket`          | `ilias-data`|
|               |         | Endpoint                     | `objectstores.ilias.endpoint`        |             |
|               |         | Region                       | `objectstores.ilias.region`          |             |
|               |         | Secret                       | `objectstores.ilias.secret`          |             |
|               |         | Username                     | `objectstores.ilias.username`        |             |

### Cache

| Component     | Name    | Type  | Parameter                    | Key                        | Default          |
| ------------- | ------- | ----- | ---------------------------- | -------------------------- | ---------------- |
| BigBlueButton | BBB     | Redis |                              |                            |                  |
|               |         |       | Host                         | `cache.bbb.host`           | `redis-headless` |
|               |         |       | Port                         | `cache.bbb.port`           | `6379`           |
| Zammad        | Zammad  | Redis |                              |                            |                  |
|               |         |       | Host                         | `cache.zammad.host`        | `redis-headless` |
|               |         |       | Port                         | `cache.zammad.port`        | `6379`           |
| SOGo          | SOGo    | Memcached |                            |                            |                  |
|               |         |       | Host                         | `cache.sogo.host`          | `memcached`      |
|               |         |       | Port                         | `cache.sogo.port`          | `11211`          |

## Footnotes

[^1] The upstream product documentation provides some valuable information regarding database migrations:

* Nextcloud: <https://docs.nextcloud.com/server/latest/admin_manual/configuration_database/db_conversion.html>
* XWiki:
  * <https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/Backup#HUsingtheXWikiExportfeature>
  * <https://www.xwiki.org/xwiki/bin/view/Documentation/AdminGuide/ImportExport>

[^2] OX App Suite only supports MariaDB and requires root access, as it manages its databases itself.

[^3] openDesk Enterprise only.

[^4] XWiki requires root access when using MariaDB due to the fact that sub-wikis use separate databases that are managed by XWiki. When using PostgreSQL with XWiki no root user is required as the sub-wikis are managed within multiple schemas within a single database.
