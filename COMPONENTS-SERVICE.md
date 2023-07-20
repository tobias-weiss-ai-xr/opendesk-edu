<!--
SPDX-FileCopyrightText: 2023 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"

SPDX-License-Identifier: Apache-2.0
-->
**Content / Quick navigation**

[[_TOC_]]

# Service Components

Service components are required to operate the SWP. The deployment automation contains a full set of service components in order for the deployment to be self contained. But please be aware that the components are not ment to be used in production scenarios. Check out the service components details to understand how to make use of external services in case you want to setup production environments.

## Database - MariaDB

This services is used by:
- Nextcloud
- Open-Xchange
- XWiki

## Database - PostgreSQL

This services is used by:
- Keycloak
- OpenProject

## Redis

This service is used by:
- Intercom-Service
- Nextcloud

## Postfix

This service is used by:
- Keycloak (e.g. new device login notification)
- Nextcloud (e.g. share file notifictions)
- Open-Xchange (emails)
- OpenProject (general notifications)
- UCS (e.g. password reset emails)
- XWiki (e.g. change notifications)

## TURN Server

- dOZ 2.0
- Jitsi

## NFS

[remove this as it should be addressed by the RWX prerequsite!?]

This service is used by
- Dovecot
- Nextcloud

## ICAP

This service is used by
- Nextcloud
- Open-Xchange

## Objectstore - MinIO
