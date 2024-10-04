<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
SPDX-License-Identifier: Apache-2.0
-->

<h1>External services</h1>

This document will cover the additional configuration for external services like databases, caches, or buckets.

<!-- TOC -->
* [Database](#database)
* [Object storage](#object-storage)
* [Cache](#cache)
<!-- TOC -->

# Database

When deploying this suite to production, you need to configure the applications to use your production-grade database
service.

| Component   | Name               | Type       | Parameter | Key                                      | Default                    |
|-------------|--------------------|------------|-----------|------------------------------------------|----------------------------|
| Element     | Synapse            | PostgreSQL |           |                                          |                            |
|             |                    |            | Name      | `databases.synapse.name` | `matrix` |
|             |                    |            | Host      | `databases.synapse.host` | `postgresql` |
|             |                    |            | Port      | `databases.synapse.port` | `5432` |
|             |                    |            | Username  | `databases.synapse.username` | `matrix_user` |
|             |                    |            | Password  | `databases.synapse.password` |                            |
| Keycloak    | Keycloak           | PostgreSQL |           |                                          |                            |
|             |                    |            | Name      | `databases.keycloak.name` | `keycloak` |
|             |                    |            | Host      | `databases.keycloak.host` | `postgresql` |
|             |                    |            | Port      | `databases.keycloak.port` | `5432` |
|             |                    |            | Username  | `databases.keycloak.username` | `keycloak_user` |
|             |                    |            | Password  | `databases.keycloak.password` |                            |
|             | Keycloak Extension | PostgreSQL |           |                                          |                            |
|             |                    |            | Name      | `databases.keycloakExtension.name` | `keycloak_extensions` |
|             |                    |            | Host      | `databases.keycloakExtension.host` | `postgresql` |
|             |                    |            | Port      | `databases.keycloakExtension.port` | `5432` |
|             |                    |            | Username  | `databases.keycloakExtension.username` | `keycloak_extensions_user` |
|             |                    |            | Password  | `databases.keycloakExtension.password` |                            |
| UMS         | Notifications API  | PostgreSQL |           |                                          |                            |
|             |                    |            | Name      | `databases.umsNotificationsApi.name` | `notificationsapi` |
|             |                    |            | Host      | `databases.umsNotificationsApi.host` | `postgresql` |
|             |                    |            | Port      | `databases.umsNotificationsApi.port` | `5432` |
|             |                    |            | Username  | `databases.umsNotificationsApi.username` | `notificationsapi_user` |
|             |                    |            | Password  | `databases.umsNotificationsApi.password` |                            |
|             | Self Service       | PostgreSQL |           |                                          |                            |
|             |                    |            | Name      | `databases.umsSelfservice.name` | `selfservice` |
|             |                    |            | Host      | `databases.umsSelfservice.host` | `postgresql` |
|             |                    |            | Port      | `databases.umsSelfservice.port` | `5432` |
|             |                    |            | Username  | `databases.umsSelfservice.username` | `selfservice_user` |
|             |                    |            | Password  | `databases.umsSelfservice.password` |                            |
| Nextcloud   | Nextcloud          | MariaDB    |           |                                          |                            |
|             |                    |            | Name      | `databases.nextcloud.name` | `nextcloud` |
|             |                    |            | Host      | `databases.nextcloud.host` | `mariadb` |
|             |                    |            | Username  | `databases.nextcloud.username` | `nextcloud_user` |
|             |                    |            | Password  | `databases.nextcloud.password` |                            |
| OpenProject | OpenProject        | PostgreSQL |           |                                          |                            |
|             |                    |            | Name      | `databases.openproject.name` | `openproject` |
|             |                    |            | Host      | `databases.openproject.host` | `postgresql` |
|             |                    |            | Port      | `databases.openproject.port` | `5432` |
|             |                    |            | Username  | `databases.openproject.username` | `openproject_user` |
|             |                    |            | Password  | `databases.openproject.password` |                            |
| OX Appsuite | OX Appsuite        | MariaDB    |           |                                          |                            |
|             |                    |            | Name      | `databases.oxAppsuite.name` | `CONFIGDB` |
|             |                    |            | Host      | `databases.oxAppsuite.host` | `mariadb` |
|             |                    |            | Username  | `databases.oxAppsuite.username` | `root` |
|             |                    |            | Password  | `databases.oxAppsuite.password` |                            |
| XWiki       | XWiki              | MariaDB    |           |                                          |                            |
|             |                    |            | Name      | `databases.xwiki.name` | `xwiki` |
|             |                    |            | Host      | `databases.xwiki.host` | `mariadb` |
|             |                    |            | Username  | `databases.xwiki.username` | `xwiki_user` |
|             |                    |            | Password  | `databases.xwiki.password` |                            |

# Object storage

When deploying this suite to production, you need to configure the applications to use your production-grade object
storage service.

| Component   | Name        | Parameter       | Key                                      | Default            |
|-------------|-------------|-----------------|------------------------------------------|--------------------|
| OpenProject | OpenProject |                 |                                          |                    |
|             |             | Backend         | `objectstores.openproject.backend` | `minio` |
|             |             | Bucket          | `objectstores.openproject.bucket` | `openproject` |
|             |             | Endpoint        | `objectstores.openproject.endpoint` |                    |
|             |             | Provider        | `objectstores.openproject.provider` | `AWS` |
|             |             | Region          | `objectstores.openproject.region` |                    |
|             |             | Secret          | `objectstores.openproject.secret` |                    |
|             |             | Username        | `objectstores.openproject.username` | `openproject_user` |
|             |             | Use IAM profile | `objectstores.openproject.useIAMProfile` |                    |

# Cache

When deploying this suite to production, you need to configure the applications to use your production-grade cache
service.

| Component        | Name             | Type      | Parameter | Key                          | Default          |
|------------------|------------------|-----------|-----------|------------------------------|------------------|
| Intercom Service | Intercom Service | Redis     |           |                              |                  |
|                  |                  |           | Host      | `cache.intercomService.host` | `redis-headless` |
|                  |                  |           | Port      | `cache.intercomService.port` | `6379` |
| Nextcloud        | Nextcloud        | Redis     |           |                              |                  |
|                  |                  |           | Host      | `cache.nextcloud.host` | `redis-headless` |
|                  |                  |           | Port      | `cache.nextcloud.port` | `6379` |
| OpenProject      | OpenProject      | Memcached |           |                              |                  |
|                  |                  |           | Host      | `cache.openproject.host` | `memcached` |
|                  |                  |           | Port      | `cache.openproject.port` | `11211` |
| UMS              | Self Service     | Memcached |           |                              |                  |
|                  |                  |           | Host      | `cache.umsSelfservice.host` | `memcached` |
|                  |                  |           | Port      | `cache.umsSelfservice.port` | `11211` |
